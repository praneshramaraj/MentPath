from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field
from app.schemas.student import StudentProfileResponse


class MentorProfileCreateRequest(BaseModel):
    employee_id: str = Field(..., min_length=2, description="Employee ID")
    department: str = Field(..., min_length=2, description="Department name")
    designation: str = Field(..., min_length=2, description="Designation (e.g. Assistant Professor)")
    qualification: Optional[str] = Field(None, description="Qualification (e.g. Ph.D, M.Tech)")
    max_mentees: int = Field(default=30, ge=1, le=100, description="Maximum mentee quota")


class MentorProfileResponse(BaseModel):
    id: str
    user_id: str
    employee_id: str
    department: str
    designation: str
    qualification: Optional[str] = None
    assigned_student_count: int = 0
    max_mentees: int = 30
    created_at: datetime
    updated_at: datetime


class StudentAssignRequest(BaseModel):
    student_identifier: str = Field(..., description="Student register number or email address")
    academic_year: str = Field(default="2025-2026", description="Academic year for assignment")


class AssignedStudentSummary(BaseModel):
    student_id: str
    user_id: str
    full_name: str
    register_number: str
    department: str
    course: str
    year: int
    semester: int
    section: Optional[str] = None
    college_email: EmailStr
    phone_number: str
    assigned_date: datetime
