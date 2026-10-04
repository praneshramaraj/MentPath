from fastapi import APIRouter, Depends, status
from app.core.dependencies import get_current_active_user, require_roles
from app.models.user import UserModel, UserRole
from app.schemas.academic import (
    AttendanceRecordCreate,
    AttendanceRecordResponse,
    AttendanceSummaryResponse,
    MarksRecordCreate,
    MarksRecordResponse,
    StudentMarksSummaryResponse
)
from app.services.academic_service import AcademicService

router = APIRouter(tags=["Attendance & Academic Marks"])


# --- Attendance Endpoints ---

@router.post(
    "/attendance",
    response_model=AttendanceRecordResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Log Attendance Record for Assigned Student",
    description="Mentor or Admin logs an attendance entry (present, absent, on_duty, leave) for an assigned student."
)
async def log_attendance(
    request: AttendanceRecordCreate,
    current_user: UserModel = Depends(require_roles([UserRole.MENTOR, UserRole.ADMIN]))
) -> AttendanceRecordResponse:
    """Log real attendance entry in MongoDB."""
    return await AcademicService.log_attendance(current_user, request)


@router.get(
    "/attendance/student/{student_id}",
    response_model=AttendanceSummaryResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Attendance Logs & Dynamic Percentage Summary",
    description="Student views their own attendance summary, or Mentor views their assigned mentee's attendance."
)
async def get_student_attendance(
    student_id: str,
    current_user: UserModel = Depends(get_current_active_user)
) -> AttendanceSummaryResponse:
    """Fetch attendance records & calculated attendance percentage."""
    return await AcademicService.get_student_attendance(current_user, student_id)


# --- Marks Endpoints ---

@router.post(
    "/marks",
    response_model=MarksRecordResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Log Exam Marks for Assigned Student",
    description="Mentor or Admin logs subject exam marks (Internal 1, Internal 2, Semester Exam) for an assigned student."
)
async def log_marks(
    request: MarksRecordCreate,
    current_user: UserModel = Depends(require_roles([UserRole.MENTOR, UserRole.ADMIN]))
) -> MarksRecordResponse:
    """Log real subject marks in MongoDB."""
    return await AcademicService.log_marks(current_user, request)


@router.get(
    "/marks/student/{student_id}",
    response_model=StudentMarksSummaryResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Academic Marks & GPA Performance Summary",
    description="Student views their own subject marks, or Mentor views their assigned mentee's marks."
)
async def get_student_marks(
    student_id: str,
    current_user: UserModel = Depends(get_current_active_user)
) -> StudentMarksSummaryResponse:
    """Fetch marks records and average percentage."""
    return await AcademicService.get_student_marks(current_user, student_id)
