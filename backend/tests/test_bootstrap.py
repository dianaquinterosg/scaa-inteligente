import sqlite3

from fastapi.testclient import TestClient
import pytest

from scaa_backend.database import Database
from scaa_backend.main import create_app
from scaa_backend.settings import Settings


def test_health_initializes_profile_schema(tmp_path):
    settings = Settings("test", tmp_path)
    with TestClient(create_app(settings)) as client:
        response = client.get("/api/v1/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok", "database": "ok", "environment": "test"}
    assert settings.database_path.is_file()
    with sqlite3.connect(settings.database_path) as connection:
        assert set(connection.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()) == {("profile",), ("context_item",)}
        assert connection.execute("PRAGMA user_version").fetchone() == (1,)


def test_database_transactions_and_foreign_keys(tmp_path):
    database = Database(tmp_path / "scaa.sqlite3")
    database.initialize()
    with database.connection() as connection:
        assert connection.execute("PRAGMA foreign_keys").fetchone() == (1,)
        connection.execute("CREATE TABLE probe(value TEXT)")
        connection.execute("INSERT INTO probe VALUES ('confirmado')")
    with pytest.raises(RuntimeError):
        with database.connection() as connection:
            connection.execute("INSERT INTO probe VALUES ('descartado')")
            raise RuntimeError("fallo simulado")
    with database.connection() as connection:
        assert connection.execute("SELECT value FROM probe").fetchall() == [("confirmado",)]


def test_environments_use_different_database_files(tmp_path):
    paths = {Settings(environment, tmp_path).database_path for environment in ["dev", "test", "demo"]}
    assert len(paths) == 3


def test_initialize_preserves_existing_schema_version(tmp_path):
    database = Database(tmp_path / "scaa.sqlite3")
    database.initialize()
    with database.connection() as connection:
        connection.execute("PRAGMA user_version = 3")
    database.initialize()
    with database.connection() as connection:
        assert connection.execute("PRAGMA user_version").fetchone() == (3,)


def test_settings_read_and_validate_environment(monkeypatch, tmp_path):
    monkeypatch.setenv("SCAA_ENV", "demo")
    monkeypatch.setenv("SCAA_DATA_ROOT", str(tmp_path))
    assert Settings.from_env().database_path == tmp_path / "demo" / "scaa.sqlite3"
    monkeypatch.setenv("SCAA_ENV", "desconocido")
    with pytest.raises(ValueError):
        Settings.from_env()


def test_health_does_not_expose_storage_paths(tmp_path, monkeypatch):
    app = create_app(Settings("test", tmp_path))
    with TestClient(app) as client:
        def fail():
            raise sqlite3.OperationalError(f"error interno: {tmp_path}")
        monkeypatch.setattr(app.state.database, "check", fail)
        response = client.get("/api/v1/health")
        assert response.status_code == 503
        assert response.json() == {"detail": "Almacenamiento no disponible"}
        assert str(tmp_path) not in response.text
