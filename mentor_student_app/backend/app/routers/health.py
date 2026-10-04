from fastapi import APIRouter, status
from app.schemas.health import HealthResponse
from app.services.health_service import HealthService

router = APIRouter(prefix="/health", tags=["Health"])


@router.get(
    "",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
    summary="Real System & Database Health Check",
    description="Returns real health status of the application and MongoDB database connection."
)
async def get_health() -> HealthResponse:
    """Retrieve real-time backend and database health status."""
    return await HealthService.check_health()
