from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class AchievementCreate(BaseModel):
    title: str = Field(..., min_length=2, description="Achievement or certification title")
    category: str = Field(..., description="Category (Hackathons, Certifications, Internships, Projects, Competitions, Sports, Cultural Achievements, Other Approved Achievements)")
    organization: Optional[str] = Field(None, description="Hosting institution / organization / issuer")
    description: str = Field(..., min_length=3, description="Detailed description")
    date_awarded: str = Field(..., description="Date awarded/completed (YYYY-MM-DD)")
    certificate_url: Optional[str] = Field(None, description="Certificate link / document reference URL")


class AchievementResponse(BaseModel):
    id: str
    student_id: str
    student_name: Optional[str] = None
    register_number: Optional[str] = None
    title: str
    category: str
    organization: Optional[str] = None
    description: str
    date_awarded: str
    certificate_url: Optional[str] = None
    verified_by_mentor: bool = False
    verification_status: str = "pending"
    verifier_id: Optional[str] = None
    verifier_name: Optional[str] = None
    verification_timestamp: Optional[datetime] = None
    created_at: datetime


class AchievementVerifyRequest(BaseModel):
    verified: bool = True
    remarks: Optional[str] = Field(None, description="Optional mentor verification remarks")
