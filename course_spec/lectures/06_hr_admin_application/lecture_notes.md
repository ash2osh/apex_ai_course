# Lecture 06: HR Administration Application

## 📋 Lecture Metadata
* **Episode**: 6 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: APEX Developers, Enterprise App Builders
* **Prerequisites**: Authorization schemes created (Episode 5)
* **Related Specs**:
  * [`ADMIN_APP.md`](../../ADMIN_APP.md)
  * [`AUTHORIZATION_MODEL.md`](../../AUTHORIZATION_MODEL.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. How to create and configure Application 200 (HR Administration) in APEX.
2. How to build executive KPI cards and charts on the Admin Dashboard.
3. How to build administrative management pages for Leave Types, Leave Balances, and Employees.
4. How to restrict Super Admin pages (Users, Roles, System Settings) using granular authorization schemes.

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. App 200 Overview & Navigation (00:00 – 03:30)
* **What to Show**: App 200 page hierarchy:
  * Dashboard (Page 1)
  * My Tasks (Page 2) *(Pre-configured for Episode 8)*
  * Pending Leave Requests (Page 3)
  * Leave Request Details (Page 4)
  * Employees & Leave History (Pages 5 & 6)
  * Leave Types & Balances (Pages 7 & 8)
  * Workflow Monitor (Page 9)
  * Super Admin Zone: Users (Page 10), Roles (Page 11), Settings (Page 12)
* **Talking Points**:
  * "App 200 is the operational command center for managers, HR administrators, and system administrators."

### 2. Admin Dashboard & Analytics (Page 1) (03:30 – 07:30)
* **What to Show**: Dashboard KPI cards & charts:
  * KPI Cards: Pending Requests Count, Approved This Month, Rejected This Month, Employees Currently on Leave.
  * Charts: Requests by Department (Bar Chart), Leave Type Distribution (Donut Chart).
* **Talking Points**:
  * "Using APEX faceted search and built-in Oracle JET charts, HR administrators get immediate operational visibility."

### 3. Maintaining Types, Balances & Adjustments (Pages 7 & 8) (07:30 – 12:30)
* **What to Show**: Interactive Grids and Modal Forms:
  * Page 7: Managing Leave Types (Annual, Sick, Unpaid, Emergency, Default Entitlements).
  * Page 8: Admin balance adjustments (e.g. adding $+2$ bonus days to an employee's annual entitlement).
* **Talking Points**:
  * "Admins can adjust balances with full auditability, updating `ADJUSTMENT_DAYS` in `HR_LEAVE_BALANCES`."

### 4. Securing Super Admin Pages (Pages 10–12) (12:30 – 16:30)
* **What to Show**: Applying `IS_SUPER_ADMIN` to Pages 10, 11, and 12:
  * Page 10: User Management (Create user, assign manager, toggle active status).
  * Page 11: Role Assignment (Grant/Revoke `ADMIN` or `EMPLOYEE` roles).
  * Page 12: System Settings (e.g., `LONG_LEAVE_THRESHOLD`, `ALLOW_LEAVE_CANCELLATION`).
* **Talking Points**:
  * "Regular Admins can approve requests and view employee balances, but only Super Admins can alter security roles and global system parameters."

### 5. Wrap-up (16:30 – 18:00)
* **Talking Points**:
  * "Our dual applications (Employee Self-Service and HR Admin) are now completely built."
  * "In Episode 7, we will bring the business process to life by designing the native APEX Workflow engine."

---

## 💻 SQL Query Reference

### Admin Dashboard KPI SQL
```sql
SELECT 
    COUNT(CASE WHEN status IN ('PENDING_MANAGER_APPROVAL', 'PENDING_HR_APPROVAL') THEN 1 END) AS pending_count,
    COUNT(CASE WHEN status = 'APPROVED' AND TRUNC(updated_at, 'MM') = TRUNC(SYSDATE, 'MM') THEN 1 END) AS approved_this_month,
    COUNT(CASE WHEN status = 'REJECTED' AND TRUNC(updated_at, 'MM') = TRUNC(SYSDATE, 'MM') THEN 1 END) AS rejected_this_month
FROM hr_leave_requests;
```

---

## 🖥️ Live Demo Script
1. Log into App 200 as `HR001` (HR Admin):
   * Verify access is granted.
   * View the Dashboard KPIs and charts.
   * Open Leave Types: update Annual Leave default entitlement.
   * Try opening Users / Roles: verify links are hidden and direct URL navigation triggers Access Denied.
2. Log in as `ADMIN001` (Super Admin):
   * Verify Users, Roles, and System Settings menus are visible and accessible.

---

## ❓ Common Questions & Pitfalls
* **Q: Can managers see requests from all departments?**
  * *A*: On the general Admin dashboard, HR Admins see company-wide data, but on the "My Tasks" approval inbox, managers see only their direct report tasks.

---

## ⏭️ Next Episode
* **[Lecture 07: APEX Workflow Engine Design](../07_apex_workflow_design/lecture_notes.md)**
