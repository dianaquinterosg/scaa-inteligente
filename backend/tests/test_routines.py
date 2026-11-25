import base64
import json
import sqlite3

from fastapi.testclient import TestClient
import httpx
import pytest

from scaa_backend.main import create_app
from scaa_backend.routine_generation import GenerationError, OllamaGenerator
from scaa_backend.settings import Settings

R = "/api/v1/routines"
P = "/api/v1/pictograms"
PROFILE = "/api/v1/profile"
PNG = "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAFElEQVR4nGNkYPjPgA0wYRUdtBIAy0MBD1YkjLoAAAAASUVORK5CYII="


class Remote:
    def __init__(self, database):
        self.database = database
        self.downloads = []
        self.searches = []
        self.on_search = None

    def search(self, query):
        self.searches.append(query)
        if self.on_search:
            self.on_search()
        return [{"external_id": 777, "label": query, "image_url": f"{P}/arasaac/777/image"}]

    def image(self, external_id):
        # La descarga debe poder tomar un lock independiente de escritura.
        with self.database.connection() as connection:
            connection.execute("PRAGMA busy_timeout=1")
            connection.execute("BEGIN IMMEDIATE")
        self.downloads.append(external_id)
        return base64.b64decode(PNG)


@pytest.fixture
def app_context(tmp_path):
    settings = Settings("test", tmp_path)
    app = create_app(settings)
    app.state.arasaac = Remote(app.state.database)
    with TestClient(app) as client:
        response = client.put(PROFILE, json={
            "alias": "Alias privado", "activities": ["Mochila azul", "Pescar"], "interests": ["Ajedrez"]
        })
        assert response.status_code == 200
        yield client, app, settings


def picture(client, label="Agua"):
    result = client.post(P, json={"confirmed": True, "image_base64": PNG, "label": label})
    assert result.status_code == 201
    return result.json()


def local(order, identifier, label="Hacer paso"):
    return {"order": order, "label": label, "pictogram_id": identifier, "approved": True}


def external(order, identifier=777, label="Hacer paso"):
    return {
        "order": order, "label": label, "external_id": identifier,
        "pictogram_label": "Material", "approved": True,
    }


def approval(*steps, **patch):
    return {"confirmed": True, "name": "Preparar mochila", "description": "Preparar la mochila", "steps": steps, **patch}


def test_proposal_uses_persisted_context_without_alias_or_unconfirmed_draft(app_context):
    client, app, _ = app_context
    draft = client.get(PROFILE).json()
    draft["activities"] = ["Mochila verde, aún sin confirmar"]
    def ollama(request):
        with app.state.database.connection() as connection:
            connection.execute("PRAGMA busy_timeout=1")
            connection.execute("BEGIN IMMEDIATE")
        data = json.loads(request.content)
        user = json.loads(data["messages"][1]["content"])
        assert user == {"description": "Preparar mochila", "context": {"activities": ["Mochila azul"]}}
        with app.state.database.connection() as connection:
            assert connection.execute("SELECT count(*) FROM routine").fetchone() == (0,)
        assert draft["activities"][0] not in request.content.decode()
        return httpx.Response(200, json={"done": True, "message": {"content": json.dumps({
            "name": "Preparar mochila",
            "steps": [{"order": 1, "label": "Abrir mochila", "search_term": "mochila"}],
        })}})
    app.state.generator = OllamaGenerator("http://127.0.0.1:11434", "test", 10, httpx.MockTransport(ollama))
    response = client.post(R + "/proposals", json={"description": "  Preparar mochila "})
    assert response.status_code == 200
    step = response.json()["steps"][0]
    assert step["selected"]["external_id"] == 777 and step["approved"] is False
    assert client.get(P).json() == [] and client.get(R).json() == []
    assert not app.state.catalog.directory.exists()


