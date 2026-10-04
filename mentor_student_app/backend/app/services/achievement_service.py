from datetime import datetime, timezone
from typing import List, Optional
from bson import ObjectId
from fastapi import status
from app.database.collections import (
    ACHIEVEMENTS_COLLECTION,
    MENTOR_STUDENT_ASSIGNMENTS_COLLECTION,
    STUDENT_PROFILES_COLLECTION,
    USERS_COLLECTION,
    NOTIFICATIONS_COLLECTION
)
from app.database.mongodb import get_database
from app.models.user import UserModel, UserRole
from app.schemas.achievement import AchievementCreate, AchievementResponse, AchievementVerifyRequest
from app.utils.error_handlers import AppException


class AchievementService:

    @staticmethod
    async def _get_student_info(student_id_str: str) -> tuple[str, str]:
        db = get_database()
        profile = await db[STUDENT_PROFILES_COLLECTION].find_one({
            "$or": [{"user_id": student_id_str}, {"user_id": ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None}]
        })
        user = await db[USERS_COLLECTION].find_one({
            "$or": [{"_id": student_id_str}, {"_id": ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None}]
        })
        
        name = "Student"
        reg = ""

        if profile:
            name = profile.get("full_name") or (user.get("email") if user else "Student")
            reg = profile.get("register_number", "")
        elif user:
            name = user.get("email", "Student")

        return name, reg

    @staticmethod
    async def create_achievement(user: UserModel, payload: AchievementCreate) -> AchievementResponse:
        db = get_database()
        now = datetime.now(timezone.utc)
        student_id_str = str(user.id)

        doc = {
            "student_id": student_id_str,
            "title": payload.title.strip(),
            "category": payload.category.strip(),
            "organization": payload.organization.strip() if payload.organization else None,
            "description": payload.description.strip(),
            "date_awarded": payload.date_awarded,
            "certificate_url": payload.certificate_url.strip() if payload.certificate_url else None,
            "verified_by_mentor": False,
            "verification_status": "pending",
            "verifier_id": None,
            "verifier_name": None,
            "verification_timestamp": None,
            "created_at": now,
            "updated_at": now
        }

        result = await db[ACHIEVEMENTS_COLLECTION].insert_one(doc)
        ach_id = str(result.inserted_id)

        # Notify assigned mentor if exists
        assignment = await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find_one({
            "student_id": student_id_str,
            "is_active": True
        })
        if assignment:
            mentor_id = assignment.get("mentor_id")
            await db[NOTIFICATIONS_COLLECTION].insert_one({
                "recipient_user_id": str(mentor_id),
                "title": "New Achievement Record",
                "message": f"New {payload.category} achievement '{payload.title}' added for review.",
                "notification_type": "ACHIEVEMENT_ADDED",
                "is_read": False,
                "created_at": now,
                "updated_at": now
            })

        name, reg = await AchievementService._get_student_info(student_id_str)
        return AchievementResponse(
            id=ach_id,
            student_id=student_id_str,
            student_name=name,
            register_number=reg,
            title=payload.title.strip(),
            category=payload.category.strip(),
            organization=payload.organization.strip() if payload.organization else None,
            description=payload.description.strip(),
            date_awarded=payload.date_awarded,
            certificate_url=payload.certificate_url.strip() if payload.certificate_url else None,
            verified_by_mentor=False,
            verification_status="pending",
            created_at=now
        )

    @staticmethod
    async def get_student_achievements(student_id_str: str) -> List[AchievementResponse]:
        db = get_database()
        cursor = db[ACHIEVEMENTS_COLLECTION].find({
            "$or": [{"student_id": student_id_str}, {"student_id": ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None}]
        }).sort("created_at", -1)

        name, reg = await AchievementService._get_student_info(student_id_str)
        results = []
        async for doc in cursor:
            verified = doc.get("verified_by_mentor", False) or doc.get("verification_status") == "verified"
            st_val = doc.get("verification_status") or ("verified" if verified else "pending")
            results.append(AchievementResponse(
                id=str(doc["_id"]),
                student_id=str(doc["student_id"]),
                student_name=name,
                register_number=reg,
                title=doc["title"],
                category=doc["category"],
                organization=doc.get("organization"),
                description=doc["description"],
                date_awarded=doc["date_awarded"],
                certificate_url=doc.get("certificate_url"),
                verified_by_mentor=verified,
                verification_status=st_val,
                verifier_id=doc.get("verifier_id"),
                verifier_name=doc.get("verifier_name"),
                verification_timestamp=doc.get("verification_timestamp"),
                created_at=doc.get("created_at", datetime.now(timezone.utc))
            ))
        return results

    @staticmethod
    async def get_mentor_students_achievements(mentor_id_str: str) -> List[AchievementResponse]:
        db = get_database()
        cursor_assignments = db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find({
            "mentor_id": mentor_id_str,
            "is_active": True
        })
        student_ids = [str(doc["student_id"]) async for doc in cursor_assignments]

        if not student_ids:
            return []

        cursor = db[ACHIEVEMENTS_COLLECTION].find({"student_id": {"$in": student_ids}}).sort("created_at", -1)

        results = []
        async for doc in cursor:
            st_id = str(doc["student_id"])
            name, reg = await AchievementService._get_student_info(st_id)
            verified = doc.get("verified_by_mentor", False) or doc.get("verification_status") == "verified"
            st_val = doc.get("verification_status") or ("verified" if verified else "pending")
            results.append(AchievementResponse(
                id=str(doc["_id"]),
                student_id=st_id,
                student_name=name,
                register_number=reg,
                title=doc["title"],
                category=doc["category"],
                organization=doc.get("organization"),
                description=doc["description"],
                date_awarded=doc["date_awarded"],
                certificate_url=doc.get("certificate_url"),
                verified_by_mentor=verified,
                verification_status=st_val,
                verifier_id=doc.get("verifier_id"),
                verifier_name=doc.get("verifier_name"),
                verification_timestamp=doc.get("verification_timestamp"),
                created_at=doc.get("created_at", datetime.now(timezone.utc))
            ))
        return results

    @staticmethod
    async def verify_achievement(achievement_id: str, reviewer: UserModel, payload: AchievementVerifyRequest) -> AchievementResponse:
        db = get_database()
        query = {"_id": ObjectId(achievement_id) if ObjectId.is_valid(achievement_id) else achievement_id}
        doc = await db[ACHIEVEMENTS_COLLECTION].find_one(query)
        if not doc:
            raise AppException(status_code=status.HTTP_404_NOT_FOUND, message="Achievement record not found.")

        student_id_str = str(doc["student_id"])

        # Security check: Mentors can only verify achievements for their authorized assigned students
        if reviewer.role == UserRole.MENTOR.value:
            assignment = await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find_one({
                "mentor_id": str(reviewer.id),
                "student_id": {"$in": [student_id_str, ObjectId(student_id_str) if ObjectId.is_valid(student_id_str) else None]},
                "is_active": True
            })
            if not assignment:
                raise AppException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    message="You are not authorized to review achievements for this student."
                )

        now = datetime.now(timezone.utc)
        status_val = "verified" if payload.verified else "rejected"
        update_dict = {
            "verified_by_mentor": payload.verified,
            "verification_status": status_val,
            "verifier_id": str(reviewer.id),
            "verifier_name": reviewer.full_name or reviewer.email,
            "verification_timestamp": now,
            "updated_at": now
        }

        await db[ACHIEVEMENTS_COLLECTION].update_one(query, {"$set": update_dict})

        await db[NOTIFICATIONS_COLLECTION].insert_one({
            "recipient_user_id": student_id_str,
            "title": f"Achievement {status_val.title()}",
            "message": f"Your achievement '{doc['title']}' has been marked as {status_val} by your mentor.",
            "notification_type": "ACHIEVEMENT_VERIFIED",
            "is_read": False,
            "created_at": now,
            "updated_at": now
        })

        updated = await db[ACHIEVEMENTS_COLLECTION].find_one(query)
        name, reg = await AchievementService._get_student_info(student_id_str)
        return AchievementResponse(
            id=str(updated["_id"]),
            student_id=student_id_str,
            student_name=name,
            register_number=reg,
            title=updated["title"],
            category=updated["category"],
            organization=updated.get("organization"),
            description=updated["description"],
            date_awarded=updated["date_awarded"],
            certificate_url=updated.get("certificate_url"),
            verified_by_mentor=updated.get("verified_by_mentor", False),
            verification_status=updated.get("verification_status", "pending"),
            verifier_id=updated.get("verifier_id"),
            verifier_name=updated.get("verifier_name"),
            verification_timestamp=updated.get("verification_timestamp"),
            created_at=updated.get("created_at", now)
        )

    @staticmethod
    async def delete_achievement(achievement_id: str, user: UserModel) -> dict:
        db = get_database()
        query = {"_id": ObjectId(achievement_id) if ObjectId.is_valid(achievement_id) else achievement_id}
        doc = await db[ACHIEVEMENTS_COLLECTION].find_one(query)
        if not doc:
            raise AppException(status_code=status.HTTP_404_NOT_FOUND, message="Achievement record not found.")

        if str(doc["student_id"]) != str(user.id) and user.role != UserRole.ADMIN.value:
            raise AppException(status_code=status.HTTP_403_FORBIDDEN, message="You can only delete your own achievement records.")

        await db[ACHIEVEMENTS_COLLECTION].delete_one(query)
        return {"message": "Achievement record deleted successfully", "id": achievement_id}
