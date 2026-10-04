# Environment Configuration Documentation

This document outlines all environment variables and configuration files required to run the College Mentor–Student Management System in both development and production environments.

---

## 🐍 Backend Configuration (`backend/.env`)

The FastAPI backend uses `pydantic-settings` to parse configuration variables from `.env` or system environment variables.

### Environment Variable Specification

| Variable Name | Required | Default Value | Description |
| :--- | :---: | :--- | :--- |
| `MONGODB_URL` | **Yes** | `mongodb://localhost:27017` | MongoDB connection URI. |
| `MONGODB_DB_NAME` | **Yes** | `mentor_student_db` | Database name for application data. |
| `JWT_SECRET_KEY` | **Yes** | *[Generate random 64-char key]* | Secret key for signing PyJWT access tokens. |
| `JWT_ALGORITHM` | No | `HS256` | HMAC signing algorithm. |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | No | `1440` | Token validity duration in minutes (default 24h). |
| `GEMINI_API_KEY` | No | `""` | Google Gemini API Key for AI Mentor Assistant. |
| `FIREBASE_CREDENTIALS_PATH` | No | `app/core/firebase_credentials.json` | Path to Firebase Admin SDK JSON credentials. |
| `UPLOAD_DIR` | No | `uploads` | Directory relative to backend for storing user files. |
| `MAX_FILE_SIZE_MB` | No | `10` | Maximum allowed file upload size in megabytes. |
| `ALLOWED_EXTENSIONS` | No | `.pdf,.png,.jpg,.jpeg,.webp` | Allowed file extensions for document upload. |
| `LOG_LEVEL` | No | `INFO` | Logging level (`DEBUG`, `INFO`, `WARNING`, `ERROR`). |
| `CORS_ORIGINS` | No | `*` | Allowed CORS origins (comma-separated or `*`). |

### Example Production `.env` File

```ini
# Database Configuration
MONGODB_URL=mongodb://mongo_admin:SecurePassword123@127.0.0.1:27017/mentor_student_db?authSource=admin
MONGODB_DB_NAME=mentor_student_db

# Security & Authentication
JWT_SECRET_KEY=e4a79c81b234567890abcdef1234567890abcdef1234567890abcdef12345678
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# AI Assistant Integrations
GEMINI_API_KEY=AIzaSyD-YourGeminiProductionKeyHere

# Firebase FCM Integration
FIREBASE_CREDENTIALS_PATH=/etc/mentor_app/firebase_credentials.json

# File Storage & Limits
UPLOAD_DIR=/var/www/mentor_app/uploads
MAX_FILE_SIZE_MB=10
ALLOWED_EXTENSIONS=.pdf,.png,.jpg,.jpeg,.webp

# Application Settings
LOG_LEVEL=INFO
CORS_ORIGINS=https://mentorapp.college.edu,https://api.mentorapp.college.edu
```

---

## 📱 Mobile Configuration (`mobile/lib/core/constants/app_constants.dart`)

The Flutter application relies on `AppConstants` for API URLs and network settings.

### File: `mobile/lib/core/constants/app_constants.dart`

```dart
class AppConstants {
  // Production REST API Base URL
  static const String baseUrl = 'https://api.mentorapp.college.edu/api/v1';

  // Development Base URLs:
  // Android Emulator: 'http://10.0.2.2:8000/api/v1'
  // iOS Simulator / Desktop: 'http://127.0.0.1:8000/api/v1'

  // Timeout Configuration
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;

  // Key Constants
  static const String authTokenKey = 'auth_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
}
```

---

## 🔥 Firebase Cloud Messaging (FCM) Setup

For production push notifications:

1. **Android Configuration:**
   - Place `google-services.json` into `mobile/android/app/`.
   - Update `mobile/android/build.gradle` with Google Services classpath.

2. **iOS Configuration:**
   - Place `GoogleService-Info.plist` into `mobile/ios/Runner/`.
   - Enable Push Notifications and Background Modes in Xcode Capabilities.

3. **Backend Service Credentials:**
   - Generate a Service Account JSON key from Firebase Console.
   - Save the file at the path referenced by `FIREBASE_CREDENTIALS_PATH`.
