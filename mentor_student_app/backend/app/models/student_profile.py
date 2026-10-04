from typing import Optional
from pydantic import EmailStr, Field
from app.models.base import BaseDBModel, PyObjectId


class StudentProfileModel(BaseDBModel):
    user_id: PyObjectId

    # Section 1: Personal Information
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

    # Section 2: College Information
    register_number: str
    department: str
    course: str
    year: int
    semester: int
    section: Optional[str] = None
    admission_year: int
    mentor_id: Optional[PyObjectId] = None

    # Section 3: Parent / Guardian Information
    parent_name: str
    relationship: str
    parent_phone: str
    parent_email: Optional[EmailStr] = None

    # Section 4: Academic Information
    cgpa: Optional[float] = None
    previous_semester_info: Optional[str] = None
    backlog_count: int = 0
