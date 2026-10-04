from fastapi import APIRouter, Depends, status
from app.core.dependencies import require_roles
from app.models.user import UserModel, UserRole
from app.schemas.common import APIResponse

router = APIRouter(prefix="/admin", tags=["Admin Module"])


@router.get(
    "/dashboard",
    response_model=APIResponse[dict],
    status_code=status.HTTP_200_OK,
    summary="Admin Dashboard Endpoint (Role Restricted)",
    description="Backend enforced endpoint accessible ONLY by users with the ADMIN role."
)
async def get_admin_dashboard(
    current_user: UserModel = Depends(require_roles([UserRole.ADMIN]))
) -> APIResponse[dict]:
    """Protected admin dashboard endpoint."""
    return APIResponse(
        success=True,
        message=f"Welcome to Administration Portal, {current_user.full_name}!",
        data={
            "user_id": str(current_user.id),
            "email": current_user.email,
            "full_name": current_user.full_name,
            "role": current_user.role.value,
            "access_granted": True
        }
    )
