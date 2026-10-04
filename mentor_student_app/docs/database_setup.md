# Database Setup & Schema Specification

The College Mentor–Student Management System utilizes **MongoDB** as its primary persistence engine, interacted with asynchronously via the `motor` driver and defined with **Pydantic v2** validation models.

---

## 🗄 Database Overview

* **Database Engine:** MongoDB 6.0+
* **Database Name:** `mentor_student_db`
* **Driver:** `motor.motor_asyncio.AsyncIOMotorClient`
* **Object ID Mapping:** MongoDB default `_id` is serialized to a 24-character hexadecimal `id` string in API schemas via custom `PyObjectId` field handlers.

---

## 📑 Collection Catalog & Schemas (13 Collections)

### 1. `users`
Stores user authentication credentials, names, and assigned security roles.
```json
{
  "_id": ObjectId("6ac10eb31bc166bf637f322f"),
  "email": "student@college.edu",
  "password_hash": "$2b$12$eImiTXuWVxfM37uY4JANjO5E...",
  "full_name": "Alexander Wright",
  "role": "student", // "student", "mentor", "admin"
  "is_active": true,
  "created_at": ISODate("2026-10-03T19:50:00.000Z"),
  "updated_at": ISODate("2026-10-03T19:50:00.000Z")
}
```

### 2. `student_profiles`
Stores student academic metadata and personal contact numbers.
```json
{
  "_id": ObjectId("..."),
  "user_id": "6ac10eb31bc166bf637f322f",
  "register_number": "312821104001",
  "department": "Computer Science and Engineering",
  "semester": 5,
  "academic_year": "2026-2027",
  "phone_number": "+919876543210",
  "parent_phone_number": "+919876543211",
  "created_at": ISODate("...")
}
```

### 3. `mentor_profiles`
Stores mentor staff metadata and department information.
```json
{
  "_id": ObjectId("..."),
  "user_id": "6ac10eb41bc166bf637f3233",
  "staff_id": "EMP-CSE-102",
  "department": "Computer Science and Engineering",
  "designation": "Associate Professor",
  "office_location": "Block B, Room 304",
  "phone_number": "+919876543220",
  "created_at": ISODate("...")
}
```

### 4. `departments`
Stores academic department configuration.
```json
{
  "_id": ObjectId("..."),
  "code": "CSE",
  "name": "Computer Science and Engineering",
  "hod_user_id": "6ac10eb41bc166bf637f3999"
}
```

### 5. `mentor_student_assignments`
Maps mentees to their authorized faculty mentors.
```json
{
  "_id": ObjectId("..."),
  "mentor_id": "6ac10eb41bc166bf637f3233",
  "student_id": "6ac10eb31bc166bf637f322f",
  "assigned_at": ISODate("...")
}
```

### 6. `attendance`
Stores daily attendance records per subject.
```json
{
  "_id": ObjectId("..."),
  "student_id": "6ac10eb31bc166bf637f322f",
  "subject_code": "CS8591",
  "subject_name": "Computer Networks",
  "date": "2026-10-03",
  "status": "present", // "present", "absent", "od"
  "recorded_by_mentor_id": "6ac10eb41bc166bf637f3233",
  "created_at": ISODate("...")
}
```

### 7. `marks`
Stores real examination marks entered by mentors.
```json
{
  "_id": ObjectId("..."),
  "student_id": "6ac10eb31bc166bf637f322f",
  "subject_code": "CS8591",
  "subject_name": "Computer Networks",
  "exam_type": "Internal", // "Internal", "Model", "Semester", "Assignment", "Practical"
  "exam_name": "Internal Assessment 1",
  "max_marks": 100.0,
  "obtained_marks": 88.0,
  "semester": 5,
  "academic_year": "2026-2027",
  "created_at": ISODate("...")
}
```

### 8. `leave_requests`
Stores leave applications and approval history.
```json
{
  "_id": ObjectId("..."),
  "student_id": "6ac10eb31bc166bf637f322f",
  "start_date": "2026-10-10",
  "end_date": "2026-10-12",
  "reason": "Attending national technical symposium",
  "document_url": "/uploads/documents/symposium_letter.pdf",
  "status": "approved", // "pending", "approved", "rejected", "cancelled"
  "reviewer_id": "6ac10eb41bc166bf637f3233",
  "remarks": "Approved with recommendation to collect notes.",
  "review_timestamp": ISODate("..."),
  "created_at": ISODate("...")
}
```

