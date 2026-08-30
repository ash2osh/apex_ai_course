# App 200 — HR Administration

## Identity and authorization

- Application ID: 200; alias: `HR-ADMINISTRATION`; workspace and parsing schema: `DEMO`; compatibility mode: 26.1.
- Page access uses package-backed `IS_MANAGER`, `IS_ADMIN`, and `IS_SUPER_ADMIN`. Navigation visibility never replaces page, process, and package authorization.
- Managers act only on direct-report requests. Administrators review company-wide requests. Only super administrators manage users, roles, and settings.
- App 200 owns workflow `LEAVE_APPROVAL` and both Human Task definitions. `HR_WORKFLOW_PKG.START_LEAVE_APPROVAL` therefore starts application 200 explicitly while retaining the employee from App 100 as the workflow initiator.

## Shared components

- Authorization: `IS_MANAGER`, `IS_ADMIN`, `IS_SUPER_ADMIN`, and `CAN_APPROVE_REQUEST` backed by `HR_AUTH_PKG`.
- LOVs: employees, departments, active leave types, roles, request states, and balance year.
- Task reports use documented `APEX_TASKS` and `APEX_TASK_PARTICIPANTS`, comparing usernames with `UPPER`.

## Frozen page inventory

1. **Dashboard** — request-state totals, upcoming leave, and workload summaries (`IS_MANAGER` or `IS_ADMIN`).
2. **My Tasks** — tasks joined to participants for normalized `APP_USER`.
3. **Pending Leave Requests** — managers see direct reports; administrators see all pending requests.
4. **Leave Request Details** — request, employee, balance, and timeline; actions use package or Human Task APIs.
5. **Employees** — employee, department, and manager report (`IS_ADMIN`).
6. **Employee Leave History** — selected employee's requests and events (`IS_ADMIN`).
7. **Leave Types** — administrative maintenance (`IS_ADMIN`).
8. **Leave Balances** — annual balances; adjustment calls `HR_LEAVE_PKG.ADJUST_BALANCE` (`IS_ADMIN`).
9. **Workflow Monitor** — workflow/request correlation and errors (`IS_ADMIN`).
10. **Users** — user maintenance (`IS_SUPER_ADMIN`).
11. **Roles** — role assignments (`IS_SUPER_ADMIN`).
12. **System Settings** — controlled settings maintenance (`IS_SUPER_ADMIN`).

## UX and tests

Use Universal Theme, responsive reports and forms, keyboard-complete actions, labelled fields, textual states, actionable no-data messages, standard loading feedback, and safe errors. Test manager direct-report enforcement, admin visibility, super-admin page protection, package-owned balance adjustment, and the documented task views.
