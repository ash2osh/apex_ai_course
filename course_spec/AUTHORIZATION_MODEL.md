# Authorization Model

> This is a target authorization specification; executable schemes and package implementation are not included.

## Roles

### EMPLOYEE

Can:

- Access Employee Self Service
- View own profile
- View own leave balance
- Submit leave requests
- View own leave requests
- Cancel eligible own requests
- Use Employee AI Assistant
- Use Employee AI Agent

Cannot:

- View other employees' private HR data
- Approve leave
- Manage users
- Manage roles

## ADMIN

Can:

- Access HR Administration
- View assigned approval tasks
- Approve or reject leave
- View employees
- View leave history
- Maintain leave balances
- Maintain leave types
- Monitor workflow

Cannot:

- Assign SUPER_ADMIN role
- Change protected system settings unless explicitly allowed

## SUPER_ADMIN

Can:

- Access all Admin functionality
- Manage users
- Manage roles
- Manage application configuration
- Access system-level administration

## Suggested APEX Authorization Schemes

```text
IS_EMPLOYEE
IS_ADMIN
IS_SUPER_ADMIN
CAN_APPROVE_LEAVE
CAN_MANAGE_USERS
CAN_MANAGE_ROLES
```

## Suggested Database Functions

```text
HR_AUTH_PKG.HAS_ROLE
HR_AUTH_PKG.IS_ADMIN
HR_AUTH_PKG.IS_SUPER_ADMIN
HR_AUTH_PKG.CAN_APPROVE_REQUEST
```

## Access Matrix

| Function | Employee | Admin | Super Admin |
|---|---:|---:|---:|
| Employee App | Yes | Yes | Yes |
| View Own Profile | Yes | Yes | Yes |
| Submit Leave | Yes | Yes | Yes |
| View Own Requests | Yes | Yes | Yes |
| Admin App | No | Yes | Yes |
| Approve Leave | No | Yes | Yes |
| Manage Leave Types | No | Yes | Yes |
| Manage Users | No | No | Yes |
| Manage Roles | No | No | Yes |
| System Settings | No | Limited | Yes |

## Security Rules

1. Hiding navigation entries is not enough.
2. Protect pages using authorization schemes.
3. Protect sensitive regions and buttons.
4. Protect server-side processes.
5. Enforce important authorization rules in PL/SQL packages.
6. AI Tools must use the authenticated user context.
7. AI Tools must not accept arbitrary user IDs when the operation is meant to be self-service.
