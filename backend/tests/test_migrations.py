import sqlite3

import pytest

from scaa_backend.database import Database
import scaa_backend.migrate as migrations


def test_failed_migration_is_atomic(tmp_path, monkeypatch):
    database = Database(tmp_path / "scaa.sqlite3")
    database.initialize()
    sql = tmp_path / "invalid.sql"
    sql.write_text("CREATE TABLE partial(value TEXT); INVALID SQL;")
    monkeypatch.setattr(migrations, "MIGRATIONS", [(1, sql)])
    with pytest.raises(sqlite3.Error):
        migrations.migrate(database)
    with database.connection() as connection:
        assert connection.execute("PRAGMA user_version").fetchone() == (0,)
        assert connection.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall() == []


def test_newer_schema_is_not_downgraded(tmp_path):
    database = Database(tmp_path / "scaa.sqlite3")
    database.initialize()
    with database.connection() as connection:
        connection.execute("PRAGMA user_version = 10")
    with pytest.raises(RuntimeError):
        migrations.migrate(database)
    with database.connection() as connection:
        assert connection.execute("PRAGMA user_version").fetchone() == (10,)
