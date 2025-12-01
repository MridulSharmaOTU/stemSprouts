from fastapi import FastAPI
from .routers import system, ai

app = FastAPI()
app.include_router(system.router)
app.include_router(ai.router)