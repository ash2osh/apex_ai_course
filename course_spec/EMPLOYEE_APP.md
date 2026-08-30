# Employee Self Service Application

> This document describes the App 100 target experience. Generated application runtime source is not included.

## Purpose

Allow employees to manage their personal leave information and interact with HR AI features.

## Page 1 — Dashboard

Suggested content:

```text
Welcome, Ahmed

Annual Leave Available: 14
Pending Requests: 1
Next Approved Leave: 10-Sep-2026
```

Regions:

- Leave balance cards
- Upcoming leave
- Recent requests
- Quick actions
- AI Assistant

## Page 2 — My Profile

Display:

```text
Employee Number
Full Name
Email
Department
Manager
Account Status
```

Initial tutorial:

Read-only profile.

## Page 3 — My Leave Balance

Display one card per leave type.

Example:

```text
Annual Leave
Entitlement: 21
Used: 7
Pending: 0
Available: 14
```

## Page 4 — Submit Leave Request

Items:

```text
Leave Type
Start Date
End Date
Calculated Days
Reason
```

Actions:

```text
Submit
Cancel
```

Validations:

- Valid dates
- Positive duration
- No overlap
- Sufficient balance

## Page 5 — My Leave Requests

Suggested filters:

```text
All
Pending
Approved
Rejected
Cancelled
```

Columns:

```text
Request ID
Leave Type
Start Date
End Date
Days
Status
Submitted
```

## Page 6 — Leave Request Details

Show:

- Request information
- Current status
- Manager
- Approval comments
- AI summary
- Workflow timeline

Actions:

```text
Cancel Request
```

when permitted.

## Page 7 — Workflow Timeline

Example:

```text
✓ Submitted
✓ Validation Passed
✓ AI Summary Generated
● Waiting for Manager Approval
○ Balance Update
○ Completed
```

## Page 8 — HR AI Assistant

Use for:

- Leave questions
- Policy questions
- Process explanation

## Page 9 — HR AI Agent

Use for:

- Get leave balance
- Retrieve requests
- Calculate leave days
- Submit leave
- Cancel eligible leave

## Navigation

Suggested menu:

```text
Home
My Profile
Leave
  - Balances
  - Request Leave
  - My Requests
HR Assistant
```
