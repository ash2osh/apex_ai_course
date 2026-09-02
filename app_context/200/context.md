# App 200 — HR Administration Context

## 1. Application Overview
- **Application ID**: 200
- **Alias**: `HR-ADMINISTRATION`
- **Parsing Schema**: `DEMO`
- **Purpose**: Managerial approvals, HR management, employee directory, leave balance adjustments, and super-admin system administration.

## 2. Roles & Authorization Mapping
- **`MANAGER`** (`IS_MANAGER`): Direct-report approvals, tasks, pending list.
- **`ADMIN`** (`IS_ADMIN`): Company-wide leave history, employee directory, leave types catalog, balance adjustments, workflow monitor.
- **`SUPER_ADMIN`** (`IS_SUPER_ADMIN`): User accounts management, role mappings, system settings.
- **Action Auth (`CAN_APPROVE_REQUEST`)**: Enforces manager direct-report ownership or admin rights for leave request decisions.

## 3. Page Inventory
1. **Dashboard** (P1): Administrative KPIs, pending workload, quick links.
2. **My Tasks** (P2): Human Tasks and assigned approval actions.
3. **Pending Leave Requests** (P3): Role-filtered pending requests report.
4. **Leave Request Details** (P4): Full request review with Approve/Reject actions and audit trail.
5. **Employees** (P5): Employee directory.
6. **Employee Leave History** (P6): Detailed history for selected employee.
7. **Leave Types** (P7): Policy catalog.
8. **Leave Balances** (P8): Balances and administrative adjustment tool calling `HR_LEAVE_PKG.ADJUST_BALANCE`.
9. **Workflow Monitor** (P9): Workflow correlation and error tracking.
10. **Users** (P10): Super admin user accounts maintenance.
11. **Roles** (P11): Role assignment administration.
12. **System Settings** (P12): System parameters configuration.

