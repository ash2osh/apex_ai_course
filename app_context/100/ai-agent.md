# App 100 AI Agent

`portal-helper` (name: `portal helper`) is an embedded GenAI agent configured with service `open-ai-assistant` within the Employee Self Service application (App 100) on the Employee Dashboard.

The agent interacts in Egyptian Arabic with strict single-user privacy guardrails (scoped strictly to `&APP_USER.`, rejecting third-party employee inquiries).

It exposes eight AI tools returning `CLOB` JSON serialized via `JSON_OBJECT`:
1. `get_my_profile`: Personal profile details.
2. `get_my_balance`: Personal leave balance for a given leave type code (ANNUAL, SICK, EMERGENCY, UNPAID).
3. `get_my_leave_requests`: List of employee's own leave requests.
4. `get_leave_request`: Details and timeline for employee's own leave request.
5. `calculate_leave_days`: Calculates working days (Sunday–Thursday) between dates.
6. `create_leave_request`: Submits a leave request on behalf of the employee with transactional savepoints.
7. `cancel_leave_request`: Cancels an eligible pending request owned by the employee with transactional savepoints.
8. `generate_request_summary`: Generates an AI summary for a request, enforcing ownership (`r.user_id = l_caller_id OR hr_auth_pkg.is_admin`).

Database package `HR_AI_PKG` backs all tool implementations.
