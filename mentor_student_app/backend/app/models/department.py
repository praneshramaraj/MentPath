from typing import Optional
from app.models.base import BaseDBModel, PyObjectId


class DepartmentModel(BaseDBModel):
    name: str
    code: str
    hod_user_id: Optional[PyObjectId] = None
