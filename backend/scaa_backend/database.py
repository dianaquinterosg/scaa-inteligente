"""Conexiones SQLite compartidas por la API y las migraciones versionadas."""

from contextlib import contextmanager
from pathlib import Path
import sqlite3
from typing import Iterator


class Database:
    def __init__(self, path: Path):
        self.path = path

    @contextmanager
    def connection(self) -> Iterator[sqlite3.Connection]:
        connection = sqlite3.connect(self.path, timeout=5)
        try:
            connection.execute("PRAGMA foreign_keys = ON")
            yield connection
            connection.commit()
        except Exception:
            connection.rollback()
            raise
        finally:
            connection.close()

    def initialize(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        empty = not self.path.exists() or self.path.stat().st_size == 0
        with self.connection() as connection:
            # Inicializa el archivo SQLite sin crear tablas de dominio.
            # 0 significa que todavía no se aplicó una migración funcional.
            if empty:
                connection.execute("PRAGMA user_version = 0")

    def check(self) -> None:
        with self.connection() as connection:
            if connection.execute("PRAGMA quick_check").fetchone() != ("ok",):
                raise sqlite3.DatabaseError("Falló la comprobación SQLite")
