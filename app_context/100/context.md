# Employee Self Service (app 100)

## Purpose

Employee Self Service (App 100) allows employees in workspace and schema `DEMO` to view their personal profile, monitor annual and category leave balances, submit new leave requests, track request approval progress across workflows, inspect audit timelines, cancel eligible pending requests, and interact with the HR AI Assistant and AI Agent capabilities.

## Architecture Notes

- Application ID: `100`; Alias: `EMPLOYEE-SELF-SERVICE`; Parsing Schema: `DEMO`.
- Compatibility Mode: `26.1`.
- `APP_USER` is the sole employee identity input; page queries and package processes resolve identity through `HR_USER_PKG.CURRENT_USER_ID` or `HR_USER_PKG.CURRENT_USERNAME`.
- Database packages (`HR_LEAVE_PKG`, `HR_WORKFLOW_PKG`, `HR_AUTH_PKG`, `HR_AI_PKG`, `HR_USER_PKG`) own authorization, balance locking, state transitions, workflow orchestration, and AI tool execution.
- App 100 initiates leave approval by calling `HR_LEAVE_PKG.CREATE_REQUEST` and `HR_WORKFLOW_PKG.START_LEAVE_APPROVAL` in one caller-owned transaction.
- App 200 owns the underlying workflow `LEAVE_APPROVAL` and human task definitions `LEAVE_MANAGER_APPROVAL` and `LEAVE_HR_APPROVAL`.
- App 100 owns the conversational AI assistant and AI agent (`portal-helper`).

## Page Inventory
1. **Dashboard** (P1): Employee KPI metrics, quick actions, balance summary, and embedded AI Agent (`IS_EMPLOYEE`).
2. **My Profile** (P2): Employee personal information and manager hierarchy (`IS_EMPLOYEE`).
3. **My Leave Balances** (P3): Category leave balance cards and balance history (`IS_EMPLOYEE`).
4. **Submit Leave Request** (P4): Interactive request submission form with dynamic working days calculation and workflow instantiation (`IS_EMPLOYEE`).
5. **My Leave Requests** (P5): Interactive report of historical and pending leave requests (`IS_EMPLOYEE`).
6. **Leave Request Details** (P6): Detailed request review, cancellation action, and audit trail strictly scoped to session user (`IS_EMPLOYEE`).
7. **Workflow Timeline** (P7): Visual audit timeline of request events strictly scoped to session user (`IS_EMPLOYEE`).
8. **Login** (P9999): Application authentication page.

## Known Patterns

- **Session Security**: All user pages require `@is-employee`. Reports, cards, and detail queries filter strictly by `HR_USER_PKG.CURRENT_USER_ID`. No item or URL parameter accepts an arbitrary user ID or employee username for self-service operations.
- **Balance Reservation**: Submission moves days to `PENDING_DAYS`. Manager approval moves days to `USED_DAYS` (or forwards to HR if > 5 days). Rejection or cancellation releases `PENDING_DAYS`.
- **Caller-Owned Transactions**: Page processes explicitly call database package procedures and manage the final `COMMIT;`.
- **Breadcrumb Navigation**: Detail and timeline pages return to `My Leave Requests` (Page 5).

## Known Issues / Gotchas

- APEXlang `.apx` files must strictly use Unix LF line endings; CRLF line endings will cause the compiler to fail.
- Cancellation is permitted only for requests owned by the current user that are still in a pending approval state (`CAN_CANCEL_REQUEST`).

## Last Updated

2026-09-12 — Synchronized authorization schemes (`IS_EMPLOYEE` across all pages 1–7), corrected AI agent documentation to `portal-helper`, and documented row-level session security boundaries.
