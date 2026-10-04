from typing import List
from fastapi import APIRouter, Depends, status
from app.core.dependencies import get_current_user, require_roles
from app.models.user import UserModel, UserRole
from app.schemas.notification import NotificationResponse, FCMTokenUpdate, AnnouncementCreate
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("", response_model=List[NotificationResponse])
async def get_my_notifications(
    current_user: UserModel = Depends(get_current_user)
):
    """Get all in-app notifications for authenticated user (Students see only theirs, Mentors see only theirs)."""
    return await NotificationService.get_user_notifications(user=current_user)


@router.put("/read-all")
async def mark_all_notifications_read(
    current_user: UserModel = Depends(get_current_user)
):
    """Mark all unread notifications for authenticated user as read."""
    return await NotificationService.mark_all_as_read(user=current_user)


@router.put("/{notification_id}/read", response_model=NotificationResponse)
async def mark_notification_read(
    notification_id: str,
    current_user: UserModel = Depends(get_current_user)
):
    """Mark a specific notification as read."""
    return await NotificationService.mark_as_read(notification_id=notification_id, user=current_user)


@router.post("/fcm-token", status_code=status.HTTP_200_OK)
async def register_fcm_token(
    payload: FCMTokenUpdate,
    current_user: UserModel = Depends(get_current_user)
):
    """Register or update device FCM token for push notifications."""
    return await NotificationService.register_fcm_token(user=current_user, payload=payload)


@router.post("/announcement", status_code=status.HTTP_201_CREATED)
async def create_college_announcement(
    payload: AnnouncementCreate,
    current_user: UserModel = Depends(require_roles(UserRole.MENTOR, UserRole.ADMIN))
):
    """Broadcast a college announcement to target students and mentors."""
    return await NotificationService.create_college_announcement(creator=current_user, payload=payload)
