"""Configuración explícita de entornos, sin credenciales en el código."""

from dataclasses import dataclass
import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
OLLAMA_PROMPT_PROFILES = ("baseline", "alternate")


@dataclass(frozen=True)
class Settings:
    environment: str
    data_root: Path
    ollama_base_url: str = "http://127.0.0.1:11434"
    ollama_model: str = "qwen2.5:1.5b"
    ollama_timeout: float = 60
    ollama_prompt_profile: str = "baseline"

    def __post_init__(self) -> None:
        if self.environment not in {"dev", "test", "demo"}:
            raise ValueError("SCAA_ENV debe ser dev, test o demo")
        if not 1 <= self.ollama_timeout <= 120:
            raise ValueError("OLLAMA_TIMEOUT debe estar entre 1 y 120 segundos")
        if self.ollama_prompt_profile not in OLLAMA_PROMPT_PROFILES:
            raise ValueError("OLLAMA_PROMPT_PROFILE debe ser baseline o alternate")
        root = self.data_root.expanduser()
        if not root.is_absolute():
            root = PROJECT_ROOT / root
        object.__setattr__(self, "data_root", root.resolve())

    @classmethod
    def from_env(cls) -> "Settings":
        return cls(
            environment=os.getenv("SCAA_ENV", "dev"),
            data_root=Path(os.getenv("SCAA_DATA_ROOT", ".localdata")),
            ollama_base_url=os.getenv("OLLAMA_BASE_URL", "http://127.0.0.1:11434"),
            ollama_model=os.getenv("OLLAMA_MODEL", "qwen2.5:1.5b"),
            ollama_timeout=float(os.getenv("OLLAMA_TIMEOUT", "60")),
            ollama_prompt_profile=os.getenv("OLLAMA_PROMPT_PROFILE", "baseline"),
        )

    @property
    def database_path(self) -> Path:
        return self.data_root / self.environment / "scaa.sqlite3"
