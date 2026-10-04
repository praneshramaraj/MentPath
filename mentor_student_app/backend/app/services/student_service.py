from datetime import datetime, timezone
from bson import ObjectId
from fastapi import status
from app.core.logging import logger
from app.database.collections import (
    STUDENT_PROFILES_COLLECTION,
    USERS_COLLECTION,
    MENTOR_STUDENT_ASSIGNMENTS_COLLECTION,
    MENTOR_PROFILES_COLLECTION
)
from app.database.mongodb import get_database
from app.models.student_profile import StudentProfileModel
from app.models.user import UserModel
from app.schemas.student import StudentProfileCreateRequest, StudentProfileUpdateRequest, StudentProfileResponse
from app.utils.error_handlers import AppException


class StudentService:
    @staticmethod
    async def create_profile(user: UserModel, request: StudentProfileCreateRequest) -> StudentProfileResponse:
        """Create or initialize real student profile in MongoDB."""
        db = get_database()

        # Security check: verify if profile already exists for this authenticated user
        existing_profile = await db[STUDENT_PROFILES_COLLECTION].find_one({
            "$or": [{"user_id": str(user.id)}, {"user_id": user.id}]
        })
        if existing_profile:
            logger.info(f"Student profile already exists for user {user.email}, updating...")
            # If profile exists, treat as update to prevent duplicate document creation

        # Check register_number uniqueness across all students
        reg_number_clean = request.register_number.strip().upper()
        duplicate_reg = await db[STUDENT_PROFILES_COLLECTION].find_one({
            "register_number": reg_number_clean,
            "user_id": {"$ne": str(user.id)}
        })
        if duplicate_reg:
            raise AppException(
                message=f"Register number '{reg_number_clean}' is already assigned to another student profile.",
                code="REGISTER_NUMBER_EXISTS",
                status_code=status.HTTP_400_BAD_REQUEST
            )

        now = datetime.now(timezone.utc)
        profile_data = {
            "user_id": str(user.id),
            "full_name": request.full_name.strip(),
            "date_of_birth": request.date_of_birth.strip(),
            "gender": request.gender.strip(),
            "phone_number": request.phone_number.strip(),
            "college_email": str(request.college_email).lower().strip(),
            "personal_email": str(request.personal_email).lower().strip() if request.personal_email else None,
            "address": request.address.strip(),
            "city": request.city.strip(),
            "state": request.state.strip(),
            "pincode": request.pincode.strip(),
            "register_number": reg_number_clean,
            "department": request.department.strip(),
            "course": request.course.strip(),
            "year": request.year,
            "semester": request.semester,
            "section": request.section.strip().upper() if request.section else None,
            "admission_year": request.admission_year,
            "mentor_id": None,
            "parent_name": request.parent_name.strip(),
            "relationship": request.relationship.strip(),
            "parent_phone": request.parent_phone.strip(),
            "parent_email": str(request.parent_email).lower().strip() if request.parent_email else None,
            "cgpa": request.cgpa,
            "previous_semester_info": request.previous_semester_info.strip() if request.previous_semester_info else None,
            "backlog_count": request.backlog_count,
            "created_at": now,
            "updated_at": now
        }

        if existing_profile:
            await db[STUDENT_PROFILES_COLLECTION].update_one(
                {"_id": existing_profile["_id"]},
                {"$set": profile_data}
            )
            inserted_id = str(existing_profile["_id"])
        else:
            result = await db[STUDENT_PROFILES_COLLECTION].insert_one(profile_data)
            inserted_id = str(result.inserted_id)

        # Update users collection record setting is_profile_complete = True
        await db[USERS_COLLECTION].update_one(
            {"$or": [{"_id": user.id}, {"_id": str(user.id)}]},
            {"$set": {"is_profile_complete": True, "updated_at": now}}
        )

        logger.info(f"Student profile created & linked for user {user.email} (Reg: {reg_number_clean})")

        return StudentProfileResponse(
            id=inserted_id,
            user_id=str(user.id),
            full_name=profile_data["full_name"],
            date_of_birth=profile_data["date_of_birth"],
            gender=profile_data["gender"],
            phone_number=profile_data["phone_number"],
            college_email=profile_data["college_email"],
            personal_email=profile_data["personal_email"],
            address=profile_data["address"],
            city=profile_data["city"],
            state=profile_data["state"],
            pincode=profile_data["pincode"],
            register_number=profile_data["register_number"],
            department=profile_data["department"],
            course=profile_data["course"],
            year=profile_data["year"],
            semester=profile_data["semester"],
            section=profile_data["section"],
            admission_year=profile_data["admission_year"],
            mentor_id=None,
            parent_name=profile_data["parent_name"],
            relationship=profile_data["relationship"],
            parent_phone=profile_data["parent_phone"],
            parent_email=profile_data["parent_email"],
            cgpa=profile_data["cgpa"],
            previous_semester_info=profile_data["previous_semester_info"],
            backlog_count=profile_data["backlog_count"],
            created_at=now,
            updated_at=now
        )

    @staticmethod
    async def get_profile(user: UserModel) -> StudentProfileResponse:
        """Fetch real student profile for the authenticated student user."""
        db = get_database()
        profile_dict = await db[STUDENT_PROFILES_COLLECTION].find_one({
            "$or": [{"user_id": str(user.id)}, {"user_id": user.id}]
        })

        if not profile_dict:
            raise AppException(
                message="Student profile not found. Please complete your initial profile setup.",
                code="PROFILE_NOT_FOUND",
                status_code=status.HTTP_404_NOT_FOUND
            )

        mentor_id_str = str(profile_dict["mentor_id"]) if profile_dict.get("mentor_id") else None
        mentor_name = None
        mentor_email = None
        mentor_dept = None

        # Check mentor_student_assignments if mentor_id not directly set in profile
        student_user_id = str(profile_dict["user_id"])
        assignment = await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find_one({
            "student_id": student_user_id,
            "is_active": True
        })

        actual_mentor_id = mentor_id_str or (str(assignment["mentor_id"]) if assignment else None)

        if actual_mentor_id:
            mentor_user = await db[USERS_COLLECTION].find_one({
                "$or": [{"_id": actual_mentor_id}, {"_id": ObjectId(actual_mentor_id) if ObjectId.is_valid(actual_mentor_id) else None}]
            })
            if mentor_user:
                mentor_email = mentor_user.get("email")
                mentor_name = mentor_user.get("full_name") or mentor_email

            m_prof = await db[MENTOR_PROFILES_COLLECTION].find_one({
                "$or": [{"user_id": actual_mentor_id}, {"user_id": ObjectId(actual_mentor_id) if ObjectId.is_valid(actual_mentor_id) else None}]
            })
            if m_prof:
                mentor_dept = m_prof.get("department")

        return StudentProfileResponse(
            id=str(profile_dict["_id"]),
            user_id=student_user_id,
            full_name=profile_dict["full_name"],
            date_of_birth=profile_dict["date_of_birth"],
            gender=profile_dict["gender"],
            phone_number=profile_dict["phone_number"],
            college_email=profile_dict["college_email"],
            personal_email=profile_dict.get("personal_email"),
            address=profile_dict["address"],
            city=profile_dict["city"],
            state=profile_dict["state"],
            pincode=profile_dict["pincode"],
            register_number=profile_dict["register_number"],
            department=profile_dict["department"],
            course=profile_dict["course"],
            year=profile_dict["year"],
            semester=profile_dict["semester"],
            section=profile_dict.get("section"),
            admission_year=profile_dict["admission_year"],
            mentor_id=actual_mentor_id,
            mentor_name=mentor_name,
            mentor_email=mentor_email,
            mentor_department=mentor_dept,
            parent_name=profile_dict["parent_name"],
            relationship=profile_dict["relationship"],
            parent_phone=profile_dict["parent_phone"],
            parent_email=profile_dict.get("parent_email"),
            cgpa=profile_dict.get("cgpa"),
            previous_semester_info=profile_dict.get("previous_semester_info"),
            backlog_count=profile_dict.get("backlog_count", 0),
            created_at=profile_dict.get("created_at", datetime.now(timezone.utc)),
            updated_at=profile_dict.get("updated_at", datetime.now(timezone.utc))
        )

    @staticmethod
    async def update_profile(user: UserModel, request: StudentProfileUpdateRequest) -> StudentProfileResponse:
        """Update permitted fields for authenticated student profile."""
        db = get_database()
        profile_dict = await db[STUDENT_PROFILES_COLLECTION].find_one({
            "$or": [{"user_id": str(user.id)}, {"user_id": user.id}]
        })

        if not profile_dict:
            raise AppException(
                message="Student profile not found. Please create profile first.",
                code="PROFILE_NOT_FOUND",
                status_code=status.HTTP_404_NOT_FOUND
            )

        update_data = {k: v for k, v in request.model_dump().items() if v is not None}
        if not update_data:
            return await StudentService.get_profile(user)

        update_data["updated_at"] = datetime.now(timezone.utc)
        await db[STUDENT_PROFILES_COLLECTION].update_one(
            {"_id": profile_dict["_id"]},
            {"$set": update_data}
        )

        return await StudentService.get_profile(user)
