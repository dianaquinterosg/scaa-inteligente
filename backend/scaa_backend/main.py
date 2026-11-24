"""API SCAA: salud del servicio y CU01, perfil y contexto."""

from contextlib import asynccontextmanager
import logging
import sqlite3

from fastapi import FastAPI, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from .arasaac import ArasaacClient
from .catalog import Catalog, CatalogError
from .catalog_api import router as catalog_router
from .database import Database
from .settings import Settings
from .migrate import migrate
from .profile import ProfilePayload, ProfileRepository, ProfileResponse

logger = logging.getLogger(__name__)


class HealthResponse(BaseModel):
    status: str
    database: str
    environment: str


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or Settings.from_env()
    database = Database(settings.database_path)
    profiles = ProfileRepository(database)
    catalog = Catalog(database)

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        database.initialize()
        migrate(database)
        catalog.recover_files()
        yield

    app = FastAPI(title="SCAA — preparación técnica", version="0.0.0", lifespan=lifespan)
    app.state.database = database
    app.state.profiles = profiles
    app.state.catalog = catalog
    app.state.arasaac = ArasaacClient()
    app.include_router(catalog_router)

    @app.exception_handler(CatalogError)
    async def catalog_error(request, error: CatalogError):
        return JSONResponse(status_code=error.status, content={"detail": str(error)})

    @app.exception_handler(sqlite3.Error)
    @app.exception_handler(OSError)
    async def storage_error(request, error):
        logger.error("Almacenamiento no disponible", exc_info=error)
        return JSONResponse(status_code=503, content={"detail": "No pudimos completar la operación. Reintenta."})

    @app.exception_handler(RequestValidationError)
    async def validation_error(request, error: RequestValidationError):
        # No reflejar datos personales ni texto Unicode inválido en errores.
        detail = [{"loc": [part.encode("utf-8", errors="replace").decode() if isinstance(part, str) else part
                           for part in item["loc"]],
                   "msg": item["msg"].removeprefix("Value error, "), "type": item["type"]}
                  for item in error.errors()]
        return JSONResponse(status_code=422, content={"detail": detail})

    @app.get("/api/v1/profile", response_model=ProfileResponse)
    def load_profile() -> ProfileResponse:
        try:
            profile = profiles.load()
        except (sqlite3.Error, OSError) as error:
            raise HTTPException(status_code=503, detail="No se pudo consultar el perfil") from error
        if profile is None:
            raise HTTPException(status_code=404, detail="Perfil no configurado")
        return profile

    @app.put("/api/v1/profile", response_model=ProfileResponse)
    def save_profile(payload: ProfilePayload) -> ProfileResponse:
        try:
            return profiles.save(payload)
        except (sqlite3.Error, OSError) as error:
            raise HTTPException(status_code=503, detail="No se pudo guardar el perfil") from error

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
