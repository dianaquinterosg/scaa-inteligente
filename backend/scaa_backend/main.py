"""API técnica inicial: salud del servicio y conectividad SQLite."""

from contextlib import asynccontextmanager
import logging
import sqlite3

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from .database import Database
from .settings import Settings
from .migrate import migrate

logger = logging.getLogger(__name__)


class HealthResponse(BaseModel):
    status: str
    database: str
    environment: str


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or Settings.from_env()
    database = Database(settings.database_path)

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        database.initialize()
        migrate(database)
        yield

    app = FastAPI(title="SCAA — preparación técnica", version="0.0.0", lifespan=lifespan)
    app.state.database = database

    @app.get("/api/v1/health", response_model=HealthResponse)
    def health() -> HealthResponse:
        try:
            database.check()
        except (sqlite3.Error, OSError) as error:
            logger.exception("Almacenamiento no disponible")
            raise HTTPException(status_code=503, detail="Almacenamiento no disponible") from error
        return HealthResponse(status="ok", database="ok", environment=settings.environment)

    return app


app = create_app()
