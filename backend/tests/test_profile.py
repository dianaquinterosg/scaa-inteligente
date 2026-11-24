import sqlite3
import json

from fastapi.testclient import TestClient
import pytest

from scaa_backend.main import create_app
from scaa_backend.settings import Settings


@pytest.fixture
def configured(tmp_path):
    settings = Settings("test", tmp_path)
    app = create_app(settings)
    with TestClient(app) as client:
        yield client, settings


def test_first_use_requires_alias_and_has_no_profile(configured):
    client, _ = configured
    assert client.get("/api/v1/profile").status_code == 404
    assert client.put("/api/v1/profile", json={}).status_code == 422
    assert client.get("/api/v1/profile").status_code == 404


def test_create_normalize_and_recover_all_context_types(configured):
    client, _ = configured
    payload = {"alias": "  Ana  ", "interests": [" Música ", "Agua"],
               "activities": [" Agua "], "frequent_routines": [" Salida "]}
    response = client.put("/api/v1/profile", json=payload)
    assert response.status_code == 200
    assert response.json() == {"id": 1, "alias": "Ana", "interests": ["Música", "Agua"],
                               "activities": ["Agua"], "frequent_routines": ["Salida"]}
    assert client.get("/api/v1/profile").json() == response.json()


@pytest.mark.parametrize("field", ["interests", "activities", "frequent_routines"])
def test_edit_and_delete_individual_items(configured, field):
    client, _ = configured
    payload = {"alias": "Ana", "interests": ["Música", "Agua"], "activities": ["Caminar"], "frequent_routines": ["Lectura"]}
    client.put("/api/v1/profile", json=payload)
    payload.update(alias="Eva")
    payload[field] = ["Editado"]
    response = client.put("/api/v1/profile", json=payload)
    assert response.status_code == 200
    assert client.get("/api/v1/profile").json() == {"id": 1, **payload}
    payload[field] = []
    assert client.put("/api/v1/profile", json=payload).status_code == 200
    assert client.get("/api/v1/profile").json() == {"id": 1, **payload}


@pytest.mark.parametrize("alias", ["", "  ", "a" * 51, None, 123, "\ud800"])
def test_invalid_alias_does_not_replace_saved_profile(configured, alias):
    client, _ = configured
    before = client.put("/api/v1/profile", json={"alias": "Confirmado"}).json()
    response = client.put("/api/v1/profile", content=json.dumps({"alias": alias}), headers={"Content-Type": "application/json"})
    assert response.status_code == 422
    assert all("input" not in item and not item["msg"].startswith("Value error, ") for item in response.json()["detail"])
    assert client.get("/api/v1/profile").json() == before


@pytest.mark.parametrize("field", ["interests", "activities", "frequent_routines"])
@pytest.mark.parametrize("items", [[""], ["  "], ["a" * 51], [" Agua ", "aGUA"], ["Straße", "STRASSE"], [1], None])
def test_invalid_items_are_rejected_per_type(configured, field, items):
    client, _ = configured
    before = client.put("/api/v1/profile", json={"alias": "Confirmado"}).json()
    response = client.put("/api/v1/profile", json={"alias": "Nuevo", field: items})
    assert response.status_code == 422
    assert client.get("/api/v1/profile").json() == before


def test_boundaries_unicode_and_single_profile(configured):
    client, settings = configured
    payload = {"alias": "ñ" * 50, "interests": ["😀" * 50]}
    assert client.put("/api/v1/profile", json=payload).status_code == 200
    assert client.put("/api/v1/profile", json={"alias": "D'Angelo"}).status_code == 200
    assert client.put("/api/v1/profile", json={"alias": "Otro", "id": 2}).status_code == 422
    with sqlite3.connect(settings.database_path) as db:
        assert db.execute("SELECT count(*) FROM profile").fetchone() == (1,)


def test_database_failure_rolls_back_alias_deletion_and_partial_insert(configured):
    client, settings = configured
    before = client.put("/api/v1/profile", json={"alias": "Anterior", "interests": ["Guardado"], "activities": ["Caminar"]}).json()
    with sqlite3.connect(settings.database_path) as db:
        db.execute("CREATE TRIGGER fail_probe BEFORE INSERT ON context_item WHEN NEW.value = 'FALLAR' BEGIN SELECT RAISE(ABORT, 'fallo de prueba'); END")
    response = client.put("/api/v1/profile", json={"alias": "Cambio", "interests": ["Insertado", "FALLAR"]})
    assert response.status_code == 503
    assert client.get("/api/v1/profile").json() == before


def test_profile_persists_across_application_restart(configured):
    client, settings = configured
    saved = client.put("/api/v1/profile", json={"alias": "Persistente", "frequent_routines": ["Lectura"]}).json()
    with TestClient(create_app(settings)) as restarted:
        assert restarted.get("/api/v1/profile").json() == saved


def test_only_confirmed_context_is_available(configured):
    client, _ = configured
    before = client.put("/api/v1/profile", json={"alias": "Ana", "interests": ["Confirmado"]}).json()
    draft = {"alias": "Borrador", "interests": ["No confirmado"]}
    assert client.get("/api/v1/profile").json() == before
    draft["interests"].append("")
    assert client.put("/api/v1/profile", json=draft).status_code == 422
    assert client.get("/api/v1/profile").json() == before


def test_failed_read_is_not_reported_as_first_use(configured, monkeypatch):
    client, _ = configured
    def fail():
        raise sqlite3.OperationalError("fallo de lectura")
    monkeypatch.setattr(client.app.state.profiles, "load", fail)
    assert client.get("/api/v1/profile").status_code == 503
