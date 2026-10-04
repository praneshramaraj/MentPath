from typing import Optional, List
from app.models.base import BaseDBModel, PyObjectId


class MeetingModel(BaseDBModel):
    mentor_id: PyObjectId
    student_id: PyObjectId
    topic: str
    date: str
    discussion_summary: str
    action_items: Optional[str] = None
    follow_up_date: Optional[str] = None
    is_student_visible: bool = True
