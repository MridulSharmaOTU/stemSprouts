from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Minimal config needed by the version contract test."""

    APP_VERSION: str = "0.0.0"
    OPENROUTER_API_KEY: str
    OPENROUTER_API_MODEL: str = "tngtech/deepseek-r1t2-chimera:free"
    OPENROUTER_API_URL: str = "https://openrouter.ai/api/v1/chat/completions"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()


def get_settings() -> Settings:
    return settings


# Convenience alias for modules that want the resolved version directly.
APP_VERSION = settings.APP_VERSION