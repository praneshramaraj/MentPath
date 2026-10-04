from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field


class DatabaseHealth(BaseModel):
    status: str = Field(..., description="Database connection status: connected or disconnected")
    details: str = Field(..., description="Diagnostic details or response message")
    db_name: Optional[str] = Field(None, description="Active database name")


class HealthResponse(BaseModel):
    status: str = Field(..., description="Overall API health status: healthy or degraded")
    app_name: str = Field(..., description="Application name")
    version: str = Field(..., description="API version")
    environment: str = Field(..., description="Deployment environment")
    timestamp: datetime = Field(..., description="Current server UTC timestamp")
    database: DatabaseHealth = Field(..., description="Real-time MongoDB health status")
