from datetime import datetime, timezone
from typing import Optional
from pydantic import Field
from app.models.base import BaseDBModel, PyObjectId


class MentorStudentAssignmentModel(BaseDBModel):
    mentor_id: PyObjectId
    student_id: PyObjectId
    assigned_date: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    is_active: bool = True
    academic_year: str
