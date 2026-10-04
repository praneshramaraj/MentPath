from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.logging import logger
from app.database.mongodb import connect_to_mongo, close_mongo_connection
from app.routers.api_v1 import api_v1_router
from app.utils.error_handlers import (
    AppException,
    app_exception_handler,
    validation_exception_handler,
    unhandled_exception_handler
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifecycle manager for FastAPI application (startup and shutdown)."""
    logger.info(f"Starting {settings.APP_NAME} v{settings.VERSION} [{settings.ENVIRONMENT}]")
    await connect_to_mongo()
    yield
    await close_mongo_connection()
    logger.info("Application shutdown complete.")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
    description="Production-quality Backend API for College Mentor-Student Management System",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan
)

# CORS Middleware Configuration
if settings.CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# Exception Handlers Registration
app.add_exception_handler(AppException, app_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)

import os
from fastapi.staticfiles import StaticFiles

# Register API v1 Routers
app.include_router(api_v1_router, prefix=settings.API_V1_STR)

# Serve uploaded documents and certificates statically
uploads_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "uploads")
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")


@app.get("/", include_in_schema=False)
async def root_redirect():
    return {
        "app": settings.APP_NAME,
        "version": settings.VERSION,
        "health_check": f"{settings.API_V1_STR}/health",
        "docs": "/docs"
    }
