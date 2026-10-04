from datetime import datetime, timezone
from typing import List, Optional
from bson import ObjectId
from fastapi import status
from app.core.logging import logger
from app.database.collections import (
    LEAVE_REQUESTS_COLLECTION,
    OD_REQUESTS_COLLECTION,
    MENTOR_STUDENT_ASSIGNMENTS_COLLECTION,
    STUDENT_PROFILES_COLLECTION,
    USERS_COLLECTION,
    NOTIFICATIONS_COLLECTION
)
from app.database.mongodb import get_database
from app.models.leave_request import RequestStatus
from app.models.user import UserModel
from app.services.notification_service import NotificationService
from app.schemas.leave_od import (
    LeaveRequestCreate,
    LeaveRequestResponse,
    LeaveStatusUpdate,
    ODRequestCreate,
    ODRequestResponse,
    ODStatusUpdate
)
from app.utils.error_handlers import AppException


class LeaveODService:

    @staticmethod
    async def _get_student_name_and_reg(student_id_str: str) -> tuple[str, str]:
        db = get_database()
        profile = await db[STUDENT_PROFILES_COLLECTION].find_one({
            "$or": [{"user_id": student_id_str}, {"user_id": ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None}]
        })
        user = await db[USERS_COLLECTION].find_one({
            "$or": [{"_id": student_id_str}, {"_id": ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None}]
        })
        
        student_name = "Student"
        reg_number = ""

        if profile:
            student_name = profile.get("full_name") or user.get("email", "Student")
            reg_number = profile.get("register_number", "")
        elif user:
            student_name = user.get("email", "Student")

        return student_name, reg_number

    # LEAVE REQUEST METHODS
    @staticmethod
    async def create_leave_request(user: UserModel, payload: LeaveRequestCreate) -> LeaveRequestResponse:
        db = get_database()
        now = datetime.now(timezone.utc)
        student_id_str = str(user.id)

        leave_doc = {
            "student_id": student_id_str,
            "request_type": "leave",
            "start_date": payload.start_date,
            "end_date": payload.end_date,
            "reason": payload.reason.strip(),
            "document_url": payload.document_url.strip() if payload.document_url else None,
            "status": RequestStatus.PENDING,
            "reviewer_id": None,
            "reviewer_name": None,
            "review_timestamp": None,
            "remarks": None,
            "mentor_remarks": None,
            "hod_remarks": None,
            "created_at": now,
            "updated_at": now
        }

        result = await db[LEAVE_REQUESTS_COLLECTION].insert_one(leave_doc)
        leave_id = str(result.inserted_id)

        # Notify assigned mentor if exists
        assignment = await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find_one({
            "student_id": student_id_str,
            "is_active": True
        })
        name, reg = await LeaveODService._get_student_name_and_reg(student_id_str)

        if assignment:
            mentor_id = str(assignment.get("mentor_id"))
            await NotificationService.create_and_send_notification(
                recipient_user_id=mentor_id,
                title="New Leave Application",
                message=f"Leave application submitted by {name} ({payload.start_date} to {payload.end_date}).",
                notification_type="LEAVE_STATUS_CHANGED",
                related_record_id=leave_id,
                related_record_type="leave_request"
            )
        return LeaveRequestResponse(
            id=leave_id,
            student_id=student_id_str,
            student_name=name,
            register_number=reg,
            request_type="leave",
            start_date=payload.start_date,
            end_date=payload.end_date,
            reason=payload.reason.strip(),
            document_url=payload.document_url,
            status=RequestStatus.PENDING,
            created_at=now
        )

    @staticmethod
    async def get_student_leave_requests(student_id_str: str) -> List[LeaveRequestResponse]:
        db = get_database()
        cursor = db[LEAVE_REQUESTS_COLLECTION].find({
            "$or": [{"student_id": student_id_str}, {"student_id": ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None}]
        }).sort("created_at", -1)

        name, reg = await LeaveODService._get_student_name_and_reg(student_id_str)
        results = []
        async for doc in cursor:
            try:
                st_enum = RequestStatus(doc.get("status", "pending"))
            except ValueError:
                st_enum = RequestStatus.PENDING

            results.append(LeaveRequestResponse(
                id=str(doc["_id"]),
                student_id=str(doc["student_id"]),
                student_name=name,
                register_number=reg,
                request_type="leave",
                start_date=doc["start_date"],
                end_date=doc["end_date"],
                reason=doc["reason"],
                document_url=doc.get("document_url"),
                status=st_enum,
                reviewer_id=doc.get("reviewer_id"),
                reviewer_name=doc.get("reviewer_name"),
                review_timestamp=doc.get("review_timestamp"),
                remarks=doc.get("remarks"),
                mentor_remarks=doc.get("mentor_remarks"),
                hod_remarks=doc.get("hod_remarks"),
                created_at=doc.get("created_at", datetime.now(timezone.utc))
            ))
        return results

    @staticmethod
    async def get_mentor_leave_requests(mentor_id_str: str) -> List[LeaveRequestResponse]:
        db = get_database()
        cursor_assignments = db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find({
            "mentor_id": mentor_id_str,
            "is_active": True
        })
        student_ids = [str(doc["student_id"]) async for doc in cursor_assignments]

        if not student_ids:
            return []

        cursor_leaves = db[LEAVE_REQUESTS_COLLECTION].find({
            "student_id": {"$in": student_ids}
        }).sort("created_at", -1)

        results = []
        async for doc in cursor_leaves:
            st_id = str(doc["student_id"])
            name, reg = await LeaveODService._get_student_name_and_reg(st_id)
            try:
                st_enum = RequestStatus(doc.get("status", "pending"))
            except ValueError:
                st_enum = RequestStatus.PENDING

            results.append(LeaveRequestResponse(
                id=str(doc["_id"]),
                student_id=st_id,
                student_name=name,
                register_number=reg,
                request_type="leave",
                start_date=doc["start_date"],
                end_date=doc["end_date"],
                reason=doc["reason"],
                document_url=doc.get("document_url"),
                status=st_enum,
                reviewer_id=doc.get("reviewer_id"),
                reviewer_name=doc.get("reviewer_name"),
                review_timestamp=doc.get("review_timestamp"),
                remarks=doc.get("remarks"),
                mentor_remarks=doc.get("mentor_remarks"),
                hod_remarks=doc.get("hod_remarks"),
                created_at=doc.get("created_at", datetime.now(timezone.utc))
            ))
        return results

    @staticmethod
    async def update_leave_status(request_id: str, reviewer: UserModel, payload: LeaveStatusUpdate) -> LeaveRequestResponse:
        db = get_database()
        query = {"_id": ObjectId(request_id) if ObjectId.is_valid(request_id) else request_id}
        doc = await db[LEAVE_REQUESTS_COLLECTION].find_one(query)
        if not doc:
            raise AppException(status_code=status.HTTP_404_NOT_FOUND, message="Leave request not found.")

        student_id_str = str(doc["student_id"])

        # Security check: Mentors can only review requests from their authorized assigned students
        if reviewer.role == "mentor":
            assignment = await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find_one({
                "mentor_id": str(reviewer.id),
                "student_id": {"$in": [student_id_str, ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None]},
                "is_active": True
            })
            if not assignment:
                raise AppException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    message="You are not authorized to review leave requests for this student."
                )

        now = datetime.now(timezone.utc)
        update_dict = {
            "status": payload.status.value,
            "reviewer_id": str(reviewer.id),
            "reviewer_name": reviewer.full_name or reviewer.email,
            "review_timestamp": now,
            "remarks": payload.remarks.strip() if payload.remarks else None,
            "updated_at": now
        }
        if reviewer.role in ["mentor", "admin"]:
            update_dict["mentor_remarks"] = payload.remarks.strip() if payload.remarks else None
        if reviewer.role == "admin":
            update_dict["hod_remarks"] = payload.remarks.strip() if payload.remarks else None

        await db[LEAVE_REQUESTS_COLLECTION].update_one(query, {"$set": update_dict})

        await NotificationService.create_and_send_notification(
            recipient_user_id=student_id_str,
            title=f"Leave Request {payload.status.value.replace('_', ' ').title()}",
            message=f"Your leave request from {doc.get('start_date')} to {doc.get('end_date')} has been marked as {payload.status.value}.",
            notification_type="LEAVE_STATUS_CHANGED",
            related_record_id=request_id,
            related_record_type="leave_request"
        )

        updated_doc = await db[LEAVE_REQUESTS_COLLECTION].find_one(query)
        name, reg = await LeaveODService._get_student_name_and_reg(student_id_str)
        return LeaveRequestResponse(
            id=str(updated_doc["_id"]),
            student_id=student_id_str,
            student_name=name,
            register_number=reg,
            request_type="leave",
            start_date=updated_doc["start_date"],
            end_date=updated_doc["end_date"],
            reason=updated_doc["reason"],
            document_url=updated_doc.get("document_url"),
            status=payload.status,
            reviewer_id=str(reviewer.id),
            reviewer_name=reviewer.full_name or reviewer.email,
            review_timestamp=now,
            remarks=updated_doc.get("remarks"),
            mentor_remarks=updated_doc.get("mentor_remarks"),
            hod_remarks=updated_doc.get("hod_remarks"),
            created_at=updated_doc.get("created_at", now)
        )

    @staticmethod
    async def cancel_leave_request(user: UserModel, request_id: str) -> LeaveRequestResponse:
        db = get_database()
        query = {"_id": ObjectId(request_id) if ObjectId.is_valid(request_id) else request_id}
        doc = await db[LEAVE_REQUESTS_COLLECTION].find_one(query)
        if not doc:
            raise AppException(status_code=status.HTTP_404_NOT_FOUND, message="Leave request not found.")
        if str(doc["student_id"]) != str(user.id):
            raise AppException(status_code=status.HTTP_403_FORBIDDEN, message="You can only cancel your own leave requests.")
        if doc.get("status") in [RequestStatus.APPROVED.value, RequestStatus.REJECTED.value, RequestStatus.CANCELLED.value]:
            raise AppException(
                status_code=status.HTTP_400_BAD_REQUEST,
                message=f"Cannot cancel a request that is already '{doc.get('status')}'."
            )

        now = datetime.now(timezone.utc)
        await db[LEAVE_REQUESTS_COLLECTION].update_one(
            query,
            {"$set": {"status": RequestStatus.CANCELLED.value, "updated_at": now}}
        )
        updated_doc = await db[LEAVE_REQUESTS_COLLECTION].find_one(query)
        student_id_str = str(user.id)
        name, reg = await LeaveODService._get_student_name_and_reg(student_id_str)
        return LeaveRequestResponse(
            id=str(updated_doc["_id"]),
            student_id=student_id_str,
            student_name=name,
            register_number=reg,
            request_type="leave",
            start_date=updated_doc["start_date"],
            end_date=updated_doc["end_date"],
            reason=updated_doc["reason"],
            document_url=updated_doc.get("document_url"),
            status=RequestStatus.CANCELLED,
            reviewer_id=updated_doc.get("reviewer_id"),
            reviewer_name=updated_doc.get("reviewer_name"),
            review_timestamp=updated_doc.get("review_timestamp"),
            remarks=updated_doc.get("remarks"),
            mentor_remarks=updated_doc.get("mentor_remarks"),
            hod_remarks=updated_doc.get("hod_remarks"),
            created_at=updated_doc.get("created_at", now)
        )

    # OD REQUEST METHODS
    @staticmethod
    async def create_od_request(user: UserModel, payload: ODRequestCreate) -> ODRequestResponse:
        db = get_database()
        now = datetime.now(timezone.utc)
        student_id_str = str(user.id)

        od_doc = {
            "student_id": student_id_str,
            "request_type": "od",
            "start_date": payload.start_date,
            "end_date": payload.end_date,
            "event_name": payload.event_name.strip(),
            "organization": payload.organization.strip(),
            "reason": payload.reason.strip(),
            "proof_document_url": payload.proof_document_url.strip() if payload.proof_document_url else None,
            "status": RequestStatus.PENDING,
            "reviewer_id": None,
            "reviewer_name": None,
            "review_timestamp": None,
            "remarks": None,
            "mentor_remarks": None,
            "hod_remarks": None,
            "created_at": now,
            "updated_at": now
        }

        result = await db[OD_REQUESTS_COLLECTION].insert_one(od_doc)
        od_id = str(result.inserted_id)

        name, reg = await LeaveODService._get_student_name_and_reg(student_id_str)
        assignment = await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find_one({
            "student_id": student_id_str,
            "is_active": True
        })
        if assignment:
            mentor_id = str(assignment.get("mentor_id"))
            await NotificationService.create_and_send_notification(
                recipient_user_id=mentor_id,
                title="New On-Duty (OD) Request",
                message=f"OD request submitted by {name} for event '{payload.event_name}'.",
                notification_type="OD_STATUS_CHANGED",
                related_record_id=od_id,
                related_record_type="od_request"
            )
        return ODRequestResponse(
            id=od_id,
            student_id=student_id_str,
            student_name=name,
            register_number=reg,
            request_type="od",
            start_date=payload.start_date,
            end_date=payload.end_date,
            event_name=payload.event_name.strip(),
            organization=payload.organization.strip(),
            reason=payload.reason.strip(),
            status=RequestStatus.PENDING,
            proof_document_url=payload.proof_document_url,
            created_at=now
        )

    @staticmethod
    async def get_student_od_requests(student_id_str: str) -> List[ODRequestResponse]:
        db = get_database()
        cursor = db[OD_REQUESTS_COLLECTION].find({
            "$or": [{"student_id": student_id_str}, {"student_id": ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None}]
        }).sort("created_at", -1)

        name, reg = await LeaveODService._get_student_name_and_reg(student_id_str)
        results = []
        async for doc in cursor:
            try:
                st_enum = RequestStatus(doc.get("status", "pending"))
            except ValueError:
                st_enum = RequestStatus.PENDING

            results.append(ODRequestResponse(
                id=str(doc["_id"]),
                student_id=str(doc["student_id"]),
                student_name=name,
                register_number=reg,
                request_type="od",
                start_date=doc["start_date"],
                end_date=doc["end_date"],
                event_name=doc["event_name"],
                organization=doc["organization"],
                reason=doc["reason"],
                status=st_enum,
                proof_document_url=doc.get("proof_document_url"),
                reviewer_id=doc.get("reviewer_id"),
                reviewer_name=doc.get("reviewer_name"),
                review_timestamp=doc.get("review_timestamp"),
                remarks=doc.get("remarks"),
                mentor_remarks=doc.get("mentor_remarks"),
                hod_remarks=doc.get("hod_remarks"),
                created_at=doc.get("created_at", datetime.now(timezone.utc))
            ))
        return results

    @staticmethod
    async def get_mentor_od_requests(mentor_id_str: str) -> List[ODRequestResponse]:
        db = get_database()
        cursor_assignments = db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find({
            "mentor_id": mentor_id_str,
            "is_active": True
        })
        student_ids = [str(doc["student_id"]) async for doc in cursor_assignments]

        if not student_ids:
            return []

        cursor_ods = db[OD_REQUESTS_COLLECTION].find({
            "student_id": {"$in": student_ids}
        }).sort("created_at", -1)

        results = []
        async for doc in cursor_ods:
            st_id = str(doc["student_id"])
            name, reg = await LeaveODService._get_student_name_and_reg(st_id)
            try:
                st_enum = RequestStatus(doc.get("status", "pending"))
            except ValueError:
                st_enum = RequestStatus.PENDING

            results.append(ODRequestResponse(
                id=str(doc["_id"]),
                student_id=st_id,
                student_name=name,
                register_number=reg,
                request_type="od",
                start_date=doc["start_date"],
                end_date=doc["end_date"],
                event_name=doc["event_name"],
                organization=doc["organization"],
                reason=doc["reason"],
                status=st_enum,
                proof_document_url=doc.get("proof_document_url"),
                reviewer_id=doc.get("reviewer_id"),
                reviewer_name=doc.get("reviewer_name"),
                review_timestamp=doc.get("review_timestamp"),
                remarks=doc.get("remarks"),
                mentor_remarks=doc.get("mentor_remarks"),
                hod_remarks=doc.get("hod_remarks"),
                created_at=doc.get("created_at", datetime.now(timezone.utc))
            ))
        return results

    @staticmethod
    async def update_od_status(request_id: str, reviewer: UserModel, payload: ODStatusUpdate) -> ODRequestResponse:
        db = get_database()
        query = {"_id": ObjectId(request_id) if ObjectId.is_valid(request_id) else request_id}
        doc = await db[OD_REQUESTS_COLLECTION].find_one(query)
        if not doc:
            raise AppException(status_code=status.HTTP_404_NOT_FOUND, message="OD request not found.")

        student_id_str = str(doc["student_id"])

        # Security check: Mentors can only review requests from their authorized assigned students
        if reviewer.role == "mentor":
            assignment = await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find_one({
                "mentor_id": str(reviewer.id),
                "student_id": {"$in": [student_id_str, ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None]},
                "is_active": True
            })
            if not assignment:
                raise AppException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    message="You are not authorized to review OD requests for this student."
                )

        now = datetime.now(timezone.utc)
        update_dict = {
            "status": payload.status.value,
            "reviewer_id": str(reviewer.id),
            "reviewer_name": reviewer.full_name or reviewer.email,
            "review_timestamp": now,
            "remarks": payload.remarks.strip() if payload.remarks else None,
            "updated_at": now
        }
        if reviewer.role in ["mentor", "admin"]:
            update_dict["mentor_remarks"] = payload.remarks.strip() if payload.remarks else None
        if reviewer.role == "admin":
            update_dict["hod_remarks"] = payload.remarks.strip() if payload.remarks else None

        await db[OD_REQUESTS_COLLECTION].update_one(query, {"$set": update_dict})

        await NotificationService.create_and_send_notification(
            recipient_user_id=student_id_str,
            title=f"OD Request {payload.status.value.replace('_', ' ').title()}",
            message=f"Your OD request for '{doc.get('event_name')}' has been marked as {payload.status.value}.",
            notification_type="OD_STATUS_CHANGED",
            related_record_id=request_id,
            related_record_type="od_request"
        )

        updated_doc = await db[OD_REQUESTS_COLLECTION].find_one(query)
        name, reg = await LeaveODService._get_student_name_and_reg(student_id_str)
        return ODRequestResponse(
            id=str(updated_doc["_id"]),
            student_id=student_id_str,
            student_name=name,
            register_number=reg,
            request_type="od",
            start_date=updated_doc["start_date"],
            end_date=updated_doc["end_date"],
            event_name=updated_doc["event_name"],
            organization=updated_doc["organization"],
            reason=updated_doc["reason"],
            status=payload.status,
            proof_document_url=updated_doc.get("proof_document_url"),
            reviewer_id=str(reviewer.id),
            reviewer_name=reviewer.full_name or reviewer.email,
            review_timestamp=now,
            remarks=updated_doc.get("remarks"),
            mentor_remarks=updated_doc.get("mentor_remarks"),
            hod_remarks=updated_doc.get("hod_remarks"),
            created_at=updated_doc.get("created_at", now)
        )

    @staticmethod
    async def cancel_od_request(user: UserModel, request_id: str) -> ODRequestResponse:
        db = get_database()
        query = {"_id": ObjectId(request_id) if ObjectId.is_valid(request_id) else request_id}
        doc = await db[OD_REQUESTS_COLLECTION].find_one(query)
        if not doc:
            raise AppException(status_code=status.HTTP_404_NOT_FOUND, message="OD request not found.")
        if str(doc["student_id"]) != str(user.id):
            raise AppException(status_code=status.HTTP_403_FORBIDDEN, message="You can only cancel your own OD requests.")
        if doc.get("status") in [RequestStatus.APPROVED.value, RequestStatus.REJECTED.value, RequestStatus.CANCELLED.value]:
            raise AppException(
                status_code=status.HTTP_400_BAD_REQUEST,
                message=f"Cannot cancel a request that is already '{doc.get('status')}'."
            )

        now = datetime.now(timezone.utc)
        await db[OD_REQUESTS_COLLECTION].update_one(
            query,
            {"$set": {"status": RequestStatus.CANCELLED.value, "updated_at": now}}
        )
        updated_doc = await db[OD_REQUESTS_COLLECTION].find_one(query)
        student_id_str = str(user.id)
        name, reg = await LeaveODService._get_student_name_and_reg(student_id_str)
        return ODRequestResponse(
            id=str(updated_doc["_id"]),
            student_id=student_id_str,
            student_name=name,
            register_number=reg,
            request_type="od",
            start_date=updated_doc["start_date"],
            end_date=updated_doc["end_date"],
            event_name=updated_doc["event_name"],
            organization=updated_doc["organization"],
            reason=updated_doc["reason"],
            status=RequestStatus.CANCELLED,
            proof_document_url=updated_doc.get("proof_document_url"),
            reviewer_id=updated_doc.get("reviewer_id"),
            reviewer_name=updated_doc.get("reviewer_name"),
            review_timestamp=updated_doc.get("review_timestamp"),
            remarks=updated_doc.get("remarks"),
            mentor_remarks=updated_doc.get("mentor_remarks"),
            hod_remarks=updated_doc.get("hod_remarks"),
            created_at=updated_doc.get("created_at", now)
        )
