"""Migraciones SQL ordenadas, transaccionales y sin retrocesos implícitos."""

from pathlib import Path

from .database import Database

MIGRATIONS = [(1, Path(__file__).parent / "migrations" / "001_profile_context.sql")]


def migrate(database: Database) -> None:
    with database.connection() as connection:
        version = connection.execute("PRAGMA user_version").fetchone()[0]
        if version > MIGRATIONS[-1][0]:
            raise RuntimeError("La versión de la base de datos es posterior a este backend")
        for target, path in MIGRATIONS:
            if target > version:
                connection.executescript(
                    "BEGIN IMMEDIATE;\n" + path.read_text() +
                    f"\nPRAGMA user_version = {target};\nCOMMIT;"
                )
