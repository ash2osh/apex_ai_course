# Demo Scenarios

> These scenarios are acceptance specifications for the future generated implementation; they are not runnable in this standalone repository.

## Scenario 1 — Employee Login

Login as:

```text
EMP001
```

Demonstrate:

- Employee navigation
- Employee-only access
- Dashboard cards

## Scenario 2 — Check Leave Balance

Employee opens Leave Balance.

Expected:

```text
Annual Leave Available: 14 days
```

## Scenario 3 — Ask AI Assistant

Prompt:

```text
How much annual leave do I have?
```

Explain difference between:

- AI-generated conversational assistance
- AI Agent tool execution

## Scenario 4 — Use AI Agent

Prompt:

```text
Show my annual leave balance.
```

Agent calls:

```text
GET_LEAVE_BALANCE
```

## Scenario 5 — Submit Leave Manually

Employee requests:

```text
Annual Leave
10-Sep-2026
14-Sep-2026
5 days
```

Expected:

- Request created
- Workflow starts
- Status becomes pending

## Scenario 6 — AI Workflow Summary

Workflow creates a manager-facing summary.

Show:

- Workflow activity
- Stored AI summary
- Summary displayed to approver

## Scenario 7 — Manager Approval

Login as:

```text
MGR001
```

Demonstrate:

- My Tasks
- Open approval
- Employee balance
- Leave history
- AI summary
- Approve

Expected:

- Request becomes approved
- Leave balance updates
- Workflow completes

## Scenario 8 — Rejection

Create another request.

Manager rejects it with comments.

Expected:

- Request status becomes rejected
- Balance remains unchanged
- Employee can see rejection comments

## Scenario 9 — Authorization

Login as Employee.

Attempt to access Admin application.

Expected:

```text
Access denied
```

Login as Admin.

Show Admin pages.

Login as Super Admin.

Show additional:

```text
Users
Roles
System Settings
```

## Scenario 10 — AI Agent Creates Leave

Employee says:

```text
I want annual leave from 20 September through 22 September.
```

Agent:

1. Calculates days.
2. Checks balance.
3. Confirms details.
4. Creates leave request.
5. Starts workflow.

## Scenario 11 — Overlapping Leave Validation

Existing request:

```text
20-Sep-2026 through 22-Sep-2026
```

Attempt:

```text
21-Sep-2026 through 24-Sep-2026
```

Expected:

Validation error.

## Scenario 12 — Requirement Change

New requirement:

```text
Leave requests longer than five days require HR approval after manager approval.
```

Use coding agent to:

- Inspect project architecture
- Find workflow dependencies
- Modify implementation
- Validate
- Export
- Review Git diff

## Scenario 13 — Graphify Impact Analysis

Ask:

```text
What depends on HR_LEAVE_REQUESTS?
```

Then:

```text
Trace leave submission from the APEX page to the workflow task.
```

Use this to demonstrate project understanding.

## Scenario 14 — Role Change

New requirement:

```text
Create a MANAGER role separate from ADMIN.
```

Ask coding agent to identify:

- Authorization schemes
- Pages
- Navigation
- Workflow potential owners
- Database role mappings
