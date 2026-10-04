from datetime import datetime, timezone
from typing import List, Optional
from bson import ObjectId
from fastapi import status
from app.database.collections import (
    MENTOR_NOTES_COLLECTION,
    MEETINGS_COLLECTION,
    MENTOR_STUDENT_ASSIGNMENTS_COLLECTION,
    STUDENT_PROFILES_COLLECTION,
    USERS_COLLECTION,
    NOTIFICATIONS_COLLECTION
)
from app.database.mongodb import get_database
from app.models.user import UserModel, UserRole
from app.services.notification_service import NotificationService
from app.schemas.meeting_note import (
    MentorNoteCreate,
    MentorNoteResponse,
    MeetingCreate,
    MeetingResponse
)
from app.utils.error_handlers import AppException


class MeetingNoteService:

    @staticmethod
    async def _get_student_info(student_id_str: str) -> tuple[str, str]:
        db = get_database()
        profile = await db[STUDENT_PROFILES_COLLECTION].find_one({
            "$or": [{"user_id": student_id_str}, {"user_id": ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None}]
        })
        user = await db[USERS_COLLECTION].find_one({
            "$or": [{"_id": student_id_str}, {"_id": ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None}]
        })
        name = "Student"
        reg = ""
        if profile:
            name = profile.get("full_name") or (user.get("email") if user else "Student")
            reg = profile.get("register_number", "")
        elif user:
            name = user.get("email", "Student")
        return name, reg

    @staticmethod
    async def _verify_mentor_mentee_assignment(mentor_id_str: str, student_id_str: str):
        db = get_database()
        assignment = await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find_one({
            "mentor_id": mentor_id_str,
            "student_id": {"$in": [student_id_str, ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None]},
            "is_active": True
        })
        if not assignment:
            raise AppException(
                status_code=status.HTTP_403_FORBIDDEN,
                message="You are not authorized to create or access records for this student."
            )

    # MENTOR NOTES
    @staticmethod
    async def create_mentor_note(mentor: UserModel, payload: MentorNoteCreate) -> MentorNoteResponse:
        db = get_database()
        now = datetime.now(timezone.utc)
        mentor_id_str = str(mentor.id)
        student_id_str = payload.student_id

        # Security check: Mentors can only create notes for authorized assigned students
        if mentor.role == UserRole.MENTOR.value:
            await MeetingNoteService._verify_mentor_mentee_assignment(mentor_id_str, student_id_str)

        doc = {
            "mentor_id": mentor_id_str,
            "mentor_name": mentor.full_name or mentor.email,
            "student_id": student_id_str,
            "category": payload.category.strip(),
            "title": payload.title.strip(),
            "note": payload.note.strip(),
            "date": payload.date.strip(),
            "follow_up_date": payload.follow_up_date.strip() if payload.follow_up_date else None,
            "is_student_visible": payload.is_student_visible,
            "created_at": now,
            "updated_at": now
        }

        result = await db[MENTOR_NOTES_COLLECTION].insert_one(doc)
        note_id = str(result.inserted_id)

        # Notify student if configured as student-visible
        if payload.is_student_visible:
            await NotificationService.create_and_send_notification(
                recipient_user_id=student_id_str,
                title=f"New Mentor Note: {payload.title}",
                message=f"Your mentor shared a note under category '{payload.category}'.",
                notification_type="NEW_MENTOR_NOTE",
                related_record_id=note_id,
                related_record_type="mentor_note"
            )

        st_name, reg = await MeetingNoteService._get_student_info(student_id_str)
        return MentorNoteResponse(
            id=note_id,
            mentor_id=mentor_id_str,
            mentor_name=mentor.full_name or mentor.email,
            student_id=student_id_str,
            student_name=st_name,
            register_number=reg,
            category=payload.category.strip(),
            title=payload.title.strip(),
            note=payload.note.strip(),
            date=payload.date.strip(),
            follow_up_date=payload.follow_up_date.strip() if payload.follow_up_date else None,
            is_student_visible=payload.is_student_visible,
            created_at=now
        )

    @staticmethod
    async def get_student_notes(student_id_str: str, current_user: UserModel) -> List[MentorNoteResponse]:
        db = get_database()
        
        # Security authorization checks
        if current_user.role == UserRole.STUDENT.value:
            if str(current_user.id) != student_id_str:
                raise AppException(status_code=status.HTTP_403_FORBIDDEN, message="You can only access your own notes.")
            query = {
                "student_id": {"$in": [student_id_str, ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None]},
                "is_student_visible": True
            }
        elif current_user.role == UserRole.MENTOR.value:
            await MeetingNoteService._verify_mentor_mentee_assignment(str(current_user.id), student_id_str)
            query = {
                "student_id": {"$in": [student_id_str, ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None]}
            }
        else:
            query = {
                "student_id": {"$in": [student_id_str, ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None]}
            }

        cursor = db[MENTOR_NOTES_COLLECTION].find(query).sort("created_at", -1)

        results = []
        st_name, reg = await MeetingNoteService._get_student_info(student_id_str)
        async for doc in cursor:
            results.append(MentorNoteResponse(
                id=str(doc["_id"]),
                mentor_id=str(doc["mentor_id"]),
                mentor_name=doc.get("mentor_name"),
                student_id=str(doc["student_id"]),
                student_name=st_name,
                register_number=reg,
                category=doc.get("category", "General Note"),
                title=doc.get("title", "Mentor Note"),
                note=doc.get("note", doc.get("content", "")),
                date=doc.get("date", doc.get("created_at", datetime.now(timezone.utc)).strftime("%Y-%m-%d")),
                follow_up_date=doc.get("follow_up_date"),
                is_student_visible=doc.get("is_student_visible", not doc.get("is_private", True)),
                created_at=doc.get("created_at", datetime.now(timezone.utc))
            ))
        return results

    # MENTOR MEETINGS
    @staticmethod
    async def create_meeting(mentor: UserModel, payload: MeetingCreate) -> MeetingResponse:
        db = get_database()
        now = datetime.now(timezone.utc)
        mentor_id_str = str(mentor.id)
        student_id_str = payload.student_id

        # Security check: Mentors can only record meetings for assigned students
        if mentor.role == UserRole.MENTOR.value:
            await MeetingNoteService._verify_mentor_mentee_assignment(mentor_id_str, student_id_str)

        doc = {
            "mentor_id": mentor_id_str,
            "mentor_name": mentor.full_name or mentor.email,
            "student_id": student_id_str,
            "topic": payload.topic.strip(),
            "date": payload.date.strip(),
            "discussion_summary": payload.discussion_summary.strip(),
            "action_items": payload.action_items.strip() if payload.action_items else None,
            "follow_up_date": payload.follow_up_date.strip() if payload.follow_up_date else None,
            "is_student_visible": payload.is_student_visible,
            "created_at": now,
            "updated_at": now
        }

        result = await db[MEETINGS_COLLECTION].insert_one(doc)
        meeting_id = str(result.inserted_id)

        # Notify student if configured as student-visible
        if payload.is_student_visible:
            await NotificationService.create_and_send_notification(
                recipient_user_id=student_id_str,
                title=f"Counseling Session Logged: {payload.topic}",
                message=f"Counseling meeting record on {payload.date} logged by your mentor.",
                notification_type="MEETING_SCHEDULED",
                related_record_id=meeting_id,
                related_record_type="meeting"
            )

        st_name, reg = await MeetingNoteService._get_student_info(student_id_str)
        return MeetingResponse(
            id=meeting_id,
            mentor_id=mentor_id_str,
            mentor_name=mentor.full_name or mentor.email,
            student_id=student_id_str,
            student_name=st_name,
            register_number=reg,
            topic=payload.topic.strip(),
            date=payload.date.strip(),
            discussion_summary=payload.discussion_summary.strip(),
            action_items=payload.action_items.strip() if payload.action_items else None,
            follow_up_date=payload.follow_up_date.strip() if payload.follow_up_date else None,
            is_student_visible=payload.is_student_visible,
            created_at=now
        )

    @staticmethod
    async def get_student_meetings(student_id_str: str, current_user: UserModel) -> List[MeetingResponse]:
        db = get_database()

        # Security authorization checks
        if current_user.role == UserRole.STUDENT.value:
            if str(current_user.id) != student_id_str:
                raise AppException(status_code=status.HTTP_403_FORBIDDEN, message="You can only access your own meeting records.")
            query = {
                "student_id": {"$in": [student_id_str, ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None]},
                "is_student_visible": True
            }
        elif current_user.role == UserRole.MENTOR.value:
            await MeetingNoteService._verify_mentor_mentee_assignment(str(current_user.id), student_id_str)
            query = {
                "student_id": {"$in": [student_id_str, ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None]}
            }
        else:
            query = {
                "student_id": {"$in": [student_id_str, ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None]}
            }

        cursor = db[MEETINGS_COLLECTION].find(query).sort("created_at", -1)

        results = []
        st_name, reg = await MeetingNoteService._get_student_info(student_id_str)
        async for doc in cursor:
            results.append(MeetingResponse(
                id=str(doc["_id"]),
                mentor_id=str(doc["mentor_id"]),
                mentor_name=doc.get("mentor_name"),
                student_id=str(doc.get("student_id") or (doc.get("student_ids", [""])[0] if doc.get("student_ids") else "")),
                student_name=st_name,
                register_number=reg,
                topic=doc.get("topic", doc.get("title", "Mentor Meeting")),
                date=doc.get("date", doc.get("scheduled_time", datetime.now(timezone.utc)).strftime("%Y-%m-%d")),
                discussion_summary=doc.get("discussion_summary", doc.get("agenda", "")),
                action_items=doc.get("action_items", doc.get("minutes_of_meeting")),
                follow_up_date=doc.get("follow_up_date"),
                is_student_visible=doc.get("is_student_visible", True),
                created_at=doc.get("created_at", datetime.now(timezone.utc))
            ))
        return results
