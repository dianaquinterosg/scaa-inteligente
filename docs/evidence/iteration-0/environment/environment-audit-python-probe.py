import sqlite3
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from pydantic import BaseModel, PositiveInt, ValidationError

def test_fastapi_asgi_roundtrip():
    app = FastAPI()
    @app.get("/audit-health")
    def health():
        return {"status": "ok"}
    with TestClient(app) as client:
        response = client.get("/audit-health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}

def test_pydantic_validation():
    class Probe(BaseModel):
        label: str
        order: PositiveInt
    assert Probe.model_validate_json('{"label":"prueba","order":1}').order == 1
    with pytest.raises(ValidationError):
        Probe(label="prueba", order=0)

def test_sqlite_integrity_and_rollback():
    with sqlite3.connect(":memory:") as db:
        db.execute("PRAGMA foreign_keys=ON")
        db.execute("CREATE TABLE parent(id INTEGER PRIMARY KEY)")
        db.execute("CREATE TABLE child(id INTEGER PRIMARY KEY, parent_id INTEGER REFERENCES parent(id))")
        assert db.execute("PRAGMA foreign_keys").fetchone()[0] == 1
        with pytest.raises(sqlite3.IntegrityError):
            with db:
                db.execute("INSERT INTO parent VALUES (1)")
                db.execute("INSERT INTO child VALUES (1,999)")
        assert db.execute("SELECT count(*) FROM parent").fetchone()[0] == 0
