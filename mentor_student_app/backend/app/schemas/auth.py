from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field
from app.models.user import UserRole


class UserRegisterRequest(BaseModel):
    email: EmailStr = Field(..., description="Unique user email address")
    password: str = Field(..., min_length=6, description="User password (min 6 characters)")
    full_name: str = Field(..., min_length=2, description="User's full name")
    role: UserRole = Field(default=UserRole.STUDENT, description="Target user role")
    phone_number: Optional[str] = Field(None, description="Contact phone number")


class UserLoginRequest(BaseModel):
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., description="User password")


class UserResponse(BaseModel):
    id: str = Field(..., description="Unique user ObjectId string")
    email: EmailStr = Field(..., description="User email address")
    full_name: str = Field(..., description="Full name")
    role: UserRole = Field(..., description="Assigned role")
    is_active: bool = Field(..., description="Account active status")
    is_profile_complete: bool = Field(..., description="Profile completion status")
    phone_number: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class TokenResponse(BaseModel):
    access_token: str = Field(..., description="JWT Bearer access token")
    token_type: str = Field(default="bearer", description="Token type")
    expires_in: int = Field(..., description="Expiration time in seconds")
    user: UserResponse = Field(..., description="Authenticated user profile details")
