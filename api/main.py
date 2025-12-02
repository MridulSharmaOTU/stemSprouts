import sys
import os
from fastapi import FastAPI

# Add the project root directory to the Python path.
# This allows for absolute imports from any module in the project,
# which is crucial for both running the app and for tools like Pytest.
# The project root is the directory containing this main.py file.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Now that the Python path is configured, we can use absolute imports.
from routers import system, ai

app = FastAPI()
app.include_router(system.router)
app.include_router(ai.router)
