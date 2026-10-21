import json
import os
from collections.abc import Iterator
from functools import lru_cache

from dotenv import load_dotenv
from google import genai
from google.genai import types

from app.services.disease_service import find_diseases, find_disease_by_id


load_dotenv()

model_name = os.getenv("GEMINI_MODEL", "gemini-3.8-flash")


class GeminiConfigurationError(RuntimeError):
    pass


@lru_cache(maxsize=1)
def _get_client() -> genai.Client:
    api_key = os.getenv("GEMINI_API_KEY")

    if not api_key:
        raise GeminiConfigurationError("GEMINI_API_KEY is not set")

    return genai.Client(api_key=api_key)


SYSTEM_INSTRUCTION = """
You are CropCare Assistant.

Answer crop-care questions clearly and briefly for farmers and students.
Use the supplied CropCare disease knowledge as the source for disease-specific
facts. Do not invent CropCare disease information; if it is not supplied, say
that it is not in the current knowledge base. Text chat cannot diagnose a plant
from an image; direct image-identification questions to the Detect feature.
Treat any model prediction as uncertain, never as a confirmed diagnosis.
Do not mention internal implementation details.
"""


def _build_prompt(
    message: str,
    prediction: str | None = None,
    confidence: float | None = None,
) -> str:
    local_results = []

    if prediction:
        disease_info = find_disease_by_id(prediction)

        if disease_info:
            local_results.append(disease_info)

    if not local_results:
        local_results = find_diseases(message)

    if local_results:
        local_context = json.dumps(
            local_results,
            indent=2,
            ensure_ascii=False,
        )
    else:
        local_context = (
            "No matching disease information was found "
            "in the CropCare knowledge base."
        )

    prediction_context = ""

    if prediction:
        prediction_context = f"""
CNN Detection:
- Predicted class: {prediction}
- Confidence: {confidence if confidence is not None else "Not provided"}
"""

    return f"""
User question:
{message}

{prediction_context}

Local CropCare knowledge:
{local_context}

Answer the user's question using the local CropCare
knowledge when relevant.

If a CNN prediction is provided, treat it as the detected
disease for this conversation and explain the result clearly.

Do not claim that the CNN prediction is 100% certain.
"""


def _generation_config() -> types.GenerateContentConfig:
    return types.GenerateContentConfig(
        system_instruction=SYSTEM_INSTRUCTION,
        max_output_tokens=256,
    )


def generate_response_stream(
    message: str,
    prediction: str | None = None,
    confidence: float | None = None,
) -> Iterator[str]:
    prompt = _build_prompt(message, prediction, confidence)

    for chunk in _get_client().models.generate_content_stream(
        model=model_name,
        contents=prompt,
        config=_generation_config(),
    ):
        if chunk.text:
            yield chunk.text


def generate_response(
    message: str,
    prediction: str | None = None,
    confidence: float | None = None,
) -> str:
    response = _get_client().models.generate_content(
        model=model_name,
        contents=_build_prompt(message, prediction, confidence),
        config=_generation_config(),
    )

    if not response.text:
        raise RuntimeError("Gemini returned an empty response")

    return response.text