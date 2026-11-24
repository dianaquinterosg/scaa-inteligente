"""Contratos de entrada para propuestas y confirmación de rutinas."""

from typing import Literal

from pydantic import Field, field_validator, model_validator

from .catalog_api import BodyIdentifier, clean
from .routine_generation import Description, MAX_STEPS, ShortText, StrictInput


def explicit(value):
    if value is not True:
        raise ValueError("Se requiere confirmación explícita.")
    return value


class ProposalInput(StrictInput):
    description: Description

    @field_validator("description")
    @classmethod
    def valid_description(cls, value):
        return clean(value, 500)


class ApprovedStep(StrictInput):
    order: int = Field(ge=1, le=MAX_STEPS)
    label: ShortText
    approved: Literal[True]
    pictogram_id: BodyIdentifier | None = None
    external_id: BodyIdentifier | None = None
    pictogram_label: ShortText | None = None

    _approved = field_validator("approved", mode="before")(explicit)

    @field_validator("label", "pictogram_label")
    @classmethod
    def valid_label(cls, value):
        return clean(value, 100) if value is not None else None

    @model_validator(mode="after")
    def selection(self):
        if (self.pictogram_id is None) == (self.external_id is None):
            raise ValueError("Selecciona un pictograma aprobado para cada paso.")
        if (self.external_id is None) != (self.pictogram_label is None):
            raise ValueError("Indica la etiqueta del pictograma de ARASAAC.")
        return self


class RoutineApproval(StrictInput):
    name: ShortText
    description: str = Field(default="", max_length=500)
    confirmed: Literal[True]
    steps: list[ApprovedStep] = Field(min_length=1, max_length=MAX_STEPS)

    _confirmed = field_validator("confirmed", mode="before")(explicit)

    @field_validator("name", "description")
    @classmethod
    def valid_text(cls, value, info):
        return clean(value, 100 if info.field_name == "name" else 500) if value else value

    @model_validator(mode="after")
    def consecutive(self):
        if any(step.order != index for index, step in enumerate(self.steps, 1)):
            raise ValueError("Usa posiciones consecutivas en el orden de los pasos.")
        return self
