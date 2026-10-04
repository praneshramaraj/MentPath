from enum import Enum
from typing import Optional
from pydantic import EmailStr, Field
from app.models.base import BaseDBModel


class UserRole(str, Enum):
    STUDENT = "student"
    MENTOR = "mentor"
    HOD = "hod"
    ADMIN = "admin"


class UserModel(BaseDBModel):
    email: EmailStr
    hashed_password: str
    role: UserRole
    full_name: str
    is_active: bool = True
    is_verified: bool = False
    is_profile_complete: bool = False
    phone_number: Optional[str] = None
