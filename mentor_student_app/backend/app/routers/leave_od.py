from typing import List
from fastapi import APIRouter, Depends, status
from app.core.dependencies import require_roles, get_current_user
from app.models.user import UserModel, UserRole
from app.schemas.leave_od import (
    LeaveRequestCreate,
    LeaveRequestResponse,
    LeaveStatusUpdate,
    ODRequestCreate,
    ODRequestResponse,
    ODStatusUpdate
)
from app.services.leave_od_service import LeaveODService

router = APIRouter(prefix="", tags=["Leave & On-Duty"])


# LEAVE REQUEST ENDPOINTS
@router.post("/leave", response_model=LeaveRequestResponse, status_code=status.HTTP_201_CREATED)
async def submit_leave_request(
    payload: LeaveRequestCreate,
    current_user: UserModel = Depends(require_roles(UserRole.STUDENT))
):
    """Submit a new Leave Request (Student)."""
    return await LeaveODService.create_leave_request(user=current_user, payload=payload)


@router.get("/leave/student", response_model=List[LeaveRequestResponse])
async def get_my_leave_requests(
    current_user: UserModel = Depends(require_roles(UserRole.STUDENT))
):
    """Get authenticated student's leave requests."""
    return await LeaveODService.get_student_leave_requests(student_id_str=str(current_user.id))


@router.get("/leave/mentor", response_model=List[LeaveRequestResponse])
async def get_assigned_students_leave_requests(
    current_user: UserModel = Depends(require_roles(UserRole.MENTOR, UserRole.ADMIN))
):
    """Get leave requests for mentor's assigned mentees."""
    return await LeaveODService.get_mentor_leave_requests(mentor_id_str=str(current_user.id))


@router.put("/leave/{request_id}/status", response_model=LeaveRequestResponse)
async def update_leave_request_status(
    request_id: str,
    payload: LeaveStatusUpdate,
    current_user: UserModel = Depends(require_roles(UserRole.MENTOR, UserRole.ADMIN))
):
    """Approve or reject a Leave Request (Mentor / HOD Admin)."""
    return await LeaveODService.update_leave_status(request_id=request_id, reviewer=current_user, payload=payload)


@router.put("/leave/{request_id}/cancel", response_model=LeaveRequestResponse)
async def cancel_leave_request(
    request_id: str,
    current_user: UserModel = Depends(require_roles(UserRole.STUDENT))
):
    """Cancel a pending Leave Request (Student)."""
    return await LeaveODService.cancel_leave_request(user=current_user, request_id=request_id)


# ON-DUTY (OD) REQUEST ENDPOINTS
@router.post("/od", response_model=ODRequestResponse, status_code=status.HTTP_201_CREATED)
async def submit_od_request(
    payload: ODRequestCreate,
    current_user: UserModel = Depends(require_roles(UserRole.STUDENT))
):
    """Submit a new On-Duty (OD) Request (Student)."""
    return await LeaveODService.create_od_request(user=current_user, payload=payload)


@router.get("/od/student", response_model=List[ODRequestResponse])
async def get_my_od_requests(
    current_user: UserModel = Depends(require_roles(UserRole.STUDENT))
):
    """Get authenticated student's OD requests."""
    return await LeaveODService.get_student_od_requests(student_id_str=str(current_user.id))


@router.get("/od/mentor", response_model=List[ODRequestResponse])
async def get_assigned_students_od_requests(
    current_user: UserModel = Depends(require_roles(UserRole.MENTOR, UserRole.ADMIN))
):
    """Get OD requests for mentor's assigned mentees."""
    return await LeaveODService.get_mentor_od_requests(mentor_id_str=str(current_user.id))


@router.put("/od/{request_id}/status", response_model=ODRequestResponse)
async def update_od_request_status(
    request_id: str,
    payload: ODStatusUpdate,
    current_user: UserModel = Depends(require_roles(UserRole.MENTOR, UserRole.ADMIN))
):
    """Approve or reject an OD Request (Mentor / HOD Admin)."""
    return await LeaveODService.update_od_status(request_id=request_id, reviewer=current_user, payload=payload)


@router.put("/od/{request_id}/cancel", response_model=ODRequestResponse)
async def cancel_od_request(
    request_id: str,
    current_user: UserModel = Depends(require_roles(UserRole.STUDENT))
):
    """Cancel a pending OD Request (Student)."""
    return await LeaveODService.cancel_od_request(user=current_user, request_id=request_id)

