"""\
Strict bootstrap and contract tests for the FastAPI backend.

Scope (only):
- System router (api/routers/system.py)
  • GET /healthz → 200 {"ok": true}
  • GET /version → 200 {"version": "<from config>"}
- Config (api/core/config.py) using pydantic-settings
  • Vars: APP_ENV (local|dev|prod), LOG_LEVEL, ALLOWED_ORIGINS (CSV), MAX_BODY_BYTES (default 65536), APP_VERSION.
  • Load from env and .env (documented in .env.example).
- Errors (api/core/errors.py)
  • Standard envelope: {"error":{"code":"STRING","message":"...","details":{}}}
  • Map 422→VALIDATION_ERROR, 404→NOT_FOUND, 500→INTERNAL

Anything else is out of scope for this file.
"""
from __future__ import annotations

import importlib
import importlib.util
import sys
from pathlib import Path
from typing import Any, Optional

import pytest
from fastapi import FastAPI
from starlette.testclient import TestClient


# ------------------------------
# Repo root resolution (so imports work from tests/)
# ------------------------------

def _repo_root() -> Path:
    """Best-effort detection of the repository root that contains the `api/` package.
    Falls back to the tests' parent directory.
    """
    here = Path(__file__).resolve()
    candidates = [
        here.parent.parent,  # <root>/tests/ -> <root>
        here.parents[2] if len(here.parents) > 2 else None,
        Path.cwd(),
    ]
    for c in candidates:
        if c and (c / "api").exists():
            return c
    return here.parent.parent


_ROOT = _repo_root()
if str(_ROOT) not in map(str, sys.path):
    sys.path.insert(0, str(_ROOT))


# ------------------------------
# Utilities
# ------------------------------

def _load_main_app() -> FastAPI:
    """Import api.main and return a FastAPI instance via `app` or `create_app()`."""
    main = importlib.import_module("api.main")

    app = getattr(main, "app", None)
    if isinstance(app, FastAPI):
        return app

    factory = getattr(main, "create_app", None)
    if callable(factory):
        app = factory()
        if isinstance(app, FastAPI):
            return app

    raise AssertionError(
        "api.main must expose FastAPI `app` or a `create_app()` returning FastAPI."
    )


def _import_config_module():
    return importlib.import_module("api.core.config")


def _get_settings_and_class() -> tuple[Any, Optional[type]]:
    """Return (settings_instance, Settings_class|None). Supports several common patterns."""
    cfg = _import_config_module()

    settings = getattr(cfg, "settings", None)
    if settings is None:
        getter = getattr(cfg, "get_settings", None)
        if callable(getter):
            settings = getter()

    settings_cls = getattr(cfg, "Settings", None)
    if not isinstance(settings_cls, type):
        settings_cls = None

    return settings, settings_cls


def _extract_version_from_settings(settings: Any) -> Optional[str]:
    for key in ("APP_VERSION", "app_version", "version", "APPVERSION"):
        if hasattr(settings, key):
            return str(getattr(settings, key))
        if isinstance(settings, dict) and key in settings:
            return str(settings[key])
    return None


def _is_settings_subclass_of_basesettings(settings_cls: type | None) -> bool:
    """Return True if `settings_cls` subclasses a Pydantic BaseSettings (v1 or v2).
    Uses dynamic imports to avoid static import errors in editors like Pylance.
    """
    if settings_cls is None:
        return False

    # Pydantic Settings v2: pydantic_settings.BaseSettings
    try:
        if importlib.util.find_spec("pydantic_settings") is not None:
            mod = importlib.import_module("pydantic_settings")
            V2Base = getattr(mod, "BaseSettings", None)
            if V2Base is not None and issubclass(settings_cls, V2Base):
                return True
    except Exception:
        pass

    # Pydantic v1: pydantic.BaseSettings
    try:
        if importlib.util.find_spec("pydantic") is not None:
            mod = importlib.import_module("pydantic")
            V1Base = getattr(mod, "BaseSettings", None)
            if V1Base is not None and issubclass(settings_cls, V1Base):
                return True
    except Exception:
        pass

    return False


