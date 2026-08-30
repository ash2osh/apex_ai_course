# HR AI Agent and AI Tools

> This is the target tool contract. Agent definitions and package-backed tool implementation are not included.

## Agent Name

```text
EMPLOYEE_HR_AGENT
```

## Purpose

Allow employees to use natural language to retrieve their HR information and perform controlled leave actions.

## Design Principle

The AI Agent may only access capabilities explicitly exposed through approved AI Tools.

## Tool 1 — GET_MY_PROFILE

Purpose:

Return the authenticated employee's profile.

Inputs:

```text
None
```

Output:

```json
{
  "user_id": 101,
  "full_name": "Ahmed Employee",
  "email": "ahmed@example.com",
  "department": "IT"
}
```

Security:

- Resolve employee from authenticated session.
- Do not accept arbitrary `USER_ID`.

## Tool 2 — GET_LEAVE_BALANCE

Purpose:

Return available leave balance.

Inputs:

```text
LEAVE_TYPE_CODE
```

Output:

```json
{
  "leave_type": "ANNUAL",
  "entitlement": 21,
  "used": 7,
  "pending": 0,
  "available": 14
}
```

## Tool 3 — GET_MY_LEAVE_REQUESTS

Purpose:

Return employee leave requests.

Optional inputs:

```text
STATUS
DATE_FROM
DATE_TO
```

## Tool 4 — GET_LEAVE_REQUEST

Purpose:

Return details for one request owned by the current employee.

Input:

```text
REQUEST_ID
```

Security:

Request must belong to authenticated user.

## Tool 5 — CALCULATE_LEAVE_DAYS

Inputs:

```text
START_DATE
END_DATE
```

Output:

```text
REQUESTED_DAYS
```

Future enhancement:

Exclude:

- Weekends
- Company holidays

## Tool 6 — CREATE_LEAVE_REQUEST

Inputs:

```text
LEAVE_TYPE_CODE
START_DATE
END_DATE
REASON
```

Responsibilities:

1. Resolve authenticated employee.
2. Calculate requested days.
3. Validate dates.
4. Validate overlap.
5. Validate leave balance.
6. Create request.
7. Start workflow.
8. Return request ID and status.

## Tool 7 — CANCEL_LEAVE_REQUEST

Input:

```text
REQUEST_ID
```

Responsibilities:

- Verify request ownership.
- Verify current status.
- Cancel workflow if required.
- Update request status.

## Tools Not Exposed to Employees

Do not expose:

```text
APPROVE_LEAVE
REJECT_LEAVE
CHANGE_USER_ROLE
UPDATE_ANOTHER_EMPLOYEE_BALANCE
```

## Example Conversation

```text
User:
How much annual leave do I have?

Agent:
Calls GET_LEAVE_BALANCE.

Response:
You currently have 14 annual leave days available.
```

## Transaction Example

```text
User:
I want annual leave from 10 September to 14 September.

Agent:
1. Calls CALCULATE_LEAVE_DAYS.
2. Calls GET_LEAVE_BALANCE.
3. Confirms the request details.
4. Calls CREATE_LEAVE_REQUEST.
5. Returns the new request number.
```

## Admin Agent Future Enhancement

Possible tools:

```text
GET_PENDING_APPROVALS
GET_EMPLOYEE_LEAVE_HISTORY
GET_TEAM_LEAVE_CALENDAR
SUMMARIZE_REQUEST
```

Approval should remain a Human Task in the initial tutorial.
