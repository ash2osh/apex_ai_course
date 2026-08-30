# Lecture 08: APEX Human Tasks & Manager Approvals

## 📋 Lecture Metadata
* **Episode**: 8 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: APEX Developers, Workflow Specialists
* **Prerequisites**: APEX Workflow defined (Episode 7)
* **Related Specs**:
  * [`LEAVE_WORKFLOW.md`](../../LEAVE_WORKFLOW.md)
  * [`ADMIN_APP.md`](../../ADMIN_APP.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. How APEX Task Definitions work and how they integrate with Workflows.
2. How to dynamically assign potential owners and actual owners based on the employee's manager (`MANAGER_ID`).
3. How to build the unified "My Tasks" inbox on Page 2 of the HR Admin App.
4. How to implement Approve, Reject, Claim, and Release actions with custom comments.
5. How human actions resume paused workflow instances.

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. Human Tasks in Oracle APEX (00:00 – 03:30)
* **What to Show**: Task Definition Concept:
  * Task Definition: `LEAVE_MANAGER_APPROVAL`
  * Potential Owner: SQL Query resolving the employee's direct manager username.
  * Task Priority, Due Date, and Action Buttons (Approve, Reject).
* **Talking Points**:
  * "A Human Task represents a unit of human work. In APEX, it can be assigned to a specific user, a role, or calculated dynamically from SQL."

### 2. Configuring Task Definition & Potential Owners (03:30 – 08:00)
* **What to Show**: Shared Components $\to$ Task Definitions:
  * Potential Owner Expression (SQL Query):
    ```sql
    SELECT m.username
      FROM hr_users u
      JOIN hr_users m ON u.manager_id = m.user_id
     WHERE u.user_id = :EMPLOYEE_ID
    ```
  * Task Outcome: `APPROVED` or `REJECTED`.
* **Talking Points**:
  * "Because we dynamically query `MANAGER_ID`, when Ahmed (`EMP001`) submits a request, it automatically routes to Sarah (`MGR001`)."

### 3. Building the "My Tasks" Inbox (Page 2, App 200) (08:00 – 13:00)
* **What to Show**: Unified Task List component in Page Designer:
  * Displays tasks assigned to current user (`APP_USER`).
  * Shows Request Details, Employee Name, Dates, Requested Days, and status.
  * Modal Action Dialog with Approver Comments.
* **Talking Points**:
  * "Managers can claim tasks from a shared pool or immediately action tasks assigned directly to them."

### 4. Resuming the Workflow on Completion (13:00 – 16:30)
* **What to Show**: Workflow execution diagram:
  * Workflow halts at Activity 4 $\to$ Waits for Human Task $\to$ Manager clicks **Approve** $\to$ Task completes with outcome `APPROVED` $\to$ Workflow resumes $\to$ Executes balance deduction activity $\to$ Completes.
* **Talking Points**:
  * "The integration is seamless. The workflow sleeps while waiting for the human, and wakes up immediately when the task is resolved."

### 5. Wrap-up (16:30 – 18:00)
* **Talking Points**:
  * "Our business approval engine is fully functional!"
  * "In Episode 9, we begin the AI journey by building the conversational HR AI Assistant for employees."

---

## 🖥️ Live Demo Script
1. Log into Employee App (App 100) as `EMP001` (Ahmed) $\to$ Submit a 3-day leave request.
2. Log into HR Admin App (App 200) as `MGR001` (Sarah Manager).
3. Navigate to **My Tasks**:
   * Verify Ahmed's pending approval task appears in the list.
   * Click **Open Task** $\to$ Review details.
   * Enter approver comments: *"Approved, have a great holiday!"*.
   * Click **Approve**.
4. Switch back to Employee App as `EMP001` $\to$ Refresh **My Leave Requests**:
   * Verify status changed to `APPROVED`.
   * Verify available balance decreased by 3 days.

---

## ❓ Common Questions & Pitfalls
* **Q: What if an employee does not have a manager assigned?**
  * *A*: In `HR_WORKFLOW_PKG`, we add a fallback check. If `MANAGER_ID` is null, the task is routed to the general `ADMIN` role pool.

---

## ⏭️ Next Episode
* **[Lecture 09: Conversational HR AI Assistant](../09_conversational_ai_assistant/lecture_notes.md)**

