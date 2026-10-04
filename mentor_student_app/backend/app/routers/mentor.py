from typing import List
from fastapi import APIRouter, Depends, status
from app.core.dependencies import require_roles
from app.models.user import UserModel, UserRole
from app.schemas.common import APIResponse
from app.schemas.mentor import (
    MentorProfileCreateRequest,
    MentorProfileResponse,
    StudentAssignRequest,
    AssignedStudentSummary
)
from app.schemas.student import StudentProfileResponse
from app.services.mentor_service import MentorService

router = APIRouter(prefix="/mentor", tags=["Mentor Module"])


@router.get(
    "/dashboard",
    response_model=APIResponse[dict],
    status_code=status.HTTP_200_OK,
    summary="Mentor Dashboard Summary",
    description="Returns real mentor profile summary, department, and assigned mentee count from MongoDB."
)
async def get_mentor_dashboard(
    current_user: UserModel = Depends(require_roles([UserRole.MENTOR]))
) -> APIResponse[dict]:
    """Protected mentor dashboard summary endpoint."""
    profile = await MentorService.get_profile(current_user)
    students = await MentorService.get_assigned_students(current_user)

    return APIResponse(
        success=True,
        message=f"Welcome to Mentor Portal, {current_user.full_name}!",
        data={
            "user_id": str(current_user.id),
            "email": current_user.email,
            "full_name": current_user.full_name,
            "role": current_user.role.value,
            "department": profile.department,
            "employee_id": profile.employee_id,
            "designation": profile.designation,
            "assigned_student_count": len(students),
            "max_mentees": profile.max_mentees
        }
    )


@router.get(
    "/profile",
    response_model=MentorProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Mentor Profile",
    description="Retrieves the profile of the authenticated mentor."
)
async def get_mentor_profile(
    current_user: UserModel = Depends(require_roles([UserRole.MENTOR]))
) -> MentorProfileResponse:
    """Get own mentor profile."""
    return await MentorService.get_profile(current_user)


@router.post(
    "/profile",
    response_model=MentorProfileResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create or Update Mentor Profile",
    description="Saves or updates profile details for authenticated mentor."
)
async def create_or_update_mentor_profile(
    request: MentorProfileCreateRequest,
    current_user: UserModel = Depends(require_roles([UserRole.MENTOR]))
) -> MentorProfileResponse:
    """Create or update mentor profile."""
    return await MentorService.create_or_update_profile(current_user, request)


@router.post(
    "/assign-student",
    response_model=dict,
    status_code=status.HTTP_200_OK,
    summary="Assign Real Student to Mentor",
    description="Assigns a real registered student (by register number or email) to authenticated mentor."
)
async def assign_student(
    request: StudentAssignRequest,
    current_user: UserModel = Depends(require_roles([UserRole.MENTOR, UserRole.ADMIN]))
) -> dict:
    """Assign student to mentor."""
    return await MentorService.assign_student(current_user, request)


@router.get(
    "/students",
    response_model=List[AssignedStudentSummary],
    status_code=status.HTTP_200_OK,
    summary="Get List of Assigned Students",
    description="Returns list of real students assigned to authenticated mentor from MongoDB."
)
async def get_assigned_students(
    current_user: UserModel = Depends(require_roles([UserRole.MENTOR]))
) -> List[AssignedStudentSummary]:
    """Get assigned mentees list."""
    return await MentorService.get_assigned_students(current_user)


@router.get(
    "/students/{student_id}",
    response_model=StudentProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Assigned Student Detail (Role & Ownership Restricted)",
    description="Fetches full student profile details ONLY IF the student is assigned to authenticated mentor. Returns 403 Forbidden otherwise."
)
async def get_assigned_student_detail(
    student_id: str,
    current_user: UserModel = Depends(require_roles([UserRole.MENTOR]))
) -> StudentProfileResponse:
    """Get assigned student detail with strict backend authorization."""
    return await MentorService.get_assigned_student_detail(current_user, student_id)
