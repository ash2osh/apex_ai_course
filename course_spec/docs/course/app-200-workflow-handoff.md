# App 200 Workflow Handoff

The executable `LEAVE_APPROVAL` workflow is intentionally a guarded post-copy step. This specifications package does not include workflow or task-definition runtime source because the initialized repository must resolve installed APEX 26.1 workflow plug-in metadata through saved SQLcl connection `demo` before generating and validating those components.

## Fixed contract

- Owning application: App 200 (`HR Administration`)
- Workflow static ID: `LEAVE_APPROVAL`
- Manager task static ID: `LEAVE_MANAGER_APPROVAL`
- HR task static ID: `LEAVE_HR_APPROVAL`
- Inputs: `REQUEST_ID`, `EMPLOYEE_ID`, `MANAGER_ID`, and `REQUESTED_DAYS`
- Threshold setting: `LONG_LEAVE_THRESHOLD`, initially `5`
- Package entry point: `HR_WORKFLOW_PKG.START_LEAVE_APPROVAL`
- Package callbacks: `HR_WORKFLOW_PKG.MANAGER_OUTCOME`, `HR_WORKFLOW_PKG.HR_OUTCOME`, and `HR_WORKFLOW_PKG.RECORD_FAULT`

## Required flow

```text
Start
  → create LEAVE_MANAGER_APPROVAL task for the employee's direct manager
  → rejected: call MANAGER_OUTCOME(..., 'REJECTED', ...), then end
  → approved: call MANAGER_OUTCOME(..., 'APPROVED', ...)
      → REQUESTED_DAYS <= LONG_LEAVE_THRESHOLD: end approved
      → REQUESTED_DAYS > LONG_LEAVE_THRESHOLD:
          create LEAVE_HR_APPROVAL task for ADMIN / SUPER_ADMIN participants
          → call HR_OUTCOME with APPROVED or REJECTED
          → end
  → on workflow fault: call RECORD_FAULT
```

The package callbacks are the only owners of request state and balance transitions. Workflow activities must not update `HR_LEAVE_REQUESTS` or `HR_LEAVE_BALANCES` directly.

## Complete after copying into the template repository

1. Initialize `APEX_PROJECT_TEMPLATE` for workspace/schema `DEMO`, App IDs `100,200`, and saved connection `demo`.
2. Run the template's read-only database identity check; require session user and current schema `DEMO`.
3. Resolve current APEXlang compiler and live workflow plug-in metadata for App 200.
4. Generate the `LEAVE_APPROVAL` workflow and both task definitions from the fixed contract above and `apps/DEMO/200/application-spec.md`.
5. Format, compiler-audit, and run check-only live validation. Do not import as part of validation.
6. Import only after separate approval through the template's guarded application workflow.
7. Test both branches, rejection at each task, cancellation, fault handling, participant visibility through `APEX_TASKS` / `APEX_TASK_PARTICIPANTS`, and exactly-once balance finalization.

The current standalone environment has no saved SQLcl connection named `demo`, so steps 2–5 cannot be completed safely here.
