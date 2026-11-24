"""CU01: contrato validado y persistencia del único perfil confirmado."""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from .database import Database


def normalized_text(value: str) -> str:
    value = value.strip()
    if not 1 <= len(value) <= 50:
        raise ValueError("Usa entre 1 y 50 caracteres, sin espacios externos")
    try:
        value.encode("utf-8")
    except UnicodeEncodeError as error:
        raise ValueError("El texto contiene caracteres inválidos") from error
    return value


class ProfilePayload(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    alias: str
    interests: list[str] = Field(default_factory=list)
    activities: list[str] = Field(default_factory=list)
    frequent_routines: list[str] = Field(default_factory=list)

    @field_validator("alias")
    @classmethod
    def validate_alias(cls, value: str) -> str:
        return normalized_text(value)

    @field_validator("interests", "activities", "frequent_routines")
    @classmethod
    def validate_items(cls, values: list[str]) -> list[str]:
        result = [normalized_text(value) for value in values]
        keys = [value.casefold() for value in result]
        if len(keys) != len(set(keys)):
            raise ValueError("No repitas elementos del mismo tipo, aunque cambies mayúsculas")
        return result


class ProfileResponse(ProfilePayload):
    id: Literal[1] = 1


class ProfileRepository:
    GROUPS = {"interests": "INTEREST", "activities": "ACTIVITY", "frequent_routines": "ROUTINE"}

    def __init__(self, database: Database):
        self.database = database

    def load(self) -> ProfileResponse | None:
        with self.database.connection() as connection:
            profile = connection.execute("SELECT alias FROM profile WHERE id = 1").fetchone()
            if profile is None:
                return None
            items = connection.execute(
                "SELECT type, value FROM context_item WHERE profile_id = 1 ORDER BY id"
            ).fetchall()
        groups = {name: [value for kind, value in items if kind == item_type]
                  for name, item_type in self.GROUPS.items()}
        return ProfileResponse(alias=profile[0], **groups)

    def save(self, payload: ProfilePayload) -> ProfileResponse:
        result = ProfileResponse(**payload.model_dump())
        with self.database.connection() as connection:
            connection.execute(
                "INSERT INTO profile (id, alias) VALUES (1, ?) "
                "ON CONFLICT(id) DO UPDATE SET alias=excluded.alias, updated_at=CURRENT_TIMESTAMP",
                (payload.alias,),
            )
            connection.execute("DELETE FROM context_item WHERE profile_id = 1")
            for field, kind in self.GROUPS.items():
                connection.executemany(
                    "INSERT INTO context_item (profile_id, type, value, value_key) VALUES (1, ?, ?, ?)",
                    [(kind, value, value.casefold()) for value in getattr(payload, field)],
                )
        return result
