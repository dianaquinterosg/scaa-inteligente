"""Migraciones SQL ordenadas, transaccionales y sin retrocesos implícitos."""

from pathlib import Path

from .database import Database

DIRECTORY = Path(__file__).parent / "migrations"
MIGRATIONS = [
    (1, DIRECTORY / "001_profile_context.sql"),
    (2, DIRECTORY / "002_pictograms.sql"),
]


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
