# Episode 12: Coding Agent Prompts & Impact Analysis

## 🤖 Coding Agent Prompts (Requirement Change, Debugging & Verification)

### Prompt 1: Graphify Dependency Analysis
```text
Find all database packages, workflow activities, and tables dependent on leave request duration and approval steps.
Summarize the blast radius before implementing changes.
```

### Prompt 2: Implement Multi-Tier Escalation
```text
New Requirement:
Requests > 5 days require HR Admin approval after Manager approval.
Requests <= 5 days remain single Manager approval.
Update LEAVE_APPROVAL workflow branches, HR_LEAVE_PKG status transitions, and test scenarios.
```

### Prompt 3: Diagnosing Workflow Termination & Double-Deduction
```text
Workflows are being terminated because emp001 does not have balance.
Trace the workflow execution history and balance calculation to determine why HAVE_BALANCE is taking the NO BALANCE branch.
```

### Prompt 4: Automated Verification & APEX Export
```text
Create and execute an automated verification script that tests:
1. Requests <= 5 days finalized directly by manager.
2. Requests > 5 days escalating to HR admin and approved.
3. Requests > 5 days rejected at HR stage, verifying reserved pending days are released cleanly.
Export App 200 and validate with uc-apx validate.
```