# ------------------------------
# Fixtures
# ------------------------------

@pytest.fixture(scope="module")
def app() -> FastAPI:
    return _load_main_app()


@pytest.fixture()
def client(app: FastAPI) -> TestClient:
    # fresh client each test so we can add test-only routes safely
    return TestClient(app)


# ------------------------------
# System router: /healthz and /version contracts
# ------------------------------

def test_healthz_contract(client: TestClient) -> None:
    res = client.get("/healthz")
    assert res.status_code == 200, "GET /healthz must return 200"
    data = res.json()
    assert isinstance(data, dict), "/healthz must return a JSON object"
    assert set(data.keys()) == {"ok"}, "/healthz response must only contain 'ok'"
    assert data["ok"] is True, "ok must be true"


def test_version_contract_uses_config(client: TestClient) -> None:
    settings, _ = _get_settings_and_class()
    version = _extract_version_from_settings(settings)
    assert version, "APP_VERSION (or equivalent) must be provided by config"

    res = client.get("/version")
    assert res.status_code == 200, "GET /version must return 200"
    data = res.json()
    assert isinstance(data, dict), "/version must return a JSON object"
    assert set(data.keys()) == {"version"}, "/version response must only contain 'version'"
    assert data["version"] == version, "/version must echo the version from config"


# ------------------------------
# Config: pydantic-settings with required vars and env/.env loading
# ------------------------------

def test_config_declares_expected_fields_and_types(monkeypatch: pytest.MonkeyPatch) -> None:
    # Ensure env vars do not interfere with default checks first
    for k in ("APP_ENV", "LOG_LEVEL", "ALLOWED_ORIGINS", "MAX_BODY_BYTES", "APP_VERSION"):
        monkeypatch.delenv(k, raising=False)

    cfg = _import_config_module()
    settings, settings_cls = _get_settings_and_class()

    # Must be pydantic BaseSettings (v1 or v2)
    assert _is_settings_subclass_of_basesettings(settings_cls), (
        "api.core.config.Settings must subclass pydantic BaseSettings (pydantic-settings)."
    )

    # Fields present
    for attr in ("APP_ENV", "LOG_LEVEL", "ALLOWED_ORIGINS", "MAX_BODY_BYTES", "APP_VERSION"):
        assert hasattr(settings, attr), f"Missing config field: {attr}"

    # Defaults/constraints
    assert getattr(settings, "MAX_BODY_BYTES") == 65536, "MAX_BODY_BYTES default must be 65536"
    assert getattr(settings, "APP_ENV") in {"local", "dev", "prod"}, (
        "APP_ENV must be one of: local|dev|prod"
    )

    # ALLOWED_ORIGINS should be derived from CSV → list/tuple of strings
    allowed = getattr(settings, "ALLOWED_ORIGINS")
    assert isinstance(allowed, (list, tuple)), "ALLOWED_ORIGINS should parse CSV into a list/tuple"
    assert all(isinstance(x, str) for x in allowed), "ALLOWED_ORIGINS entries must be strings"

    # Version presence (string)
    assert isinstance(getattr(settings, "APP_VERSION"), str), "APP_VERSION must be a string"


