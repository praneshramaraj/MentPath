from typing import Optional, List
from pydantic import Field
from app.models.base import BaseDBModel, PyObjectId


class MentorProfileModel(BaseDBModel):
    user_id: PyObjectId
    employee_id: str
    department_id: PyObjectId
    designation: str
    qualification: Optional[str] = None
    assigned_student_ids: List[PyObjectId] = Field(default_factory=list)
    max_mentees: int = 30
