"""Contrato de la propuesta lingüística con una sola inferencia."""

import json

import httpx
import pytest
from pydantic import ValidationError

from scaa_backend.routine_generation import (
    GenerationError, LinguisticGeneratedRoutine, OllamaGenerator,
)


@pytest.mark.parametrize("label", [
    "dormir", "defecar", "orinar", "caminar", "saltar", "acostar", "vestir",
    "lavar las manos", "abrir la mochila", "poner el pijama", "sentar en el váter",
    "ir al baño",
])
def test_label_is_preserved_in_both_contract_fields(label):
    routine = LinguisticGeneratedRoutine.model_validate(
        {"name": "Rutina", "steps": [{"order": 1, "label": label}]},
    ).to_proposal()
    assert routine.steps[0].label == routine.steps[0].search_term == label


@pytest.mark.parametrize("label", [
    "lavarse las manos", "ponerse el pijama", "acostarse", "vestirse",
    "mojar", "colocar", "poner", "abrir", "guardar", "lavar manos",
    "sentar en el inodoro", "encender el computador", "beber el jugo",
])
def test_rejects_violations_of_the_stated_rules(label):
    with pytest.raises(ValidationError):
        LinguisticGeneratedRoutine.model_validate(
            {"name": "Rutina", "steps": [{"order": 1, "label": label}]},
        )


def test_ollama_receives_compact_schema_and_only_one_call():
    calls = []

    def reply(request):
        data = json.loads(request.content)
        calls.append(data)
        assert data["keep_alive"] == "10m"
        assert data["options"]["temperature"] == 0
        assert data["format"]["properties"]["steps"]["maxItems"] == 4
        properties = data["format"]["$defs"]["LinguisticStep"]["properties"]
        assert set(properties) == {"order", "label"}
        return httpx.Response(200, json={
            "done": True, "message": {"content": json.dumps({
                "name": "Higiene", "steps": [{"order": 1, "label": "lavar las manos"}],
            })},
        })

    generator = OllamaGenerator(
        "http://localhost:11434", "qwen3:4b-instruct", 60,
        httpx.MockTransport(reply), prompt_profile="linguistic",
    )
    assert generator.generate("Lavarse las manos", {}).steps[0].search_term == "lavar las manos"
    assert len(calls) == 1


@pytest.mark.parametrize("steps", [
    [{"order": 2, "label": "dormir"}],
    [{"order": 1, "label": "dormir", "search_term": "cama"}],
    [{"order": i, "label": "dormir"} for i in range(1, 6)],
])
def test_ollama_response_rejects_extra_fields_and_invalid_orders_or_lengths(steps):
    generator = OllamaGenerator(
        "http://localhost:11434", "qwen3:4b-instruct", 60,
        httpx.MockTransport(lambda request: httpx.Response(200, json={
            "done": True, "message": {"content": json.dumps({"name": "Dormir", "steps": steps})},
        })), prompt_profile="linguistic",
    )
    with pytest.raises(GenerationError, match="invalid_output"):
        generator.generate("Prepararse para dormir", {})
