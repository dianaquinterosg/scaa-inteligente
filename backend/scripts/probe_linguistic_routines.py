"""Mide una propuesta por rutina usando Uvicorn, Ollama y ARASAAC reales."""

import json
from pathlib import Path
import socket
import sys
from tempfile import TemporaryDirectory
from threading import Thread
from time import perf_counter, sleep
from unittest.mock import patch

import httpx
import uvicorn

from scaa_backend import routine_api, routine_association
from scaa_backend.arasaac import ArasaacClient, ArasaacUnavailable
from scaa_backend.main import create_app
from scaa_backend.routine_generation import LINGUISTIC_MAX_STEPS, LINGUISTIC_MIN_STEPS
from scaa_backend.settings import Settings

MODEL = "qwen3:4b-instruct"
OLLAMA = "http://127.0.0.1:11434"
DESCRIPTIONS = (
    "Lavarse las manos", "Cepillarse los dientes", "Prepararse para dormir", "Ir al baño",
    "Guardar los juguetes",
)


def run(output):
    with TemporaryDirectory() as storage, httpx.Client(timeout=60, trust_env=False) as ollama:
        preload = ollama.post(OLLAMA + "/api/generate", json={"model": MODEL, "keep_alive": "10m"})
        preload.raise_for_status()
        resident = next(row for row in ollama.get(OLLAMA + "/api/ps").json()["models"] if row["name"] == MODEL)
        app = create_app(Settings("test", Path(storage), ollama_model=MODEL, ollama_prompt_profile="linguistic"))
        catalog_list = app.state.catalog.list
        measurements = {}
        queries = {}
        actual_associate = routine_api.associate
        actual_local_match = routine_association.best_local

        def capture_inference(request):
            sent = json.loads(request.content)
            assert sent["model"] == MODEL
            assert sent["keep_alive"] == "10m"
            steps = sent["format"]["properties"]["steps"]
            assert steps["minItems"] == LINGUISTIC_MIN_STEPS
            assert steps["maxItems"] == LINGUISTIC_MAX_STEPS
            assert "search_term" not in sent["format"]["$defs"]["LinguisticStep"]["properties"]
            started = perf_counter()
            reply = ollama.send(request)
            body = reply.json()
            measurements["inferences"] += 1
            measurements["inference"] = perf_counter() - started
            measurements["ollama_status"] = reply.status_code
            measurements["ollama_error"] = body.get("error")
            measurements["eval_count"] = body.get("eval_count")
            measurements["load_duration_ns"] = body.get("load_duration")
            measurements["raw_model"] = body.get("message", {}).get("content")
            return reply

        def capture_list(*args, **kwargs):
            started = perf_counter()
            rows = catalog_list(*args, **kwargs)
            measurements["local"] += perf_counter() - started
            return rows

        def capture_local_match(*args, **kwargs):
            started = perf_counter()
            match = actual_local_match(*args, **kwargs)
            measurements["local"] += perf_counter() - started
            return match

        def capture_association(*args, **kwargs):
            started = perf_counter()
            result = actual_associate(*args, **kwargs)
            measurements["association"] = perf_counter() - started
            return result

        class RecordedArasaac(ArasaacClient):
            def search(self, term, *, include_keywords=False):
                assert not include_keywords
                started = perf_counter()
                candidates = []
                unavailable = False
                try:
                    candidates = super().search(term, include_keywords=True)
                    return [{k: v for k, v in item.items() if k != "keywords"} for item in candidates]
                except ArasaacUnavailable:
                    unavailable = True
                    raise
                finally:
                    queries[term] = (started, perf_counter(), candidates[0] if candidates else None, unavailable)

        app.state.arasaac = RecordedArasaac()
        app.state.catalog.list = capture_list
        app.state.generator.transport = httpx.MockTransport(capture_inference)
        server = uvicorn.Server(uvicorn.Config(app, log_level="error", access_log=False))
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            thread = Thread(target=server.run, kwargs={"sockets": [listener]}, daemon=True)
            thread.start()
            try:
                for _ in range(100):
                    if server.started:
                        break
                    sleep(.02)
                assert server.started
                port = listener.getsockname()[1]
                with httpx.Client(base_url=f"http://127.0.0.1:{port}/api/v1", timeout=70, trust_env=False) as api, patch.object(
                    routine_api, "associate", capture_association
                ), patch.object(routine_association, "best_local", capture_local_match):
                    assert api.put("/profile", json={"alias": "Perfil sintético"}).status_code == 200
                    report = {
                        "model": MODEL, "ollama_version": ollama.get(OLLAMA + "/api/version").json()["version"],
                        "digest": resident["digest"], "context_window": resident.get("context_length"),
                        "preloaded": True, "keep_alive": "10m",
                        "results": [],
                    }
                    for description in DESCRIPTIONS:
                        measurements.clear()
                        measurements.update(inferences=0, local=0.0)
                        queries.clear()
                        start = perf_counter()
                        response = api.post("/routines/proposals", json={"description": description})
                        total = perf_counter() - start
                        proposal = response.json()
                        remote = (max(row[1] for row in queries.values()) - min(row[0] for row in queries.values())
                                  if queries else 0.0)
                        steps = []
                        for step in proposal.get("steps", []):
                            assert step["label"] == step["search_term"] and not step["approved"]
                            query = queries.get(step["label"])
                            chosen = step["selected"]
                            first = query[2] if query else None
                            if query:
                                assert (chosen or {}).get("external_id") == (first or {}).get("external_id")
                            steps.append({
                                "order": step["order"], "label": step["label"], "search_term": step["search_term"],
                                "arasaac_query": step["label"] if query else None,
                                "arasaac_query_seconds": round(query[1] - query[0], 3) if query else None,
                                "arasaac_unavailable": query[3] if query else False,
                                "suggestion_id": (chosen or {}).get("external_id"),
                                "suggestion_label": (chosen or {}).get("label"),
                                "keywords": (first or {}).get("keywords", []),
                            })
                        assert measurements["inferences"] == 1
                        assert api.get("/routines").json() == []
                        report["results"].append({
                            "description": description, "status": response.status_code,
                            "steps": steps, "error": proposal.get("detail"),
                            "seconds": {"inference": round(measurements["inference"], 3),
                                        "local_catalog": round(measurements["local"], 4),
                                        "arasaac_wall": round(remote, 3),
                                        "association_including_search": round(measurements.get("association", 0), 3),
                                        "association_without_search": round(max(
                                            0.0, measurements.get("association", 0) - measurements["local"] - remote
                                        ), 4),
                                        "http_total": round(total, 3)},
                            "ollama_status": measurements.get("ollama_status"),
                            "ollama_error": measurements.get("ollama_error"),
                            "generated_tokens": measurements.get("eval_count"),
                            "model_load_ns": measurements.get("load_duration_ns"),
                            "raw_model": measurements.get("raw_model"),
                        })
                        output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
                        print(description, response.status_code, round(total, 3),
                              [step["label"] for step in steps] or measurements.get("raw_model"), flush=True)
            finally:
                server.should_exit = True
                thread.join(timeout=5)


if __name__ == "__main__":
    run(Path(sys.argv[1]))
