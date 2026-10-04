from datetime import datetime, timezone
from app.core.config import settings
from app.core.logging import logger
from app.core.security import get_password_hash, verify_password, create_access_token
from app.database.collections import USERS_COLLECTION
from app.database.mongodb import get_database
from app.models.user import UserModel, UserRole
from app.schemas.auth import UserRegisterRequest, UserLoginRequest, UserResponse, TokenResponse
from app.utils.error_handlers import AppException
from fastapi import status


class AuthService:
    @staticmethod
    async def register_user(request: UserRegisterRequest) -> UserResponse:
        """Register a new real user account in MongoDB."""
        db = get_database()
        email_normalized = request.email.lower().strip()

        # Check for existing email in MongoDB
        existing_user = await db[USERS_COLLECTION].find_one({"email": email_normalized})
        if existing_user:
            raise AppException(
                message=f"Account with email '{email_normalized}' already exists",
                code="EMAIL_EXISTS",
                status_code=status.HTTP_400_BAD_REQUEST
            )

        # Hash plain-text password using bcrypt
        hashed_password = get_password_hash(request.password)

        # Create domain UserModel
        now = datetime.now(timezone.utc)
        user_model = UserModel(
            email=email_normalized,
            hashed_password=hashed_password,
            role=request.role,
            full_name=request.full_name.strip(),
            phone_number=request.phone_number.strip() if request.phone_number else None,
            is_active=True,
            is_verified=True,
            is_profile_complete=False,
            created_at=now,
            updated_at=now
        )

        # Insert user document into MongoDB users collection
        user_dict = user_model.model_dump(by_alias=True)
        result = await db[USERS_COLLECTION].insert_one(user_dict)
        user_dict["_id"] = result.inserted_id

        logger.info(f"Registered new real user: {email_normalized} with role {request.role.value}")

        return UserResponse(
            id=str(result.inserted_id),
            email=user_model.email,
            full_name=user_model.full_name,
            role=user_model.role,
            is_active=user_model.is_active,
            is_profile_complete=user_model.is_profile_complete,
            phone_number=user_model.phone_number,
            created_at=user_model.created_at,
            updated_at=user_model.updated_at
        )

    @staticmethod
    async def login_user(request: UserLoginRequest) -> TokenResponse:
        """Authenticate real user credentials against MongoDB and generate JWT token."""
        db = get_database()
        email_normalized = request.email.lower().strip()

        # Fetch user document from MongoDB
        user_dict = await db[USERS_COLLECTION].find_one({"email": email_normalized})
        if not user_dict:
            raise AppException(
                message="Invalid email or password",
                code="INVALID_CREDENTIALS",
                status_code=status.HTTP_401_UNAUTHORIZED
            )

        user = UserModel(**user_dict)

        # Verify password using bcrypt
        if not verify_password(request.password, user.hashed_password):
            raise AppException(
                message="Invalid email or password",
                code="INVALID_CREDENTIALS",
                status_code=status.HTTP_401_UNAUTHORIZED
            )

        if not user.is_active:
            raise AppException(
                message="Your account has been deactivated. Please contact administrator.",
                code="ACCOUNT_INACTIVE",
                status_code=status.HTTP_403_FORBIDDEN
            )

        # Generate JWT token
        extra_claims = {
            "role": user.role.value,
            "email": user.email,
            "name": user.full_name
        }
        access_token = create_access_token(subject=str(user.id), extra_claims=extra_claims)

        user_response = UserResponse(
            id=str(user.id),
            email=user.email,
            full_name=user.full_name,
            role=user.role,
            is_active=user.is_active,
            is_profile_complete=user.is_profile_complete,
            phone_number=user.phone_number,
            created_at=user.created_at,
            updated_at=user.updated_at
        )

        # Trigger profile completion reminder if student profile is incomplete
        if (user.role == UserRole.STUDENT or user.role == "student") and not user.is_profile_complete:
            try:
                from app.services.notification_service import NotificationService
                await NotificationService.create_and_send_notification(
                    recipient_user_id=str(user.id),
                    title="Complete Your Student Profile",
                    message="Please complete your student profile setup to access all academic & mentorship features.",
                    notification_type="PROFILE_COMPLETION_REMINDER",
                    related_record_id=str(user.id),
                    related_record_type="profile"
                )
            except Exception as e:
                logger.warning(f"Could not send profile completion notification: {e}")

        logger.info(f"User login successful: {email_normalized} (Role: {user.role.value})")

        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user=user_response
        )
