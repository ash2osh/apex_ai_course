# Episode 6: Coding Agent Prompts & Security Setup

## 🤖 Coding Agent Prompts (Custom Authentication, App 200 CRUD & Security)

### Prompt 1: Custom Authentication with Username/Password
```text
Read ../../DATABASE_MODEL.md and ../../../apps/DEMO/100/shared-components/authentications.apx.

1. Implement the custom authentication function hr_auth_pkg.authenticate(p_username, p_password) returning BOOLEAN.
   - Verify that the username exists in HR_USERS and active_yn = 'Y'.
   - Validate non-empty password credentials.
2. Configure a Custom Authentication Scheme in APEX Shared Components (HR_CUSTOM_AUTH) for both App 100 and App 200 pointing to hr_auth_pkg.authenticate.
3. Ensure Login Page (Page 9999) processes the submission via APEX_AUTHENTICATION.LOGIN.
```

### Prompt 2: Configure Create & Edit (CRUD) Pages in App 200
```text
Enhance the following administration pages in Application 200 to enable Create and Edit functionality:
1. Page 7 (Leave Types): Create & Edit leave type records in HR_LEAVE_TYPES (Code, Name, Default Entitlement, Requires Balance, Active, Display Order).
2. Page 8 (Leave Balances): Create administrative balance adjustment process calling HR_LEAVE_PKG.ADJUST_BALANCE with user ID, leave type ID, year, days delta, and audit reason.
3. Page 10 (Users): Create new employee record and edit existing user status (Department, Manager, Active Y/N).
4. Page 11 (Roles): Assign and revoke user roles (EMPLOYEE, MANAGER, ADMIN, SUPER_ADMIN) in HR_USER_ROLES.
5. Page 12 (System Settings): Edit configuration parameters.
```

### Prompt 3: Apply Multi-Tier Authorization across App 100 & App 200
```text
Apply the pre-implemented authorization schemes across both applications to secure all pages and actions:
1. App 100 (Employee Self Service):
   - Application Level: Protect with IS_EMPLOYEE.
   - Component Level: Protect the "Cancel Request" button on Page 6 using CAN_CANCEL_REQUEST.
   - Process Level: Ensure cancellation calls HR_LEAVE_PKG.CANCEL_REQUEST with :APP_USER.
2. App 200 (HR Administration):
   - Application Level: Protect with IS_ADMIN or IS_MANAGER.
   - Page Level: Protect Pages 10 (Users), 11 (Roles), and 12 (System Settings) with IS_SUPER_ADMIN.
   - Page Level: Protect Pages 7 (Leave Types) and 8 (Balances) with IS_ADMIN.
   - Component Level: Protect Approve/Reject buttons on Page 4 using CAN_APPROVE_REQUEST.
```

### Prompt 4: Security & Authentication Test Script
```text
Generate a comprehensive PL/SQL test script to verify:
1. Custom Authentication:
   - Valid credentials for EMP001, MGR001, HR001, ADMIN001 return TRUE.
   - Invalid password or non-existent username returns FALSE.
2. Role Matrix:
   - EMP001 has EMPLOYEE role; blocked from ADMIN and SUPER_ADMIN.
   - MGR001 has EMPLOYEE and MANAGER roles; can approve direct reports in App 200.
   - HR001 has EMPLOYEE and ADMIN roles; can edit Leave Types & Balances; blocked from Users/Roles.
   - ADMIN001 has SUPER_ADMIN role; full access across all pages, roles, and settings.
```
