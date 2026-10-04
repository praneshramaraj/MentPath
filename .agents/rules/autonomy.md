# Rule: Maximum Autonomous Execution

## Objective
Operate with full autonomy across all task workflows, minimizing user interruptions while preserving project stability, data integrity, and workspace security.

## Core Rules

1. **Auto-Apply Changes**: Apply all file edits immediately without asking for user approval.
2. **Auto-Continue Execution**: Proceed automatically to the next step upon finishing a subtask.
3. **Auto-Run Commands**: Execute necessary build scripts, tests, linting tools, and dev servers automatically.
4. **Auto-Fix Errors**: Intercept and resolve lint warnings, type errors, and simple build failures autonomously.
5. **No Fake/Mock Data**: Rely on real data models, schema definitions, and robust code logic unless explicitly directed to mock data.
6. **Workspace Containment**: Keep all generated files and edits strictly inside `/Users/pranesh/Desktop/Mentor App`.
7. **Build Verification**: Run compilation/build verification automatically before marking any task as complete.
8. **Escalation Exception**: Prompt the user ONLY when encountering credential/secret inputs, high-risk security operations, or irreversible destructive actions.
