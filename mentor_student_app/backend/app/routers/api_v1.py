from fastapi import APIRouter
from app.routers import (
    health,
    auth,
    student,
    mentor,
    admin,
    academic,
    leave_od,
    achievement,
    meeting_note,
    notification,
    upload,
    ai_mentor
)

api_v1_router = APIRouter()

# Include feature routers
api_v1_router.include_router(health.router)
api_v1_router.include_router(auth.router)
api_v1_router.include_router(student.router)
api_v1_router.include_router(mentor.router)
api_v1_router.include_router(admin.router)
api_v1_router.include_router(academic.router)
api_v1_router.include_router(leave_od.router)
api_v1_router.include_router(achievement.router)
api_v1_router.include_router(meeting_note.router)
api_v1_router.include_router(notification.router)
api_v1_router.include_router(upload.router)
api_v1_router.include_router(ai_mentor.router)

