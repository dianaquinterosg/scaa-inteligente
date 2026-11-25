"""Coordinación de propuestas en memoria y confirmación de rutinas."""

from fastapi import APIRouter, HTTPException, Request, Response

from .catalog import CatalogError, PreparedImage
from .catalog_api import Identifier, remote_image
from .routine_association import associate
from .routine_generation import GenerationError, relevant_context
from .routine_models import ProposalInput, RoutineApproval

router = APIRouter(prefix="/api/v1/routines")


@router.post("/proposals")
def propose(payload: ProposalInput, request: Request):
    state = request.app.state
    profile = state.profiles.load()
    if profile is None:
        raise CatalogError(409, "Configura el perfil antes de generar una rutina.")
    try:
        result = state.generator.generate(payload.description, relevant_context(profile, payload.description))
    except GenerationError as error:
        status, message = {
            "timeout": (504, "La generación tardó demasiado."),
            "unavailable": (503, "Ollama no está disponible o el modelo no pudo iniciarse."),
            "invalid_output": (502, "La IA devolvió una propuesta con estructura inválida."),
        }[error.kind]
        raise HTTPException(status, message + " Puedes crear la rutina manualmente.") from error
    association = associate(
        result, state.catalog, state.arasaac,
        contextual_external=state.contextual_external_match,
        exact_label_lookup=state.exact_label_lookup,
    )
    return {"description": payload.description, **association}


@router.get("")
def routines(request: Request):
    return request.app.state.routines.list()


@router.get("/{identifier}")
def routine(identifier: Identifier, request: Request):
    return request.app.state.routines.get(identifier)


def confirm(payload, request, identifier=None):
    state = request.app.state
    if state.profiles.load() is None:
        raise CatalogError(409, "Configura el perfil antes de guardar una rutina.")
    if identifier is not None:
        state.routines.get(identifier)
    external_images = {}
    for external_id in dict.fromkeys(step.external_id for step in payload.steps if step.external_id is not None):
        if not state.catalog.includes_arasaac(external_id):
            external_images[external_id] = PreparedImage.validate(remote_image(request, external_id))
    return state.routines.save(payload, external_images, identifier)


@router.post("", status_code=201)
def create(payload: RoutineApproval, request: Request):
    return confirm(payload, request)


@router.put("/{identifier}")
def update(identifier: Identifier, payload: RoutineApproval, request: Request):
    return confirm(payload, request, identifier)


@router.delete("/{identifier}", status_code=204)
def delete(identifier: Identifier, request: Request):
    request.app.state.routines.delete(identifier)
    return Response(status_code=204)
