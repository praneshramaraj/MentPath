from datetime import datetime, timezone
from typing import List, Dict
from bson import ObjectId
from fastapi import status
from app.core.logging import logger
from app.database.collections import (
    ATTENDANCE_COLLECTION,
    MARKS_COLLECTION,
    MENTOR_STUDENT_ASSIGNMENTS_COLLECTION,
    STUDENT_PROFILES_COLLECTION,
    USERS_COLLECTION
)
from app.database.mongodb import get_database
from app.models.attendance import AttendanceStatus
from app.models.user import UserModel, UserRole
from app.services.notification_service import NotificationService
from app.schemas.academic import (
    AttendanceRecordCreate,
    AttendanceRecordResponse,
    AttendanceSummaryResponse,
    SubjectAttendanceSummary,
    MarksRecordCreate,
    MarksRecordResponse,
    SemesterPerformanceSummary,
    SubjectPerformanceSummary,
    ExamPerformanceSummary,
    StudentMarksSummaryResponse
)
from app.utils.error_handlers import AppException


class AcademicService:

    @staticmethod
    async def _resolve_student_user_id(student_id_or_profile_id: str) -> str:
        """Resolve profile ID, user ID, register_number, or email to standard student user_id string."""
        db = get_database()
        val = student_id_or_profile_id.strip()
        query = {
            "$or": [
                {"_id": val},
                {"user_id": val},
                {"college_email": val.lower()},
                {"register_number": val.upper()}
            ]
        }
        if ObjectId.is_valid(val):
            query["$or"].append({"_id": ObjectId(val)})
            query["$or"].append({"user_id": ObjectId(val)})

        profile = await db[STUDENT_PROFILES_COLLECTION].find_one(query)
        if profile:
            return str(profile["user_id"])

        user_by_email = await db[USERS_COLLECTION].find_one({"email": val.lower()})
        if user_by_email:
            return str(user_by_email["_id"])

        return val

    @staticmethod
    async def _verify_access(current_user: UserModel, student_user_id: str):
        """Verify student or mentor authorization for target student data."""
        db = get_database()
        if current_user.role == UserRole.STUDENT:
            if str(current_user.id) != student_user_id:
                raise AppException(
                    message="Access forbidden: You can only view your own academic records.",
                    code="FORBIDDEN_RECORD_ACCESS",
                    status_code=status.HTTP_403_FORBIDDEN
                )
        elif current_user.role == UserRole.MENTOR:
            assignment = await db[MENTOR_STUDENT_ASSIGNMENTS_COLLECTION].find_one({
                "mentor_id": str(current_user.id),
                "student_id": student_user_id,
                "is_active": True
            })
            if not assignment:
                raise AppException(
                    message="Access forbidden: This student is not assigned to your mentorship.",
                    code="FORBIDDEN_MENTEE",
                    status_code=status.HTTP_403_FORBIDDEN
                )

    # ATTENDANCE METHODS
    @staticmethod
    async def log_attendance(current_user: UserModel, request: AttendanceRecordCreate) -> AttendanceRecordResponse:
        db = get_database()
        student_user_id = await AcademicService._resolve_student_user_id(request.student_id)
        await AcademicService._verify_access(current_user, student_user_id)

        now = datetime.now(timezone.utc)
        record_doc = {
            "student_id": student_user_id,
            "date": request.date.strip(),
            "status": request.status.value,
            "subject_code": request.subject_code.strip().upper() if request.subject_code else None,
            "subject_name": request.subject_name.strip() if request.subject_name else None,
            "period_session": request.period_session.strip() if request.period_session else None,
            "remarks": request.remarks.strip() if request.remarks else None,
            "created_by": str(current_user.id),
            "created_at": now,
            "updated_at": now
        }

        result = await db[ATTENDANCE_COLLECTION].insert_one(record_doc)
        rec_id = str(result.inserted_id)

        if request.status in [AttendanceStatus.ABSENT, AttendanceStatus.LATE]:
            await NotificationService.create_and_send_notification(
                recipient_user_id=student_user_id,
                title=f"Attendance Alert: Marked {request.status.value.title()}",
                message=f"Attendance on {request.date.strip()} marked as {request.status.value.title()} for {request.subject_code or 'session'}.",
                notification_type="ATTENDANCE_ALERT",
                related_record_id=rec_id,
                related_record_type="attendance"
            )

        return AttendanceRecordResponse(
            id=rec_id,
            student_id=student_user_id,
            date=record_doc["date"],
            status=request.status,
            subject_code=record_doc["subject_code"],
            subject_name=record_doc["subject_name"],
            period_session=record_doc["period_session"],
            remarks=record_doc["remarks"],
            created_by=str(current_user.id),
            created_at=now
        )

    @staticmethod
    async def get_student_attendance(current_user: UserModel, target_student_id: str) -> AttendanceSummaryResponse:
        db = get_database()
        student_user_id = await AcademicService._resolve_student_user_id(target_student_id)
        await AcademicService._verify_access(current_user, student_user_id)

        cursor = db[ATTENDANCE_COLLECTION].find({"student_id": student_user_id}).sort("date", -1)
        raw_records = await cursor.to_list(length=500)

        if not raw_records:
            return AttendanceSummaryResponse(
                total_days=0,
                present_days=0,
                absent_days=0,
                late_days=0,
                od_days=0,
                leave_days=0,
                attendance_percentage=None,
                subject_wise=[],
                records=[]
            )

        records: List[AttendanceRecordResponse] = []
        present_count = 0
        absent_count = 0
        late_count = 0
        od_count = 0
        leave_count = 0

        subject_map: Dict[str, dict] = {}

        for r in raw_records:
            st_val = r["status"]
            try:
                st_enum = AttendanceStatus(st_val)
            except ValueError:
                st_enum = AttendanceStatus.PRESENT

            if st_enum == AttendanceStatus.PRESENT:
                present_count += 1
            elif st_enum == AttendanceStatus.ABSENT:
                absent_count += 1
            elif st_enum == AttendanceStatus.LATE:
                late_count += 1
            elif st_enum == AttendanceStatus.OD:
                od_count += 1
            elif st_enum == AttendanceStatus.LEAVE:
                leave_count += 1

            subj_code = r.get("subject_code")
            subj_name = r.get("subject_name")

            if subj_code:
                if subj_code not in subject_map:
                    subject_map[subj_code] = {"name": subj_name, "total": 0, "attended": 0}
                subject_map[subj_code]["total"] += 1
                if st_enum in [AttendanceStatus.PRESENT, AttendanceStatus.LATE, AttendanceStatus.OD]:
                    subject_map[subj_code]["attended"] += 1

            records.append(
                AttendanceRecordResponse(
                    id=str(r["_id"]),
                    student_id=r["student_id"],
                    date=r["date"],
                    status=st_enum,
                    subject_code=subj_code,
                    subject_name=subj_name,
                    period_session=r.get("period_session"),
                    remarks=r.get("remarks"),
                    created_by=r.get("created_by"),
                    created_at=r.get("created_at", datetime.now(timezone.utc))
                )
            )

        total_days = len(records)
        effective_present = present_count + late_count + od_count
        pct = round((effective_present / total_days) * 100, 2) if total_days > 0 else None

        subject_summaries: List[SubjectAttendanceSummary] = []
        for sc, data in subject_map.items():
            tot = data["total"]
            att = data["attended"]
            s_pct = round((att / tot) * 100, 2) if tot > 0 else 0.0
            subject_summaries.append(
                SubjectAttendanceSummary(
                    subject_code=sc,
                    subject_name=data["name"],
                    total_classes=tot,
                    attended_classes=att,
                    attendance_percentage=s_pct
                )
            )

        return AttendanceSummaryResponse(
            total_days=total_days,
            present_days=present_count,
            absent_days=absent_count,
            late_days=late_count,
            od_days=od_count,
            leave_days=leave_count,
            attendance_percentage=pct,
            subject_wise=subject_summaries,
            records=records
        )

    # MARKS SERVICE METHODS
    @staticmethod
    async def log_marks(current_user: UserModel, request: MarksRecordCreate) -> MarksRecordResponse:
        db = get_database()
        student_user_id = await AcademicService._resolve_student_user_id(request.student_id)
        await AcademicService._verify_access(current_user, student_user_id)

        pct = round((request.marks_obtained / request.max_marks) * 100, 2)
        grade = request.grade
        if not grade:
            if pct >= 90:
                grade = "O"
            elif pct >= 80:
                grade = "A+"
            elif pct >= 70:
                grade = "A"
            elif pct >= 60:
                grade = "B+"
            elif pct >= 50:
                grade = "B"
            else:
                grade = "U"

        now = datetime.now(timezone.utc)
        doc = {
            "student_id": student_user_id,
            "semester": request.semester,
            "academic_year": request.academic_year.strip() if request.academic_year else None,
            "subject_code": request.subject_code.strip().upper(),
            "subject_name": request.subject_name.strip(),
            "exam_type": request.exam_type.strip(),
            "exam_name": request.exam_name.strip() if request.exam_name else None,
            "exam_date": request.exam_date.strip() if request.exam_date else None,
            "marks_obtained": request.marks_obtained,
            "max_marks": request.max_marks,
            "percentage": pct,
            "grade": grade,
            "created_at": now,
            "updated_at": now
        }

        result = await db[MARKS_COLLECTION].insert_one(doc)
        marks_id = str(result.inserted_id)

        await NotificationService.create_and_send_notification(
            recipient_user_id=student_user_id,
            title=f"Academic Marks Published: {request.subject_code}",
            message=f"Marks published for {request.subject_code} - {request.subject_name} ({request.marks_obtained}/{request.max_marks}, Grade: {grade}).",
            notification_type="ACADEMIC_UPDATE",
            related_record_id=marks_id,
            related_record_type="marks"
        )

        return MarksRecordResponse(
            id=marks_id,
            student_id=student_user_id,
            semester=request.semester,
            academic_year=doc["academic_year"],
            subject_code=doc["subject_code"],
            subject_name=doc["subject_name"],
            exam_type=doc["exam_type"],
            exam_name=doc["exam_name"],
            exam_date=doc["exam_date"],
            marks_obtained=doc["marks_obtained"],
            max_marks=doc["max_marks"],
            percentage=pct,
            grade=grade,
            created_at=now
        )

    @staticmethod
    async def get_student_marks(current_user: UserModel, target_student_id: str) -> StudentMarksSummaryResponse:
        db = get_database()
        student_user_id = await AcademicService._resolve_student_user_id(target_student_id)
        await AcademicService._verify_access(current_user, student_user_id)

        cursor = db[MARKS_COLLECTION].find({"student_id": student_user_id}).sort("semester", 1)
        raw = await cursor.to_list(length=500)

        if not raw:
            return StudentMarksSummaryResponse(
                average_percentage=None,
                total_records=0,
                semester_performance=[],
                subject_performance=[],
                exam_performance=[],
                records=[]
            )

        records: List[MarksRecordResponse] = []
        total_pct = 0.0

        # Grouping maps for performance breakdown
        sem_map: Dict[int, List[float]] = {}
        sub_map: Dict[str, dict] = {}  # subject_code -> {name, pcts}
        exam_map: Dict[str, List[float]] = {}

        for m in raw:
            pct = m.get("percentage", 0.0)
            total_pct += pct
            sem = m["semester"]
            sc = m["subject_code"]
            sn = m["subject_name"]
            et = m["exam_type"]

            # Track sem
            sem_map.setdefault(sem, []).append(pct)
            # Track sub
            if sc not in sub_map:
                sub_map[sc] = {"name": sn, "pcts": []}
            sub_map[sc]["pcts"].append(pct)
            # Track exam
            exam_map.setdefault(et, []).append(pct)

            records.append(
                MarksRecordResponse(
                    id=str(m["_id"]),
                    student_id=m["student_id"],
                    semester=sem,
                    academic_year=m.get("academic_year"),
                    subject_code=sc,
                    subject_name=sn,
                    exam_type=et,
                    exam_name=m.get("exam_name"),
                    exam_date=m.get("exam_date"),
                    marks_obtained=m["marks_obtained"],
                    max_marks=m["max_marks"],
                    percentage=pct,
                    grade=m.get("grade"),
                    created_at=m.get("created_at", datetime.now(timezone.utc))
                )
            )

        avg_pct = round(total_pct / len(records), 2) if records else None

        sem_summaries = [
            SemesterPerformanceSummary(semester=s, average_percentage=round(sum(pcts) / len(pcts), 2), total_exams=len(pcts))
            for s, pcts in sorted(sem_map.items())
        ]

        sub_summaries = [
            SubjectPerformanceSummary(subject_code=sc, subject_name=info["name"], average_percentage=round(sum(info["pcts"]) / len(info["pcts"]), 2), total_exams=len(info["pcts"]))
            for sc, info in sub_map.items()
        ]

        exam_summaries = [
            ExamPerformanceSummary(exam_type=et, average_percentage=round(sum(pcts) / len(pcts), 2), total_exams=len(pcts))
            for et, pcts in exam_map.items()
        ]

        return StudentMarksSummaryResponse(
            average_percentage=avg_pct,
            total_records=len(records),
            semester_performance=sem_summaries,
            subject_performance=sub_summaries,
            exam_performance=exam_summaries,
            records=records
        )
