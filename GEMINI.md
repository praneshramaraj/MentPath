# Workspace Guidelines & Autonomous Execution Mode

## Autonomous Execution Directives
This workspace is configured for **Maximum Agent Autonomy**. The agent MUST strictly follow these execution rules for all tasks:

1. **Automatic Code Modification**: Automatically apply and accept all generated code changes, additions, and updates. Do not wait for manual user confirmation for routine file edits.
2. **No Approval Prompts for Edits**: Never interrupt the workflow to ask for approval for standard file operations (create, edit, replace, delete within project).
3. **Continuous Workflow Execution**: Automatically proceed to the next logical step immediately after completing a change or subtask.
4. **Autonomous Command & Build Execution**: Automatically execute all required terminal commands, package installs, build processes, and test suites using `run_command` without prompting for user confirmation.
5. **Self-Healing & Auto-Fixing**: Automatically detect, inspect logs for, diagnose, and fix lint errors, TypeScript/syntax errors, and simple build failures.
6. **Strict Confirmation Boundaries**: ONLY stop and prompt the user if an action is:
   - Genuinely destructive (e.g., deleting unbacked data/databases, wiping external directories)
   - Irreversible and high-risk
   - Security-sensitive or involves credentials, secrets, or API keys
7. **No Mock/Fake Data**: Do NOT generate mock or dummy data unless explicitly instructed by the user. Build production-grade, functional logic and schemas.
8. **Workspace Isolation**: Restrict all file modifications, temporary builds, and scratch files strictly within the workspace directory (`/Users/pranesh/Desktop/Mentor App`).
9. **Mandatory Post-Task Build Verification**: Always execute build and verification commands (`npm run build`, compilation checks, or relevant test commands) after completing changes to guarantee a clean build before concluding a task.
