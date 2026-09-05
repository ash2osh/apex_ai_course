# Lecture 07: APEX Workflow Engine Design

## 📋 Lecture Metadata
* **Episode**: 7 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: APEX Developers, Business Process Analysts, Workflow Engineers
* **Prerequisites**: Oracle APEX 26.1.4, Apps 100 and 200 configured
* **Related Specs**:
  * [`LEAVE_WORKFLOW.md`](../../LEAVE_WORKFLOW.md)
  * [`APP_ARCHITECTURE.md`](../../APP_ARCHITECTURE.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. The native APEX Workflow Engine architecture and visual Workflow Designer.
2. How to define Workflow Variables (`REQUEST_ID`, `EMPLOYEE_ID`, `MANAGER_ID`, `REQUESTED_DAYS`).
3. How to implement automated validation activities and conditional branching.
4. How to synchronize workflow state with the `HR_LEAVE_REQUESTS` table via `HR_WORKFLOW_PKG`.
5. How to handle cancellation and workflow error strategies.

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. Introduction to APEX Workflows (00:00 – 03:30)
* **What to Show**: APEX Workflow Designer UI:
  * Start Activity $\to$ Automated Actions $\to$ Switch/Condition $\to$ Human Tasks $\to$ End.
* **Talking Points**:
  * "Starting in APEX 23.2, Oracle introduced native stateful workflows built directly into the database engine."
  * "No external BPEL servers, no complex middleware—pure declarative business process management."

### 2. The `LEAVE_APPROVAL` Workflow Diagram (03:30 – 08:30)
* **What to Show**: State Machine Flow:
  ```text
  START
    │
    ▼
  [Activity 1: Validate Request]
    │
    ▼
  [Activity 2: Check Available Balance]
    ├── Insufficient ────────► [Activity 2a: Auto-Reject Request] ──► END (Rejected)
    │
    ▼ Sufficient
  [Activity 3: AI Summary Step] (Configured in Episode 11)
    │
    ▼
  [Activity 4: LEAVE_MANAGER_APPROVAL Human Task]
    ├── Rejected ────────────► [Manager outcome callback] ─────────► END (Rejected)
    │
    ▼ Approved
  [Activity 5: Requested days > LONG_LEAVE_THRESHOLD?]
    ├── Yes ─────────────────► [LEAVE_HR_APPROVAL Human Task]
    │                              ├── Rejected ───────────────────► END (Rejected)
    │                              └── Approved ───────────────────► Finalize balance
    └── No ──────────────────► [Finalize balance]
                                   │
                                   ▼
                              END (Approved)
    │
    ▼
  END (Approved)
  ```
* **Talking Points**:
  * "Notice the automated balance check before the manager is even alerted. If the balance is insufficient, the system auto-rejects and saves manager time."

### 3. Defining Workflow Variables (08:30 – 12:00)
* **What to Show**: Workflow Variables configuration pane in APEX:
  * `REQUEST_ID` (Number - Primary Key)
  * `EMPLOYEE_ID` (Number)
  * `MANAGER_ID` (Number)
  * `LEAVE_TYPE_ID` (Number)
  * `START_DATE` / `END_DATE` (Date)
  * `REQUESTED_DAYS` (Number)
  * `APPROVAL_RESULT` (String: `APPROVED` / `REJECTED`)
* **Talking Points**:
  * "Variables carry the execution payload across activities without needing repeated database queries."

### 4. Hooking Workflow into PL/SQL (12:00 – 16:30)
* **What to Show**: Triggering the App 200-owned workflow through the package boundary:
  ```sql
  l_workflow_id := hr_workflow_pkg.start_leave_approval(
      p_request_id => l_request_id
  );
  ```
* **Talking Points**:
  * "When an employee clicks submit in App 100, `HR_LEAVE_PKG` starts the workflow instance and saves the `WORKFLOW_ID` in `HR_LEAVE_REQUESTS`."

### 5. Wrap-up (16:30 – 18:00)
* **Talking Points**:
  * "Our workflow orchestration backbone is defined."
  * "In Episode 8, we will connect the Human Task activity so managers receive, claim, and approve tasks in their inbox."

---

## 💻 PL/SQL Workflow Starter Code

### Calling from App 100 Submit Process (Page 4)
```sql
declare
    l_request_id  number;
    l_workflow_id number;
    l_start_date  date;
    l_end_date    date;
begin
    begin
        l_start_date := to_date(:P4_START_DATE, 'YYYY-MM-DD');
    exception when others then
        l_start_date := to_date(:P4_START_DATE);
    end;
    begin
        l_end_date := to_date(:P4_END_DATE, 'YYYY-MM-DD');
    exception when others then
        l_end_date := to_date(:P4_END_DATE);
    end;

    hr_leave_pkg.create_request(
        p_username        => :APP_USER,
        p_leave_type_code => :P4_LEAVE_TYPE_CODE,
        p_start_date      => l_start_date,
        p_end_date        => l_end_date,
        p_reason          => :P4_REASON,
        p_request_id      => l_request_id
    );

    l_workflow_id := hr_workflow_pkg.start_leave_approval(
        p_request_id => l_request_id
    );

    :P4_REQUEST_ID  := l_request_id;
    :P4_WORKFLOW_ID := l_workflow_id;
    commit;
    apex_application.g_print_success_message := 'Leave request #' || l_request_id || ' submitted successfully.';
end;
```

### Native Workflow Initiation in `HR_WORKFLOW_PKG`
`HR_WORKFLOW_PKG.start_leave_approval` owns the APEX 26.1 call. It passes `p_application_id => 200`, `p_static_id => 'leave-approval'`, and indexed `APEX_WORKFLOW.T_WORKFLOW_PARAMETER` records, then stores the returned workflow instance ID in `HR_LEAVE_REQUESTS`:

```sql
l_params(1) := apex_workflow.t_workflow_parameter(
    static_id    => 'P_REQUEST_ID',
    string_value => to_char(p_request_id)
);

l_workflow_id := apex_workflow.start_workflow(
    p_application_id => 200,
    p_static_id      => 'leave-approval',
    p_parameters     => l_params,
    p_initiator      => coalesce(apex_application.g_user, l_username, sys_context('USERENV', 'SESSION_USER')),
    p_detail_pk      => to_char(p_request_id)
);

update hr_leave_requests
   set workflow_id = l_workflow_id
 where request_id = p_request_id;
```

---

## 🖥️ Live Demo Script
1. In APEX App Builder (App 200) $\to$ Shared Components $\to$ Workflows $\to$ Create `LEAVE_APPROVAL` (Static ID: `leave-approval`).
2. Add input parameter `P_REQUEST_ID` (Number, Required).
3. Select version `v1` $\to$ Set Status to **Active** (crucial for runtime execution).
4. Add activities: Execute Code (Validate), True/False Condition (Balance Check).
5. Run test submission from Employee App (Page 4) $\to$ Check APEX Workflow Monitor to see the instance executing.

---

## ❓ Common Questions & Pitfalls
* **Q: Why does `apex_workflow.start_workflow` fail with `ORA-20987: Workflow leave-approval has no Active version`?**
  * *A*: A newly created workflow version in APEX starts in `Development` status. In APEX App Builder, open the workflow version `v1` and change the status from **Development** to **Active**.
* **Q: Why does `apex_workflow.start_workflow` fail with `ORA-01403: no data found`?**
  * *A*: APEX generates a slugified static ID (such as `leave-approval` instead of uppercase `LEAVE_APPROVAL`). Verify `STATIC_ID` in `APEX_APPL_WORKFLOWS`.
* **Q: What happens if the database crashes while a workflow is running?**
  * *A*: APEX Workflows are transactional and database-native. Active states and variables are persisted automatically.

---

## ⏭️ Next Episode
* **[Lecture 08: APEX Human Tasks & Manager Approvals](../08_human_tasks_and_approvals/lecture_notes.md)**
