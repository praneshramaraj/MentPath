from fastapi import APIRouter, Depends, status
from app.core.dependencies import require_roles
from app.models.user import UserModel, UserRole
from app.schemas.common import APIResponse
from app.schemas.student import StudentProfileCreateRequest, StudentProfileUpdateRequest, StudentProfileResponse
from app.services.student_service import StudentService

router = APIRouter(prefix="/student", tags=["Student Module"])


@router.get(
    "/dashboard",
    response_model=APIResponse[dict],
    status_code=status.HTTP_200_OK,
    summary="Student Dashboard Endpoint (Role Restricted)",
    description="Backend enforced endpoint accessible ONLY by users with the STUDENT role."
)
async def get_student_dashboard(
    current_user: UserModel = Depends(require_roles([UserRole.STUDENT]))
) -> APIResponse[dict]:
    """Protected student dashboard endpoint."""
    return APIResponse(
        success=True,
        message=f"Welcome to Student Dashboard, {current_user.full_name}!",
        data={
            "user_id": str(current_user.id),
            "email": current_user.email,
            "full_name": current_user.full_name,
            "role": current_user.role.value,
            "is_profile_complete": current_user.is_profile_complete,
            "access_granted": True
        }
    )


@router.post(
    "/profile",
    response_model=StudentProfileResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create / Save Student First-Time Profile Setup",
    description="Allows authenticated student to submit their required and optional personal, college, parent, and academic details."
)
async def create_student_profile(
    request: StudentProfileCreateRequest,
    current_user: UserModel = Depends(require_roles([UserRole.STUDENT]))
) -> StudentProfileResponse:
    """Create initial student profile."""
    return await StudentService.create_profile(current_user, request)


@router.get(
    "/profile",
    response_model=StudentProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Authenticated Student Profile",
    description="Retrieves the profile of the currently logged-in student."
)
async def get_student_profile(
    current_user: UserModel = Depends(require_roles([UserRole.STUDENT]))
) -> StudentProfileResponse:
    """Get own student profile."""
    return await StudentService.get_profile(current_user)


@router.put(
    "/profile",
    response_model=StudentProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Authenticated Student Profile",
    description="Allows authenticated student to update permitted profile fields."
)
async def update_student_profile(
    request: StudentProfileUpdateRequest,
    current_user: UserModel = Depends(require_roles([UserRole.STUDENT]))
) -> StudentProfileResponse:
    """Update own student profile."""
    return await StudentService.update_profile(current_user, request)
