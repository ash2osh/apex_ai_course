# Database Model

> This document specifies the target model. DDL, PL/SQL package bodies, seed data, migrations, and installers are generated later inside the initialized template repository.

## Naming Convention

Suggested prefix:

```text
HR_
```

## Tables

### HR_USERS

Purpose:

Store application users and employee identity.

Suggested columns:

```text
USER_ID
USERNAME
FULL_NAME
EMAIL
MANAGER_ID
DEPARTMENT_ID
ACTIVE_YN
CREATED_AT
CREATED_BY
UPDATED_AT
UPDATED_BY
```

## HR_ROLES

Suggested columns:

```text
ROLE_ID
ROLE_CODE
ROLE_NAME
DESCRIPTION
```

Suggested role codes:

```text
EMPLOYEE
ADMIN
SUPER_ADMIN
```

Optional future role:

```text
MANAGER
```

## HR_USER_ROLES

Suggested columns:

```text
USER_ID
ROLE_ID
CREATED_AT
CREATED_BY
```

## HR_DEPARTMENTS

Suggested columns:

```text
DEPARTMENT_ID
DEPARTMENT_CODE
DEPARTMENT_NAME
MANAGER_ID
ACTIVE_YN
```

## HR_LEAVE_TYPES

Suggested columns:

```text
LEAVE_TYPE_ID
LEAVE_TYPE_CODE
LEAVE_TYPE_NAME
DEFAULT_ENTITLEMENT
REQUIRES_BALANCE_YN
ACTIVE_YN
DISPLAY_ORDER
```

Examples:

```text
ANNUAL
SICK
UNPAID
EMERGENCY
```

## HR_LEAVE_BALANCES

Suggested columns:

```text
BALANCE_ID
USER_ID
LEAVE_TYPE_ID
BALANCE_YEAR
ENTITLEMENT_DAYS
USED_DAYS
PENDING_DAYS
ADJUSTMENT_DAYS
```

Derived balance:

```text
AVAILABLE_DAYS =
ENTITLEMENT_DAYS
+ ADJUSTMENT_DAYS
- USED_DAYS
- PENDING_DAYS
```

## HR_LEAVE_REQUESTS

Suggested columns:

```text
REQUEST_ID
USER_ID
LEAVE_TYPE_ID
START_DATE
END_DATE
REQUESTED_DAYS
REASON
STATUS
AI_SUMMARY
WORKFLOW_ID
CREATED_AT
CREATED_BY
UPDATED_AT
UPDATED_BY
```

Suggested statuses:

```text
DRAFT
SUBMITTED
PENDING
APPROVED
REJECTED
CANCELLED
COMPLETED
```

## Optional Table — HR_SYSTEM_SETTINGS

Suggested columns:

```text
SETTING_CODE
SETTING_VALUE
DESCRIPTION
UPDATED_AT
UPDATED_BY
```

## Relationships

```text
HR_USERS
  |
  +-- HR_USER_ROLES
  |      |
  |      +-- HR_ROLES
  |
  +-- HR_LEAVE_BALANCES
  |
  +-- HR_LEAVE_REQUESTS
  |
  +-- HR_USERS.MANAGER_ID
```

## Recommended Packages

### HR_USER_PKG

Responsibilities:

- Get current user
- Get employee profile
- Validate active account

### HR_AUTH_PKG

Responsibilities:

- Check roles
- Check authorization
- Check manager relationships

### HR_LEAVE_PKG

Responsibilities:

- Calculate leave days
- Validate overlap
- Validate balance
- Create request
- Cancel request
- Approve request
- Reject request
- Update balances

### HR_WORKFLOW_PKG

Responsibilities:

- Start workflow
- Handle workflow completion
- Synchronize request status

### HR_AI_PKG

Responsibilities:

- AI Tool wrappers
- Safe employee data retrieval
- AI action validation

## Sample Users

```text
EMP001  Ahmed Employee     EMPLOYEE
MGR001  Sarah Manager      EMPLOYEE, ADMIN
ADM001  HR Admin           ADMIN
SYS001  System Admin       SUPER_ADMIN
```
