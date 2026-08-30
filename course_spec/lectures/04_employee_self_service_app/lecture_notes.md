# Lecture 04: Employee Self Service Application

## 📋 Lecture Metadata
* **Episode**: 4 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: APEX Developers, UI/UX Designers
* **Prerequisites**: Database schema deployed (Episode 3)
* **Related Specs**:
  * [`EMPLOYEE_APP.md`](../../EMPLOYEE_APP.md)
  * [`APP_ARCHITECTURE.md`](../../APP_ARCHITECTURE.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. How to create and configure Application 100 (Employee Self Service) in APEX.
2. How to build the Employee Dashboard with KPI cards and recent activities.
3. How to build a clean leave request submission form with dynamic validations.
4. How to display balance cards per leave type (Annual, Sick, Unpaid).
5. How to build the interactive "My Requests" report and details view with request cancellation capabilities.

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. App 100 Overview & Design Philosophy (00:00 – 03:00)
* **What to Show**: App navigation structure:
  * Home / Dashboard (Page 1)
  * My Profile (Page 2)
  * My Leave Balance (Page 3)
  * Submit Leave Request (Page 4)
  * My Leave Requests (Page 5)
  * Leave Request Details (Page 6)
* **Talking Points**:
  * "The Employee Self Service application is built for high usability and clarity."
  * "Every page automatically queries data scoped strictly to `v('APP_USER')`."

### 2. Building the Dashboard & Balances (Pages 1 & 3) (03:00 – 08:00)
* **What to Show**: APEX Page Designer:
  * Creating Cards Region for Leave Balances (Annual: 14 days available, Sick: 10 days available).
  * Quick Actions buttons (Submit Request, Ask HR AI).
  * Upcoming approved leaves list.
* **Talking Points**:
  * "Using APEX Cards regions, we present balance metrics at a glance."
  * "We display Entitlement, Used, Pending, and Available days dynamically."

### 3. The Leave Submission Form (Page 4) (08:00 – 13:00)
* **What to Show**: Page 4 items & dynamic actions:
  * `P4_LEAVE_TYPE_ID` (Select List)
  * `P4_START_DATE` & `P4_END_DATE` (Date Pickers)
  * `P4_REQUESTED_DAYS` (Calculated dynamically on change)
  * `P4_REASON` (Text Area)
  * Form Processing: Calls `HR_LEAVE_PKG.CREATE_REQUEST`
* **Talking Points**:
  * "Notice we have client-side dynamic actions to compute requested days as the user changes dates, but the final validation and calculation is always re-verified on the server in `HR_LEAVE_PKG`."

### 4. My Requests & Request Details (Pages 5 & 6) (13:00 – 17:00)
* **What to Show**: Interactive Report with pill badges for `PENDING_MANAGER_APPROVAL`, `PENDING_HR_APPROVAL`, `APPROVED`, `REJECTED`, `CANCELLED`, and `WORKFLOW_ERROR`.
  * The Cancel button on Page 6 is shown only for an owned request in a pending approval stage whose start date is in the future; the process calls `HR_LEAVE_PKG.CANCEL_REQUEST`.
* **Talking Points**:
  * "Employees can track their request status and review approver comments."
  * "Eligible requests can be cancelled directly by the employee."

### 5. Wrap-up (17:00 – 18:00)
* **Talking Points**:
  * "We have our core employee self-service UI running."
  * "In Episode 5, we will implement multi-tier authorization schemes to enforce rock-solid security."

---

## 💻 APEX Page Designer Configuration Reference

### Page 4 Form Submission Process (PL/SQL)
```sql
DECLARE
    l_request_id NUMBER;
BEGIN
    hr_leave_pkg.create_request(
        p_username      => :APP_USER,
        p_leave_type_id => :P4_LEAVE_TYPE_ID,
        p_start_date    => :P4_START_DATE,
        p_end_date      => :P4_END_DATE,
        p_reason        => :P4_REASON,
        p_request_id    => l_request_id
    );
    
    apex_message.set_custom_success_message('Leave request #' || l_request_id || ' submitted successfully.');
END;
```

---

## 🖥️ Live Demo Script
1. Log into App 100 as `EMP001` (Ahmed Employee).
2. View the Dashboard: verify annual leave balance displays **14 Available**.
3. Navigate to **Submit Leave Request**:
   * Select *Annual Leave*.
   * Pick dates: `10-Sep-2026` to `14-Sep-2026` (5 days).
   * Enter reason: *"Family vacation"*.
   * Click **Submit**.
4. Navigate to **My Leave Requests**: verify the new request appears as `PENDING_MANAGER_APPROVAL`.
5. Open **Leave Request Details**: verify the **Cancel Request** button is visible and active.

---

## ❓ Common Questions & Pitfalls
* **Q: Why not let employees edit an existing request?**
  * *A*: In enterprise workflows, editing an in-flight request invalidates previous approvals. It is cleaner to cancel and submit a new request.

---

## ⏭️ Next Episode
* **[Lecture 05: Multi-Tier Authorization & Security Model](../05_authorization_and_security/lecture_notes.md)**
