from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from bson import ObjectId
from fastapi import status
from app.core.logging import logger
from app.database.collections import NOTIFICATIONS_COLLECTION, USERS_COLLECTION, STUDENT_PROFILES_COLLECTION
from app.database.mongodb import get_database
from app.models.user import UserModel, UserRole
from app.schemas.notification import NotificationResponse, FCMTokenUpdate, AnnouncementCreate
from app.services.fcm_service import FCMService
from app.utils.error_handlers import AppException


class NotificationService:

    @staticmethod
    async def create_and_send_notification(
        recipient_user_id: str,
        title: str,
        message: str,
        notification_type: str,
        related_record_id: Optional[str] = None,
        related_record_type: Optional[str] = None,
        action_url: Optional[str] = None
    ) -> NotificationResponse:
        """Central helper to persist a notification in MongoDB and trigger FCM push notification."""
        db = get_database()
        now = datetime.now(timezone.utc)
        recipient_str = str(recipient_user_id)

        doc = {
            "recipient_user_id": recipient_str,
            "title": title.strip(),
            "message": message.strip(),
            "notification_type": notification_type.strip(),
            "related_record_id": str(related_record_id) if related_record_id else None,
            "related_record_type": related_record_type.strip() if related_record_type else None,
            "action_url": action_url.strip() if action_url else None,
            "is_read": False,
            "created_at": now,
            "updated_at": now
        }

        result = await db[NOTIFICATIONS_COLLECTION].insert_one(doc)
        notification_id = str(result.inserted_id)

        # Look up recipient user's FCM token from database
        recipient_user = await db[USERS_COLLECTION].find_one({
            "$or": [{"_id": recipient_str}, {"_id": ObjectId(recipient_str) if ObjectId.is_valid(recipient_str) else None}]
        })

        if recipient_user and recipient_user.get("fcm_token"):
            fcm_token = recipient_user["fcm_token"]
            push_data = {
                "notification_id": notification_id,
                "notification_type": notification_type,
                "related_record_id": str(related_record_id or ""),
                "related_record_type": str(related_record_type or "")
            }
            await FCMService.send_push_notification(
                fcm_token=fcm_token,
                title=title,
                body=message,
                data=push_data
            )

        return NotificationResponse(
            id=notification_id,
            recipient_user_id=recipient_str,
            title=title.strip(),
            message=message.strip(),
            notification_type=notification_type.strip(),
            related_record_id=str(related_record_id) if related_record_id else None,
            related_record_type=related_record_type.strip() if related_record_type else None,
            action_url=action_url,
            is_read=False,
            created_at=now
        )

    @staticmethod
    async def get_user_notifications(user: UserModel) -> List[NotificationResponse]:
        """Fetch notifications strictly owned by the authenticated user."""
        db = get_database()
        user_id_str = str(user.id)

        cursor = db[NOTIFICATIONS_COLLECTION].find({
            "$or": [
                {"recipient_user_id": user_id_str},
                {"recipient_user_id": ObjectId(user_id_str) if ObjectId.is_valid(user_id_str) else None}
            ]
        }).sort("created_at", -1)

        results = []
        async for doc in cursor:
            results.append(NotificationResponse(
                id=str(doc["_id"]),
                recipient_user_id=str(doc["recipient_user_id"]),
                title=doc["title"],
                message=doc["message"],
                notification_type=doc.get("notification_type", "GENERAL"),
                related_record_id=doc.get("related_record_id"),
                related_record_type=doc.get("related_record_type"),
                action_url=doc.get("action_url"),
                is_read=doc.get("is_read", False),
                created_at=doc.get("created_at", datetime.now(timezone.utc))
            ))
        return results

    @staticmethod
    async def mark_as_read(notification_id: str, user: UserModel) -> NotificationResponse:
        """Mark a specific notification as read after confirming user ownership."""
        db = get_database()
        user_id_str = str(user.id)
        query = {"_id": ObjectId(notification_id) if ObjectId.is_valid(notification_id) else notification_id}

        doc = await db[NOTIFICATIONS_COLLECTION].find_one(query)
        if not doc:
            raise AppException(status_code=status.HTTP_404_NOT_FOUND, message="Notification not found.")

        if str(doc.get("recipient_user_id")) != user_id_str:
            raise AppException(status_code=status.HTTP_403_FORBIDDEN, message="You can only manage your own notifications.")

        now = datetime.now(timezone.utc)
        await db[NOTIFICATIONS_COLLECTION].update_one(query, {"$set": {"is_read": True, "updated_at": now}})

        updated = await db[NOTIFICATIONS_COLLECTION].find_one(query)
        return NotificationResponse(
            id=str(updated["_id"]),
            recipient_user_id=str(updated["recipient_user_id"]),
            title=updated["title"],
            message=updated["message"],
            notification_type=updated.get("notification_type", "GENERAL"),
            related_record_id=updated.get("related_record_id"),
            related_record_type=updated.get("related_record_type"),
            action_url=updated.get("action_url"),
            is_read=True,
            created_at=updated.get("created_at", now)
        )

    @staticmethod
    async def mark_all_as_read(user: UserModel) -> dict:
        """Mark all unread notifications for authenticated user as read."""
        db = get_database()
        user_id_str = str(user.id)
        now = datetime.now(timezone.utc)

        result = await db[NOTIFICATIONS_COLLECTION].update_many(
            {
                "$or": [
                    {"recipient_user_id": user_id_str},
                    {"recipient_user_id": ObjectId(user_id_str) if ObjectId.is_valid(user_id_str) else None}
                ],
                "is_read": False
            },
            {"$set": {"is_read": True, "updated_at": now}}
        )

        return {
            "message": "All notifications marked as read",
            "modified_count": result.modified_count
        }

    @staticmethod
    async def register_fcm_token(user: UserModel, payload: FCMTokenUpdate) -> dict:
        """Store Firebase Cloud Messaging token for push notification dispatch."""
        db = get_database()
        user_id_str = str(user.id)
        now = datetime.now(timezone.utc)

        await db[USERS_COLLECTION].update_one(
            {"$or": [{"_id": user_id_str}, {"_id": ObjectId(user_id_str) if ObjectId.is_valid(user_id_str) else None}]},
            {"$set": {"fcm_token": payload.fcm_token.strip(), "fcm_token_updated_at": now}}
        )

        logger.info(f"Registered FCM token for user {user.email} ({user_id_str})")
        return {"message": "FCM token registered successfully", "user_id": user_id_str}

    @staticmethod
    async def create_college_announcement(creator: UserModel, payload: AnnouncementCreate) -> dict:
        """Broadcast a college announcement notification to target users."""
        db = get_database()
        query: Dict[str, Any] = {"is_active": True}

        if payload.target_role and payload.target_role.lower() != "all":
            query["role"] = payload.target_role.lower()

        users_cursor = db[USERS_COLLECTION].find(query)
        target_user_ids = [str(u["_id"]) async for u in users_cursor]

        # Optional department filter
        if payload.target_department:
            dept = payload.target_department.strip().lower()
            profiles_cursor = db[STUDENT_PROFILES_COLLECTION].find({"department": {"$regex": f"^{dept}$", "$options": "i"}})
            dept_user_ids = {str(p["user_id"]) async for p in profiles_cursor}
            target_user_ids = [uid for uid in target_user_ids if uid in dept_user_ids]

        sent_count = 0
        for uid in target_user_ids:
            await NotificationService.create_and_send_notification(
                recipient_user_id=uid,
                title=payload.title,
                message=payload.message,
                notification_type="COLLEGE_ANNOUNCEMENT",
                related_record_id=str(creator.id),
                related_record_type="announcement"
            )
            sent_count += 1

        return {
            "message": f"College announcement broadcasted to {sent_count} users",
            "recipients_count": sent_count,
            "title": payload.title
        }
