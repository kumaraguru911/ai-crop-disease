from fastapi import FastAPI

from app.routes.chat import router as chat_router
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="CropCare Backend",
    description="Backend API for the CropCare Assistant",
    version="1.0.0",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {
        "status": "ok"
    }


app.include_router(chat_router)