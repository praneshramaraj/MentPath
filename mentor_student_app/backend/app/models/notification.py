from typing import Optional
from app.models.base import BaseDBModel, PyObjectId


class NotificationModel(BaseDBModel):
    recipient_user_id: str
    title: str
    message: str
    notification_type: str  # LEAVE_STATUS_CHANGED, OD_STATUS_CHANGED, NEW_MENTOR_NOTE, MEETING_SCHEDULED, ACADEMIC_UPDATE, PROFILE_COMPLETION_REMINDER, COLLEGE_ANNOUNCEMENT
    related_record_id: Optional[str] = None
    related_record_type: Optional[str] = None
    action_url: Optional[str] = None
    is_read: bool = False
