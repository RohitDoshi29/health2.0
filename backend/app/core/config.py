"""Application configuration.

All configuration is read from environment variables (optionally via a
.env file during local development). Never hardcode secrets here.
"""

from functools import lru_cache

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Central application settings, loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # --- Application ---
    APP_NAME: str = "Heathify API"
    ENVIRONMENT: str = "development"

    # --- Database ---
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@db:5432/heathify"

    @field_validator("DATABASE_URL", mode="after")
    @classmethod
    def assemble_db_url(cls, v: str) -> str:
        """Convert standard postgres:// or postgresql:// URLs into asyncpg driver format."""
        import re

        if v.startswith("postgres://"):
            v = v.replace("postgres://", "postgresql+asyncpg://", 1)
        elif v.startswith("postgresql://") and not v.startswith("postgresql+asyncpg://"):
            v = v.replace("postgresql://", "postgresql+asyncpg://", 1)
        # asyncpg does not accept 'sslmode' query param (it expects SSLContext via connect_args)
        if "sslmode=" in v:
            v = re.sub(r"[?&]sslmode=[^&]+", "", v)
            v = v.rstrip("?")
        return v

    # --- Gemini API ---
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-2.5-flash"

    # --- CORS ---
    # Comma-separated origins, parsed into a list for the CORS middleware.
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:5173"

    # --- Uploads ---
    MAX_UPLOAD_SIZE_MB: int = 8
    UPLOAD_DIR: str = "uploads"

    # --- Authentication / JWT ---
    JWT_SECRET_KEY: str = "heathify-dev-secret-key-change-in-production-at-least-32-chars"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7

    # --- Google / Firebase Auth ---
    GOOGLE_CLIENT_ID: str = ""
    FIREBASE_PROJECT_ID: str = ""

    # --- Verification & External Nutrition Sources ---
    USDA_API_KEY: str = ""
    OPENFOODFACTS_ENABLED: bool = True


    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]

    @property
    def max_upload_size_bytes(self) -> int:
        return self.MAX_UPLOAD_SIZE_MB * 1024 * 1024

    @property
    def is_development(self) -> bool:
        return self.ENVIRONMENT.lower() == "development"


@lru_cache
def get_settings() -> Settings:
    """Cached settings accessor so the environment is only parsed once."""
    return Settings()


settings = get_settings()
