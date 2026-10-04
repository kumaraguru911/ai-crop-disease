import os
import json

from dotenv import load_dotenv
from google import genai

from app.services.disease_service import find_diseases, find_disease_by_id


load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
model_name = os.getenv("GEMINI_MODEL", "gemini-3.8-flash")

if not api_key:
    raise RuntimeError("GEMINI_API_KEY is not set")

client = genai.Client(api_key=api_key)


SYSTEM_INSTRUCTION = """
You are CropCare Assistant.

You help users understand crop diseases, symptoms,
prevention, and basic treatment or management information.

Use the local CropCare knowledge provided with each request
as the primary source for disease-specific information.

Important rules:

1. Do not invent CropCare disease information.
2. If local knowledge is provided, use it when answering.
3. If the user asks about a disease that is not in the local
   knowledge, clearly say that the disease is not currently
   included in the CropCare knowledge base.
4. Do not claim that text conversation can diagnose a plant
   from an image.
5. For image-based disease identification, tell the user to
   use the Detect feature.
6. Keep answers clear and easy to understand for farmers
   and students.
7. Do not mention internal implementation details such as
   JSON, APIs, RAG, embeddings, or vector databases.
"""


def generate_response(
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

    prompt = f"""
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

    response = client.models.generate_content(
        model=model_name,
        contents=prompt,
        config={
            "system_instruction": SYSTEM_INSTRUCTION,
        },
    )

    return response.text