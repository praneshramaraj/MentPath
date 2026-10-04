from typing import List, Callable, Union
from bson import ObjectId
from fastapi import Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.logging import logger
from app.core.security import decode_access_token
from app.database.collections import USERS_COLLECTION
from app.database.mongodb import get_database
from app.models.user import UserModel, UserRole
from app.utils.error_handlers import AppException

security = HTTPBearer()


async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> UserModel:
    """Validate JWT access token and return the current user model."""
    token = credentials.credentials
    payload = decode_access_token(token)
    if not payload:
        raise AppException(
            message="Could not validate credentials or token has expired",
            code="UNAUTHORIZED",
            status_code=status.HTTP_401_UNAUTHORIZED
        )

    user_id_str = payload.get("sub")
    if not user_id_str:
        raise AppException(
            message="Invalid authentication payload in token",
            code="UNAUTHORIZED",
            status_code=status.HTTP_401_UNAUTHORIZED
        )

    db = get_database()
    
    # Flexible lookup for both String _id and BSON ObjectId _id
    query_filter = {"$or": [{"_id": user_id_str}]}
    if ObjectId.is_valid(user_id_str):
        query_filter["$or"].append({"_id": ObjectId(user_id_str)})

    user_dict = await db[USERS_COLLECTION].find_one(query_filter)
    if not user_dict:
        raise AppException(
            message="User account no longer exists",
            code="USER_NOT_FOUND",
            status_code=status.HTTP_401_UNAUTHORIZED
        )

    user = UserModel(**user_dict)
    return user


async def get_current_active_user(current_user: UserModel = Depends(get_current_user)) -> UserModel:
    """Verify that current user account is active."""
    if not current_user.is_active:
        raise AppException(
            message="Account is inactive or deactivated",
            code="ACCOUNT_INACTIVE",
            status_code=status.HTTP_403_FORBIDDEN
        )
    return current_user


def require_roles(*allowed_roles: Union[UserRole, List[UserRole]]) -> Callable:
    """Dependency factory enforcing strict role-based access control (RBAC)."""
    roles_set = set()
    for item in allowed_roles:
        if isinstance(item, list):
            roles_set.update(item)
        else:
            roles_set.add(item)

    async def role_checker(current_user: UserModel = Depends(get_current_active_user)) -> UserModel:
        if current_user.role not in roles_set:
            logger.warning(
                f"Unauthorized access attempt by user {current_user.email} (Role: {current_user.role.value}) "
                f"to resource restricted to {[r.value for r in roles_set]}"
            )
            raise AppException(
                message=f"Access forbidden: Role '{current_user.role.value}' is not authorized to access this resource",
                code="FORBIDDEN_ROLE",
                status_code=status.HTTP_403_FORBIDDEN
            )
        return current_user

    return role_checker

