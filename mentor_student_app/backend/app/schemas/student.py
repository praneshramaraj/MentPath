from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field, field_validator
import re


class StudentProfileCreateRequest(BaseModel):
    # Section 1: Personal Information (Required & Optional)
    full_name: str = Field(..., min_length=2, description="Student full name")
    date_of_birth: str = Field(..., description="Date of birth (YYYY-MM-DD)")
    gender: str = Field(..., description="Gender (Male, Female, Other, Prefer not to say)")
    phone_number: str = Field(..., description="10-digit primary phone number")
    college_email: EmailStr = Field(..., description="Official college email address")
    personal_email: Optional[EmailStr] = Field(None, description="Personal email address (Optional)")
    address: str = Field(..., min_length=5, description="Residential street address")
    city: str = Field(..., min_length=2, description="City")
    state: str = Field(..., min_length=2, description="State")
    pincode: str = Field(..., description="6-digit postal pincode")

    # Section 2: College Information (Required & Optional)
    register_number: str = Field(..., min_length=3, description="College register number")
    department: str = Field(..., min_length=2, description="Department (e.g. Computer Science)")
    course: str = Field(..., min_length=2, description="Course (e.g. B.E. / B.Tech)")
    year: int = Field(..., ge=1, le=4, description="Current academic year (1-4)")
    semester: int = Field(..., ge=1, le=8, description="Current semester (1-8)")
    section: Optional[str] = Field(None, description="Class section (e.g. A, B, C) (Optional)")
    admission_year: int = Field(..., ge=2000, le=2030, description="Admission year")

    # Section 3: Parent / Guardian Information (Required & Optional)
    parent_name: str = Field(..., min_length=2, description="Parent or Guardian name")
    relationship: str = Field(..., min_length=2, description="Relationship (Father, Mother, Guardian)")
    parent_phone: str = Field(..., description="10-digit parent phone number")
    parent_email: Optional[EmailStr] = Field(None, description="Parent email address (Optional)")

    # Section 4: Academic Information (Optional)
    cgpa: Optional[float] = Field(None, ge=0.0, le=10.0, description="Current CGPA (Optional)")
    previous_semester_info: Optional[str] = Field(None, description="Previous semester performance info (Optional)")
    backlog_count: int = Field(default=0, ge=0, description="Active backlog count")

    @field_validator("phone_number", "parent_phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        cleaned = re.sub(r"\D", "", v)
        if len(cleaned) != 10:
            raise ValueError("Phone number must be exactly 10 digits")
        return cleaned

    @field_validator("pincode")
    @classmethod
    def validate_pincode(cls, v: str) -> str:
        cleaned = re.sub(r"\D", "", v)
        if len(cleaned) != 6:
            raise ValueError("Pincode must be exactly 6 digits")
        return cleaned


class StudentProfileUpdateRequest(BaseModel):
    phone_number: Optional[str] = None
    personal_email: Optional[EmailStr] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    parent_name: Optional[str] = None
    relationship: Optional[str] = None
    parent_phone: Optional[str] = None
    parent_email: Optional[EmailStr] = None
    cgpa: Optional[float] = None
    previous_semester_info: Optional[str] = None
    backlog_count: Optional[int] = None


class StudentProfileResponse(BaseModel):
    id: str
    user_id: str

    # Personal
    full_name: str
    date_of_birth: str
    gender: str
    phone_number: str
    college_email: EmailStr
    personal_email: Optional[EmailStr] = None
    address: str
    city: str
    state: str
    pincode: str

    # College
    register_number: str
    department: str
    course: str
    year: int
    semester: int
    section: Optional[str] = None
    admission_year: int
    mentor_id: Optional[str] = None
    mentor_name: Optional[str] = None
    mentor_email: Optional[str] = None
    mentor_department: Optional[str] = None

    # Parent
    parent_name: str
    relationship: str
    parent_phone: str
    parent_email: Optional[EmailStr] = None

    # Academic
    cgpa: Optional[float] = None
    previous_semester_info: Optional[str] = None
    backlog_count: int = 0

    created_at: datetime
    updated_at: datetime
