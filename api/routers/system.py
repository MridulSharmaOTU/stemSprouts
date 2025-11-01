from fastapi import APIRouter

version = "0.1.0"
router = APIRouter(prefix="/system")

@router.get("/healthz")
async def health():
    return {"ok": True}

@router.get("/version")
async def version():
    return {"version": version}