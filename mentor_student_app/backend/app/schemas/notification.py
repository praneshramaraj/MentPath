from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field


class NotificationResponse(BaseModel):
    id: str
    recipient_user_id: str
    title: str
    message: str
    notification_type: str
    related_record_id: Optional[str] = None
    related_record_type: Optional[str] = None
    action_url: Optional[str] = None
    is_read: bool = False
    created_at: datetime


class FCMTokenUpdate(BaseModel):
    fcm_token: str = Field(..., min_length=5, description="Firebase Cloud Messaging device token")


class AnnouncementCreate(BaseModel):
    title: str = Field(..., min_length=2, description="Announcement title")
    message: str = Field(..., min_length=3, description="Announcement body content")
    target_role: Optional[str] = Field("all", description="Target recipient role: all, student, mentor")
    target_department: Optional[str] = Field(None, description="Optional target department filter")
