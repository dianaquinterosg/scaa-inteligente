"""Configuración explícita de entornos, sin credenciales en el código."""

from dataclasses import dataclass
import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]


@dataclass(frozen=True)
class Settings:
    environment: str
    data_root: Path

    def __post_init__(self) -> None:
        if self.environment not in {"dev", "test", "demo"}:
            raise ValueError("SCAA_ENV debe ser dev, test o demo")
        root = self.data_root.expanduser()
        if not root.is_absolute():
            root = PROJECT_ROOT / root
        object.__setattr__(self, "data_root", root.resolve())

    @classmethod
    def from_env(cls) -> "Settings":
        return cls(
            environment=os.getenv("SCAA_ENV", "dev"),
            data_root=Path(os.getenv("SCAA_DATA_ROOT", ".localdata")),
        )

    @property
    def database_path(self) -> Path:
        return self.data_root / self.environment / "scaa.sqlite3"
