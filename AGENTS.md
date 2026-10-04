# Agent Configuration & Rules

## Maximum Autonomy Mode Active

### Rules of Engagement:
- **Autonomy**: Execute all task steps end-to-end without pausing for confirmation on file edits, command execution, lint fixes, or build steps.
- **Continuity**: Move directly to subsequent task phases after completing prerequisite edits.
- **Self-Healing**: Intercept build and lint errors immediately, fetch full error tracebacks, and fix them autonomously.
- **Verification**: Run build and verification commands after completing work to confirm project stability.
- **Data Integrity**: Avoid dummy or mock data unless requested.
- **Scope Limit**: Keep all changes within the current workspace directory (`/Users/pranesh/Desktop/Mentor App`).
- **User Escalation Threshold**: Stop and prompt ONLY for credential entries, security key handling, or irreversible external/destructive operations.
