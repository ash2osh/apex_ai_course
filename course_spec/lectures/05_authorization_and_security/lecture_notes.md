# Lecture 05: Multi-Tier Authorization & Security Model

## 📋 Lecture Metadata
* **Episode**: 5 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: APEX Developers, Security Architects
* **Prerequisites**: Employee App built (Episode 4)
* **Related Specs**:
  * [`AUTHORIZATION_MODEL.md`](../../AUTHORIZATION_MODEL.md)
  * [`DATABASE_MODEL.md`](../../DATABASE_MODEL.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. The Role-Based Access Control (RBAC) hierarchy: `EMPLOYEE`, `ADMIN`, and `SUPER_ADMIN`.
2. How to create reusable APEX Authorization Schemes based on `HR_AUTH_PKG`.
3. The "Defense in Depth" principle: protecting navigation, pages, regions, buttons, and PL/SQL processes.
4. Why URL manipulation and browser-side hacks cannot bypass server-side package security.

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. The Threat Model & RBAC Principles (00:00 – 04:00)
* **What to Show**: Access Matrix:
  | Capability | Employee | Admin | Super Admin |
  |---|:---:|:---:|:---:|
  | Access Employee App |  Yes |  Yes |  Yes |
  | View Own Balance & History |  Yes |  Yes |  Yes |
  | Access HR Admin App |  No |  Yes |  Yes |
  | Approve / Reject Leave |  No |  Yes |  Yes |
  | Manage Users & Roles |  No |  No |  Yes |
* **Talking Points**:
  * "Security in Oracle APEX is not just hiding a navigation tab."
  * "If an employee changes the URL from page 4 to page 10 (User Management), APEX must return an Access Denied error."

### 2. Creating APEX Authorization Schemes (04:00 – 09:00)
* **What to Show**: Shared Components $\to$ Authorization Schemes:
  * `IS_EMPLOYEE`: `hr_auth_pkg.has_role(:APP_USER, 'EMPLOYEE')`
  * `IS_ADMIN`: `hr_auth_pkg.is_admin(:APP_USER)`
  * `IS_SUPER_ADMIN`: `hr_auth_pkg.is_super_admin(:APP_USER)`
  * `CAN_APPROVE_LEAVE`: Checks if user is Admin or assigned Manager.
* **Talking Points**:
  * "We set evaluation point to *'Once per session'* for static roles or *'Must Not be Cached / Once per page view'* for dynamic task rights."

### 3. Layered Defense in Action (09:00 – 14:00)
* **What to Show**: Applying security at multiple levels:
  1. **Application Level**: Admin App has `IS_ADMIN` scheme at the application level.
  2. **Page Level**: User Management page has `IS_SUPER_ADMIN`.
  3. **Region & Button Level**: "Approve" button has `CAN_APPROVE_LEAVE`.
  4. **PL/SQL Package Level**: `HR_LEAVE_PKG.APPROVE_REQUEST` asserts caller identity.
* **Talking Points**:
  * "Even if an attacker sends an AJAX request directly to trigger the approval process, the database package checks `hr_auth_pkg.can_approve_request` and raises an exception."

### 4. Testing Authorization with Seed Users (14:00 – 17:30)
* **What to Show**: Demonstrating negative & positive authorization tests:
  * Log in as `EMP001` $\to$ Try opening Admin App $\to$ Access Denied.
  * Log in as `HR001` $\to$ Company-wide HR approval and administration, but no protected role or settings maintenance.
  * Log in as `ADMIN001` $\to$ Super-admin access to protected users, roles, and settings pages.
* **Talking Points**:
  * "Always test the negative path. Proving unauthorized users are blocked is just as important as proving authorized users can log in."

### 5. Wrap-up (17:30 – 18:30)
* **Talking Points**:
  * "Our security model is locked down and verified."
  * "In Episode 6, we will build the HR Administration Application."

---

## 💻 Code Reference

### `HR_AUTH_PKG` Package Body Sample
```sql
CREATE OR REPLACE PACKAGE BODY hr_auth_pkg AS

    FUNCTION has_role(
        p_username IN VARCHAR2,
        p_role_code IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_dummy NUMBER;
    BEGIN
        SELECT 1
          INTO l_dummy
          FROM hr_users u
          JOIN hr_user_roles ur ON u.user_id = ur.user_id
          JOIN hr_roles r       ON ur.role_id = r.role_id
         WHERE UPPER(u.username) = UPPER(p_username)
           AND u.active_yn = 'Y'
           AND r.role_code = UPPER(p_role_code);
           
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END has_role;

    FUNCTION is_admin(p_username IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN has_role(p_username, 'ADMIN') OR has_role(p_username, 'SUPER_ADMIN');
    END is_admin;

    FUNCTION is_super_admin(p_username IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN has_role(p_username, 'SUPER_ADMIN');
    END is_super_admin;

END hr_auth_pkg;
/
```

---

## 🖥️ Live Demo Script
1. Open Shared Components $\to$ Authorization Schemes in APEX.
2. Create scheme `IS_ADMIN` with PL/SQL Function Returning Boolean:
   ```sql
   RETURN hr_auth_pkg.is_admin(:APP_USER);
   ```
3. Test with `EMP001`: Verify access is restricted.
4. Test with `HR001` and `ADMIN001`, and verify each role receives only its documented scope.

---

## ❓ Common Questions & Pitfalls
* **Q: Should Authorization Schemes be evaluated 'Once per Session' or 'Once per Page View'?**
  * *A*: For static roles (`IS_SUPER_ADMIN`), 'Once per Session' saves database queries. For dynamic checks (e.g. "Can this user approve this specific request?"), use 'Once per Page View' or enforce directly in PL/SQL.

---

## ⏭️ Next Episode
* **[Lecture 06: HR Administration Application](../06_hr_admin_application/lecture_notes.md)**
