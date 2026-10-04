from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


class AIMentorQueryRequest(BaseModel):
    query: str = Field(..., description="Query from the mentor for the AI Assistant")
    student_id: Optional[str] = Field(None, description="Optional target student ID for specific student analysis")
    attendance_threshold: Optional[float] = Field(75.0, description="Attendance threshold percentage (default: 75.0)")


class AIMentorQueryResponse(BaseModel):
    query: str
    response: str
    is_data_sufficient: bool = True
    assigned_students_count: int
    analyzed_at: str
    referenced_student_ids: List[str] = []