### 9. `od_requests`
Stores On-Duty permission requests and verification status.
```json
{
  "_id": ObjectId("..."),
  "student_id": "6ac10eb31bc166bf637f322f",
  "start_date": "2026-10-15",
  "end_date": "2026-10-15",
  "event_name": "Smart India Hackathon 2026",
  "organization": "AICTE",
  "reason": "Smart India Hackathon finals",
  "proof_document_url": "/uploads/documents/hackathon_invite.pdf",
  "status": "approved",
  "reviewer_id": "6ac10eb41bc166bf637f3233",
  "remarks": "Approved. Represent college team.",
  "review_timestamp": ISODate("..."),
  "created_at": ISODate("...")
}
```

### 10. `achievements`
Stores co-curricular and extra-curricular achievements.
```json
{
  "_id": ObjectId("..."),
  "student_id": "6ac10eb31bc166bf637f322f",
  "title": "1st Place - State Level Coding Marathon",
  "category": "Hackathons",
  "organization": "Anna University",
  "description": "Secured 1st rank among 150 participating teams.",
  "date_awarded": "2026-09-25",
  "certificate_url": "/uploads/certificates/winner_cert.pdf",
  "is_verified": true,
  "verified_by_mentor_id": "6ac10eb41bc166bf637f3233",
  "remarks": "Verified certificate.",
  "created_at": ISODate("...")
}
```

### 11. `mentor_notes`
Stores mentor counseling notes.
```json
{
  "_id": ObjectId("..."),
  "mentor_id": "6ac10eb41bc166bf637f3233",
  "student_id": "6ac10eb31bc166bf637f322f",
  "category": "Academic discussion",
  "note_content": "Reviewed midterm progress. Suggested extra practice in algorithms.",
  "is_student_visible": true,
  "follow_up_date": "2026-10-25",
  "created_at": ISODate("...")
}
```

### 12. `meetings`
Stores mentor-student meeting minutes.
```json
{
  "_id": ObjectId("..."),
  "mentor_id": "6ac10eb41bc166bf637f3233",
  "student_id": "6ac10eb31bc166bf637f322f",
  "meeting_date": "2026-10-03",
  "topic": "Career guidance & Higher Studies",
  "discussion_summary": "Discussed GATE preparation strategy and research paper topics.",
  "action_items": "Select 2 research paper domain options by next week.",
  "follow_up_date": "2026-10-17",
  "created_at": ISODate("...")
}
```

### 13. `notifications`
Stores real-time event notifications for students and mentors.
```json
{
  "_id": ObjectId("..."),
  "recipient_id": "6ac10eb31bc166bf637f322f",
  "type": "leave_status",
  "title": "Leave Request Approved",
  "message": "Your leave request for 2026-10-10 has been approved.",
  "related_id": "6ac110db5250191d811e3f37",
  "route": "/leave",
  "is_read": false,
  "created_at": ISODate("...")
}
```

---

## ⚡ Indexing & Performance Optimization

To ensure fast query response times under high concurrency, run the index creation script below.

### Index Creation Python Script (`backend/app/database/create_indexes.py`)

```python
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import os

MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DB_NAME = os.getenv("MONGODB_DB_NAME", "mentor_student_db")

async def setup_database_indexes():
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DB_NAME]
    print(f"Applying production database indexes to '{DB_NAME}'...")

    # Users
    await db["users"].create_index("email", unique=True)

    # Student Profiles
    await db["student_profiles"].create_index("user_id", unique=True)
    await db["student_profiles"].create_index("register_number", unique=True)

    # Mentor Profiles
    await db["mentor_profiles"].create_index("user_id", unique=True)

    # Mentor-Student Assignments
    await db["mentor_student_assignments"].create_index([("mentor_id", 1), ("student_id", 1)], unique=True)

    # Attendance
    await db["attendance"].create_index([("student_id", 1), ("date", -1)])
    await db["attendance"].create_index([("student_id", 1), ("subject_code", 1)])

    # Marks
    await db["marks"].create_index([("student_id", 1), ("semester", 1)])

    # Leave & OD Requests
    await db["leave_requests"].create_index([("student_id", 1), ("created_at", -1)])
    await db["od_requests"].create_index([("student_id", 1), ("created_at", -1)])

    # Achievements
    await db["achievements"].create_index([("student_id", 1), ("created_at", -1)])

    # Notes & Meetings
    await db["mentor_notes"].create_index([("student_id", 1), ("mentor_id", 1)])
    await db["meetings"].create_index([("student_id", 1), ("mentor_id", 1)])

    # Notifications
    await db["notifications"].create_index([("recipient_id", 1), ("is_read", 1), ("created_at", -1)])

    print("All production database indexes created successfully!")
    client.close()

if __name__ == "__main__":
    asyncio.run(setup_database_indexes())
```
