# App 200 Database Model

App 200 uses all nine shared `HR_` tables and the five packages `HR_USER_PKG`, `HR_AUTH_PKG`, `HR_LEAVE_PKG`, `HR_WORKFLOW_PKG`, and `HR_AI_PKG`.

Balance maintenance calls `HR_LEAVE_PKG.ADJUST_BALANCE`; pages never perform direct balance DML. Approval callbacks lock the request and matching annual balance, accept only explicit source states, and write `HR_LEAVE_REQUEST_EVENTS` alongside the state change.
