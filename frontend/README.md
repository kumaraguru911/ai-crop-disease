# CropCare Flutter app

Install dependencies and run the mobile app from this directory:

The disease classifier and retrieval-based chat assistant run locally. The
assistant searches the bundled crop disease guide; it does not need a backend,
internet access, Gemini API key, USB port forwarding, or `CHAT_API_BASE_URL`.
Start the app from this directory:

```powershell
flutter pub get
flutter run
```

The optional `backend/` FastAPI service is separate and is not used by mobile
chat. For project details, see the repository [README](../README.md).
