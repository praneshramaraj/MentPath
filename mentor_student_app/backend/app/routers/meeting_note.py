from typing import List
from fastapi import APIRouter, Depends, status
from app.core.dependencies import require_roles, get_current_user
from app.models.user import UserModel, UserRole
from app.schemas.meeting_note import (
    MentorNoteCreate,
    MentorNoteResponse,
    MeetingCreate,
    MeetingResponse
)
from app.services.meeting_note_service import MeetingNoteService

router = APIRouter(prefix="", tags=["Mentor Notes & Meetings"])


# MENTOR NOTES ENDPOINTS
@router.post("/notes", response_model=MentorNoteResponse, status_code=status.HTTP_201_CREATED)
async def create_mentor_note(
    payload: MentorNoteCreate,
    current_user: UserModel = Depends(require_roles(UserRole.MENTOR, UserRole.ADMIN))
):
    """Create a new mentor note for an assigned student (Mentor/Admin)."""
    return await MeetingNoteService.create_mentor_note(mentor=current_user, payload=payload)


@router.get("/notes/student/{student_id}", response_model=List[MentorNoteResponse])
async def get_student_notes(
    student_id: str,
    current_user: UserModel = Depends(get_current_user)
):
    """Get mentor notes for a student (Students see only student-visible notes)."""
    return await MeetingNoteService.get_student_notes(student_id_str=student_id, current_user=current_user)


# MENTOR MEETINGS ENDPOINTS
@router.post("/meetings", response_model=MeetingResponse, status_code=status.HTTP_201_CREATED)
async def create_mentor_meeting(
    payload: MeetingCreate,
    current_user: UserModel = Depends(require_roles(UserRole.MENTOR, UserRole.ADMIN))
):
    """Log a meeting record with an assigned student (Mentor/Admin)."""
    return await MeetingNoteService.create_meeting(mentor=current_user, payload=payload)


@router.get("/meetings/student/{student_id}", response_model=List[MeetingResponse])
async def get_student_meetings(
    student_id: str,
    current_user: UserModel = Depends(get_current_user)
):
    """Get meeting records for a student (Students see only student-visible records)."""
    return await MeetingNoteService.get_student_meetings(student_id_str=student_id, current_user=current_user)
