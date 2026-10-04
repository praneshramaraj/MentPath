import os
import uuid
from typing import Set
from fastapi import UploadFile, status
from app.core.logging import logger
from app.utils.error_handlers import AppException

# Base uploads directory inside backend
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
UPLOADS_DIR = os.path.join(BASE_DIR, "uploads")
CERTIFICATES_DIR = os.path.join(UPLOADS_DIR, "certificates")
DOCUMENTS_DIR = os.path.join(UPLOADS_DIR, "documents")

# Ensure upload directories exist
os.makedirs(CERTIFICATES_DIR, exist_ok=True)
os.makedirs(DOCUMENTS_DIR, exist_ok=True)

ALLOWED_EXTENSIONS: Set[str] = {".pdf", ".png", ".jpg", ".jpeg", ".webp"}
ALLOWED_MIME_TYPES: Set[str] = {
    "application/pdf",
    
    "image/png",
    "image/jpeg",
    "image/webp"
}
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB


class UploadService:

    @staticmethod
    async def save_uploaded_file(file: UploadFile, subfolder: str = "certificates") -> dict:
        """Securely validate and store uploaded file on disk."""
        if not file.filename:
            raise AppException(status_code=status.HTTP_400_BAD_REQUEST, message="Uploaded file must have a valid filename.")

        # 1. Extension Validation
        _, ext = os.path.splitext(file.filename.lower())
        if ext not in ALLOWED_EXTENSIONS:
            raise AppException(
                status_code=status.HTTP_400_BAD_REQUEST,
                message=f"Invalid file extension '{ext}'. Allowed extensions: {', '.join(sorted(ALLOWED_EXTENSIONS))}"
            )

        # 2. Content Type Validation
        if file.content_type and file.content_type.lower() not in ALLOWED_MIME_TYPES:
            raise AppException(
                status_code=status.HTTP_400_BAD_REQUEST,
                message=f"Unsupported file type '{file.content_type}'. Allowed types: PDF, PNG, JPEG, WEBP."
            )

        # 3. Read content and enforce size limit
        content = await file.read()
        if len(content) > MAX_FILE_SIZE_BYTES:
            raise AppException(
                status_code=status.HTTP_400_BAD_REQUEST,
                message=f"File size exceeds maximum allowed limit of {MAX_FILE_SIZE_BYTES // (1024*1024)} MB."
            )

        # 4. Generate cryptographically safe unique filename (UUID v4)
        unique_name = f"{uuid.uuid4().hex}{ext}"
        target_dir = CERTIFICATES_DIR if subfolder == "certificates" else DOCUMENTS_DIR
        file_path = os.path.join(target_dir, unique_name)

        # 5. Write to disk
        with open(file_path, "wb") as f:
            f.write(content)

        file_url = f"/uploads/{subfolder}/{unique_name}"
        logger.info(f"File stored securely: {file_path} ({len(content)} bytes)")

        return {
            "filename": unique_name,
            "original_name": file.filename,
            "content_type": file.content_type or "application/octet-stream",
            "size_bytes": len(content),
            "url": file_url
        }
