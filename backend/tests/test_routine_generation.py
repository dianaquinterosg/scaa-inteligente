import json

import httpx
from pydantic import ValidationError
import pytest

from scaa_backend.arasaac import ArasaacUnavailable
from scaa_backend.routine_association import associate
from scaa_backend.routine_generation import GeneratedRoutine, GenerationError, OllamaGenerator


def generated(*terms):
    return GeneratedRoutine.model_validate({
        "name": "Rutina", "steps": [
            {"order": i, "label": term, "search_term": term}
            for i, term in enumerate(terms, 1)
        ],
    })


def generator(handler):
    return OllamaGenerator("http://127.0.0.1:11434", "test", 10, httpx.MockTransport(handler))


def test_ollama_uses_schema_and_strictly_validates_messages():
    def respond(request):
        data = json.loads(request.content)
        assert request.url.path == "/api/chat"
        assert data["format"] == GeneratedRoutine.model_json_schema()
        assert data["stream"] is False and "tools" not in data
        assert json.loads(data["messages"][1]["content"]) == {
            "description": "Preparar mochila", "context": {"activities": ["Mochila azul"]}
        }
        return httpx.Response(200, json={
            "done": True, "message": {"content": generated("Mochila").model_dump_json()},
        })

    assert generator(respond).generate("Preparar mochila", {"activities": ["Mochila azul"]}).steps[0].order == 1


@pytest.mark.parametrize("content", [
    "no es JSON",
    '{"name":"X","steps":[]}',
    '{"name":"X","steps":[{"order":"1","label":"A","search_term":"a"}]}',
    '{"name":"X","steps":[{"order":2,"label":"A","search_term":"a"}]}',
    '{"name":"X","steps":[{"order":1,"label":"A","search_term":" " }]}',
    '{"name":"X","steps":[{"order":1,"label":"A","search_term":"a","id":3}]}',
])
def test_rejects_invalid_model_content(content):
    with pytest.raises(GenerationError, match="invalid_output"):
        generator(lambda _: httpx.Response(
            200, json={"done": True, "message": {"content": content}},
        )).generate("Preparar mochila", {})


def test_ollama_classifies_timeout_and_truncated_response():
    def timeout(request):
        raise httpx.ReadTimeout("límite", request=request)

    with pytest.raises(GenerationError, match="timeout"):
        generator(timeout).generate("Preparar mochila", {})
    with pytest.raises(GenerationError, match="invalid_output"):
        generator(lambda _: httpx.Response(200, json={
            "done": True, "done_reason": "length", "message": {"content": generated("Mochila").model_dump_json()},
        })).generate("Preparar mochila", {})


def test_limits_steps_and_rejects_remote_inference_host():
    with pytest.raises(ValidationError):
        generated(*["paso"] * 13)
    with pytest.raises(ValueError):
        OllamaGenerator("https://example.org", "test", 10)


class CatalogFixture:
    def list(self):
        return [
            {"id": 1, "label": "Água"},
            {"id": 2, "label": "Agua fría"},
            {"id": 3, "label": "Beber agua"},
            {"id": 4, "label": "Jabón   líquido"},
            {"id": 5, "label": "Usar jabón"},
            {"id": 6, "label": "Toalla grande"},
            {"id": 7, "label": "Toalla pequeña"},
            {"id": 8, "label": "Secar la mesa"},
        ]


class RemoteFixture:
    def __init__(self):
        self.calls = []

    def search(self, term):
        self.calls.append(term)
        if term == "caída":
            raise ArasaacUnavailable
        return [{"external_id": 99, "label": term}, {"external_id": 98, "label": "alternativa"}]


def test_association_ranks_and_respects_ambiguity():
    remote = RemoteFixture()
    result = associate(generated("  AGUA  ", "Jabon", "mesa", "toalla"), CatalogFixture(), remote)
    steps = result["steps"]
    assert [step["association"] for step in steps] == ["exact", "prefix", "contains", "ambiguous"]
    assert [step["selected"]["id"] for step in steps[:3]] == [1, 4, 8]
    assert steps[3]["selected"] is None
    assert [item["id"] for item in steps[3]["candidates"]] == [6, 7]
    assert not any(step["approved"] for step in steps)
    assert remote.calls == []


def test_association_deduplicates_queries_and_isolates_remote_failure():
    remote = RemoteFixture()
    result = associate(generated("Tomátes", "tomates", "caída", "agua"), CatalogFixture(), remote)
    steps = result["steps"]
    assert sorted(remote.calls) == ["Tomátes", "caída"]
    assert [s["association"] for s in steps] == ["arasaac", "arasaac", "unavailable", "exact"]
    assert steps[0]["selected"]["external_id"] == steps[1]["selected"]["external_id"] == 99
    assert steps[2]["selected"] is None
    assert not any(step["approved"] for step in steps)
