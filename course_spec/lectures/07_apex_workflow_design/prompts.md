# Episode 7: Coding Agent Prompts & Workflow Setup

## 🤖 Coding Agent Prompts (Workflow Orchestration)

### Prompt 1: LEAVE_APPROVAL Workflow Definition
```text
Read ../../LEAVE_WORKFLOW.md.
Design the state machine for the APEX Workflow LEAVE_APPROVAL:
1. Define workflow variables: REQUEST_ID, EMPLOYEE_ID, MANAGER_ID, REQUESTED_DAYS, APPROVAL_RESULT.
2. Define activity sequence: Validate Request -> Check Balance -> AI Summary -> Human Task -> Finalize.
3. Write PL/SQL helper procedures in HR_WORKFLOW_PKG to initiate and synchronize workflow instances.
```
