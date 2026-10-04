from typing import Optional
from app.models.base import BaseDBModel, PyObjectId


class MarksModel(BaseDBModel):
    student_id: PyObjectId
    semester: int
    academic_year: Optional[str] = None  # e.g., "2025-2026"
    subject_code: str
    subject_name: str
    exam_type: str  # e.g., "Internal", "Model", "Semester", "Assignment", "Practical"
    exam_name: Optional[str] = None  # e.g., "Internal Assessment 1"
    exam_date: Optional[str] = None  # e.g., "2026-10-15"
    marks_obtained: float
    max_marks: float = 100.0
    percentage: Optional[float] = None
    grade: Optional[str] = None
