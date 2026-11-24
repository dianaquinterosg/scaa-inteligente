"""Persistencia del catálogo. Cada registro corresponde a una imagen confirmada."""

from contextlib import suppress
from io import BytesIO
import logging
import os
from pathlib import Path
import sqlite3
import re
from uuid import uuid4

from PIL import Image, UnidentifiedImageError

from .arasaac import ATTRIBUTION, MAX_IMAGE_BYTES
from .database import Database

logger = logging.getLogger(__name__)
IMAGE_FORMATS = {"PNG": ("png", "image/png"), "JPEG": ("jpg", "image/jpeg"), "WEBP": ("webp", "image/webp")}


MANAGED_IMAGE = re.compile(r"[0-9a-f]{32}\.(?:png|jpg|webp)(?:\.deleted)?")


class CatalogError(Exception):
    def __init__(self, status: int, message: str):
        super().__init__(message)
        self.status = status


def image_format(data: bytes) -> tuple[str, str]:
    if len(data) > MAX_IMAGE_BYTES:
        raise CatalogError(413, "La imagen supera el máximo de 5 MB.")
    try:
        with Image.open(BytesIO(data), formats=list(IMAGE_FORMATS)) as image:
            if image.width * image.height > 16_000_000 or getattr(image, "is_animated", False):
                raise CatalogError(422, "Usa una imagen estática de hasta 16 megapíxeles.")
            fmt = IMAGE_FORMATS[image.format]
            image.verify()
        with Image.open(BytesIO(data), formats=list(IMAGE_FORMATS)) as image:
            image.load()
    except (UnidentifiedImageError, OSError, ValueError, SyntaxError, Image.DecompressionBombError) as error:
        raise CatalogError(422, "Selecciona una imagen válida en formato PNG, JPG o WebP.") from error
    return fmt


