from datetime import datetime, timezone
from typing import List, Optional
from bson import ObjectId
from fastapi import status
from app.core.logging import logger
from app.database.collections import (
    MENTOR_PROFILES_COLLECTION,
    MENTOR_STUDENT_ASSIGNMENTS_COLLECTION,
    STUDENT_PROFILES_COLLECTION,
    USERS_COLLECTION
)
from app.database.mongodb import get_database
from app.models.user import UserModel
from app.schemas.mentor import (
    MentorProfileCreateRequest,
    MentorProfileResponse,
    StudentAssignRequest,
    AssignedStudentSummary
)
from app.schemas.student import StudentProfileResponse
from app.utils.error_handlers import AppException


class MentorService:
    @staticmethod
    async def create_or_update_profile(user: UserModel, request: MentorProfileCreateRequest) -> MentorProfileResponse:
        """Create or update authenticated mentor's profile."""
        db = get_database()
        now = datetime.now(timezone.utc)

        existing_profile = await db[MENTOR_PROFILES_COLLECTION].find_one({
            "$or": [{"user_id": str(user.id)}, {"user_id": user.id}]
        })

        profile_data = {
            "user_id": str(user.id),
            "employee_id": request.employee_id.strip().upper(),
            "department": request.department.strip(),
            "designation": request.designation.strip(),
            "qualification": request.qualification.strip() if request.qualification else None,
            "max_mentees": request.max_mentees,
            "updated_at": now
        }

        if existing_profile:
            await db[MENTOR_PROFILES_COLLECTION].update_one(
                {"_id": existing_profile["_id"]},
                {"$set": profile_data}
            )
            profile_id = str(existing_profile["_id"])
        else:
            profile_data["created_at"] = now
            result = await db[MENTOR_PROFILES_COLLECTION].insert_one(profile_data)
            profile_id = str(result.inserted_id)

        # Count active assigned students from DB
        assigned_count = await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].count_documents({
            "mentor_id": str(user.id),
            "is_active": True
        })

        return MentorProfileResponse(
            id=profile_id,
            user_id=str(user.id),
            employee_id=profile_data["employee_id"],
            department=profile_data["department"],
            designation=profile_data["designation"],
            qualification=profile_data["qualification"],
            assigned_student_count=assigned_count,
            max_mentees=profile_data["max_mentees"],
            created_at=existing_profile.get("created_at", now) if existing_profile else now,
            updated_at=now
        )

    @staticmethod
    async def get_profile(user: UserModel) -> MentorProfileResponse:
        """Get profile and real assigned student count for authenticated mentor."""
        db = get_database()
        profile_dict = await db[MENTOR_PROFILES_COLLECTION].find_one({
            "$or": [{"user_id": str(user.id)}, {"user_id": user.id}]
        })

        assigned_count = await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].count_documents({
            "mentor_id": str(user.id),
            "is_active": True
        })

        if not profile_dict:
            # Return basic profile structure derived from authenticated user
            now = datetime.now(timezone.utc)
            return MentorProfileResponse(
                id="",
                user_id=str(user.id),
                employee_id="M-" + str(user.id)[-6:].upper(),
                department="General Academics",
                designation="Faculty Mentor",
                qualification=None,
                assigned_student_count=assigned_count,
                max_mentees=30,
                created_at=user.created_at,
                updated_at=now
            )

        return MentorProfileResponse(
            id=str(profile_dict["_id"]),
            user_id=str(profile_dict["user_id"]),
            employee_id=profile_dict["employee_id"],
            department=profile_dict["department"],
            designation=profile_dict["designation"],
            qualification=profile_dict.get("qualification"),
            assigned_student_count=assigned_count,
            max_mentees=profile_dict.get("max_mentees", 30),
            created_at=profile_dict.get("created_at", datetime.now(timezone.utc)),
            updated_at=profile_dict.get("updated_at", datetime.now(timezone.utc))
        )

    @staticmethod
    async def assign_student(mentor_user: UserModel, request: StudentAssignRequest) -> dict:
        """Assign a real registered student to this mentor."""
        db = get_database()
        identifier = request.student_identifier.strip()

        # Find target student by register_number or email
        student_profile = await db[STUDENT_PROFILES_COLLECTION].find_one({
            "$or": [
                {"register_number": identifier.upper()},
                {"college_email": identifier.lower()},
                {"personal_email": identifier.lower()}
            ]
        })

        if not student_profile:
            # Try finding user by email first
            target_user = await db[USERS_COLLECTION].find_one({"email": identifier.lower()})
            if target_user:
                student_profile = await db[STUDENT_PROFILES_COLLECTION].find_one({
                    "$or": [{"user_id": str(target_user["_id"])}, {"user_id": target_user["_id"]}]
                })

        if not student_profile:
            raise AppException(
                message=f"No student profile found matching '{identifier}'. Student must complete initial profile setup first.",
                code="STUDENT_NOT_FOUND",
                status_code=status.HTTP_404_NOT_FOUND
            )

        student_user_id = str(student_profile["user_id"])
        now = datetime.now(timezone.utc)

        # Deactivate any previous active assignments for this student if re-assigning
        await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].update_many(
            {"student_id": student_user_id, "is_active": True},
            {"$set": {"is_active": False, "unassigned_at": now}}
        )

        # Create new mentor-student assignment record
        assignment_doc = {
            "mentor_id": str(mentor_user.id),
            "student_id": student_user_id,
            "academic_year": request.academic_year,
            "assigned_date": now,
            "is_active": True,
            "created_at": now,
            "updated_at": now
        }

        await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].insert_one(assignment_doc)

        # Update mentor_id in student_profile
        await db[STUDENT_PROFILES_COLLECTION].update_one(
            {"_id": student_profile["_id"]},
            {"$set": {"mentor_id": str(mentor_user.id), "updated_at": now}}
        )

        logger.info(f"Assigned student {student_profile['full_name']} (Reg: {student_profile['register_number']}) to mentor {mentor_user.email}")

        return {
            "success": True,
            "message": f"Successfully assigned student '{student_profile['full_name']}' (Reg: {student_profile['register_number']}) to your mentorship.",
            "student_name": student_profile["full_name"],
            "register_number": student_profile["register_number"]
        }

    @staticmethod
    async def get_assigned_students(mentor_user: UserModel) -> List[AssignedStudentSummary]:
        """Fetch list of real students assigned to the authenticated mentor."""
        db = get_database()

        cursor = db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find({
            "mentor_id": str(mentor_user.id),
            "is_active": True
        })

        assignments = await cursor.to_list(length=100)
        if not assignments:
            return []

        student_user_ids = [a["student_id"] for a in assignments]
        assignment_map = {a["student_id"]: a["assigned_date"] for a in assignments}

        # Query real student profiles from MongoDB
        profiles_cursor = db[STUDENT_PROFILES_COLLECTION].find({
            "$or": [
                {"user_id": {"$in": student_user_ids}},
                {"user_id": {"$in": [ObjectId(uid) for uid in student_user_ids if ObjectId.is_valid(uid)]}}
            ]
        })

        profiles = await profiles_cursor.to_list(length=100)

        result: List[AssignedStudentSummary] = []
        for p in profiles:
            uid = str(p["user_id"])
            assigned_dt = assignment_map.get(uid, p.get("created_at", datetime.now(timezone.utc)))
            result.append(
                AssignedStudentSummary(
                    student_id=str(p["_id"]),
                    user_id=uid,
                    full_name=p["full_name"],
                    register_number=p["register_number"],
                    department=p["department"],
                    course=p["course"],
                    year=p["year"],
                    semester=p["semester"],
                    section=p.get("section"),
                    college_email=p["college_email"],
                    phone_number=p["phone_number"],
                    assigned_date=assigned_dt
                )
            )

        return result

    @staticmethod
    async def get_assigned_student_detail(mentor_user: UserModel, target_student_id: str) -> StudentProfileResponse:
        """
        Fetch full student detail with STRICT BACKEND AUTHORIZATION ENFORCEMENT.
        Mentor A CANNOT view students assigned to Mentor B or unassigned students.
        """
        db = get_database()

        # Find target student profile by profile ObjectId or user_id
        query_filter = {"$or": [{"_id": target_student_id}, {"user_id": target_student_id}]}
        if ObjectId.is_valid(target_student_id):
            query_filter["$or"].append({"_id": ObjectId(target_student_id)})
            query_filter["$or"].append({"user_id": ObjectId(target_student_id)})

        student_profile = await db[STUDENT_PROFILES_COLLECTION].find_one(query_filter)
        if not student_profile:
            raise AppException(
                message="Student profile not found.",
                code="STUDENT_NOT_FOUND",
                status_code=status.HTTP_404_NOT_FOUND
            )

        student_user_id = str(student_profile["user_id"])

        # STRICT BACKEND AUTHORIZATION CHECK: verify mentor_student_assignments
        assignment = await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find_one({
            "mentor_id": str(mentor_user.id),
            "student_id": student_user_id,
            "is_active": True
        })

        if not assignment:
            logger.warning(
                f"Unauthorized mentor access attempt: Mentor {mentor_user.email} (ID: {mentor_user.id}) "
                f"tried to access Student {student_profile['full_name']} (User ID: {student_user_id}) which is NOT assigned to them."
            )
            raise AppException(
                message=f"Access denied: Student '{student_profile['full_name']}' is not assigned to your mentorship.",
                code="FORBIDDEN_MENTEE",
                status_code=status.HTTP_403_FORBIDDEN
            )

        return StudentProfileResponse(
            id=str(student_profile["_id"]),
            user_id=student_user_id,
            full_name=student_profile["full_name"],
            date_of_birth=student_profile["date_of_birth"],
            gender=student_profile["gender"],
            phone_number=student_profile["phone_number"],
            college_email=student_profile["college_email"],
            personal_email=student_profile.get("personal_email"),
            address=student_profile["address"],
            city=student_profile["city"],
            state=student_profile["state"],
            pincode=student_profile["pincode"],
            register_number=student_profile["register_number"],
            department=student_profile["department"],
            course=student_profile["course"],
            year=student_profile["year"],
            semester=student_profile["semester"],
            section=student_profile.get("section"),
            admission_year=student_profile["admission_year"],
            mentor_id=str(mentor_user.id),
            parent_name=student_profile["parent_name"],
            relationship=student_profile["relationship"],
            parent_phone=student_profile["parent_phone"],
            parent_email=student_profile.get("parent_email"),
            cgpa=student_profile.get("cgpa"),
            previous_semester_info=student_profile.get("previous_semester_info"),
            backlog_count=student_profile.get("backlog_count", 0),
            created_at=student_profile.get("created_at", datetime.now(timezone.utc)),
            updated_at=student_profile.get("updated_at", datetime.now(timezone.utc))
        )
