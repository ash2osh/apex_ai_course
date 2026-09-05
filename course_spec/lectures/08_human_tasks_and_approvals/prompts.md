# Episode 8: Coding Agent Prompts & Human Task Setup

## 🤖 Coding Agent Prompts (Task Definitions & Inbox)

### Prompt 1: Task Participant SQL Expressions
```text
Write two SQL queries for APEX Task Definition LEAVE_MANAGER_APPROVAL using only :T_REQUEST_ID:
1. Potential Owner: Resolves the active manager's username for the leave request.
2. Business Administrator: Resolves active ADMIN and SUPER_ADMIN users, excluding the requesting employee.
```

### Prompt 2: Task Definition Action Handlers
```text
Write the PL/SQL code for the 3 actions in LEAVE_MANAGER_APPROVAL task definition:
1. ON APPROVED: calls hr_workflow_pkg.manager_outcome with outcome 'APPROVED' and passes :APEX$TASK_COMMENTS.
2. ON REJECT: calls hr_workflow_pkg.manager_outcome with outcome 'REJECTED' and passes :APEX$TASK_COMMENTS.
3. ON CANCEL: calls hr_workflow_pkg.manager_outcome with outcome 'CANCELLED' and passes :APEX$TASK_COMMENTS.
Ensure the code updates HR_LEAVE_REQUESTS status, adjusts balances, and writes lifecycle events.
```

### Prompt 3: My Tasks Unified Inbox Query
```text
Write the unified SQL query for Page 2 (My Tasks) in App 200 using documented APEX 26.1 runtime views (APEX_TASKS, APEX_TASK_PARTICIPANTS) to display pending approval tasks for the current user.
```
