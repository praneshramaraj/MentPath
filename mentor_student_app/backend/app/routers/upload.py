from fastapi import APIRouter, Depends, File, UploadFile, Query, status
from app.core.dependencies import get_current_user
from app.models.user import UserModel
from app.services.upload_service import UploadService

router = APIRouter(prefix="/upload", tags=["File Uploads"])


@router.post("", status_code=status.HTTP_201_CREATED)
async def upload_file(
    file: UploadFile = File(...),
    subfolder: str = Query("certificates", description="Target folder: certificates or documents"),
    current_user: UserModel = Depends(get_current_user)
):
    """Secure file upload endpoint (authenticated users)."""
    return await UploadService.save_uploaded_file(file=file, subfolder=subfolder)
