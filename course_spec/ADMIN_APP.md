# HR Administration Application

> This document describes the App 200 target experience. Generated application, workflow, and task runtime source are not included.

## Purpose

Provide leave approval, HR management, reporting, and system administration.

## Roles

Primary roles:

```text
ADMIN
SUPER_ADMIN
```

## Page 1 — Dashboard

Suggested KPI cards:

```text
Pending Requests
Approved This Month
Rejected This Month
Employees Currently on Leave
```

Suggested reports:

- Requests by department
- Requests by leave type
- Monthly leave trend

## Page 2 — My Tasks

Purpose:

Display Human Tasks assigned to the current approver.

Actions:

```text
Open
Approve
Reject
Claim
Release
```

Use APEX Human Tasks as the central approval mechanism.

## Page 3 — Pending Leave Requests

Columns:

```text
Request ID
Employee
Department
Leave Type
Start Date
End Date
Days
Status
Submitted Date
```

## Page 4 — Leave Request Details

Regions:

- Employee information
- Request details
- Available balance
- AI-generated summary
- Previous leave history
- Workflow status
- Approval task

## Page 5 — Employees

Admin capabilities:

- Search employees
- View profiles
- View leave history
- View balances

Super Admin capabilities may include:

- Create user
- Disable user
- Assign roles

## Page 6 — Employee Leave History

Show:

- Approved leave
- Rejected leave
- Cancelled leave
- Pending leave

## Page 7 — Leave Types

Maintain:

```text
Code
Name
Default Entitlement
Requires Balance
Active
Display Order
```

## Page 8 — Leave Balances

Admin operations:

- View balances
- Adjust balances
- Add administrative adjustment
- Review usage

## Page 9 — Workflow Monitor

Display:

- Request
- Workflow instance
- Current activity
- Current task
- Status
- Started date
- Last update

## Page 10 — Users

Authorization:

```text
SUPER_ADMIN only
```

## Page 11 — Roles

Authorization:

```text
SUPER_ADMIN only
```

## Page 12 — System Settings

Authorization:

```text
SUPER_ADMIN
```

Possible settings:

```text
DEFAULT_ANNUAL_ENTITLEMENT
ALLOW_LEAVE_CANCELLATION
LONG_LEAVE_THRESHOLD
```
