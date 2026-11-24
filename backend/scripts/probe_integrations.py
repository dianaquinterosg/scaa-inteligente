"""Sonda real de servicios externos; no incorpora recursos ni rutinas al catálogo."""

import argparse
import hashlib
import json
import os
from pathlib import Path
from urllib.parse import quote

from dotenv import load_dotenv
import httpx
from pydantic import BaseModel, ConfigDict, Field

ROOT = Path(__file__).resolve().parents[2]


class Step(BaseModel):
    model_config = ConfigDict(extra="forbid")
    order: int = Field(gt=0)
    label: str = Field(min_length=1)
    search_term: str = Field(min_length=1)


class Proposal(BaseModel):
    model_config = ConfigDict(extra="forbid")
    name: str = Field(min_length=1)
    steps: list[Step] = Field(min_length=1)


def probe_arasaac(client: httpx.Client) -> dict:
    base = os.getenv("ARASAAC_BASE_URL", "https://api.arasaac.org/api").rstrip("/")
    response = client.get(f"{base}/pictograms/es/search/{quote('agua', safe='')}")
    response.raise_for_status()
    pictograms = response.json()
    if not isinstance(pictograms, list) or not pictograms:
        raise ValueError("ARASAAC no devolvió alternativas para agua")
    identifier = pictograms[0]["_id"]
    if type(identifier) is not int or identifier <= 0:
        raise ValueError("Identificador ARASAAC inválido")
    image = client.get(f"https://static.arasaac.org/pictograms/{identifier}/{identifier}_300.png")
    image.raise_for_status()
    if not image.content.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("La imagen de prueba no es PNG")
    return {
        "status": "passed", "query": "agua", "url": str(response.url),
        "http_status": response.status_code, "count": len(pictograms),
        "sample_id": identifier, "sample_keywords": pictograms[0].get("keywords", []),
        "image": {"url": str(image.url), "http_status": image.status_code,
                  "bytes": len(image.content), "sha256": hashlib.sha256(image.content).hexdigest()},
        "persistence": "Solo metadatos de evidencia; sin incorporar pictogramas a la aplicación",
        "source": "https://arasaac.org/", "license_reference": "https://arasaac.org/terms-of-use",
    }


def probe_ollama(client: httpx.Client) -> dict:
    base = os.getenv("OLLAMA_BASE_URL", "http://127.0.0.1:11434").rstrip("/")
    model = os.getenv("OLLAMA_MODEL", "qwen2.5:1.5b")
    version = client.get(f"{base}/api/version")
    version.raise_for_status()
    proposals = []
    for description in ["Organizar una mochila", "Poner la mesa", "Guardar juguetes"]:
        payload = {
            "model": model, "stream": False, "format": Proposal.model_json_schema(),
            "prompt": (
                "Propón una rutina visual sencilla para: " + description + ". "
                "Devuelve solo JSON con name y entre 3 y 5 steps. Cada paso tiene order desde 1, "
                "label y search_term breve para buscar un pictograma. Usa español también en "
                "search_term, una acción concreta por paso y no añadas contexto que no se indicó."
            ),
            "options": {"temperature": 0, "num_ctx": 2048, "num_predict": 400},
            "keep_alive": "1m",
        }
        response = client.post(f"{base}/api/generate", json=payload, timeout=120)
        response.raise_for_status()
        data = response.json()
        if not data.get("done"):
            raise ValueError("Generación incompleta")
        proposal = Proposal.model_validate_json(data["response"])
        if [step.order for step in proposal.steps] != list(range(1, len(proposal.steps) + 1)):
            raise ValueError("Posiciones de pasos no consecutivas")
        proposals.append({"description": description, "request": payload,
                          "response": data, "validated": proposal.model_dump(),
                          "schema_valid": True, "human_approved": False})
    running = client.get(f"{base}/api/ps")
    running.raise_for_status()
    return {"status": "passed", "version": version.json(), "model": model,
            "proposals": proposals, "running": running.json(),
            "scope": "Viabilidad técnica; calidad y aprobación humana pendientes"}



def documentary(value):
    """Conservar resultados y excluir metadatos temporales de la evidencia."""
    if isinstance(value, dict):
        return {k: documentary(v) for k, v in value.items()
                if not k.endswith("_duration") and not k.endswith("_at")
                and k not in {"created", "lastUpdated", "elapsed_seconds"}}
    if isinstance(value, list):
        return [documentary(item) for item in value]
    return value


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--service", choices=["arasaac", "ollama", "all"], default="all")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("La evidencia ya existe; elige otra ruta para conservar los resultados anteriores")
    load_dotenv(ROOT / "backend" / ".env", override=False)
    results = {}
    with httpx.Client(timeout=20, follow_redirects=True) as client:
        for name, probe in [("arasaac", probe_arasaac), ("ollama", probe_ollama)]:
            if args.service not in {"all", name}:
                continue
            try:
                results[name] = probe(client)
            except Exception as error:
                results[name] = {"status": "failed", "error": str(error)}
            print(f"{name}: {results[name]['status']}", flush=True)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("x") as output:
        json.dump(documentary(results), output, ensure_ascii=False, indent=2)
    return 0 if all(result["status"] == "passed" for result in results.values()) else 1


if __name__ == "__main__":
    raise SystemExit(main())
