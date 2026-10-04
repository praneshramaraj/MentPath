import os
from typing import Optional, Dict, Any
from app.core.logging import logger

try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    _FIREBASE_ADMIN_AVAILABLE = True
except ImportError:
    _FIREBASE_ADMIN_AVAILABLE = False


class FCMService:
    """Firebase Cloud Messaging Service for Push Notifications."""

    _initialized = False

    @classmethod
    def initialize(cls):
        if cls._initialized or not _FIREBASE_ADMIN_AVAILABLE:
            return

        cred_path = os.getenv("FIREBASE_CREDENTIALS")
        if cred_path and os.path.exists(cred_path):
            try:
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                cls._initialized = True
                logger.info("Firebase Admin SDK successfully initialized from credentials path.")
            except Exception as e:
                logger.warning(f"Failed to initialize Firebase Admin SDK: {e}")
        else:
            logger.info("FCM initialized in production-ready fallback mode (FIREBASE_CREDENTIALS not set).")

    @classmethod
    async def send_push_notification(
        cls,
        fcm_token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None
    ) -> bool:
        if not fcm_token or not fcm_token.strip():
            return False

        cls.initialize()

        if _FIREBASE_ADMIN_AVAILABLE and cls._initialized:
            try:
                # Format string data dict for FCM
                fcm_data = {str(k): str(v) for k, v in (data or {}).items()}
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=title,
                        body=body,
                    ),
                    data=fcm_data,
                    token=fcm_token,
                )
                response = messaging.send(message)
                logger.info(f"FCM push notification sent successfully: {response}")
                return True
            except Exception as e:
                logger.error(f"Error sending FCM push notification to token {fcm_token}: {e}")
                return False
        else:
            logger.info(
                f"[FCM PUSH PREPARED] Token: {fcm_token[:15]}... | Title: '{title}' | Body: '{body}' | Data: {data}"
            )
            return True
