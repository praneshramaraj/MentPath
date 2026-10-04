from fastapi import APIRouter, Depends, status
from app.core.dependencies import get_current_active_user
from app.models.user import UserModel
from app.schemas.auth import UserRegisterRequest, UserLoginRequest, UserResponse, TokenResponse
from app.schemas.common import APIResponse
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new real user account",
    description="Creates a new real user account in MongoDB (Student, Mentor, or Admin). Hashes passwords with bcrypt."
)
async def register(request: UserRegisterRequest) -> UserResponse:
    """Register a new user account in MongoDB."""
    return await AuthService.register_user(request)


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Authenticate real user and obtain JWT access token",
    description="Authenticates real user credentials stored in MongoDB and returns a signed JWT access token."
)
async def login(request: UserLoginRequest) -> TokenResponse:
    """Authenticate user credentials and issue JWT access token."""
    return await AuthService.login_user(request)


@router.get(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Get current authenticated user profile",
    description="Validates Bearer token and returns authenticated user details."
)
async def get_me(current_user: UserModel = Depends(get_current_active_user)) -> UserResponse:
    """Validate token and return active user profile."""
    return UserResponse(
        id=str(current_user.id),
        email=current_user.email,
        full_name=current_user.full_name,
        role=current_user.role,
        is_active=current_user.is_active,
        is_profile_complete=current_user.is_profile_complete,
        phone_number=current_user.phone_number,
        created_at=current_user.created_at,
        updated_at=current_user.updated_at
    )


@router.post(
    "/logout",
    response_model=APIResponse[dict],
    status_code=status.HTTP_200_OK,
    summary="Logout authenticated user session",
    description="Confirms token session termination."
)
async def logout(current_user: UserModel = Depends(get_current_active_user)) -> APIResponse[dict]:
    """Logout endpoint."""
    return APIResponse(
        success=True,
        message=f"User {current_user.email} successfully logged out.",
        data={"user_id": str(current_user.id)}
    )
