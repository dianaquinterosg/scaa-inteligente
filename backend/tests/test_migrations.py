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


def test_upgrade_preserves_confirmed_profile_and_enforces_category_relationships(tmp_path, monkeypatch):
    database = Database(tmp_path / "scaa.sqlite3")
    database.initialize()
    with monkeypatch.context() as scoped:
        scoped.setattr(migrations, "MIGRATIONS", migrations.MIGRATIONS[:1])
        migrations.migrate(database)
    with database.connection() as connection:
        connection.execute("INSERT INTO profile(id, alias) VALUES (1, 'Ana')")
        connection.execute(
            "INSERT INTO context_item(profile_id,type,value,value_key) VALUES (1,'INTEREST','Agua','agua')"
        )
    migrations.migrate(database)
    with database.connection() as connection:
        assert connection.execute("SELECT alias FROM profile").fetchone() == ("Ana",)
        assert connection.execute("SELECT value FROM context_item").fetchone() == ("Agua",)
        connection.execute("INSERT INTO category VALUES (1, 'Higiene', 'higiene')")
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute("INSERT INTO pictogram_category VALUES (1,1)")
        connection.execute(
            "INSERT INTO pictogram(label,label_key,source,image_path,media_type) "
            "VALUES ('Agua','agua','CUSTOM','file.png','image/png')"
        )
        connection.execute("INSERT INTO pictogram_category VALUES (1,1)")
        connection.execute("DELETE FROM category WHERE id=1")
        assert connection.execute("SELECT label FROM pictogram").fetchone() == ("Agua",)
        assert connection.execute("SELECT * FROM pictogram_category").fetchall() == []


def test_upgrade_to_routines_preserves_profile_catalog_and_categories(tmp_path, monkeypatch):
    database = Database(tmp_path / "scaa.sqlite3")
    database.initialize()
    with monkeypatch.context() as scoped:
        scoped.setattr(migrations, "MIGRATIONS", migrations.MIGRATIONS[:2])
        migrations.migrate(database)
    with database.connection() as connection:
        connection.execute("INSERT INTO profile(id,alias) VALUES (1,'Ana')")
        connection.execute("INSERT INTO category VALUES (1,'Casa','casa')")
        connection.execute(
            "INSERT INTO pictogram(label,label_key,source,image_path,media_type) "
            "VALUES ('Agua','agua','CUSTOM','file.png','image/png')"
        )
        connection.execute("INSERT INTO pictogram_category VALUES (1,1)")
    migrations.migrate(database)
    with database.connection() as connection:
        assert connection.execute("SELECT alias FROM profile").fetchone() == ("Ana",)
        assert connection.execute("SELECT label FROM pictogram").fetchone() == ("Agua",)
        assert connection.execute("SELECT * FROM pictogram_category").fetchall() == [(1, 1)]
        connection.execute("INSERT INTO routine(id,profile_id,name,description) VALUES (1,1,'Beber','')")
        connection.execute("INSERT INTO routine_step(routine_id,pictogram_id,position,label) VALUES (1,1,1,'Verter')")
        connection.execute("INSERT INTO routine_step(routine_id,pictogram_id,position,label) VALUES (1,1,2,'Beber')")
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute("INSERT INTO routine_step(routine_id,pictogram_id,position,label) VALUES (1,1,2,'Duplicado')")
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute("DELETE FROM pictogram WHERE id=1")
        connection.execute("DELETE FROM routine WHERE id=1")
        assert connection.execute("SELECT * FROM routine_step").fetchall() == []
        assert connection.execute("SELECT label FROM pictogram").fetchone() == ("Agua",)
