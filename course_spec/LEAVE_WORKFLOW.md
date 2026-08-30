# Leave Approval Workflow

> This is the target workflow contract. Workflow and Human Task runtime artifacts are generated later from the App 200 specification.

## Workflow Name

```text
LEAVE_APPROVAL
```

## Goal

Process an employee leave request from submission through final approval or rejection.

## Basic Flow

```text
START
  |
  v
VALIDATE REQUEST
  |
  v
CHECK BALANCE
  |
  +------ insufficient ------> REJECT
  |
  v
GENERATE AI SUMMARY
  |
  v
MANAGER APPROVAL TASK
  |
  +------ rejected ----------> UPDATE REQUEST
  |
  v
APPROVED
  |
  v
UPDATE LEAVE BALANCE
  |
  v
NOTIFY EMPLOYEE
  |
  v
END
```

## Workflow Variables

Suggested variables:

```text
REQUEST_ID
EMPLOYEE_ID
MANAGER_ID
LEAVE_TYPE_ID
START_DATE
END_DATE
REQUESTED_DAYS
REQUEST_REASON
AI_SUMMARY
APPROVAL_RESULT
```

## Validation

Before creating approval tasks:

- Employee must be active.
- Leave type must be active.
- Start date must be valid.
- End date must not precede start date.
- Requested days must be greater than zero.
- Request must not overlap an existing active leave request.
- Available balance must be sufficient when the leave type requires a balance.

## AI Workflow Step

Generate a short manager-facing summary.

Example input:

```text
Employee:
Ahmed Employee

Leave Type:
Annual Leave

Dates:
10-Sep-2026 through 14-Sep-2026

Reason:
I need a few days with my family.
```

Expected output:

```text
Ahmed requests five days of annual leave from 10-Sep-2026 through 14-Sep-2026 for personal reasons.
```

## Human Task

Task:

```text
LEAVE_MANAGER_APPROVAL
```

Potential owner:

```text
Employee's manager
```

Available actions:

```text
APPROVE
REJECT
```

Optional comments:

```text
APPROVER_COMMENTS
```

## Conditional Approval Enhancement

Optional rule:

```text
Requested Days <= 5
    -> Manager Approval

Requested Days > 5
    -> Manager Approval
    -> HR Approval
```

## Status Mapping

```text
Workflow Started   -> PENDING
Approved           -> APPROVED
Rejected           -> REJECTED
Cancelled          -> CANCELLED
Workflow Error     -> PENDING / ERROR handling strategy
```

## Cancellation Rule

Suggested:

An employee may cancel only if:

- The request belongs to the current user.
- Status is `SUBMITTED` or `PENDING`.
- Leave has not already started.
- Workflow state allows cancellation.
