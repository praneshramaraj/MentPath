from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database.mongodb import get_database
from app.core.dependencies import get_current_user
from app.models.user import UserModel, UserRole
from app.schemas.ai_assistant import AIMentorQueryRequest, AIMentorQueryResponse
from app.services.ai_mentor_service import AIMentorService

router = APIRouter(prefix="/ai-mentor", tags=["AI Mentor Assistant"])


@router.post("/query", response_model=AIMentorQueryResponse)
async def query_ai_mentor_assistant(
    request: AIMentorQueryRequest,
    current_user: UserModel = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Query the AI Mentor Assistant for intelligent insights on assigned students.
    
    Authorization:
    - Only authenticated Mentors can query the assistant.
    - Strict Isolation: Mentors can only query data for students assigned to them.
    - Zero Hallucination: The AI responds strictly using real database records.
    """
    if current_user.role != UserRole.MENTOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. The AI Mentor Assistant is only accessible to authorized mentors."
        )

    mentor_user_id = str(current_user.id)

    response_data = await AIMentorService.query_ai_mentor(
        db=db,
        mentor_user_id=mentor_user_id,
        query=request.query,
        target_student_id=request.student_id,
        attendance_threshold=request.attendance_threshold or 75.0
    )

    return response_data
