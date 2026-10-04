from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field


# MENTOR NOTES SCHEMAS
class MentorNoteCreate(BaseModel):
    student_id: str = Field(..., description="Target student user ID")
    category: str = Field(..., description="Category: Academic discussion, Career guidance, Attendance discussion, Personal follow-up, Improvement plan")
    title: str = Field(..., min_length=2, description="Note title")
    note: str = Field(..., min_length=2, description="Note content / observation")
    date: str = Field(..., description="Date of note (YYYY-MM-DD)")
    follow_up_date: Optional[str] = Field(None, description="Optional follow-up date (YYYY-MM-DD)")
    is_student_visible: bool = Field(False, description="Whether note is configured to be visible to the student")


class MentorNoteResponse(BaseModel):
    id: str
    mentor_id: str
    mentor_name: Optional[str] = None
    student_id: str
    student_name: Optional[str] = None
    register_number: Optional[str] = None
    category: str
    title: str
    note: str
    date: str
    follow_up_date: Optional[str] = None
    is_student_visible: bool = False
    created_at: datetime


# MENTOR MEETING SCHEMAS
class MeetingCreate(BaseModel):
    student_id: str = Field(..., description="Target student user ID")
    topic: str = Field(..., min_length=2, description="Meeting topic / title")
    date: str = Field(..., description="Meeting date (YYYY-MM-DD)")
    discussion_summary: str = Field(..., min_length=3, description="Summary of discussion points")
    action_items: Optional[str] = Field(None, description="Action items agreed upon")
    follow_up_date: Optional[str] = Field(None, description="Optional follow-up date (YYYY-MM-DD)")
    is_student_visible: bool = Field(True, description="Whether meeting record is configured to be visible to the student")


class MeetingResponse(BaseModel):
    id: str
    mentor_id: str
    mentor_name: Optional[str] = None
    student_id: str
    student_name: Optional[str] = None
    register_number: Optional[str] = None
    topic: str
    date: str
    discussion_summary: str
    action_items: Optional[str] = None
    follow_up_date: Optional[str] = None
    is_student_visible: bool = True
    created_at: datetime
