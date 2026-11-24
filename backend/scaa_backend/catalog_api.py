"""API del catálogo. La búsqueda y las vistas previas no escriben datos."""

import base64
import binascii
import sqlite3
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, HTTPException, Path, Request, Response
from fastapi.exceptions import RequestValidationError
from pydantic import BaseModel, ConfigDict, Field, ValidationError, field_validator, model_validator

from .arasaac import ArasaacNotFound, ArasaacUnavailable, MAX_IMAGE_BYTES
from .catalog import CatalogError, image_format

router = APIRouter(prefix="/api/v1")
MAX_BODY = ((MAX_IMAGE_BYTES + 2) // 3) * 4 + 8192
MAX_ID = 2**63 - 1
Identifier = Annotated[int, Path(gt=0, le=MAX_ID)]
BodyIdentifier = Annotated[int, Field(gt=0, le=MAX_ID)]


def clean(text: str, maximum: int) -> str:
    text = text.strip()
    if not 1 <= len(text) <= maximum:
        raise ValueError(f"Ingresa entre 1 y {maximum} caracteres.")
    try:
        text.encode("utf-8")
    except UnicodeEncodeError as error:
        raise ValueError("El texto contiene caracteres inválidos.") from error
    return text


class CategoryInput(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    name: str

    @field_validator("name")
    @classmethod
    def name_is_valid(cls, name):
        return clean(name, 50)


class PictogramInput(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    label: str
    category_ids: list[BodyIdentifier] = Field(default_factory=list)

    @field_validator("label")
    @classmethod
    def label_is_valid(cls, label):
        return clean(label, 100)

    @field_validator("category_ids")
    @classmethod
    def category_ids_are_unique(cls, category_ids):
        if len(set(category_ids)) != len(category_ids):
            raise ValueError("Selecciona cada categoría una sola vez.")
        return category_ids


class PictogramApproval(PictogramInput):
    confirmed: Literal[True]
    external_id: BodyIdentifier | None = None
    image_base64: str | None = None

    @field_validator("confirmed", mode="before")
    @classmethod
    def explicit_confirmation(cls, value):
        if value is not True:
            raise ValueError("Confirma la incorporación del pictograma.")
        return value

    @model_validator(mode="after")
    def single_image_source(self):
        if (self.external_id is None) == (self.image_base64 is None):
            raise ValueError("Selecciona una referencia de ARASAAC o una imagen propia.")
        return self


@router.get("/categories")
def categories(request: Request):
    return request.app.state.catalog.categories()


@router.post("/categories", status_code=201)
def create_category(payload: CategoryInput, request: Request):
    return request.app.state.catalog.save_category(payload.name)


@router.put("/categories/{identifier}")
def rename_category(identifier: Identifier, payload: CategoryInput, request: Request):
    return request.app.state.catalog.save_category(payload.name, identifier)


@router.delete("/categories/{identifier}", status_code=204)
def delete_category(identifier: Identifier, request: Request):
    request.app.state.catalog.delete_category(identifier)
    return Response(status_code=204)


@router.get("/pictograms")
def list_pictograms(request: Request, category_id: int | None = None):
    if category_id is not None and not 0 < category_id <= MAX_ID:
        raise HTTPException(422, "Identificador de categoría inválido.")
    return request.app.state.catalog.list(category_id=category_id)


@router.get("/pictograms/search")
def search(request: Request, q: str, category_id: int | None = None, alternatives: bool = False):
    try:
        q = clean(q, 100)
    except ValueError as error:
        raise HTTPException(422, str(error)) from error
    if category_id is not None and not 0 < category_id <= MAX_ID:
        raise HTTPException(422, "Identificador de categoría inválido.")
    local = request.app.state.catalog.list(q, category_id)
    if category_id is not None or (local and not alternatives):
        return {"local": local, "alternatives": [], "remote_status": "not_requested"}
    try:
        remote = request.app.state.arasaac.search(q)
    except ArasaacUnavailable:
        return {"local": local, "alternatives": [], "remote_status": "unavailable"}
    return {"local": local, "alternatives": remote, "remote_status": "available"}


def remote_image(request, identifier):
    try:
        return request.app.state.arasaac.image(identifier)
    except ArasaacNotFound as error:
        raise CatalogError(404, "La imagen de ARASAAC ya no está disponible.") from error
    except ArasaacUnavailable as error:
        raise CatalogError(503, "ARASAAC no está disponible. Reintenta o importa una imagen propia.") from error


def image_response(data, media_type):
    return Response(data, media_type=media_type, headers={
        "X-Content-Type-Options": "nosniff", "Cache-Control": "private, no-store",
    })


@router.get("/pictograms/arasaac/{identifier}/image")
def preview_arasaac(identifier: Identifier, request: Request):
    data = remote_image(request, identifier)
    return image_response(data, image_format(data)[1])


async def read_approval(request: Request):
    body = bytearray()
    async for chunk in request.stream():
        if len(body) + len(chunk) > MAX_BODY:
            raise HTTPException(413, "La imagen supera el máximo de 5 MB.")
        body.extend(chunk)
    try:
        return PictogramApproval.model_validate_json(body)
    except ValidationError as error:
        raise RequestValidationError(error.errors()) from error


@router.post("/pictograms", status_code=201)
def approve(request: Request, payload: Annotated[PictogramApproval, Depends(read_approval)]):
    catalog = request.app.state.catalog
    duplicate = "Esta referencia ARASAAC ya está guardada. Reutilízala desde Mis pictogramas."
    if payload.external_id is not None:
        if catalog.includes_arasaac(payload.external_id):
            raise CatalogError(409, duplicate)
        data = remote_image(request, payload.external_id)
    else:
        try:
            data = base64.b64decode(payload.image_base64, validate=True)
        except (binascii.Error, ValueError) as error:
            raise CatalogError(422, "No se pudo leer el archivo seleccionado.") from error
    try:
        return catalog.create(payload.label, payload.category_ids, data, payload.external_id)
    except sqlite3.IntegrityError as error:
        if payload.external_id is not None and error.sqlite_errorcode == sqlite3.SQLITE_CONSTRAINT_UNIQUE:
            raise CatalogError(409, duplicate) from error
        raise


@router.put("/pictograms/{identifier}")
def update(identifier: Identifier, payload: PictogramInput, request: Request):
    return request.app.state.catalog.update(identifier, payload.label, payload.category_ids)


@router.get("/pictograms/{identifier}/image")
def stored_image(identifier: Identifier, request: Request):
    return image_response(*request.app.state.catalog.image(identifier))


@router.delete("/pictograms/{identifier}", status_code=204)
def delete(identifier: Identifier, request: Request):
    try:
        request.app.state.catalog.delete(identifier)
    except sqlite3.IntegrityError as error:
        if error.sqlite_errorcode in (sqlite3.SQLITE_CONSTRAINT_FOREIGNKEY, sqlite3.SQLITE_CONSTRAINT_TRIGGER):
            raise CatalogError(409, "El pictograma tiene referencias activas y no se puede eliminar.") from error
        raise
    return Response(status_code=204)
