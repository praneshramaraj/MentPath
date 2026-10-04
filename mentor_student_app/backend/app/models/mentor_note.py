from datetime import datetime
from typing import Optional
from app.models.base import BaseDBModel, PyObjectId


class MentorNoteModel(BaseDBModel):
    mentor_id: PyObjectId
    student_id: PyObjectId
    category: str  # Academic discussion, Career guidance, Attendance discussion, Personal follow-up, Improvement plan
    title: str
    note: str
    date: str
    follow_up_date: Optional[str] = None
    is_student_visible: bool = False
