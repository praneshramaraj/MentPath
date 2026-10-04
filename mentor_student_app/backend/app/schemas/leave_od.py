from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from app.models.leave_request import RequestStatus


class LeaveRequestCreate(BaseModel):
    start_date: str = Field(..., description="Start date (YYYY-MM-DD)")
    end_date: str = Field(..., description="End date (YYYY-MM-DD)")
    reason: str = Field(..., min_length=3, description="Reason for leave")
    document_url: Optional[str] = Field(None, description="Optional supporting document URL / link")


class LeaveStatusUpdate(BaseModel):
    status: RequestStatus = Field(..., description="New status (approved, rejected, cancelled)")
    remarks: Optional[str] = Field(None, description="Remarks by mentor or HOD")


class LeaveRequestResponse(BaseModel):
    id: str
    student_id: str
    student_name: Optional[str] = None
    register_number: Optional[str] = None
    request_type: str = "leave"
    start_date: str
    end_date: str
    reason: str
    document_url: Optional[str] = None
    status: RequestStatus
    reviewer_id: Optional[str] = None
    reviewer_name: Optional[str] = None
    review_timestamp: Optional[datetime] = None
    remarks: Optional[str] = None
    mentor_remarks: Optional[str] = None
    hod_remarks: Optional[str] = None
    created_at: datetime


class ODRequestCreate(BaseModel):
    start_date: str = Field(..., description="Start date (YYYY-MM-DD)")
    end_date: str = Field(..., description="End date (YYYY-MM-DD)")
    event_name: str = Field(..., min_length=2, description="Event or workshop title")
    organization: str = Field(..., min_length=2, description="Hosting organization / institution")
    reason: str = Field(..., min_length=3, description="Reason for On-Duty request")
    proof_document_url: Optional[str] = Field(None, description="Optional proof document URL / link")


class ODStatusUpdate(BaseModel):
    status: RequestStatus = Field(..., description="New status (approved, rejected, cancelled)")
    remarks: Optional[str] = Field(None, description="Remarks by mentor or HOD")


class ODRequestResponse(BaseModel):
    id: str
    student_id: str
    student_name: Optional[str] = None
    register_number: Optional[str] = None
    request_type: str = "od"
    start_date: str
    end_date: str
    event_name: str
    organization: str
    reason: str
    status: RequestStatus
    proof_document_url: Optional[str] = None
    reviewer_id: Optional[str] = None
    reviewer_name: Optional[str] = None
    review_timestamp: Optional[datetime] = None
    remarks: Optional[str] = None
    mentor_remarks: Optional[str] = None
    hod_remarks: Optional[str] = None
    created_at: datetime
