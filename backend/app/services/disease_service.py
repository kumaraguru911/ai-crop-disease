import json
from pathlib import Path


DATA_FILE = (
    Path(__file__).resolve().parents[2]
    / "data"
    / "diseases.json"
)


def load_diseases() -> dict:
    with open(DATA_FILE, "r", encoding="utf-8") as file:
        return json.load(file)


def find_disease_by_id(class_id: str) -> dict | None:
    """
    Find disease information using the exact CNN class name.
    Example:
        Tomato___Early_blight
    """
    diseases = load_diseases()

    information = diseases.get(class_id)

    if information is None:
        return None

    return {
        "id": class_id,
        **information,
    }


def find_diseases(query: str) -> list[dict]:
    """
    Find diseases from a natural-language user query.

    This is used for normal chatbot questions such as:
        "What are the symptoms of tomato early blight?"
    """
    diseases = load_diseases()
    query = query.lower()

    matches = []

    known_crops = {
        information["crop"].lower()
        for information in diseases.values()
    }

    for disease_id, information in diseases.items():
        crop = information["crop"].lower()
        disease = information["disease"].lower()

        # If both crop and disease are mentioned,
        # return only the matching crop + disease.
        if crop in query and disease in query:
            matches.append(
                {
                    "id": disease_id,
                    **information,
                }
            )

        # If only the disease is mentioned and no crop
        # is specified, return all matching crops.
        elif (
            disease in query
            and not any(
                known_crop in query
                for known_crop in known_crops
            )
        ):
            matches.append(
                {
                    "id": disease_id,
                    **information,
                }
            )

    return matches

