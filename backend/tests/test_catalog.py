import base64
from io import BytesIO

import httpx
from fastapi.testclient import TestClient
from PIL import Image
import pytest

from scaa_backend.arasaac import ArasaacClient, MAX_IMAGE_BYTES
from scaa_backend.main import create_app
from scaa_backend.settings import Settings

BASE = "/api/v1"
PICTOGRAMS = BASE + "/pictograms"
CATEGORIES = BASE + "/categories"


def picture(fmt="PNG"):
    image = BytesIO()
    Image.new("RGB", (8, 8), "blue").save(image, format=fmt)
    return image.getvalue()


def custom(label="Agua", **values):
    return {"confirmed": True, "label": label, "image_base64": base64.b64encode(picture()).decode(), **values}


@pytest.fixture
def catalog(tmp_path):
    app = create_app(Settings("test", tmp_path))
    calls = []
    app.state.arasaac = ArasaacClient(httpx.MockTransport(lambda request: remote(request, calls)))
    with TestClient(app) as client:
        yield client, app, calls


def remote(request, calls):
    calls.append(str(request.url))
    if request.url.path.endswith("/fallo"):
        return httpx.Response(503)
    if request.url.path.endswith("/ausente"):
        return httpx.Response(404)
    if request.url.host == "static.arasaac.org":
        return httpx.Response(200, content=picture())
    return httpx.Response(200, json=[{"_id": 123, "keywords": [{"keyword": "Agua"}]}])


def test_local_first_remote_alternatives_preview_and_no_implicit_save(catalog):
    client, _, calls = catalog
    assert client.get(PICTOGRAMS + "/search", params={"q": " "}).status_code == 422
    found = client.get(PICTOGRAMS + "/search", params={"q": " agua "}).json()
    assert found["local"] == []
    candidate = found["alternatives"][0]
    assert candidate["label"] == "Agua" and "CC BY-NC-SA" in candidate["attribution"]
    assert client.get(candidate["image_url"]).content == picture()
    assert client.get(PICTOGRAMS).json() == []
    assert client.post(PICTOGRAMS, json=custom("Agua potable")).status_code == 201
    calls.clear()
    local = client.get(PICTOGRAMS + "/search", params={"q": "AGUA"}).json()
    assert len(local["local"]) == 1 and local["remote_status"] == "not_requested"
    assert not calls
    alternatives = client.get(PICTOGRAMS + "/search", params={"q": "AGUA", "alternatives": True}).json()
    assert len(alternatives["local"]) == len(alternatives["alternatives"]) == len(calls) == 1


def test_arasaac_outage_offers_manual_path_and_distinguishes_no_results(catalog):
    client, _, _ = catalog
    result = client.get(PICTOGRAMS + "/search", params={"q": "fallo"}).json()
    assert result == {"local": [], "alternatives": [], "remote_status": "unavailable"}
    assert client.get(PICTOGRAMS + "/search", params={"q": "ausente"}).json()["remote_status"] == "available"
    assert client.post(PICTOGRAMS, json=custom()).status_code == 201


@pytest.mark.parametrize("fmt,mime", [("PNG", "png"), ("JPEG", "jpeg"), ("WEBP", "webp")])
def test_approved_files_are_local_and_keep_detected_formats(catalog, fmt, mime):
    client, app, _ = catalog
    data = picture(fmt)
    response = client.post(PICTOGRAMS, json=custom(" Agua ", image_base64=base64.b64encode(data).decode()))
    assert response.status_code == 201
    item = response.json()
    assert item["label"] == "Agua" and item["source"] == "CUSTOM"
    saved = client.get(item["image_url"])
    assert saved.content == data and saved.headers["content-type"] == f"image/{mime}"
    assert [p.read_bytes() for p in app.state.catalog.directory.iterdir()] == [data]


@pytest.mark.parametrize("patch", [
    {"confirmed": False}, {"confirmed": 1}, {"label": " "}, {"label": "x" * 101},
    {"image_base64": "!!!"}, {"image_base64": "dGV4dG8="},
    {"image_base64": base64.b64encode(picture()[:-20]).decode()},
    {"category_ids": [99]}, {"category_ids": [1, 1]},
    {"external_id": 123}, {"image_base64": None},
])
def test_invalid_approval_leaves_no_metadata_or_file(catalog, patch):
    client, app, _ = catalog
    assert client.post(PICTOGRAMS, json=custom(**patch)).status_code == 422
    assert client.get(PICTOGRAMS).json() == []
    assert not app.state.catalog.directory.exists()


