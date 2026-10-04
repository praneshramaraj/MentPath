from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field
from app.models.attendance import AttendanceStatus


class AttendanceRecordCreate(BaseModel):
    student_id: str = Field(..., description="Target student user_id or profile_id")
    date: str = Field(..., description="Date of attendance (YYYY-MM-DD)")
    status: AttendanceStatus = Field(..., description="Attendance status (present, absent, late, on_duty, leave)")
    subject_code: Optional[str] = Field(None, description="Subject code (e.g. CS8591)")
    subject_name: Optional[str] = Field(None, description="Subject name")
    period_session: Optional[str] = Field(None, description="Period / Session (e.g. Period 1, FN, AN)")
    remarks: Optional[str] = Field(None, description="Remarks")


class AttendanceRecordResponse(BaseModel):
    id: str
    student_id: str
    date: str
    status: AttendanceStatus
    subject_code: Optional[str] = None
    subject_name: Optional[str] = None
    period_session: Optional[str] = None
    remarks: Optional[str] = None
    created_by: Optional[str] = None
    created_at: datetime


class SubjectAttendanceSummary(BaseModel):
    subject_code: str
    subject_name: Optional[str] = None
    total_classes: int = 0
    attended_classes: int = 0
    attendance_percentage: float = 0.0


class AttendanceSummaryResponse(BaseModel):
    total_days: int = 0
    present_days: int = 0
    absent_days: int = 0
    late_days: int = 0
    od_days: int = 0
    leave_days: int = 0
    attendance_percentage: Optional[float] = None
    subject_wise: List[SubjectAttendanceSummary] = Field(default_factory=list)
    records: List[AttendanceRecordResponse] = Field(default_factory=list)


# MARKS & ACADEMIC PERFORMANCE SCHEMAS
class MarksRecordCreate(BaseModel):
    student_id: str = Field(..., description="Target student user_id or profile_id")
    semester: int = Field(..., ge=1, le=8, description="Semester (1-8)")
    academic_year: Optional[str] = Field(None, description="Academic year (e.g. 2025-2026)")
    subject_code: str = Field(..., min_length=2, description="Subject code (e.g. CS8591)")
    subject_name: str = Field(..., min_length=2, description="Subject title")
    exam_type: str = Field(..., description="Exam type (Internal, Model, Semester, Assignment, Practical)")
    exam_name: Optional[str] = Field(None, description="Exam title (e.g. Internal 1, Practical Model)")
    exam_date: Optional[str] = Field(None, description="Exam date (YYYY-MM-DD)")
    marks_obtained: float = Field(..., ge=0.0, description="Marks obtained")
    max_marks: float = Field(default=100.0, gt=0.0, description="Maximum marks")
    grade: Optional[str] = Field(None, description="Letter grade (e.g. O, A+, A, B+, B, U)")


class MarksRecordResponse(BaseModel):
    id: str
    student_id: str
    semester: int
    academic_year: Optional[str] = None
    subject_code: str
    subject_name: str
    exam_type: str
    exam_name: Optional[str] = None
    exam_date: Optional[str] = None
    marks_obtained: float
    max_marks: float
    percentage: float
    grade: Optional[str] = None
    created_at: datetime


class SemesterPerformanceSummary(BaseModel):
    semester: int
    average_percentage: float
    total_exams: int


class SubjectPerformanceSummary(BaseModel):
    subject_code: str
    subject_name: str
    average_percentage: float
    total_exams: int


class ExamPerformanceSummary(BaseModel):
    exam_type: str
    average_percentage: float
    total_exams: int


class StudentMarksSummaryResponse(BaseModel):
    average_percentage: Optional[float] = None
    total_records: int = 0
    semester_performance: List[SemesterPerformanceSummary] = Field(default_factory=list)
    subject_performance: List[SubjectPerformanceSummary] = Field(default_factory=list)
    exam_performance: List[ExamPerformanceSummary] = Field(default_factory=list)
    records: List[MarksRecordResponse] = Field(default_factory=list)
