from datetime import date, datetime
from enum import Enum
from typing import Optional
from app.models.base import BaseDBModel, PyObjectId


class RequestStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    APPROVED_BY_MENTOR = "approved_by_mentor"
    APPROVED_BY_HOD = "approved_by_hod"
    REJECTED = "rejected"
    CANCELLED = "cancelled"


class LeaveRequestModel(BaseDBModel):
    student_id: PyObjectId
    start_date: date
    end_date: date
    reason: str
    document_url: Optional[str] = None
    status: RequestStatus = RequestStatus.PENDING
    reviewer_id: Optional[PyObjectId] = None
    review_timestamp: Optional[datetime] = None
    remarks: Optional[str] = None
    mentor_remarks: Optional[str] = None
    hod_remarks: Optional[str] = None
