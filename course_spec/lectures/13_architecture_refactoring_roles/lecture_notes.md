# Lecture 13: AI-Assisted System Debugging & Workflow Recovery

## 📋 Lecture Metadata
* **Episode**: 13 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: Solution Architects, Senior APEX Developers, Database Engineers
* **Prerequisites**: Two-stage approval workflow operational (Episode 12)
* **Related Specs**:
  * [`AUTHORIZATION_MODEL.md`](../../AUTHORIZATION_MODEL.md)
  * [`AGENT_DEVELOPMENT_WORKFLOW.md`](../../AGENT_DEVELOPMENT_WORKFLOW.md)
  * [`DEMO_SCENARIOS.md`](../../DEMO_SCENARIOS.md)
  * [`LEAVE_WORKFLOW.md`](../../LEAVE_WORKFLOW.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. How to use AI coding agents for systematic debugging and root-cause analysis across APEX Workflows, Human Tasks, and PL/SQL packages.
2. How to implement secure, auditable employee request cancellation with compensating balance recovery.
3. How to synchronize APEX Workflow engine states with database transitions when requests are cancelled or terminated.
4. How to diagnose and resolve the "Double-Deduction Balance Trap" where workflow conditions evaluate remaining balance against already-reserved days.
5. How to write self-verifying SQL reconciliation routines to recover orphaned pending balances without corrupting audit history.

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. Production Realities: When Workflows Hit Edge Cases (00:00 – 03:30)
* **What to Show**: The gap between happy-path development and production operations:
  * *Happy Path*: Request $\to$ Workflow $\to$ Approval $\to$ Balance Deduction.
  * *Real-World Edge Cases*:
    * An employee needs to cancel an in-flight request while waiting for manager or HR review.
    * A workflow terminates abnormally due to balance evaluation errors, leaving requested days locked in `PENDING_DAYS`.
    * Imported workflows in headless environments throw unhandled errors when workflow versions default to `DEVELOPMENT`.
* **Talking Points**:
  * "Building an APEX workflow is only half the job. In production, business operations are messy: employees change plans, systems encounter edge cases, and balances get stuck."
  * "Today, we demonstrate how AI coding agents help us systematically trace runtime logs, implement compensating transactions, and recover system integrity."

### 2. Employee Request Cancellation & Workflow Synchronization (03:30 – 08:00)
* **What to Show**: Cancellation Lifecycle & State Machine:
  ```text
  [Employee in App 100] -> Clicks "Cancel Request"
     ├── 1. Security Gate: HR_AUTH_PKG.CAN_CANCEL_REQUEST
     │      - Actor must be request owner or Admin
     │      - Start date must be in the future (cannot cancel past/current leave)
     │      - Status must be DRAFT, PENDING_MANAGER_APPROVAL, or PENDING_HR_APPROVAL
     ├── 2. Balance Recovery: HR_LEAVE_PKG.CANCEL_REQUEST
     │      - PENDING_DAYS := PENDING_DAYS - REQUESTED_DAYS
     │      - AVAILABLE_DAYS restored immediately
     ├── 3. APEX Workflow Synchronization:
     │      - APEX_WORKFLOW.CANCEL_WORKFLOW(p_instance_id => WORKFLOW_ID)
     │      - Human Tasks in Manager / HR Worklists removed
     └── 4. Audit Event:
            - HR_LEAVE_REQUEST_EVENTS logged (CANCELLED, actor, reason, timestamp)
  ```
* **Talking Points**:
  * "When an employee cancels a request, you cannot just set `STATUS = 'CANCELLED'`. You must execute a compensating transaction to release the reserved balance, and terminate the APEX workflow instance so managers don't see ghost tasks."

### 3. Diagnosing Workflow Termination & The Double-Deduction Trap (08:00 – 12:30)
* **What to Show**: Root-cause analysis of mysterious workflow terminations:
  * *Symptom*: Employee has 14 available days. Requests 6 days. Workflow immediately aborts with `TERMINATED` status, claiming "insufficient balance".
  * *Investigation with AI Agent*:
    * Tracing APEX dictionary view `APEX_APPL_WORKFLOW_ACTIVITY_LOG`: Activity `HAVE_BALANCE` took the `NO_BALANCE` branch.
    * Inspecting `HR_LEAVE_BALANCES`: `ENTITLEMENT=21, USED=9, PENDING=11, AVAILABLE=1`.
  * *The Trap Uncovered*:
    * `HR_LEAVE_PKG.CREATE_REQUEST` immediately reserves `:REQUESTED_DAYS` into `PENDING_DAYS` upon submission.
    * Since `AVAILABLE_DAYS = ENTITLEMENT - USED - PENDING`, available days was already reduced by 6.
    * The workflow switch activity `HAVE_BALANCE` was checking:
      ```plsql
      IF v_available_days >= :REQUESTED_DAYS THEN ...
      ```
    * Because `v_available_days` was already deducted, this check required the employee to have $2 \times \text{REQUESTED\_DAYS}$ available!
  * *The Architectural Fix*:
    ```plsql
    -- CREATE_REQUEST already placed :REQUESTED_DAYS into PENDING_DAYS.
    -- (v_available_days + :REQUESTED_DAYS) represents balance before reservation.
    v_available_days := HR_LEAVE_PKG.GET_AVAILABLE_DAYS(
        p_user_id       => :USER_ID, 
        p_leave_type_id => :LEAVE_TYPE_ID
    );
    IF (v_available_days + :REQUESTED_DAYS) >= :REQUESTED_DAYS AND v_available_days >= 0 THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
    ```
* **Talking Points**:
  * "This is one of the most common logic pitfalls in workflow-driven applications. Tracing through both the PL/SQL package and the declarative workflow activities allows us to spot the double-reservation instantly."

### 4. Automated Balance Recovery & Data Healing (12:30 – 15:30)
* **What to Show**: Reconciling stuck balances:
  * When workflows terminate prematurely, the request may remain in `PENDING_MANAGER_APPROVAL` or `TERMINATED` while `PENDING_DAYS` remains locked.
  * Writing an automated, idempotent reconciliation procedure:
    * Identify leave requests where workflow is terminated, faulted, or missing, but `status != 'CANCELLED'`.
    * Call `HR_LEAVE_PKG.CANCEL_REQUEST` or balance reconciliation logic.
    * Verify balance invariants: $\text{AVAILABLE} = \text{ENTITLEMENT} - \text{USED} - \text{PENDING}$.
* **Talking Points**:
  * "Never fix balance bugs with manual ad-hoc SQL updates in production. Always write self-verifying, idempotent recovery scripts that log audit events and preserve transactional guarantees."

### 5. Defensive Workflow Architecture & Verification (15:30 – 18:30)
* **What to Show**:
  * Handling workflow version lifecycles (`DEVELOPMENT` vs `ACTIVE`):
    * Guarding `HR_WORKFLOW_PKG.START_LEAVE_APPROVAL` against headless runtime failures by querying `APEX_APPL_WORKFLOW_VERSIONS`.
  * Executing comprehensive test suite verifying:
    1. Employee cancellation before start date $\to$ balance recovered, workflow terminated.
    2. Attempted cancellation after start date $\to$ blocked.
    3. Workflow evaluation when `available == requested` $\to$ succeeds without double-deduction.
    4. Balance reconciliation for faulted workflows.
* **Talking Points**:
  * "Defensive programming makes our system resilient to unexpected user actions and infrastructure restarts."

### 6. Wrap-up (18:30 – 20:00)
* **Talking Points**:
  * "We have transformed our application from a happy-path prototype into an enterprise-grade, self-healing system."
  * "In Episode 14, our series finale, we execute the complete end-to-end system demo from AI prompt to database audit."

---

## 💻 Core Code Snippets

### 1. Robust Employee Cancellation with Workflow Termination
```sql
PROCEDURE cancel_request(
    p_request_id      IN NUMBER,
    p_actor_username  IN VARCHAR2,
    p_comments        IN VARCHAR2 DEFAULT NULL
) IS
    l_user_id        NUMBER;
    l_leave_type_id  NUMBER;
    l_requested_days NUMBER;
    l_workflow_id    NUMBER;
    l_from_status    VARCHAR2(50);
BEGIN
    SELECT user_id, leave_type_id, requested_days, workflow_id, status
      INTO l_user_id, l_leave_type_id, l_requested_days, l_workflow_id, l_from_status
      FROM hr_leave_requests
     WHERE request_id = p_request_id
       FOR UPDATE;

    -- 1. Security & state verification
    IF NOT hr_auth_pkg.can_cancel_request(p_actor_username, p_request_id) THEN
        RAISE_APPLICATION_ERROR(-20003, 'Not authorized to cancel this leave request.');
    END IF;

    -- 2. Release reserved pending days back to available balance
    IF l_from_status IN ('SUBMITTED', 'PENDING_MANAGER_APPROVAL', 'PENDING_HR_APPROVAL') THEN
        UPDATE hr_leave_balances
           SET pending_days = GREATEST(0, pending_days - l_requested_days),
               updated_at   = SYSTIMESTAMP,
               updated_by   = p_actor_username
         WHERE user_id       = l_user_id
           AND leave_type_id = l_leave_type_id;
    END IF;

    -- 3. Update request status
    UPDATE hr_leave_requests
       SET status     = 'CANCELLED',
           updated_at = SYSTIMESTAMP,
           updated_by = p_actor_username
     WHERE request_id = p_request_id;

    -- 4. Terminate active APEX workflow instance if running
    IF l_workflow_id IS NOT NULL THEN
        BEGIN
            apex_workflow.cancel_workflow(
                p_instance_id => l_workflow_id,
                p_comment     => 'Request cancelled by user ' || p_actor_username
            );
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- Workflow may already be completed or inactive
        END IF;
    END IF;

    -- 5. Audit trail
    log_event(
        p_request_id     => p_request_id,
        p_event_type     => 'CANCELLED',
        p_from_status    => l_from_status,
        p_to_status      => 'CANCELLED',
        p_actor_username => p_actor_username,
        p_comments       => NVL(p_comments, 'Leave request cancelled by employee')
    );
END cancel_request;
```

### 2. Corrected `HAVE_BALANCE` Workflow Switch Activity
```plsql
DECLARE 
    v_available_days NUMBER;
BEGIN
    -- CREATE_REQUEST already placed :REQUESTED_DAYS into PENDING_DAYS.
    -- (v_available_days + :REQUESTED_DAYS) recovers the balance before reservation.
    v_available_days := HR_LEAVE_PKG.GET_AVAILABLE_DAYS(
        p_user_id       => :USER_ID, 
        p_leave_type_id => :LEAVE_TYPE_ID
    );
    
    IF (v_available_days + :REQUESTED_DAYS) >= :REQUESTED_DAYS AND v_available_days >= 0 THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END;
```

---

## 🖥️ Live Demo Script
1. **Scenario 1: Employee Request Cancellation**
   * Log into App 100 as `EMP001` $\to$ Submit a 4-day leave request.
   * Observe `pending_days` increases by 4 and `available_days` decreases by 4.
   * Click **Cancel Request** from the leave history/details page.
   * Verify status immediately becomes `CANCELLED`.
   * Verify `pending_days` is decreased by 4 and `available_days` is completely restored.
   * Log into App 200 as `MGR001` $\to$ Verify the human task is no longer in the inbox.
2. **Scenario 2: Diagnosing & Fixing Workflow Balance Termination**
   * Submit a request for an employee who has exact remaining balance.
   * Demonstrate how the old condition failed due to double-deduction.
   * Apply the corrected PL/SQL switch expression in APEX Workflow Designer.
   * Re-run and verify the workflow smoothly progresses to the manager approval task.
3. **Scenario 3: Orphaned Balance Recovery**
   * Execute reconciliation query identifying orphaned requests.
   * Run balance recovery routine to release pending days for terminated workflows.

---

## ❓ Common Questions & Pitfalls
* **Q: Why can't employees cancel approved leave requests directly from the portal?**
  * *A*: Once leave is `APPROVED`, days have moved from `pending_days` to `used_days` and may have payroll/scheduling implications. Approved leave requires an HR administrator reversal or an explicit change request.
* **Q: What happens if `APEX_WORKFLOW.CANCEL_WORKFLOW` fails when cancelling a request?**
  * *A*: The PL/SQL block catches exceptions so database transaction rollback is avoided, but logs an audit notice if the workflow was already terminated or completed.

---

## ⏭️ Next Episode
* **[Lecture 14: End-to-End System Demo & Best Practices Wrap-Up](../14_end_to_end_demo_and_wrap_up/lecture_notes.md)**
