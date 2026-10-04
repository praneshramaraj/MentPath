from datetime import date
from typing import Optional
from app.models.base import BaseDBModel, PyObjectId
from app.models.leave_request import RequestStatus


class ODRequestModel(BaseDBModel):
    student_id: PyObjectId
    start_date: date
    end_date: date
    event_name: str
    organization: str
    reason: str
    status: RequestStatus = RequestStatus.PENDING
    proof_document_url: Optional[str] = None
    mentor_remarks: Optional[str] = None
    hod_remarks: Optional[str] = None