def test_config_reads_from_environment_and_env_file(monkeypatch: pytest.MonkeyPatch) -> None:
    # Simulate env vars
    monkeypatch.setenv("APP_ENV", "dev")
    monkeypatch.setenv("LOG_LEVEL", "WARNING")
    monkeypatch.setenv("ALLOWED_ORIGINS", "https://a,https://b")
    monkeypatch.setenv("MAX_BODY_BYTES", "1234")
    monkeypatch.setenv("APP_VERSION", "9.9.9")

    # Reload config to pick up env
    cfg = importlib.reload(_import_config_module())

    settings = getattr(cfg, "settings", None)
    if settings is None:
        getter = getattr(cfg, "get_settings", None)
        assert callable(getter), "config must expose `settings` or `get_settings()`"
        settings = getter()

    assert settings.APP_ENV == "dev"
    assert settings.LOG_LEVEL.upper() == "WARNING"
    assert list(settings.ALLOWED_ORIGINS) == ["https://a", "https://b"]
    assert settings.MAX_BODY_BYTES == 1234
    assert settings.APP_VERSION == "9.9.9"

    # Check that Settings declares an env file of ".env" (v1 or v2 styles)
    Settings = getattr(cfg, "Settings", None)
    assert Settings is not None, "Settings class must be defined"

    env_file_declared = False
    # pydantic v2 (pydantic-settings): model_config with env_file
    if hasattr(Settings, "model_config"):
        mc = getattr(Settings, "model_config")
        env_file_declared = bool(getattr(mc, "get", lambda k, d=None: None)("env_file", None) or getattr(mc, "env_file", None))
    # pydantic v1: inner Config with env_file
    if not env_file_declared and hasattr(Settings, "Config"):
        env_file_declared = getattr(Settings.Config, "env_file", None) in {".env", (_ROOT / ".env").resolve().as_posix()}

    assert env_file_declared, "Settings must declare env_file='.env' so .env is loaded"

    # .env.example must exist and document the vars (at repo root)
    example = _ROOT / ".env.example"
    assert example.exists(), ".env.example must exist at repo root"
    text = example.read_text(encoding="utf-8", errors="ignore")
    for key in ("APP_ENV", "LOG_LEVEL", "ALLOWED_ORIGINS", "MAX_BODY_BYTES", "APP_VERSION"):
        assert key in text, f".env.example must document {key}"


# ------------------------------
# Errors: envelope + code mapping (422, 404, 500)
# ------------------------------

def _assert_error_envelope(payload: Any, *, code: str) -> None:
    assert isinstance(payload, dict), "Error responses must be JSON objects"
    assert set(payload.keys()) == {"error"}, "Error envelope must only contain 'error'"
    err = payload["error"]
    assert isinstance(err, dict), "'error' must be an object"
    # details may be empty dict or populated dict
    for k in ("code", "message", "details"):
        assert k in err, f"Missing '{k}' in error envelope"
    assert err["code"] == code, f"Expected error.code={code}"
    assert isinstance(err["message"], str) and err["message"], "error.message must be a non-empty string"
    assert isinstance(err["details"], dict), "error.details must be an object"


def test_404_maps_to_NOT_FOUND(client: TestClient) -> None:
    res = client.get("/__this_path_does_not_exist__")
    assert res.status_code == 404
    _assert_error_envelope(res.json(), code="NOT_FOUND")


def test_500_maps_to_INTERNAL(app: FastAPI) -> None:
    # Add a test-only route that raises an unhandled exception
    @app.get("/__boom__")
    def _boom():  # pragma: no cover - test harness only
        raise RuntimeError("boom")

    with TestClient(app) as c:
        res = c.get("/__boom__")
        assert res.status_code == 500
        _assert_error_envelope(res.json(), code="INTERNAL")


def test_422_maps_to_VALIDATION_ERROR(app: FastAPI) -> None:
    # Add a test-only route that validates input
    try:
        from pydantic import BaseModel
    except Exception:
        from pydantic.main import BaseModel  # type: ignore

    class Payload(BaseModel):
        x: int

    @app.post("/__validate__")
    def _validate(p: Payload):  # pragma: no cover - test harness only
        return {"ok": True}

    with TestClient(app) as c:
        res = c.post("/__validate__", json={"x": "not-int"})
        assert res.status_code == 422
        _assert_error_envelope(res.json(), code="VALIDATION_ERROR")