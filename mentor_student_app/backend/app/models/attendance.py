from datetime import date
from enum import Enum
from typing import Optional
from app.models.base import BaseDBModel, PyObjectId


class AttendanceStatus(str, Enum):
    PRESENT = "present"
    ABSENT = "absent"
    LATE = "late"
    OD = "on_duty"
    LEAVE = "leave"


class AttendanceModel(BaseDBModel):
    student_id: PyObjectId
    date: date
    status: AttendanceStatus
    subject_code: Optional[str] = None
    subject_name: Optional[str] = None
    period_session: Optional[str] = None  # e.g., "Period 1", "FN", "AN"
    remarks: Optional[str] = None
    created_by: Optional[PyObjectId] = None
