# Architecture & Database Schema Documentation (Phase 1)

## 1. System Architecture Overview

The College Mentor–Student Management System uses a clean multi-tier architecture:

* **Mobile App (Flutter + Material 3):** Declarative GoRouter navigation, centralized White + Blue design tokens, async state management via Riverpod/StatefulWidgets, and robust HTTP API client with timeout and exception mapping.
* **Backend (FastAPI + Pydantic v2):** Async REST API service with environment variable parsing via `pydantic-settings`, structured logging, custom error exception handlers, and JWT security setup.
* **Database (MongoDB + Motor):** Non-blocking async MongoDB client connecting via `motor`, with collection name registries and domain entities prepared for 13 future collections.

---

## 2. Prepared Collections Architecture

The database architecture is prepared for the following 13 collections without inserting mock or sample records:

| Collection Name | Entity Model | Description |
| :--- | :--- | :--- |
| `users` | `UserModel` | Core credentials, role (student, mentor, hod, admin), active status |
| `student_profiles` | `StudentProfileModel` | Register number, department ID, batch year, semester, parent contacts |
| `mentor_profiles` | `MentorProfileModel` | Employee ID, designation, qualification, max mentee quota |
| `departments` | `DepartmentModel` | Department code, full name, HOD user reference |
| `mentor_student_assignments` | `MentorStudentAssignmentModel` | Mapping between mentors and student mentees per academic year |
| `attendance` | `AttendanceModel` | Daily or subject-wise attendance logs (present, absent, OD, leave) |
| `marks` | `MarksModel` | Exam marks, internal assessments, semester grades |
| `leave_requests` | `LeaveRequestModel` | Student leave applications with mentor & HOD approval workflows |
| `od_requests` | `ODRequestModel` | On-duty requests for sports, paper presentations, conferences |
| `achievements` | `AchievementModel` | Student academic, technical, sports awards and verification status |
| `mentor_notes` | `MentorNoteModel` | Confidential or shared counseling notes maintained by mentors |
| `meetings` | `MeetingModel` | Scheduled mentor-mentee counseling sessions and minutes |
| `notifications` | `NotificationModel` | In-app alerts for leave updates, meeting notices, announcements |

---

## 3. Health Check Contract

* **Endpoint:** `GET /api/v1/health`
* **Response Body Example:**
```json
{
  "status": "healthy",
  "app_name": "Mentor-Student Management System",
  "version": "1.0.0",
  "environment": "development",
  "timestamp": "2026-10-02T09:17:31.696026Z",
  "database": {
    "status": "connected",
    "details": "MongoDB ping successful and connection active.",
    "db_name": "mentor_student_db"
  }
}
```
