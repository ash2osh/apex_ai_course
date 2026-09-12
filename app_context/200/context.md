# App 200 — HR Administration Context

## 1. Application Overview
- **Application ID**: 200
- **Alias**: `HR-ADMINISTRATION`
- **Parsing Schema**: `DEMO`
- **Purpose**: Managerial approvals, HR management, employee directory, leave balance adjustments, unified task management, and super-admin system administration.

## 2. Roles & Authorization Mapping
- **`MANAGER`** (`IS_MANAGER` / `IS_MANAGER_OR_ADMIN`): Direct-report approvals, tasks, pending list, and unified task console.
- **`ADMIN`** (`IS_ADMIN` / `IS_MANAGER_OR_ADMIN`): Company-wide leave history, employee directory, leave types catalog, balance adjustments, workflow monitor, and workflow administration.
- **`SUPER_ADMIN`** (`IS_SUPER_ADMIN`): User accounts management, role mappings, system settings, with protection preventing lockout/deletion of the last active super admin.
- **Action Auth (`CAN_APPROVE_REQUEST`)**: Enforces manager direct-report ownership or admin rights for leave request decisions.

## 3. Page Inventory
1. **Dashboard** (P1): Administrative KPIs, pending workload, quick links (`IS_MANAGER_OR_ADMIN`).
2. **My Tasks** (P2): Assigned approval actions report (`IS_MANAGER_OR_ADMIN`).
3. **Pending Leave Requests** (P3): Role-filtered pending requests report (`IS_MANAGER_OR_ADMIN`).
4. **Leave Request Details** (P4): Full request review with Approve/Reject actions and audit trail (`CAN_APPROVE_REQUEST`).
5. **Employees** (P5): Employee directory (`IS_ADMIN`).
6. **Employee Leave History** (P6): Detailed history for selected employee (`IS_ADMIN`).
7. **Leave Types** (P7): Policy catalog (`IS_ADMIN`).
8. **Leave Balances** (P8): Balances and administrative adjustment tool calling `HR_LEAVE_PKG.ADJUST_BALANCE` (`IS_ADMIN`).
9. **Workflow Monitor** (P9): Workflow correlation and error tracking (`IS_ADMIN`).
10. **Users** (P10): Super admin user accounts maintenance (`IS_SUPER_ADMIN`).
11. **Roles** (P11): Role assignment administration (`IS_SUPER_ADMIN`).
12. **System Settings** (P12): System parameters configuration (`IS_SUPER_ADMIN`).
13. **Task Details Modal** (P17): Unified Human Task modal dialog (`IS_MANAGER_OR_ADMIN`).
14. **Unified Tasks** (P100): Oracle APEX Unified Task Console (`IS_MANAGER_OR_ADMIN`).
15. **Workflow Administration** (P200): Administrative workflow instance management (`IS_ADMIN`).
16. **Workflow Admin Form** (P201): Workflow admin drawer detail form (`IS_ADMIN`).
17. **Login** (P9999): Application authentication page.
18. **Global Page** (P0): Global page components and notifications.

## 4. Known Patterns & Security Boundaries
- **Task & Workflow Correlation**: When approving or rejecting requests on Page 4, processes query `apex_tasks` and invoke `apex_approval.complete_task` so unified tasks stay synchronized with workflow state transitions.
- **Declarative Navigation**: Interactive Report drilldown columns use `type: link` with `clearCache` target properties rather than raw URL expressions, ensuring automatic session checksum generation.
- **Safe Administrative Adjustments**: `HR_LEAVE_REQUEST_EVENTS.REQUEST_ID` is nullable, allowing administrative balance adjustments (`ADJUST_BALANCE`) without raising `ORA-01400`.
- **Super Admin Lockout Prevention**: Deactivation on Page 10 and role revoking on Page 11 enforce `assert_can_deactivate_user` and `assert_can_revoke_role` respectively to prevent locking out the system.

## 5. Last Updated
2026-09-12 — Expanded page inventory to all 18 pages, documented authorization mappings and task completion synchronization, and recorded schema adjustment conventions.
