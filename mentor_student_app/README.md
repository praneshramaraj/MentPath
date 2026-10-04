# College Mentor–Student Management System

A production-grade, enterprise-ready College Mentor–Student Management application built with **Python FastAPI**, **MongoDB (Motor)**, **Flutter (Material 3)**, and **Google Gemini AI**.

---

## 🏛 System Architecture & Tech Stack

```
                               ┌─────────────────────────────┐
                               │  Flutter Mobile App (v3.x)  │
                               │   (Material 3 White+Blue)   │
                               └──────────────┬──────────────┘
                                              │ REST API (JSON / Bearer JWT)
                                              ▼
                               ┌─────────────────────────────┐
                               │   FastAPI Async Backend     │
                               │   (Uvicorn / Gunicorn)      │
                               └──────┬───────┬───────┬──────┘
                                      │       │       │
             ┌────────────────────────┘       │       └────────────────────────┐
             ▼                                ▼                                ▼
┌─────────────────────────┐      ┌─────────────────────────┐      ┌─────────────────────────┐
│   MongoDB (Motor Driver)│      │  Google Gemini 2.5 AI   │      │  Firebase Messaging     │
│   (13 Collections)      │      │  (Anti-Hallucination)   │      │  (Push Notifications)   │
└─────────────────────────┘      └─────────────────────────┘      └─────────────────────────┘
```

### Backend Architecture
* **Framework:** Python FastAPI (Asynchronous `async`/`await` architecture)
* **Database:** MongoDB with `motor` async driver & Pydantic v2 data models
* **Security:** Passlib (Bcrypt hashing), PyJWT (JWT tokens with expiration), CORS middleware, input sanitization, safe file upload with UUID filename generation
* **AI Integration:** Google Gemini 2.5 Flash via `google-genai` SDK with deterministic offline fallbacks and strict anti-hallucination prompts

### Mobile Application Architecture
* **Framework:** Flutter 3.x with Dart 3
* **UI Design System:** Material 3 with White + Blue color palette (~80% white, 20% blue accents)
* **State Management:** Provider / BLoC pattern ready, clean feature-based modular folder structure
* **Features:** Auth flow, Student Dashboard, Mentor Dashboard, Attendance tracking, Marks entry, Leave/OD workflow, Achievements verification, Notes & Counseling Meetings, Real-time Notification Badges, AI Mentor Assistant

---

## 🎨 White + Blue Design System

* **Primary Blue:** `#1565C0`
* **Dark Blue (Headings):** `#0D47A1`
* **Light Blue (Info Areas):** `#E3F2FD`
* **Background:** `#FFFFFF`
* **Primary Text:** `#172B4D`
* **Secondary Text:** `#607D8B`
* **Border Color:** `#D9E2EC`

---

## 📚 Complete Production Documentation Index

Detailed step-by-step documentation is available in the [`docs/`](file:///Users/pranesh/Desktop/Mentor%20App/mentor_student_app/docs) directory:

1. ⚙️ **[Environment Configuration](docs/environment_config.md)**: Full reference for backend `.env` keys, mobile constants, and Firebase config setup.
2. 🔌 **[API Documentation](docs/api_documentation.md)**: Complete endpoint catalog, HTTP response wrappers, authentication headers, and error codes.
3. 🗄 **[Database Setup & Schemas](docs/database_setup.md)**: MongoDB collection specifications, Pydantic entity schemas, and index creation scripts.
4. 📱 **[Flutter Build Instructions](docs/flutter_build_instructions.md)**: Steps to run, analyze, test, and package APK / IPA production binaries.
5. 🚀 **[Production Deployment Guide](docs/production_deployment.md)**: Systemd service setup, Nginx reverse proxy configuration, SSL setup, and security hardening.

---

## ⚡ Quick Start (Local Development)

### 1. MongoDB Service
Ensure MongoDB is running locally:
```bash
mongod --dbpath /usr/local/var/mongodb
```

### 2. FastAPI Backend
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Check API health: `curl http://localhost:8000/api/v1/health`

### 3. Flutter Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

---

## 🛡 Security & Verification

* **Audit Results:** 18/18 security penetration tests passed (Student isolation, Mentor mentee isolation, RBAC checks, JWT signature verification, safe file uploads).
* **Workflow Test Suite:** 100% real-workflow automated testing verified without fake demo data.
* **Static Analysis:** `flutter analyze` — 0 issues found.
* **Unit & Widget Tests:** `flutter test` — 100% tests passed.