@pytest.mark.parametrize("kind,code", [("timeout", 504), ("invalid_output", 502), ("unavailable", 503)])
def test_ai_errors_allow_manual_creation(app_context, kind, code):
    client, app, _ = app_context

    class FailedGenerator:
        def generate(self, description, context):
            raise GenerationError(kind)

    app.state.generator = FailedGenerator()
    assert client.post(R + "/proposals", json={"description": " "}).status_code == 422
    failed = client.post(R + "/proposals", json={"description": "Higiene"})
    assert failed.status_code == code and "manualmente" in failed.json()["detail"]
    assert client.get(R).json() == []
    item = picture(client)
    result = client.post(R, json=approval(local(1, item["id"]), description=""))
    assert result.status_code == 201


@pytest.mark.parametrize("patch", [
    {"confirmed": False}, {"confirmed": 1}, {"name": " "}, {"steps": []},
    {"steps": [{"order": 1, "label": "Paso", "approved": True}]},
    {"steps": [{"order": 1, "label": "Paso", "pictogram_id": 1, "approved": False}]},
    {"steps": [local(2, 1)]}, {"steps": [local(1, 1)] * 13},
])
def test_save_rejects_incomplete_unapproved_or_invalid_draft(app_context, patch):
    client, app, _ = app_context
    assert client.post(R, json=approval(external(1), **patch)).status_code == 422
    assert client.get(R).json() == [] and client.get(P).json() == []
    assert app.state.arasaac.downloads == []


def test_reuses_external_and_local_pictures_then_reopens_edits_and_deletes(app_context):
    client, app, settings = app_context
    own = picture(client)
    response = client.post(R, json=approval(external(1), local(2, own["id"]), external(3)))
    assert response.status_code == 201
    routine = response.json()
    assert [step["order"] for step in routine["steps"]] == [1, 2, 3]
    imported = routine["steps"][0]["pictogram"]["id"]
    assert routine["steps"][2]["pictogram"]["id"] == imported
    assert app.state.arasaac.downloads == [777]
    second = client.post(R, json=approval(external(1), name="Otra rutina")).json()
    assert second["steps"][0]["pictogram"]["id"] == imported
    assert len(client.get(P).json()) == 2 and app.state.arasaac.downloads == [777]
    path = f"{R}/{routine['id']}"
    conflict = client.delete(f"{P}/{imported}")
    assert conflict.status_code == 409
    detail = conflict.json()["detail"]
    assert detail["code"] == "pictogram_in_use"
    assert detail["routines"] == [
        {"id": routine["id"], "name": routine["name"]},
        {"id": second["id"], "name": second["name"]},
    ]
    assert client.get(path).json() == routine
    assert client.get(routine["steps"][0]["pictogram"]["image_url"]).status_code == 200
    with TestClient(create_app(settings)) as restarted:
        assert restarted.get(path).json() == routine
        edited = restarted.put(path, json=approval(
            local(1, own["id"], "Confirmar"), local(2, imported, "Abrir"), name="Mi mochila",
        )).json()
        assert edited["name"] == "Mi mochila"
        assert [step["label"] for step in edited["steps"]] == ["Confirmar", "Abrir"]
        assert restarted.delete(path).status_code == 204
        assert restarted.get(path).status_code == 404
        conflict = restarted.delete(f"{P}/{imported}")
        assert conflict.status_code == 409
        assert conflict.json()["detail"]["routines"] == [{"id": second["id"], "name": second["name"]}]
        with app.state.database.connection() as connection, pytest.raises(sqlite3.IntegrityError):
            connection.execute("DELETE FROM pictogram WHERE id=?", (imported,))
        assert restarted.delete(f"{R}/{second['id']}").status_code == 204
        assert len(restarted.get(P).json()) == 2
        assert restarted.delete(f"{P}/{imported}").status_code == 204


