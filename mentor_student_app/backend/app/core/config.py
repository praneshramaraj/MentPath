import os
from typing import List, Optional, Union
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    APP_NAME: str = "MentPath"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "INFO"

    # Database
    MONGO_URI: Optional[str] = None
    MONGODB_URL: Optional[str] = None
    MONGODB_DB_NAME: str = "mentor_student_db"

    def get_mongo_uri(self) -> str:
        uri = self.MONGO_URI or self.MONGODB_URL or os.getenv("MONGO_URI") or os.getenv("MONGODB_URL")
        if not uri:
            raise RuntimeError("MONGO_URI environment variable is not configured")
        return uri

    # CORS
    CORS_ORIGINS: Union[List[str], str] = ["*"]

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str):
            if v.startswith("[") and v.endswith("]"):
                try:
                    return json.loads(v)
                except Exception:
                    pass
            return [i.strip() for i in v.split(",") if i.strip()]
        return v

    # JWT Security Configuration Architecture
    JWT_SECRET_KEY: str = "supersecretkeyforjwttokengenerationchangeinproduction"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    # AI Configuration
    GEMINI_API_KEY: str = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )


settings = Settings()
