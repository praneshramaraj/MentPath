from typing import List
from fastapi import APIRouter, Depends, status
from app.core.dependencies import require_roles
from app.models.user import UserModel, UserRole
from app.schemas.achievement import AchievementCreate, AchievementResponse, AchievementVerifyRequest
from app.services.achievement_service import AchievementService

router = APIRouter(prefix="/achievements", tags=["Achievements"])


@router.post("", response_model=AchievementResponse, status_code=status.HTTP_201_CREATED)
async def submit_achievement(
    payload: AchievementCreate,
    current_user: UserModel = Depends(require_roles(UserRole.STUDENT))
):
    """Submit a new student achievement or certification record."""
    return await AchievementService.create_achievement(user=current_user, payload=payload)


@router.get("/student/{student_id}", response_model=List[AchievementResponse])
async def get_student_achievements(
    student_id: str,
    current_user: UserModel = Depends(require_roles(UserRole.STUDENT, UserRole.MENTOR, UserRole.ADMIN))
):
    """Get achievement records for a specific student."""
    return await AchievementService.get_student_achievements(student_id_str=student_id)


@router.get("/mentor", response_model=List[AchievementResponse])
async def get_mentor_students_achievements(
    current_user: UserModel = Depends(require_roles(UserRole.MENTOR, UserRole.ADMIN))
):
    """Get achievements for mentor's assigned students."""
    return await AchievementService.get_mentor_students_achievements(mentor_id_str=str(current_user.id))


@router.put("/{achievement_id}/verify", response_model=AchievementResponse)
async def verify_achievement(
    achievement_id: str,
    payload: AchievementVerifyRequest,
    current_user: UserModel = Depends(require_roles(UserRole.MENTOR, UserRole.ADMIN))
):
    """Verify or unverify a student achievement (Mentor / HOD Admin)."""
    return await AchievementService.verify_achievement(achievement_id=achievement_id, reviewer=current_user, payload=payload)


@router.delete("/{achievement_id}")
async def delete_achievement(
    achievement_id: str,
    current_user: UserModel = Depends(require_roles(UserRole.STUDENT, UserRole.ADMIN))
):
    """Delete a student achievement record (Student / Admin)."""
    return await AchievementService.delete_achievement(achievement_id=achievement_id, user=current_user)
