# Lecture 03: Database Model & Core PL/SQL Packages

## 📋 Lecture Metadata
* **Episode**: 3 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: PL/SQL Developers, APEX Developers, Database Administrators
* **Prerequisites**: Access to an Oracle Database schema, SQLcl configured (Episode 2)
* **Related Specs**:
  * [`DATABASE_MODEL.md`](../../DATABASE_MODEL.md)
  * [`APP_ARCHITECTURE.md`](../../APP_ARCHITECTURE.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. The nine canonical tables with the `HR_` prefix and their relationships.
2. The dynamic leave balance calculation formula.
3. Why business logic must be isolated in PL/SQL packages instead of embedded in APEX page processes.
4. The responsibilities and signatures of the 5 core packages (`HR_USER_PKG`, `HR_AUTH_PKG`, `HR_LEAVE_PKG`, `HR_WORKFLOW_PKG`, `HR_AI_PKG`).
5. How to deploy deterministic seed data for `EMP001`, `EMP002`, `MGR001`, `HR001`, and `ADMIN001`.

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. Schema Design & ER Diagram (00:00 – 04:30)
* **What to Show**: Relational Entity Relationship Diagram:
  ```text
  HR_DEPARTMENTS ◄── HR_USERS ──► HR_USER_ROLES ──► HR_ROLES
                         │
             ┌───────────┴───────────┐
             ▼                       ▼
     HR_LEAVE_BALANCES       HR_LEAVE_REQUESTS
             ▲                       ▲
             └───────┬───────────────┘
                     ▼
              HR_LEAVE_TYPES
  ```
* **Talking Points**:
  * "All objects use the `HR_` prefix."
  * "`HR_USERS` stores employee identity and references `MANAGER_ID` (self-referential foreign key)."
  * "`HR_LEAVE_TYPES` specifies default entitlement and whether balance deduction is required (`REQUIRES_BALANCE_YN`)."

### 2. The Balance Formula & Request Lifecycle (04:30 – 08:30)
* **What to Show**: Formula slide & Status enum:
  $$\text{AVAILABLE\_DAYS} = \text{ENTITLEMENT\_DAYS} + \text{ADJUSTMENT\_DAYS} - \text{USED\_DAYS} - \text{PENDING\_DAYS}$$
  * **Statuses**: `PENDING_MANAGER_APPROVAL` $\to$ `PENDING_HR_APPROVAL` when required $\to$ `APPROVED` / `REJECTED`; cancellation yields `CANCELLED` and faults yield `WORKFLOW_ERROR`.
* **Talking Points**:
  * "Notice `PENDING_DAYS`. When an employee submits a 3-day request, those days are immediately marked as pending so they cannot submit a duplicate request with the same balance before approval."
  * "When approved, `PENDING_DAYS` decreases by 3 and `USED_DAYS` increases by 3."

### 3. PL/SQL Package Architecture (08:30 – 14:00)
* **What to Show**: Package responsibility breakdown:
  * `HR_USER_PKG`: Current user profile resolution from `v('APP_USER')`.
  * `HR_AUTH_PKG`: Role queries (`has_role`, `is_admin`, `can_approve_request`).
  * `HR_LEAVE_PKG`: Working days calculation, overlap detection, balance checks, create/approve/reject/cancel transactions.
  * `HR_WORKFLOW_PKG`: APEX Workflow synchronization callbacks.
  * `HR_AI_PKG`: Session-bounded helper functions tailored for AI Agent tools.
* **Talking Points**:
  * "Why put logic in packages? Because APEX is just one client. Our AI Agent is another client. If we put validation logic in APEX page processes, the AI Agent would bypass them. With PL/SQL packages, business integrity is guaranteed everywhere."

### 4. Deploying & Testing Seed Data (14:00 – 17:30)
* **What to Show**: Deploying seed users:
  ```text
  EMP001 -> Ahmed Employee (EMPLOYEE)
  MGR001   -> Mona Manager         (EMPLOYEE, MANAGER)
  HR001    -> Hala HR              (EMPLOYEE, ADMIN)
  ADMIN001 -> Samira Administrator (EMPLOYEE, SUPER_ADMIN)
  ```
* **Talking Points**:
  * "Notice `MGR001` has both `EMPLOYEE` and `ADMIN` roles in our initial model. Later in the course, we will demonstrate a live refactor to make `MANAGER` its own distinct role."

### 5. Wrap-up (17:30 – 18:30)
* **Talking Points**:
  * "Our database foundation and PL/SQL API layer are complete and verified."
  * "In Episode 4, we will build the Employee Self Service APEX application."

---

## 💻 Code & DDL Reference

### Core Balance Verification Query
```sql
CREATE OR REPLACE FUNCTION hr_leave_pkg.get_available_days(
    p_user_id       IN hr_users.user_id%TYPE,
    p_leave_type_id IN hr_leave_types.leave_type_id%TYPE,
    p_year          IN NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE)
) RETURN NUMBER IS
    l_available NUMBER;
BEGIN
    SELECT (entitlement_days + adjustment_days - used_days - pending_days)
      INTO l_available
      FROM hr_leave_balances
     WHERE user_id = p_user_id
       AND leave_type_id = p_leave_type_id
       AND balance_year = p_year;
       
    RETURN NVL(l_available, 0);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END get_available_days;
/
```

---

## 🖥️ Live Demo Script
1. Run DDL deployment script in SQLcl:
   ```sql
   Generate the implementation in the initialized template repository, obtain the
   template database write guard, then run its reviewed installer.
   ```
2. Verify table creation and foreign key constraints:
   ```sql
   SELECT table_name FROM user_tables WHERE table_name LIKE 'HR_%' ORDER BY 1;
   ```
3. Run test transaction using `HR_LEAVE_PKG`:
   ```sql
   -- Verify calculation of leave days
   SELECT hr_leave_pkg.calculate_days(DATE '2026-09-10', DATE '2026-09-14') FROM dual;
   ```

---

## ❓ Common Questions & Pitfalls
* **Q: Why store `PENDING_DAYS` in `HR_LEAVE_BALANCES` instead of calculating it on the fly?**
  * *A*: Storing pending reservations enables atomic balance checks with row-level locking (`SELECT ... FOR UPDATE`), preventing concurrent double-booking.

---

## ⏭️ Next Episode
* **[Lecture 04: Employee Self Service Application](../04_employee_self_service_app/lecture_notes.md)**
