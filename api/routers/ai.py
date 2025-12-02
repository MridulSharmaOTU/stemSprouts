import httpx
import json
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from starlette.responses import StreamingResponse

from core.config import Settings, get_settings

router = APIRouter(prefix="/chat")


class ChatRequest(BaseModel):
    messages: list[dict]
    model: str = None
    stream: bool = True


async def _parse_stream_events(response: httpx.Response):
    """Parse streamed openrouter responses. See https://openrouter.ai/docs/api/reference/streaming for details"""
    async for line in response.aiter_lines():
        if not line.startswith("data:"):
            continue

        json_str = line.removeprefix("data: ").strip()
        if json_str == "[DONE]":
            break

        try:
            chunk_json = json.loads(json_str)
            content = chunk_json["choices"][0]["delta"].get("content")
            if content:
                yield content.encode()
        except (json.JSONDecodeError, IndexError):
            continue


async def _stream_generator(url: str, headers: dict, data: dict):
    """Yields chunks from a streaming API response."""
    async with httpx.AsyncClient() as client:
        try:
            async with client.stream("POST", url, headers=headers, json=data, timeout=180) as response:
                if response.status_code >= 400:
                    error_message = f"Error from upstream API: {response.status_code}\n"
                    yield error_message.encode()
                    async for chunk in response.aiter_bytes():
                        yield chunk
                    return

                async for chunk in _parse_stream_events(response):
                    yield chunk

        except httpx.RequestError as e:
            error_message = f"Error connecting to upstream API: {e}"
            yield error_message.encode()


async def _handle_non_stream_request(url: str, headers: dict, data: dict):
    """Handles a non-streaming API request (good to have as an option)."""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, headers=headers, json=data, timeout=180)
            response.raise_for_status()
            response_json = response.json()
            content = response_json["choices"][0]["message"]["content"]
            return {"content": content}
        except httpx.HTTPStatusError as e:
            try:
                detail = e.response.json()
            except Exception:
                detail = e.response.text
            raise HTTPException(status_code=e.response.status_code, detail=detail)
        except httpx.RequestError as e:
            raise HTTPException(status_code=500, detail=f"Error connecting to upstream API: {e}")
        except (KeyError, IndexError, json.JSONDecodeError):
            raise HTTPException(status_code=500, detail=f"Unexpected response format from upstream API: {response.text}")


@router.post("/completions")
async def chat_completions(
    request: ChatRequest,
    settings: Settings = Depends(get_settings),
):
    """
    Proxies requests to the AI provider via OpenRouter.
    """
    if not settings.OPENROUTER_API_KEY:
        raise HTTPException(status_code=500, detail="OPENROUTER_API_KEY not set")

    if not request.model:
        request.model = settings.OPENROUTER_API_MODEL

    headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
    }
    data = {
        "model": request.model,
        "messages": request.messages,
        "stream": request.stream,
    }

    if request.stream:
        return StreamingResponse(_stream_generator(settings.OPENROUTER_API_URL, headers, data), media_type="text/plain")
    else:
        return await _handle_non_stream_request(settings.OPENROUTER_API_URL, headers, data)