def test_rolls_back_new_images_and_preserves_independently_approved_picture(app_context):
    client, app, _ = app_context
    independently_saved = client.post(P, json={"confirmed": True, "label": "Cuaderno", "external_id": 501}).json()
    before = set(app.state.catalog.directory.iterdir())
    with app.state.database.connection() as connection:
        connection.executescript(
            "CREATE TRIGGER fail_last BEFORE INSERT ON routine_step WHEN NEW.position=3 "
            "BEGIN SELECT RAISE(ABORT, 'fallo de prueba'); END;"
        )
    failed = client.post(R, json=approval(external(1), external(2, 778), local(3, independently_saved["id"])))
    assert failed.status_code == 503
    assert client.get(R).json() == []
    assert client.get(P).json() == [independently_saved]
    assert set(app.state.catalog.directory.iterdir()) == before
    assert client.get(independently_saved["image_url"]).status_code == 200


def test_failed_update_keeps_previously_approved_steps_and_files(app_context):
    client, app, _ = app_context
    saved = picture(client)
    routine = client.post(R, json=approval(local(1, saved["id"]))).json()
    path = f"{R}/{routine['id']}"
    before = set(app.state.catalog.directory.iterdir())
    failed = client.put(path, json=approval(external(1), local(2, 999999), name="Alterada"))
    assert failed.status_code == 422
    assert client.get(path).json() == routine
    assert set(app.state.catalog.directory.iterdir()) == before


def test_linguistic_association_sends_the_exact_label_and_reuses_duplicate_queries(tmp_path):
    from scaa_backend.routine_generation import LinguisticGeneratedRoutine

    app = create_app(Settings(
        "test", tmp_path, ollama_model="qwen3:4b-instruct",
        ollama_prompt_profile="linguistic", routine_external_match="contextual",
    ))
    labels = ["Lavar las manos", "ir al baño", "Lavar las manos", "abrir la puerta"]

    class Generator:
        def generate(self, description, context):
            return LinguisticGeneratedRoutine(
                name="Higiene",
                steps=[{"order": i, "label": label} for i, label in enumerate(labels, 1)],
            ).to_proposal()

    class RemoteKeywords:
        def __init__(self):
            self.calls = []

        def search(self, term, *, include_keywords=False):
            assert include_keywords
            self.calls.append(term)
            if term == "ir al baño":
                return [{"external_id": 27, "label": "quedarse solo"}]
            return [
                {"external_id": 25, "label": "Primera sugerencia", "keywords": ["Lavar las manos"]},
                {"external_id": 26, "label": "Lavar las manos"},
            ]

    app.state.generator = Generator()
    app.state.arasaac = remote = RemoteKeywords()
    with TestClient(app) as client:
        assert client.put(PROFILE, json={"alias": "Perfil sintético"}).status_code == 200
        saved_picture = picture(client, "abrir la puerta")
        response = client.post(f"{R}/proposals", json={"description": "Higiene"})
        assert response.status_code == 200
        steps = response.json()["steps"]
        assert sorted(remote.calls) == ["Lavar las manos", "ir al baño"]
        assert [step["search_term"] for step in steps] == labels
        assert [step["selected"] and step["selected"].get("external_id") for step in steps[:3]] == [
            26, None, 26,
        ]
        assert steps[3]["selected"]["id"] == saved_picture["id"]
        assert all(not step["approved"] for step in steps)
        assert client.get(R).json() == []
        assert client.get(P).json() == [saved_picture]


def test_linguistic_profile_keeps_twelve_manual_steps_for_creation_and_editing(tmp_path):
    app = create_app(Settings("test", tmp_path, ollama_prompt_profile="linguistic"))
    with TestClient(app) as client:
        assert client.put(PROFILE, json={"alias": "Perfil sintético"}).status_code == 200
        item = picture(client)
        steps = [local(i, item["id"], f"Acción {i}") for i in range(1, 13)]
        created = client.post(R, json=approval(*steps, description=""))
        assert created.status_code == 201
        routine = created.json()
        edited = client.put(f"{R}/{routine['id']}", json=approval(*steps, name="Rutina editada"))
        assert edited.status_code == 200
        assert edited.json()["name"] == "Rutina editada"
        assert [step["order"] for step in edited.json()["steps"]] == list(range(1, 13))
        assert client.post(R, json=approval(*steps, local(13, item["id"]))).status_code == 422
