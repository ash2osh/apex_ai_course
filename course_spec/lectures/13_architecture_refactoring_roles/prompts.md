# Episode 13: Coding Agent Prompts — Debugging & Workflow Recovery

## 🤖 Coding Agent Prompts (Debugging, Cancellation & Balance Recovery)

### Prompt 1: Diagnosing Workflow Termination & Balance Trap
```text
Investigate why leave requests are taking the NO_BALANCE branch in the LEAVE_APPROVAL workflow.
Trace the balance calculation in HR_LEAVE_PKG.CREATE_REQUEST and compare it with the condition inside the HAVE_BALANCE activity.
Explain why requests are failing and provide the corrected switch expression.
```

### Prompt 2: Implementing Employee Request Cancellation & Workflow Termination
```text
Implement safe employee request cancellation:
1. Ensure HR_AUTH_PKG.CAN_CANCEL_REQUEST allows employees to cancel their own requests in PENDING_MANAGER_APPROVAL or PENDING_HR_APPROVAL before the leave start date.
2. In HR_LEAVE_PKG.CANCEL_REQUEST, release reserved PENDING_DAYS back to available balance.
3. Terminate or cancel any active APEX workflow instance associated with the request.
4. Record an auditable event in HR_LEAVE_REQUEST_EVENTS.
```

### Prompt 3: Writing an Orphaned Balance Reconciliation Script
```text
Write an idempotent SQL reconciliation script to find any leave requests with terminated or faulted workflows that still have pending days reserved.
Cancel those orphaned requests and recover the pending days back to available balance for the affected employees.
```

### Prompt 4: Automated Verification of Edge Cases
```text
Create and run a self-verifying test script that validates:
1. Successful cancellation of a pending request with exact balance restoration.
2. Security check preventing employees from cancelling requests after the start date.
3. Workflow successfully proceeding when available days equals requested days.
```
