# App 200 Leave Workflow

App 200 owns the shared `LEAVE_APPROVAL` workflow. It uses `LEAVE_MANAGER_APPROVAL` for direct managers and `LEAVE_HR_APPROVAL` when requested working days exceed `LONG_LEAVE_THRESHOLD`, initially 5. App 100 submissions call the package, which starts application 200 explicitly.

The My Tasks page queries documented runtime views `APEX_TASKS` and `APEX_TASK_PARTICIPANTS`. Participant usernames are compared case-insensitively in the report while task definitions return normalized uppercase application usernames.
