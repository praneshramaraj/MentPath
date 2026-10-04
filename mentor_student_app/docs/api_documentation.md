# REST API Documentation

The College Mentor–Student System provides a RESTful HTTP v1 API. All endpoints return standardized JSON structures.

---

## 🔒 Authentication & Headers

Protected endpoints require a Bearer token in the `Authorization` header:

```http
Authorization: Bearer <JWT_ACCESS_TOKEN>
Content-Type: application/json
```

---

## 📦 Standard API Response Wrapper

### Success Response Format
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation completed successfully"
}
```

### Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE_NAME",
    "message": "Human-readable error explanation",
    "details": []
  }
}
```

---

## 🚦 Endpoints Catalog

### 1. Health Check
* **`GET /api/v1/health`**
  * **Auth Required:** No
  * **Response:** Returns API status, version, and MongoDB connection health state.

---

### 2. Authentication Router (`/api/v1/auth`)

* **`POST /api/v1/auth/register`**
  * **Auth Required:** No
  * **Request Body:**
    ```json
    {
      "email": "user@college.edu",
      "password": "SecurePassword123!",
      "full_name": "John Doe",
      "role": "student" // "student", "mentor", or "admin"
    }
    ```
  * **Response:** User object without password hash (`201 Created`).

* **`POST /api/v1/auth/login`**
  * **Auth Required:** No
  * **Request Body:**
    ```json
    {
      "email": "user@college.edu",
      "password": "SecurePassword123!"
    }
    ```
  * **Response:** Bearer JWT token, token type, user role, user ID (`200 OK`).

* **`GET /api/v1/auth/me`**
  * **Auth Required:** Yes
  * **Response:** Currently authenticated user entity (`200 OK`).

---

### 3. Student Profile Router (`/api/v1/student`)

* **`GET /api/v1/student/profile`**
  * **Auth Required:** Student
  * **Response:** Authenticated student profile details or 404 empty state.

* **`PUT /api/v1/student/profile`**
  * **Auth Required:** Student
  * **Request Body:** Profile details (`register_number`, `department`, `semester`, `academic_year`, `phone_number`, `parent_phone_number`).
  * **Response:** Created/updated profile entity (`200 OK`).

---

### 4. Attendance & Academic Performance Router

* **`GET /api/v1/student/attendance`**
  * **Auth Required:** Student
  * **Response:** Real attendance records and computed overall/subject percentage metrics.

* **`GET /api/v1/student/marks`**
  * **Auth Required:** Student
  * **Response:** Real subject-wise and exam-wise marks entered by authorized mentors.

* **`POST /api/v1/mentor/attendance`**
  * **Auth Required:** Mentor
  * **Request Body:**
    ```json
    {
      "student_id": "6ac10eb31bc166bf637f322f",
      "subject_code": "CS8591",
      "subject_name": "Computer Networks",
      "date": "2026-10-03",
      "status": "present" // "present", "absent", or "od"
    }
    ```
  * **Response:** Created attendance record (`201 Created`).

* **`POST /api/v1/mentor/marks`**
  * **Auth Required:** Mentor
  * **Request Body:**
    ```json
    {
      "student_id": "6ac10eb31bc166bf637f322f",
      "subject_code": "CS8591",
      "subject_name": "Computer Networks",
      "exam_type": "Internal",
      "exam_name": "Internal Assessment 1",
      "max_marks": 100,
      "obtained_marks": 88,
      "semester": 5,
      "academic_year": "2026-2027"
    }
    ```
  * **Response:** Created mark entry (`201 Created`).

---

### 5. Leave & On-Duty Requests Router (`/api/v1/leave`, `/api/v1/od`)

* **`GET /api/v1/leave`**
  * **Auth Required:** Student (own requests) or Mentor (assigned mentee requests)
  * **Response:** List of leave request objects.

* **`POST /api/v1/leave`**
  * **Auth Required:** Student
  * **Request Body:** `start_date`, `end_date`, `reason`, `document_url` (optional).
  * **Response:** Created leave request (`201 Created`). Triggers mentor notification.

