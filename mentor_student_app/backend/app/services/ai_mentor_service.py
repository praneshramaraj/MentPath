import os
import json
import logging
from datetime import datetime
from typing import List, Dict, Any, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.config import settings

logger = logging.getLogger(__name__)

# System Prompt for Anti-Hallucination AI Guardrails
SYSTEM_PROMPT = """You are an AI Mentor Assistant in an academic College Mentor-Student Management System.
Your job is to assist mentors by analyzing REAL, AUTHORIZED database records of their assigned students.

CRITICAL HALLUCINATION PREVENTION RULES:
1. You must ONLY answer using the exact ground-truth database records provided in the context below.
2. NEVER invent, fabricate, estimate, or assume any student names, attendance percentages, exam marks, achievements, medical information, or personal details.
3. If the database context does NOT contain sufficient recorded information to answer the question, or if no records exist for the query, you MUST explicitly state:
   "I don't have enough recorded data to answer that."
4. Highlight students with attendance below threshold, missing marks, or needing follow-up ONLY when supported by real records in the provided context.
5. Do NOT make assumptions about unrecorded exams, unlogged attendance, or unassigned students.
6. Provide concise, professional, and well-structured markdown answers based solely on the provided context.
"""


class AIMentorService:

    @staticmethod
    async def get_assigned_students_context(
        db: AsyncIOMotorDatabase,
        mentor_user_id: str,
        target_student_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Retrieves authorized database context for students assigned to the mentor.
        Strict authorization boundary: ONLY assigned students' records are retrieved.
        """
        # Step 1: Find mentor profile by user_id
        mentor = await db.mentor_profiles.find_one({"user_id": mentor_user_id})
        if not mentor:
            mentor = await db.mentor_profiles.find_one({"_id": mentor_user_id})
        
        mentor_doc_id = str(mentor["_id"]) if mentor else mentor_user_id

        # Step 2: Retrieve assigned student IDs from mentor_student_assignments
        cursor = db.mentor_student_assignments.find({"mentor_id": mentor_doc_id, "is_active": True})
        assignments = await cursor.to_list(length=100)
        
        if not assignments:
            # Fallback: check if mentor_id is mentor_user_id
            cursor = db.mentor_student_assignments.find({"mentor_id": mentor_user_id, "is_active": True})
            assignments = await cursor.to_list(length=100)

        assigned_student_ids = [a["student_id"] for a in assignments]

        if target_student_id:
            # Filter specifically for target student if authorized
            if target_student_id in assigned_student_ids:
                assigned_student_ids = [target_student_id]
            else:
                # Target student is not assigned to this mentor! Return empty context
                return []

        if not assigned_student_ids:
            return []

        # Step 3: Fetch authorized records for assigned students
        students_context = []

        for sid in assigned_student_ids:
            # Student Profile
            student_profile = await db.student_profiles.find_one({"_id": sid})
            if not student_profile:
                student_profile = await db.student_profiles.find_one({"user_id": sid})

            if not student_profile:
                continue

            real_sid = str(student_profile["_id"])
            user_id = student_profile.get("user_id", real_sid)

            # Attendance Data
            att_cursor = db.attendance_records.find({"student_id": {"$in": [real_sid, user_id]}})
            attendance_docs = await att_cursor.to_list(length=500)
            
            total_days = len(attendance_docs)
            present_days = sum(1 for a in attendance_docs if a.get("status") in ["PRESENT", "OD"])
            absent_days = sum(1 for a in attendance_docs if a.get("status") == "ABSENT")
            late_days = sum(1 for a in attendance_docs if a.get("status") == "LATE")
            
            att_percentage = round((present_days / total_days * 100.0), 2) if total_days > 0 else None

            # Subject-wise attendance breakdown
            subject_att: Dict[str, Dict[str, int]] = {}
            for a in attendance_docs:
                subj = a.get("subject", "General")
                if subj not in subject_att:
                    subject_att[subj] = {"total": 0, "present": 0}
                subject_att[subj]["total"] += 1
                if a.get("status") in ["PRESENT", "OD"]:
                    subject_att[subj]["present"] += 1

            subject_att_summary = {
                subj: round(data["present"] / data["total"] * 100.0, 2)
                for subj, data in subject_att.items() if data["total"] > 0
            }

            # Marks Data
            marks_cursor = db.marks_records.find({"student_id": {"$in": [real_sid, user_id]}})
            marks_docs = await marks_cursor.to_list(length=200)

            marks_list = []
            for m in marks_docs:
                marks_list.append({
                    "subject": m.get("subject"),
                    "exam_name": m.get("exam_name"),
                    "exam_type": m.get("exam_type"),
                    "obtained_marks": m.get("obtained_marks"),
                    "max_marks": m.get("max_marks"),
                    "semester": m.get("semester"),
                    "academic_year": m.get("academic_year"),
                })

            # Mentor Notes & Follow-ups
            notes_cursor = db.mentor_notes.find({"student_id": {"$in": [real_sid, user_id]}})
            notes_docs = await notes_cursor.to_list(length=100)
            notes_list = [{
                "category": n.get("category"),
                "title": n.get("title"),
                "note": n.get("note"),
                "date": n.get("date"),
                "follow_up_date": n.get("follow_up_date"),
                "is_student_visible": n.get("is_student_visible", True)
            } for n in notes_docs]

            # Counseling Meetings
            meetings_cursor = db.counseling_meetings.find({"student_id": {"$in": [real_sid, user_id]}})
            meetings_docs = await meetings_cursor.to_list(length=100)
            meetings_list = [{
                "date": m.get("date"),
                "topic": m.get("topic"),
                "discussion_summary": m.get("discussion_summary"),
                "action_items": m.get("action_items"),
                "follow_up_date": m.get("follow_up_date")
            } for m in meetings_docs]

            # Achievements
            ach_cursor = db.student_achievements.find({"student_id": {"$in": [real_sid, user_id]}})
            ach_docs = await ach_cursor.to_list(length=50)
            achievements_list = [{
                "title": a.get("title"),
                "category": a.get("category"),
                "verification_status": a.get("verification_status")
            } for a in ach_docs]

            # Leave / OD summary
            leave_cnt = await db.leave_requests.count_documents({"student_id": {"$in": [real_sid, user_id]}})
            od_cnt = await db.od_requests.count_documents({"student_id": {"$in": [real_sid, user_id]}})

            students_context.append({
                "student_id": real_sid,
                "full_name": student_profile.get("full_name"),
                "register_number": student_profile.get("register_number"),
                "department": student_profile.get("department"),
                "year": student_profile.get("year"),
                "section": student_profile.get("section"),
                "attendance": {
                    "has_records": total_days > 0,
                    "overall_percentage": att_percentage,
                    "total_days": total_days,
                    "present_days": present_days,
                    "absent_days": absent_days,
                    "late_days": late_days,
                    "subject_wise": subject_att_summary
                },
                "marks": {
                    "has_records": len(marks_list) > 0,
                    "total_records": len(marks_list),
                    "records": marks_list
                },
                "notes_count": len(notes_list),
                "notes": notes_list,
                "meetings_count": len(meetings_list),
                "meetings": meetings_list,
                "achievements_count": len(achievements_list),
                "achievements": achievements_list,
                "leave_requests_count": leave_cnt,
                "od_requests_count": od_cnt
            })

        return students_context

    @classmethod
    async def query_ai_mentor(
        cls,
        db: AsyncIOMotorDatabase,
        mentor_user_id: str,
        query: str,
        target_student_id: Optional[str] = None,
        attendance_threshold: float = 75.0
    ) -> Dict[str, Any]:
        """
        Processes mentor AI queries using Gemini API with fallback to rule-based anti-hallucination analysis.
        """
        # Step 1: Fetch authorized student database context
        students_context = await cls.get_assigned_students_context(db, mentor_user_id, target_student_id)
        assigned_count = len(students_context)

        # Handle zero assigned students immediately
        if assigned_count == 0:
            return {
                "query": query,
                "response": "I don't have enough recorded data to answer that.",
                "is_data_sufficient": False,
                "assigned_students_count": 0,
                "analyzed_at": datetime.now().isoformat(),
                "referenced_student_ids": []
            }

        # Format Context for LLM / Analysis
        context_json_str = json.dumps(students_context, indent=2)

        # Check for Gemini API key
        api_key = settings.GEMINI_API_KEY or os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")

        llm_response = None
        is_sufficient = True

        if api_key:
            try:
                from google import genai
                from google.genai import types

                client = genai.Client(api_key=api_key)
                
                user_prompt = f"""MENTOR QUESTION: "{query}"

CONFIGURED ATTENDANCE THRESHOLD: {attendance_threshold}%

AUTHORITATIVE DATABASE CONTEXT FOR ASSIGNED STUDENTS:
{context_json_str}

Respond according to system instructions. Remember: If context is missing required information, output "I don't have enough recorded data to answer that."
"""

                response = client.models.generate_content(
                    model='gemini-2.5-flash',
                    contents=user_prompt,
                    config=types.GenerateContentConfig(
                        system_instruction=SYSTEM_PROMPT,
                        temperature=0.1,
                    )
                )

                if response and response.text:
                    llm_response = response.text.strip()

            except Exception as e:
                logger.warning(f"Gemini API call failed or unconfigured: {e}. Falling back to structured analyzer.")
                llm_response = None

        # If LLM API call was not performed or failed, run structured zero-hallucination rule analyzer
        if not llm_response:
            llm_response, is_sufficient = cls._execute_deterministic_analysis(
                query=query,
                students_context=students_context,
                attendance_threshold=attendance_threshold
            )
        else:
            if "don't have enough recorded data" in llm_response.lower() or "insufficient" in llm_response.lower():
                is_sufficient = False

        referenced_ids = [s["student_id"] for s in students_context]

        return {
            "query": query,
            "response": llm_response,
            "is_data_sufficient": is_sufficient,
            "assigned_students_count": assigned_count,
            "analyzed_at": datetime.now().isoformat(),
            "referenced_student_ids": referenced_ids
        }

    @staticmethod
    def _execute_deterministic_analysis(
        query: str,
        students_context: List[Dict[str, Any]],
        attendance_threshold: float
    ) -> tuple[str, bool]:
        """
        Deterministic, zero-hallucination analysis engine for offline or fallback operation.
        Guarantees exact matching against database context without hallucinating missing records.
        """
        query_lower = query.lower()

        # Case 1: Attendance below threshold query
        if "attendance" in query_lower or "below" in query_lower or "threshold" in query_lower or "absent" in query_lower:
            students_with_records = [s for s in students_context if s["attendance"]["has_records"]]
            if not students_with_records:
                return "I don't have enough recorded data to answer that.", False

            low_att_students = [
                s for s in students_with_records
                if s["attendance"]["overall_percentage"] is not None and s["attendance"]["overall_percentage"] < attendance_threshold
            ]

            if not low_att_students:
                return (
                    f"### Attendance Analysis (Threshold: {attendance_threshold}%)\n\n"
                    f"Based on real recorded attendance data, **0 assigned students** are below the {attendance_threshold}% threshold.\n"
                    f"All assigned students with attendance logs maintain attendance above {attendance_threshold}%.",
                    True
                )

            lines = [f"### Students with Attendance Below {attendance_threshold}%\n"]
            for s in low_att_students:
                att = s['attendance']['overall_percentage']
                lines.append(f"- **{s['full_name']}** (Reg: `{s['register_number']}` | Dept: {s['department']}): **{att}%** ({s['attendance']['present_days']}/{s['attendance']['total_days']} days present)")
                if s['attendance']['subject_wise']:
                    subj_low = [f"{k}: {v}%" for k, v in s['attendance']['subject_wise'].items() if v < attendance_threshold]
                    if subj_low:
                        lines.append(f"  - Low subjects: {', '.join(subj_low)}")
            return "\n".join(lines), True

        # Case 2: Missing marks query
        if "marks" in query_lower or "missing" in query_lower or "exam" in query_lower or "grade" in query_lower:
            students_with_marks = [s for s in students_context if s["marks"]["has_records"]]
            students_no_marks = [s for s in students_context if not s["marks"]["has_records"]]

            if not students_context or (not students_with_marks and not students_no_marks):
                return "I don't have enough recorded data to answer that.", False

            lines = ["### Marks & Exam Status Summary\n"]
            if students_no_marks:
                lines.append("**Students with NO recorded marks in system:**")
                for s in students_no_marks:
                    lines.append(f"- **{s['full_name']}** (Reg: `{s['register_number']}`): No exam marks uploaded yet.")
                lines.append("")

            if students_with_marks:
                lines.append("**Students with uploaded marks records:**")
                for s in students_with_marks:
                    records_cnt = s["marks"]["total_records"]
                    lines.append(f"- **{s['full_name']}** (Reg: `{s['register_number']}`): {records_cnt} exam mark record(s) logged.")
            return "\n".join(lines), True

        # Case 3: Follow-up required query
        if "follow-up" in query_lower or "follow up" in query_lower or "attention" in query_lower or "need" in query_lower:
            follow_up_students = []
            for s in students_context:
                reasons = []
                # Check low attendance
                if s["attendance"]["has_records"] and s["attendance"]["overall_percentage"] is not None and s["attendance"]["overall_percentage"] < attendance_threshold:
                    reasons.append(f"Low attendance ({s['attendance']['overall_percentage']}%)")
                
                # Check pending notes follow-ups
                for n in s.get("notes", []):
                    if n.get("follow_up_date"):
                        reasons.append(f"Mentor note follow-up scheduled for {n['follow_up_date']}")
                
                # Check pending meeting follow-ups
                for m in s.get("meetings", []):
                    if m.get("follow_up_date"):
                        reasons.append(f"Counseling meeting follow-up scheduled for {m['follow_up_date']}")

                if reasons:
                    follow_up_students.append((s, reasons))

            if not follow_up_students:
                return (
                    "### Assigned Students Follow-up Status\n\n"
                    "Based on real database records, **no assigned students currently require urgent follow-up**.\n"
                    "All students have satisfactory attendance and no pending follow-up dates logged.",
                    True
                )

            lines = ["### Assigned Students Requiring Follow-up\n"]
            for s, reasons in follow_up_students:
                lines.append(f"- **{s['full_name']}** (Reg: `{s['register_number']}`):")
                for r in reasons:
                    lines.append(f"  - {r}")
            return "\n".join(lines), True

        # Case 4: Academic Progress Summary query
        if "summarize" in query_lower or "summary" in query_lower or "progress" in query_lower or "academic" in query_lower or "overview" in query_lower:
            lines = ["### Academic & Attendance Summary of Assigned Students\n"]
            for s in students_context:
                att_str = f"{s['attendance']['overall_percentage']}%" if s['attendance']['has_records'] else "No records"
                marks_str = f"{s['marks']['total_records']} record(s)" if s['marks']['has_records'] else "No records"
                lines.append(f"- **{s['full_name']}** (Reg: `{s['register_number']}` | {s['department']} Year {s['year']}):")
                lines.append(f"  - **Attendance:** {att_str}")
                lines.append(f"  - **Marks Logs:** {marks_str}")
                lines.append(f"  - **Counseling Meetings:** {s['meetings_count']} logged")
                lines.append(f"  - **Achievements:** {s['achievements_count']} verified/recorded")
            return "\n".join(lines), True

        # Default Fallback for ambiguous or unsupported queries when LLM is unavailable:
        return (
            "### AI Mentor Assistant Response\n\n"
            "I have retrieved authorized real database records for your assigned students.\n\n"
            "**Supported analysis topics:**\n"
            "- Attendance below configured threshold (e.g. 75%)\n"
            "- Exam marks & missing marks status\n"
            "- Students requiring follow-up or counseling attention\n"
            "- Student academic & attendance progress summary\n\n"
            "If database records are missing for specific queries, system will enforce: *\"I don't have enough recorded data to answer that.\"*",
            True
        )
