# Episode 6: Coding Agent Prompts & Security Setup

## 🤖 Coding Agent Prompts (APEX Authorization & Security Configuration)

### Prompt 1: Configure APEX Authorization Schemes in Shared Components
```text
Read ../../AUTHORIZATION_MODEL.md and ../../../apps/DEMO/100/shared-components/authorizations.apx.

Configure the reusable APEX Authorization Schemes in Shared Components for both App 100 and App 200 leveraging the pre-created HR_AUTH_PKG functions:
1. IS_EMPLOYEE: Calls hr_auth_pkg.is_employee(:APP_USER) (Evaluation Point: Once per session).
2. IS_MANAGER: Calls hr_auth_pkg.is_manager(:APP_USER) (Evaluation Point: Once per session).
3. IS_ADMIN: Calls hr_auth_pkg.is_admin(:APP_USER) (Evaluation Point: Once per session).
4. IS_SUPER_ADMIN: Calls hr_auth_pkg.is_super_admin(:APP_USER) (Evaluation Point: Once per session).
5. CAN_CANCEL_REQUEST: Calls hr_auth_pkg.can_cancel_request(:APP_USER, to_number(:P6_REQUEST_ID)) (Evaluation Point: Must Not Be Cached).
6. CAN_APPROVE_REQUEST: Calls hr_auth_pkg.can_approve_request(:APP_USER, to_number(:P4_REQUEST_ID)) (Evaluation Point: Must Not Be Cached).

Provide meaningful user-facing error messages for each authorization scheme.
```

### Prompt 2: Apply Multi-Tier Authorization across App 100 & App 200
```text
Apply the authorization schemes across both applications:
1. App 100 (Employee Self Service):
   - Application Level: Protect with IS_EMPLOYEE.
   - Component Level: Protect the "Cancel Request" button on Page 6 using CAN_CANCEL_REQUEST.
   - Process Level: Ensure cancellation calls HR_LEAVE_PKG.CANCEL_REQUEST with :APP_USER.
2. App 200 (HR Administration):
   - Application Level: Protect with IS_ADMIN or IS_MANAGER.
   - Page Level: Protect Pages 10 (Users), 11 (Roles), and 12 (System Settings) with IS_SUPER_ADMIN.
   - Component Level: Protect Approve/Reject buttons on Page 4 using CAN_APPROVE_REQUEST.
```

### Prompt 3: Security Validation & Test Script
```text
Generate a comprehensive PL/SQL test script to verify positive and negative authorization paths across all seed users:
1. EMP001 (Ahmed Employee): Must have EMPLOYEE role; must NOT have MANAGER, ADMIN, or SUPER_ADMIN access; must be blocked from administrative operations.
2. MGR001 (Mona Manager): Must have EMPLOYEE and MANAGER roles; can approve requests for direct reports in App 200.
3. HR001 (Hala HR): Must have EMPLOYEE and ADMIN roles; can approve company-wide requests; must NOT have SUPER_ADMIN access to user/role management.
4. ADMIN001 (Samira Super Admin): Must have SUPER_ADMIN access across all applications, roles, and settings.
```
