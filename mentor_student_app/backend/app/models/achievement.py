from datetime import date, datetime
from enum import Enum
from typing import Optional
from app.models.base import BaseDBModel, PyObjectId


class AchievementCategory(str, Enum):
    HACKATHONS = "Hackathons"
    CERTIFICATIONS = "Certifications"
    INTERNSHIPS = "Internships"
    PROJECTS = "Projects"
    COMPETITIONS = "Competitions"
    SPORTS = "Sports"
    CULTURAL = "Cultural Achievements"
    OTHER = "Other Approved Achievements"


class VerificationStatus(str, Enum):
    PENDING = "pending"
    VERIFIED = "verified"
    REJECTED = "rejected"


class AchievementModel(BaseDBModel):
    student_id: PyObjectId
    title: str
    category: str
    organization: Optional[str] = None
    description: str
    date_awarded: date
    certificate_url: Optional[str] = None
    verified_by_mentor: bool = False
    verification_status: VerificationStatus = VerificationStatus.PENDING
    verifier_id: Optional[PyObjectId] = None
    verifier_name: Optional[str] = None
    verification_timestamp: Optional[datetime] = None
