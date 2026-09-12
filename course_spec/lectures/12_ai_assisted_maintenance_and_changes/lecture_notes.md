# Lecture 12: AI-Assisted Maintenance & Requirement Changes

## 📋 Lecture Metadata
* **Episode**: 12 of 14
* **Target Duration**: 18–22 minutes
* **Target Audience**: APEX Developers, Technical Leads, AI Pair-Programmers
* **Prerequisites**: Full application stack completed (Episodes 1–11)
* **Related Specs**:
  * [`AGENT_DEVELOPMENT_WORKFLOW.md`](../../AGENT_DEVELOPMENT_WORKFLOW.md)
  * [`DEMO_SCENARIOS.md`](../../DEMO_SCENARIOS.md)
  * [`LEAVE_WORKFLOW.md`](../../LEAVE_WORKFLOW.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. How to manage real-world requirement changes using an AI coding agent without architecture drift.
2. How to use Graphify and static analysis for dependency tracking and blast radius assessment before touching code.
3. The new business requirement: **Leave requests longer than 5 working days require secondary HR Admin approval (`LEAVE_HR_APPROVAL`) after Manager approval**.
4. How to guide the AI agent to update PL/SQL packages, APEX workflow branches, human task definitions, and authorization gates.
5. How to identify and diagnose two subtle APEX workflow pitfalls:
   * **APEX Workflow Version States**: Why imported workflows default to `DEVELOPMENT` and require activation for runtime execution.
   * **The Double-Deduction Trap**: Why pre-reserving balance in `HR_LEAVE_PKG.CREATE_REQUEST` caused workflow `HAVE_BALANCE` switch activities to fail, and how to fix it.
6. How to write self-verifying, automated SQLcl test suites (`02_verify_multi_tier_approval.sql`) and validate APEXlang code using `uc-apx validate`.

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. The Maintenance Challenge in APEX (00:00 – 03:00)
* **What to Show**: The New Business Requirement:
  ```text
  "Requests > 5 working days require HR Admin approval after Manager approval.
   Requests <= 5 working days remain single Manager approval."
  ```
* **Talking Points**:
  * "In enterprise software, requirements evolve. The test of an AI coding architecture is whether it can safely adapt without breaking existing guarantees."
  * "Notice our invariant: exactly-once balance deduction on approval, single release on rejection, and auditable event timeline in `HR_LEAVE_REQUEST_EVENTS`."

### 2. Graphify Impact Analysis & Blast Radius (03:00 – 06:30)
* **What to Show**: Terminal running Graphify query:
  ```bash
  graphify query "Find all database packages, workflow activities, and tables dependent on leave request duration and approval steps."
  ```
  * **Blast Radius Identified**:
    * **Packages**: `HR_LEAVE_PKG` (balance transitions), `HR_WORKFLOW_PKG` (outcome handlers), `HR_AUTH_PKG` (stage authorization gates).
    * **Tables**: `HR_LEAVE_REQUESTS` (status: `PENDING_HR_APPROVAL`), `HR_LEAVE_BALANCES`, `HR_SYSTEM_SETTINGS` (`LONG_LEAVE_THRESHOLD = 5`), `HR_LEAVE_REQUEST_EVENTS`.
    * **APEX App 200**: Workflow `LEAVE_APPROVAL`, new Human Task `LEAVE_HR_APPROVAL`, and Page 4 (`p00004-leave-request-details.apx`) decision processes.
* **Talking Points**:
  * "Before writing a single line of code, we determine the exact blast radius across our database and APEX layers."

### 3. Prompting the Agent & Implementing the Changes (06:30 – 11:00)
* **What to Show**:
  * **Database Tier**:
    * `DEMO.HR_AUTH_PKG.CAN_APPROVE_REQUEST`: Blocks managers from approving at `PENDING_HR_APPROVAL`; grants approval authority to `ADMIN` and `SUPER_ADMIN`.
    * `DEMO.HR_WORKFLOW_PKG.MANAGER_OUTCOME`: Evaluates `LONG_LEAVE_THRESHOLD` (5). If $\le 5$ days, finalizes to `APPROVED`. If $> 5$ days, transitions request to `PENDING_HR_APPROVAL` and logs event `MANAGER_APPROVED`.
    * `DEMO.HR_WORKFLOW_PKG.HR_OUTCOME`: Handles final HR Admin approval and rejection.
  * **APEX 200 Component Tier**:
    * New Human Task Definition: `leave-hr-approval.apx` (`LEAVE_HR_APPROVAL`), routed to Admin/Super Admin.
    * Workflow Update: `leave-approval.apx` with `check-duration` switch (`:REQUESTED_DAYS > 5`), `hr-approval` activity, and `check-hr-outcome`.
    * Approver Details Page: `p00004-leave-request-details.apx` processes dynamically calling `hr_outcome` or `manager_outcome`.

### 4. Real-World Pitfalls & Debugging (11:00 – 16:00)
* **What to Show**:
  * **Pitfall 1: Workflow Version State (`DEVELOPMENT` vs `ACTIVE`)**:
    * When an APEX application is exported and imported, workflow versions default to `DEVELOPMENT` state.
    * In headless or runtime end-user mode, `APEX_WORKFLOW.START_WORKFLOW` on a `DEVELOPMENT` version raises `ORA-20987: Workflow has no Active version`.
    * *Fix*: Activate the version in APEX Builder (Shared Components $\to$ Workflows $\to$ Version `v1` $\to$ Set Status to **Active**), and ensure package wrappers guard against unexpected runtime rollbacks.
  * **Pitfall 2: The Double-Deduction Balance Trap**:
    * When `HR_LEAVE_PKG.CREATE_REQUEST` runs, it immediately reserves requested days in `PENDING_DAYS`.
    * As a result, `GET_AVAILABLE_DAYS` returns the *remaining* balance.
    * In the workflow, checking `IF V_AVAILABLE_DAYS >= :REQUESTED_DAYS` failed because it required the employee to have $2 \times \text{REQUESTED\_DAYS}$ available!
    * *Fix*: The workflow switch must check `(v_available_days + :REQUESTED_DAYS) >= :REQUESTED_DAYS AND v_available_days >= 0`.

### 5. Automated Verification & Delivery (16:00 – 20:00)
* **What to Show**:
  * Executing the automated multi-tier verification suite in SQLcl:
    ```text
    PASS 1.1: Request created in PENDING_MANAGER_APPROVAL
    PASS 1.2: Manager approval immediately finalizes to APPROVED for <= 5 days
    PASS 1.3: Balance updated cleanly (Used: 9 -> 12)
    PASS 2.1: Request > 5 days initiated in PENDING_MANAGER_APPROVAL
    PASS 2.2: Manager approval successfully escalated status to PENDING_HR_APPROVAL
    PASS 2.3: Security gate verified: MGR001 is NOT authorized for PENDING_HR_APPROVAL
    PASS 2.4: HR001 is authorized to approve PENDING_HR_APPROVAL
    PASS 2.5: HR Admin approval finalizes request to APPROVED
    PASS 2.6: Balance deducted exactly once (7 days consumed, Available: 13 -> 6)
    PASS 3.1: Request status transitioned to REJECTED by HR Admin
    PASS 3.2: Reserved balance released cleanly upon HR rejection
    ```
  * Exporting via `scripts/export_apps.sh` and validating via `uc-apx validate`.
  * Synchronizing database metadata mirror with `scripts/backup_db.sh`.

---

## 💻 Workflow Logic & PL/SQL Snippets

### 1. Duration Routing Condition
```sql
-- Expression condition in activity 'check-duration'
:REQUESTED_DAYS > 5
```

### 2. Corrected `HAVE_BALANCE` Activity Switch
```plsql
DECLARE 
    v_available_days NUMBER;
BEGIN
    -- CREATE_REQUEST already placed :REQUESTED_DAYS into PENDING_DAYS.
    -- (v_available_days + :REQUESTED_DAYS) represents the balance before reservation.
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

### 3. Page 4 Approver Process Dispatch
```plsql
BEGIN
    IF :P4_STATUS = 'PENDING_HR_APPROVAL' THEN
        hr_workflow_pkg.hr_outcome(
            p_request_id     => TO_NUMBER(:P4_REQUEST_ID),
            p_actor_username => :APP_USER,
            p_outcome        => 'APPROVED',
            p_comments       => :P4_APPROVER_COMMENTS
        );
    ELSE
        hr_workflow_pkg.manager_outcome(
            p_request_id     => TO_NUMBER(:P4_REQUEST_ID),
            p_actor_username => :APP_USER,
            p_outcome        => 'APPROVED',
            p_comments       => :P4_APPROVER_COMMENTS
        );
    END IF;
    COMMIT;
    apex_application.g_print_success_message := 'Leave request #' || :P4_REQUEST_ID || ' was approved successfully.';
END;
```

---

## 🖥️ Live Demo Script
1. **Scenario 1: Short Request ($\le 5$ days)**
   * Log into App 100 as `EMP001` $\to$ Submit a 3-day request.
   * Log into App 200 as `DEMO` / `MGR001` $\to$ Open My Tasks $\to$ Click **Approve**.
   * Verify status immediately finalizes to `APPROVED` and used balance increments by 3.
2. **Scenario 2: Long Request ($> 5$ days)**
   * Log into App 100 as `EMP002` $\to$ Submit a 7-day request.
   * Log into App 200 as `DEMO` $\to$ Open My Tasks $\to$ Click **Approve**.
   * Verify status transitions to `PENDING_HR_APPROVAL`.
   * Check as `MGR001` $\to$ Confirm `MGR001` cannot approve the task.
   * Log in as `HR001` (HR Admin) $\to$ Claim & Approve the secondary task.
   * Verify final status transitions to `APPROVED` and balance is deducted exactly once.
3. **Scenario 3: HR Rejection**
   * Submit a 6-day request $\to$ Manager approves $\to$ HR Admin clicks **Reject**.
   * Verify status transitions to `REJECTED` and reserved pending days are released back to available balance.

---

## ❓ Common Questions & Pitfalls

* **Q: Why did my workflow immediately terminate when created?**
  * *A*: Check the `HAVE_BALANCE` switch activity. If the PL/SQL code checks `available_days >= requested_days` *after* the request has already reserved those days into `pending_days`, it will fail unless the employee has at least twice the requested days. Always add `:REQUESTED_DAYS` back to available balance when re-evaluating inside the workflow.

* **Q: Why did `APEX_WORKFLOW.START_WORKFLOW` throw `ORA-20987: no Active version`?**
  * *A*: Newly imported APEX workflows default to `DEVELOPMENT` state. Open App 200 in APEX Builder $\to$ Shared Components $\to$ Workflows $\to$ Version `v1` and set the Status to **Active**.

---

## ⏭️ Next Episode
* **[Lecture 13: AI-Assisted System Debugging & Workflow Recovery](../13_architecture_refactoring_roles/lecture_notes.md)**
