from fastapi import APIRouter
from pydantic import BaseModel

from app.services.gemini_service import generate_response

router = APIRouter(prefix="/api", tags=["Chat"])


class ChatRequest(BaseModel):
    message: str
    prediction: str | None = None
    confidence: float | None = None


class ChatResponse(BaseModel):
    response: str


@router.post("/chat", response_model=ChatResponse)
def chat(request: ChatRequest):


    response = generate_response(
    message=request.message,
    prediction=request.prediction,
    confidence=request.confidence,
)

    return ChatResponse(
        response=response
    )