def test_missing_confirmation_and_oversize_are_rejected(catalog):
    client, _, _ = catalog
    payload = custom()
    del payload["confirmed"]
    assert client.post(PICTOGRAMS, json=payload).status_code == 422
    encoded = base64.b64encode(bytes(MAX_IMAGE_BYTES + 1)).decode()
    assert client.post(PICTOGRAMS, json=custom(image_base64=encoded)).status_code == 413
    assert client.post(PICTOGRAMS, content=b"x" * (len(encoded) + 9000)).status_code == 413
    assert client.get(PICTOGRAMS).json() == []


def test_arasaac_attribution_unique_reference_and_reopen(tmp_path):
    settings = Settings("test", tmp_path)
    app = create_app(settings)
    calls = []
    app.state.arasaac = ArasaacClient(httpx.MockTransport(lambda req: remote(req, calls)))
    payload = {"confirmed": True, "external_id": 123, "label": "Beber"}
    with TestClient(app) as client:
        response = client.post(PICTOGRAMS, json=payload)
        assert response.status_code == 201
        item = response.json()
        assert item["attribution"] and item["external_id"] == 123
        assert client.post(PICTOGRAMS, json=payload).status_code == 409
        assert len(calls) == 1
        folder = app.state.catalog.directory
        assert len(list(folder.iterdir())) == 1
    with TestClient(create_app(settings)) as restarted:
        assert restarted.get(PICTOGRAMS).json() == [item]
        assert restarted.get(item["image_url"]).content == picture()


def test_category_lifecycle_relationships_filter_and_reopen(tmp_path):
    settings = Settings("test", tmp_path)
    with TestClient(create_app(settings)) as client:
        assert client.post(CATEGORIES, json={"name": " "}).status_code == 422
        first = client.post(CATEGORIES, json={"name": " Higiene "}).json()
        second = client.post(CATEGORIES, json={"name": "Casa"}).json()
        assert first["name"] == "Higiene"
        assert client.post(CATEGORIES, json={"name": "hIGIENE"}).status_code == 409
        a, b = first["id"], second["id"]
        assert client.put(f"{CATEGORIES}/{a}", json={"name": "Casa"}).status_code == 409
        assert client.put(f"{CATEGORIES}/{a}", json={"name": "Aseo"}).json()["name"] == "Aseo"
        item = client.post(PICTOGRAMS, json=custom(category_ids=[b, a])).json()
        other = client.post(PICTOGRAMS, json=custom("Sin categoría")).json()
        assert item["category_ids"] == [a, b] and other["category_ids"] == []
        assert client.get(PICTOGRAMS, params={"category_id": a}).json() == [item]
        assert client.get(PICTOGRAMS + "/search", params={"q": "Agua", "category_id": a}).json()["remote_status"] == "not_requested"
        path = f"{PICTOGRAMS}/{item['id']}"
        assert client.put(path, json={"label": "Cambio inválido", "category_ids": [999]}).status_code == 422
        assert client.get(PICTOGRAMS, params={"category_id": a}).json() == [item]
        assert client.put(path, json={"label": "Nuevo", "category_ids": []}).json()["category_ids"] == []
        assert client.get(PICTOGRAMS, params={"category_id": a}).json() == []
        updated = client.put(path, json={"label": "Agua", "category_ids": [a, b]}).json()
        assert updated["id"] == item["id"]
    with TestClient(create_app(settings)) as client:
        assert {row["name"] for row in client.get(CATEGORIES).json()} == {"Aseo", "Casa"}
        assert client.get(PICTOGRAMS, params={"category_id": a}).json() == [updated]
        assert client.delete(f"{CATEGORIES}/{a}").status_code == 204
        assert client.get(PICTOGRAMS, params={"category_id": b}).json()[0]["category_ids"] == [b]
        assert client.get(other["image_url"]).status_code == 200


def test_delete_removes_file_and_respects_foreign_key_dependency(catalog):
    client, app, _ = catalog
    item = client.post(PICTOGRAMS, json=custom()).json()
    with app.state.database.connection() as connection:
        connection.execute("CREATE TABLE test_reference(pictogram_id REFERENCES pictogram(id) ON DELETE RESTRICT)")
        connection.execute("INSERT INTO test_reference VALUES (?)", (item["id"],))
    path = f"{PICTOGRAMS}/{item['id']}"
    assert client.delete(path).status_code == 409
    assert client.get(PICTOGRAMS).json() == [item]
    assert client.get(item["image_url"]).status_code == 200
    with app.state.database.connection() as connection:
        connection.execute("DELETE FROM test_reference")
    assert client.delete(path).status_code == 204
    assert client.get(item["image_url"]).status_code == 404
    assert not list(app.state.catalog.directory.iterdir())


def test_file_write_failure_rolls_back_approval(catalog):
    client, app, _ = catalog
    app.state.catalog.directory.write_text("archivo que impide crear el directorio")
    assert client.post(PICTOGRAMS, json=custom()).status_code == 503
    assert client.get(PICTOGRAMS).json() == []
