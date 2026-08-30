# App 100 — Employee Self Service

## Identity and ownership

- Application ID: 100; alias: `EMPLOYEE-SELF-SERVICE`; workspace and parsing schema: `DEMO`.
- Oracle APEX compatibility mode: 26.1.
- `APP_USER` is the only employee identity input. Every self-service SQL source resolves it with `HR_USER_PKG.CURRENT_USER_ID`.
- Database packages own authorization, balance locking, request state changes, workflow callbacks, and AI tools. Page processes own transaction completion.
- App 200 owns workflow `LEAVE_APPROVAL` and task definitions `LEAVE_MANAGER_APPROVAL` and `LEAVE_HR_APPROVAL`, so administrative task details resolve inside the approval application. App 100 owns AI agents `EMPLOYEE_HR_AGENT` and `LEAVE_SUMMARY_AGENT`.

## Shared components

- Authorization: `IS_AUTHENTICATED`, `IS_MANAGER`, `IS_ADMIN`, `IS_SUPER_ADMIN`, and `CAN_CANCEL_REQUEST`; each calls `HR_AUTH_PKG` where applicable.
- LOVs: active leave types, the six canonical request states, and cancellation reasons.
- Navigation: one entry for every page except the detail page; pages 8 and 9 are labelled as AI experiences.
- Breadcrumbs follow page titles and return detail/timeline pages to My Leave Requests.

## Frozen page inventory

1. **Dashboard** — balance summary, request counts, recent requests, and clear empty/error messages.
2. **My Profile** — read-only profile from `HR_USERS`, `HR_DEPARTMENTS`, and the current session user.
3. **My Leave Balances** — annual entitlement, used, pending, and computed available values.
4. **Submit Leave Request** — leave type, dates, reason, working-day preview, and Submit/Cancel buttons. Validate dates and call `HR_LEAVE_PKG.CREATE_REQUEST` followed by `HR_WORKFLOW_PKG.START_LEAVE_APPROVAL` in one page transaction.
5. **My Leave Requests** — interactive report filtered by current user; opens page 6.
6. **Leave Request Details** — owner-filtered request and event summary; cancellation calls `HR_LEAVE_PKG.CANCEL_REQUEST` and commits only in the page process.
7. **Workflow Timeline** — owner-filtered chronological `HR_LEAVE_REQUEST_EVENTS` report.
8. **HR AI Assistant** — natural-language assistant with guidance, loading state, output region, and no direct DML.
9. **HR AI Agent** — APEX AI Agent chat using `EMPLOYEE_HR_AGENT` and its seven package-backed CLOB tools.

## Workflow, tasks, and AI

`LEAVE_APPROVAL` accepts request ID, employee username, manager username, and requested working days. Manager approval is first; requests longer than `LONG_LEAVE_THRESHOLD` continue to HR approval. Task completion actions call `HR_WORKFLOW_PKG` callbacks, and participants resolve normalized usernames from canonical tables.

The employee agent exposes exactly `GET_MY_PROFILE`, `GET_LEAVE_BALANCE`, `GET_MY_LEAVE_REQUESTS`, `GET_LEAVE_REQUEST`, `CALCULATE_LEAVE_DAYS`, `CREATE_LEAVE_REQUEST`, and `CANCEL_LEAVE_REQUEST`. Create and cancel require on-demand user approval. Employee tools do not accept a username or user ID. `LEAVE_SUMMARY_AGENT` is separate.

## UX, accessibility, and tests

Use Universal Theme, responsive one-column forms, report overflow support, visible keyboard focus, meaningful labels, and textual status. Every data region has no-data text; buttons show processing feedback; package errors surface as safe inline notifications.

Test as `EMP001`: current profile and 2026 balance scope, valid submission, overlap and excess-balance failure, denial of another employee's detail, idempotent cancellation, and current-user scope for all seven AI tools.
