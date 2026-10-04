from datetime import datetime, timezone
from app.core.config import settings
from app.database.mongodb import ping_database
from app.schemas.health import HealthResponse, DatabaseHealth


class HealthService:
    @staticmethod
    async def check_health() -> HealthResponse:
        """Perform real system and database health check."""
        db_connected = await ping_database()

        if db_connected:
            db_health = DatabaseHealth(
                status="connected",
                details="MongoDB ping successful and connection active.",
                db_name=settings.MONGODB_DB_NAME
            )
            overall_status = "healthy"
        else:
            db_health = DatabaseHealth(
                status="disconnected",
                details="Unable to reach MongoDB instance.",
                db_name=settings.MONGODB_DB_NAME
            )
            overall_status = "degraded"

        return HealthResponse(
            status=overall_status,
            app_name=settings.APP_NAME,
            version=settings.VERSION,
            environment=settings.ENVIRONMENT,
            timestamp=datetime.now(timezone.utc),
            database=db_health
        )
