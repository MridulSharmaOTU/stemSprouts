from fastapi import APIRouter
from api.core.config import settings

APP_VERSION = settings.APP_VERSION
router = APIRouter(prefix="/system")

@router.get("/healthz")
async def health():
    return {"ok": True}

@router.get("/version")
async def get_version():
    return {"version": APP_VERSION}