class Catalog:
    def __init__(self, database: Database):
        self.database = database
        self.directory = database.path.parent / "pictograms"

    def recover_files(self):
        """Reconciliar archivos gestionados tras una interrupción del proceso."""
        if not self.directory.is_dir():
            return
        with self.database.connection() as connection:
            connection.execute("BEGIN IMMEDIATE")
            registered = {name for (name,) in connection.execute("SELECT image_path FROM pictogram")}
            for path in self.directory.iterdir():
                if not MANAGED_IMAGE.fullmatch(path.name) or not path.is_file():
                    continue
                if path.suffix == ".deleted":
                    original = path.with_suffix("")
                    if original.name in registered and not original.exists():
                        path.rename(original)
                    else:
                        path.unlink()
                elif path.name not in registered:
                    path.unlink()

    @staticmethod
    def _category_ids(connection, identifier):
        return [row[0] for row in connection.execute(
            "SELECT category_id FROM pictogram_category WHERE pictogram_id=? ORDER BY category_id",
            (identifier,),
        )]

    @staticmethod
    def _view(connection, row):
        identifier, label, source, external_id, attribution = row
        return {
            "id": identifier, "label": label, "source": source, "external_id": external_id,
            "attribution": attribution, "category_ids": Catalog._category_ids(connection, identifier),
            "image_url": f"/api/v1/pictograms/{identifier}/image",
        }

    def list(self, query: str = "", category_id: int | None = None):
        with self.database.connection() as connection:
            connection.execute("BEGIN")
            rows = connection.execute(
                "SELECT id,label,source,external_id,attribution FROM pictogram "
                "WHERE instr(label_key, ?) > 0 AND "
                "(? IS NULL OR id IN (SELECT pictogram_id FROM pictogram_category WHERE category_id=?)) "
                "ORDER BY label_key,id",
                (query.casefold(), category_id, category_id),
            )
            return [self._view(connection, row) for row in rows]

    def categories(self):
        with self.database.connection() as connection:
            return [{"id": i, "name": name} for i, name in connection.execute(
                "SELECT id,name FROM category ORDER BY name_key,id"
            )]

    def save_category(self, name, identifier=None):
        try:
            with self.database.connection() as connection:
                if identifier is None:
                    identifier = connection.execute(
                        "INSERT INTO category(name,name_key) VALUES (?,?)", (name, name.casefold())
                    ).lastrowid
                elif not connection.execute(
                    "UPDATE category SET name=?,name_key=? WHERE id=?", (name, name.casefold(), identifier)
                ).rowcount:
                    raise CatalogError(404, "No encontramos la categoría.")
        except sqlite3.IntegrityError as error:
            if error.sqlite_errorcode == sqlite3.SQLITE_CONSTRAINT_UNIQUE:
                raise CatalogError(409, "Ya existe una categoría con ese nombre.") from error
            raise
        return {"id": identifier, "name": name}

    def delete_category(self, identifier):
        with self.database.connection() as connection:
            if not connection.execute("DELETE FROM category WHERE id=?", (identifier,)).rowcount:
                raise CatalogError(404, "No encontramos la categoría.")

    @staticmethod
    def _assign(connection, identifier, category_ids):
        for category_id in category_ids:
            if connection.execute("SELECT 1 FROM category WHERE id=?", (category_id,)).fetchone() is None:
                raise CatalogError(422, "Una categoría ya no está disponible. Actualiza la lista.")
        connection.execute("DELETE FROM pictogram_category WHERE pictogram_id=?", (identifier,))
        connection.executemany(
            "INSERT INTO pictogram_category(pictogram_id,category_id) VALUES (?,?)",
            [(identifier, category_id) for category_id in category_ids],
        )

    def includes_arasaac(self, external_id):
        with self.database.connection() as connection:
            return connection.execute(
                "SELECT 1 FROM pictogram WHERE source='ARASAAC' AND external_id=?", (external_id,),
            ).fetchone() is not None

    def create(self, label, category_ids, data, external_id=None):
        extension, mime_type = image_format(data)
        source = "ARASAAC" if external_id is not None else "CUSTOM"
        attribution = ATTRIBUTION if external_id is not None else None
        basename = f"{uuid4().hex}.{extension}"
        path = self.directory / basename
        created = False
        try:
            with self.database.connection() as connection:
                identifier = connection.execute(
                    "INSERT INTO pictogram(label,label_key,source,external_id,image_path,media_type,attribution) "
                    "VALUES (?,?,?,?,?,?,?)",
                    (label, label.casefold(), source, external_id, basename, mime_type, attribution),
                ).lastrowid
                self._assign(connection, identifier, category_ids)
                self.directory.mkdir(exist_ok=True)
                with path.open("xb") as image:
                    created = True
                    image.write(data)
                    image.flush()
                    os.fsync(image.fileno())
                result = self._view(connection, (identifier, label, source, external_id, attribution))
            return result
        except Exception:
            if created:
                try:
                    path.unlink(missing_ok=True)
                except OSError:
                    logger.exception("No se pudo limpiar una imagen sin registro")
            raise

    def update(self, identifier, label, category_ids):
        with self.database.connection() as connection:
            if not connection.execute(
                "UPDATE pictogram SET label=?,label_key=? WHERE id=?",
                (label, label.casefold(), identifier),
            ).rowcount:
                raise CatalogError(404, "No encontramos el pictograma.")
            self._assign(connection, identifier, category_ids)
            row = connection.execute(
                "SELECT id,label,source,external_id,attribution FROM pictogram WHERE id=?",
                (identifier,),
            ).fetchone()
            return self._view(connection, row)

    def image(self, identifier):
        with self.database.connection() as connection:
            row = connection.execute(
                "SELECT image_path,media_type FROM pictogram WHERE id=?", (identifier,),
            ).fetchone()
            if row is None:
                raise CatalogError(404, "No encontramos el pictograma.")
            try:
                return (self.directory / row[0]).read_bytes(), row[1]
            except FileNotFoundError as error:
                raise CatalogError(404, "No encontramos el archivo del pictograma.") from error

    def delete(self, identifier):
        original = tombstone = None
        try:
            with self.database.connection() as connection:
                connection.execute("BEGIN IMMEDIATE")
                row = connection.execute(
                    "SELECT image_path FROM pictogram WHERE id=?", (identifier,),
                ).fetchone()
                if row is None:
                    raise CatalogError(404, "No encontramos el pictograma.")
                connection.execute("DELETE FROM pictogram WHERE id=?", (identifier,))
                path = self.directory / row[0]
                pending = path.with_suffix(path.suffix + ".deleted")
                with suppress(FileNotFoundError):
                    path.rename(pending)
                    original, tombstone = path, pending
        except Exception:
            if tombstone is not None:
                tombstone.rename(original)
            raise
        if tombstone is not None:
            try:
                tombstone.unlink(missing_ok=True)
            except OSError:
                logger.exception("No se pudo limpiar el archivo de un pictograma eliminado")
