# Employee Self Service (app 100)

## Purpose

Employee Self Service (App 100) allows employees in workspace and schema `DEMO` to view their personal profile, monitor annual and category leave balances, submit new leave requests, track request approval progress across workflows, inspect audit timelines, cancel eligible pending requests, and interact with HR AI Assistant and AI Agent capabilities.

## Architecture Notes

- Application ID: `100`; Alias: `EMPLOYEE-SELF-SERVICE`; Parsing Schema: `DEMO`.
- Compatibility Mode: `26.1`.
- `APP_USER` is the sole employee identity input; page queries and package processes resolve identity through `HR_USER_PKG.CURRENT_USER_ID` or `HR_USER_PKG.CURRENT_USERNAME`.
- Database packages (`HR_LEAVE_PKG`, `HR_WORKFLOW_PKG`, `HR_AUTH_PKG`, `HR_AI_PKG`, `HR_USER_PKG`) own authorization, balance locking, state transitions, workflow orchestration, and AI tool execution.
- App 100 initiates leave approval by calling `HR_LEAVE_PKG.CREATE_REQUEST` and `HR_WORKFLOW_PKG.START_LEAVE_APPROVAL` in one caller-owned transaction.
- App 200 owns the underlying workflow `LEAVE_APPROVAL` and human task definitions `LEAVE_MANAGER_APPROVAL` and `LEAVE_HR_APPROVAL`.
- App 100 owns the conversational AI assistant and AI agents (`EMPLOYEE_HR_AGENT`, `LEAVE_SUMMARY_AGENT`).

## Known Patterns

- **Session Security**: Reports, cards, and detail queries filter strictly by `HR_USER_PKG.CURRENT_USER_ID`. No item or URL parameter accepts an arbitrary user ID or employee username for self-service operations.
- **Balance Reservation**: Submission moves days to `PENDING_DAYS`. Manager approval moves days to `USED_DAYS` (or forwards to HR if > 5 days). Rejection or cancellation releases `PENDING_DAYS`.
- **Caller-Owned Transactions**: Page processes explicitly call database package procedures and manage the final `COMMIT;`.
- **Breadcrumb Navigation**: Detail and timeline pages return to `My Leave Requests` (Page 5).

## Known Issues / Gotchas

- APEXlang `.apx` files must strictly use Unix LF line endings; CRLF line endings will cause the compiler to fail.
- Cancellation is permitted only for requests owned by the current user that are still in a pending approval state (`CAN_CANCEL_REQUEST`).

## Last Updated

2026-09-01 — Initialized complete App 100 specifications and 9-page implementation matching course design.

