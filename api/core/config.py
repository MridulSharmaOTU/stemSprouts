from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Minimal config needed by the version contract test."""

    APP_VERSION: str = "0.0.0"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()


def get_settings() -> Settings:
    return settings


# Convenience alias for modules that want the resolved version directly.
APP_VERSION = settings.APP_VERSION