* **`PATCH /api/v1/leave/{id}/status`**
  * **Auth Required:** Mentor / Admin
  * **Request Body:** `status` ("approved", "rejected"), `remarks`.
  * **Response:** Updated leave request. Triggers student notification.

* **`POST /api/v1/od`**
  * **Auth Required:** Student
  * **Request Body:** `start_date`, `end_date`, `event_name`, `organization`, `reason`, `proof_document_url` (optional).
  * **Response:** Created OD request (`201 Created`). Triggers mentor notification.

---

### 6. Achievements Router (`/api/v1/achievements`)

* **`GET /api/v1/achievements`**
  * **Auth Required:** Student (own achievements) or Mentor (assigned mentee achievements).

* **`POST /api/v1/achievements`**
  * **Auth Required:** Student
  * **Request Body:** `title`, `category`, `organization`, `description`, `date_awarded`, `certificate_url`.

* **`PATCH /api/v1/achievements/{id}/verify`**
  * **Auth Required:** Mentor
  * **Request Body:** `is_verified` (boolean), `remarks`.

---

### 7. Mentor Management Router (`/api/v1/mentor`)

* **`POST /api/v1/mentor/assign-student`**
  * **Auth Required:** Mentor
  * **Request Body:** `{"student_identifier": "student@college.edu"}`
  * **Response:** Assignment confirmation (`200 OK`).

* **`GET /api/v1/mentor/students`**
  * **Auth Required:** Mentor
  * **Response:** List of student profiles assigned to the requesting mentor.

* **`GET /api/v1/mentor/students/{id}`**
  * **Auth Required:** Mentor (Authorized for assigned mentee only).

* **`POST /api/v1/mentor/notes`**
  * **Auth Required:** Mentor
  * **Request Body:** `student_id`, `category`, `note_content`, `is_student_visible`, `follow_up_date`.

* **`POST /api/v1/mentor/meetings`**
  * **Auth Required:** Mentor
  * **Request Body:** `student_id`, `meeting_date`, `topic`, `discussion_summary`, `action_items`, `follow_up_date`.

---

### 8. AI Mentor Assistant Router (`/api/v1/ai-mentor`)

* **`POST /api/v1/ai-mentor/query`**
  * **Auth Required:** Mentor
  * **Request Body:**
    ```json
    {
      "query": "Which assigned students have attendance below 75%?",
      "student_id": "6ac10eb31bc166bf637f322f" // Optional specific student filter
    }
    ```
  * **Response:** Anti-hallucination structured response generated strictly from real database records.

---

### 9. Notifications Router (`/api/v1/notifications`)

* **`GET /api/v1/notifications`**
  * **Auth Required:** Authenticated User
  * **Response:** Chronological list of user notifications with read/unread status.

* **`POST /api/v1/notifications/read-all`**
  * **Auth Required:** Authenticated User
  * **Response:** Marks all recipient notifications as read (`200 OK`).

---

### 10. File Upload Router (`/api/v1/upload`)

* **`POST /api/v1/upload`**
  * **Auth Required:** Authenticated User
  * **Content-Type:** `multipart/form-data`
  * **Validation:** Max size 10MB; allowed extensions `.pdf`, `.png`, `.jpg`, `.jpeg`, `.webp`.
  * **Response:** Generated secure file relative path `/uploads/<category>/<uuid4>.<ext>`.

---

## ⚠️ Standard HTTP Error Codes

| Status Code | Error Code | Description |
| :--- | :--- | :--- |
| `400 Bad Request` | `VALIDATION_ERROR` / `INVALID_FILE` | Bad payload formatting, oversized upload, or disallowed extension. |
| `401 Unauthorized` | `UNAUTHORIZED` | Missing, expired, or invalid JWT Bearer token. |
| `403 Forbidden` | `ACCESS_DENIED` | Attempted access to another user's isolated data or unauthorized RBAC role. |
| `404 Not Found` | `NOT_FOUND` | Referenced entity ID or profile does not exist in MongoDB. |
| `422 Unprocessable` | `SCHEMA_VALIDATION_FAILED` | FastAPI Pydantic schema validation error. |
| `500 Server Error` | `INTERNAL_SERVER_ERROR` | Unexpected server failure. |
