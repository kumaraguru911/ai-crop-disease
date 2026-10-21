import json
import logging
from collections.abc import Iterator

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from google.genai.errors import APIError
from pydantic import BaseModel, Field

from app.services.gemini_service import (
    GeminiConfigurationError,
    generate_response,
    generate_response_stream,
)

router = APIRouter(prefix="/api", tags=["Chat"])
logger = logging.getLogger(__name__)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)
    prediction: str | None = None
    confidence: float | None = Field(default=None, ge=0, le=1)


class ChatResponse(BaseModel):
    response: str


@router.post("/chat", response_model=ChatResponse)
def chat(request: ChatRequest) -> ChatResponse:
    message = request.message.strip()

    if not message:
        raise HTTPException(
            status_code=422,
            detail="Message must contain at least one non-whitespace character.",
        )

    try:
        response = generate_response(
            message=message,
            prediction=request.prediction,
            confidence=request.confidence,
        )
    except GeminiConfigurationError as error:
        raise HTTPException(
            status_code=503,
            detail="The chat assistant is not configured on this server.",
        ) from error
    except APIError as error:
        logger.exception("Gemini chat request failed")
        raise HTTPException(
            status_code=502,
            detail="The chat provider is temporarily unavailable.",
        ) from error

    return ChatResponse(response=response)


@router.post("/chat/stream")
def chat_stream(request: ChatRequest) -> StreamingResponse:
    message = request.message.strip()

    if not message:
        raise HTTPException(
            status_code=422,
            detail="Message must contain at least one non-whitespace character.",
        )

    def events() -> Iterator[str]:
        try:
            for text in generate_response_stream(
                message=message,
                prediction=request.prediction,
                confidence=request.confidence,
            ):
                yield json.dumps({"text": text}, ensure_ascii=False) + "\n"
        except GeminiConfigurationError:
            yield json.dumps(
                {"error": "The chat assistant is not configured on this server."}
            ) + "\n"
        except APIError:
            logger.exception("Gemini streaming chat request failed")
            yield json.dumps(
                {"error": "The chat provider is temporarily unavailable."}
            ) + "\n"

    return StreamingResponse(events(), media_type="application/x-ndjson")