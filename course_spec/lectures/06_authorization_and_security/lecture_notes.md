# Lecture 06: Custom Authentication, App 200 CRUD & Multi-Tier Security

## 📋 Lecture Metadata
* **Episode**: 6 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: APEX Developers, Security Architects, Enterprise App Builders
* **Prerequisites**: Database Model & Core Packages deployed (Episode 3), Employee App built (Episode 4), HR Admin App built (Episode 5)
* **Related Specs**:
  * [`AUTHORIZATION_MODEL.md`](../../AUTHORIZATION_MODEL.md)
  * [`DATABASE_MODEL.md`](../../DATABASE_MODEL.md)
  * [`EMPLOYEE_APP.md`](../../EMPLOYEE_APP.md)
  * [`ADMIN_APP.md`](../../ADMIN_APP.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. How to create and configure a **Custom Authentication Scheme** in Oracle APEX using username/password validated against `HR_USERS` via `HR_AUTH_PKG.AUTHENTICATE`.
2. How to configure App 200 administration pages to enable full **Create and Edit (CRUD)** operations:
   * **Page 7 (Leave Types)**: Create & Edit leave types and entitlements.
   * **Page 8 (Leave Balances)**: Administrative balance adjustments calling `HR_LEAVE_PKG.ADJUST_BALANCE`.
   * **Page 10 (Users)**: Create and maintain employee user records.
   * **Page 11 (Roles)**: Assign and revoke user roles (`EMPLOYEE`, `MANAGER`, `ADMIN`, `SUPER_ADMIN`).
   * **Page 12 (System Settings)**: Maintain global application parameters.
3. How the pre-implemented **Multi-Tier Authorization Schemes** (`IS_EMPLOYEE`, `IS_MANAGER`, `IS_ADMIN`, `IS_SUPER_ADMIN`, `CAN_APPROVE_REQUEST`, `CAN_CANCEL_REQUEST`) protect these Create/Edit operations across both App 100 and App 200.
4. The full security lifecycle: Custom Authentication $\to$ Session Establishment (`:APP_USER`) $\to$ Declarative Authorization $\to$ Non-Bypassable PL/SQL Package Assertions.
5. How to conduct automated and browser-based verification across all seed users (`EMP001`, `MGR001`, `HR001`, `ADMIN001`).

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. Custom Authentication with Username & Password (00:00 – 04:30)
* **What to Show**: Shared Components $\to$ Authentication Schemes:
  * Creating `HR_CUSTOM_AUTH` scheme (Type: *Custom*).
  * Authentication Function: `hr_auth_pkg.authenticate`
    ```sql
    FUNCTION authenticate(
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN BOOLEAN;
    ```
  * Connecting App 100 and App 200 Login Page (Page 9999) `APEX_AUTHENTICATION.LOGIN`.
* **Talking Points**:
  * "Instead of relying on developer workspace accounts, enterprise APEX applications authenticate against their own database user tables."
  * "When a user submits their credentials on Page 9999, APEX calls our custom authentication function in `HR_AUTH_PKG`. If valid, it establishes session state and sets `:APP_USER`."

### 2. Enabling Create & Edit (CRUD) in App 200 (04:30 – 09:30)
* **What to Show**: Configuring editable forms and processes on App 200 pages:
  * **Page 7 (Leave Types)**: Interactive Grid / Form to Add new leave types (e.g., *Maternity Leave*, 60 days) and update existing entitlements.
  * **Page 8 (Leave Balances)**: Form and process to perform administrative balance adjustments:
    ```sql
    hr_leave_pkg.adjust_balance(
        p_actor_username => :APP_USER,
        p_user_id        => :P8_USER_ID,
        p_leave_type_id  => :P8_LEAVE_TYPE_ID,
        p_year           => :P8_YEAR,
        p_days_delta     => :P8_ADJUSTMENT_DAYS,
        p_reason         => :P8_REASON
    );
    ```
  * **Page 10 (User Management)**: Create User form (username, full name, email, department, manager) and edit active status.
  * **Page 11 (Role Assignment)**: Assign and revoke roles in `HR_USER_ROLES`.
  * **Page 12 (System Settings)**: Edit parameters (`LONG_LEAVE_THRESHOLD`, `ALLOW_LEAVE_CANCELLATION`).
* **Talking Points**:
  * "App 200 is the administrative command center. In this step, we transform read-only views into fully functional Create and Edit interfaces for managing enterprise HR data."

### 3. Layered Defense in Action across Both Applications (09:30 – 14:00)
* **What to Show**: Enforcing our pre-implemented authorization schemes on the new Create/Edit features:
  1. **Application Level**:
     * App 100 Security Attributes $\to$ `IS_EMPLOYEE`.
     * App 200 Security Attributes $\to$ `IS_ADMIN` / `IS_MANAGER`.
  2. **Page Level (Super Admin Zone)**:
     * App 200 Pages 10 (Users), 11 (Roles), and 12 (Settings) locked with `IS_SUPER_ADMIN`.
     * App 200 Pages 7 (Leave Types) and 8 (Balances) locked with `IS_ADMIN`.
  3. **Button & Process Level**:
     * App 100 Page 6 Cancel button locked with `CAN_CANCEL_REQUEST`.
     * App 200 Page 4 Approve/Reject buttons locked with `CAN_APPROVE_REQUEST`.
  4. **PL/SQL Package Assertions**:
     * `HR_LEAVE_PKG.ADJUST_BALANCE` asserts caller is admin (`HR_AUTH_PKG.ASSERT_ADMIN`).
     * `HR_AUTH_PKG.ASSERT_SUPER_ADMIN` guards role and user modifications.
* **Talking Points**:
  * "Notice how authentication and authorization work together: Authentication determines WHO the user is (`:APP_USER`). Authorization determines WHAT they can see and edit."
  * "Even if an attacker crafts an unauthorized POST request to modify Page 10 or Page 11, the database package rejects the transaction immediately."

### 4. End-to-End Testing with Seed Users (14:00 – 17:30)
* **What to Show**: Testing the complete authentication + authorization + CRUD matrix:
  * **Login as `EMP001` (Ahmed Employee)**:
    * ✅ Authenticates via custom login with password.
    * ✅ Accesses App 100 Self-Service; submits and cancels own request.
    * ❌ Attempting to log into App 200 $\to$ Access Denied.
  * **Login as `MGR001` (Mona Manager)**:
    * ✅ Authenticates and views direct report approval tasks in App 200.
  * **Login as `HR001` (Hala HR)**:
    * ✅ Authenticates into App 200.
    * ✅ Creates a new Leave Type on Page 7 and performs a Balance Adjustment on Page 8.
    * ❌ Attempting to open Users (Page 10) or Roles (Page 11) $\to$ Access Denied.
  * **Login as `ADMIN001` (Samira Super Admin)**:
    * ✅ Authenticates and creates a new user on Page 10 and assigns roles on Page 11.
  * **Negative Authentication Test**:
    * ❌ Entering wrong password or inactive account $\to$ Login rejected.
* **Talking Points**:
  * "Testing both positive and negative paths confirms that our authentication and multi-tier authorization boundaries are completely secure."

### 5. Wrap-up (17:30 – 18:30)
* **Talking Points**:
  * "Custom authentication is active, App 200 management pages have full Create/Edit capabilities, and multi-tier authorization is enforced."
  * "In Episode 7, we will bring the business process to life by designing the native APEX Workflow engine."

---

## 💻 APEX Configuration Reference

### 1. Custom Authentication Function (`HR_AUTH_PKG`)
```sql
FUNCTION authenticate(
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
) RETURN BOOLEAN IS
    l_cnt NUMBER;
BEGIN
    IF p_username IS NULL OR p_password IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Verify active user in HR_USERS table
    SELECT COUNT(*)
      INTO l_cnt
      FROM hr_users u
     WHERE UPPER(u.username) = UPPER(TRIM(p_username))
       AND u.active_yn = 'Y';

    -- In demo/course environment, validates valid user + non-empty password
    -- (in production, compare against salted hash)
    RETURN (l_cnt > 0 AND LENGTH(TRIM(p_password)) >= 4);
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END authenticate;
```

### 2. APEX Custom Authentication Scheme Configuration
* **Name**: `HR_CUSTOM_AUTH`
* **Scheme Type**: `Custom`
* **Authentication Function Name**: `hr_auth_pkg.authenticate`
* **Invalid Session Target**: Page 9999 (Login)

### 3. App 200 Balance Adjustment Process (Page 8)
```sql
BEGIN
    hr_leave_pkg.adjust_balance(
        p_actor_username => :APP_USER,
        p_user_id        => TO_NUMBER(:P8_USER_ID),
        p_leave_type_id  => TO_NUMBER(:P8_LEAVE_TYPE_ID),
        p_year           => TO_NUMBER(:P8_YEAR),
        p_days_delta     => TO_NUMBER(:P8_ADJUSTMENT_DAYS),
        p_reason         => :P8_REASON
    );
    apex_message.set_custom_success_message('Balance adjusted successfully.');
END;
```

---

## 🖥️ Live Demo Script
1. **Configure Custom Authentication**:
   * Open App 100 & App 200 $\to$ Shared Components $\to$ Authentication Schemes.
   * Create scheme `HR_CUSTOM_AUTH` using `hr_auth_pkg.authenticate`. Make it Current.
2. **Configure App 200 Create & Edit Pages**:
   * Open Page 7 (Leave Types): Verify Add and Edit actions on `HR_LEAVE_TYPES`.
   * Open Page 8 (Leave Balances): Test the Balance Adjustment modal process calling `HR_LEAVE_PKG.ADJUST_BALANCE`.
   * Open Page 10 (Users) & Page 11 (Roles): Configure Create User and Role Assignment.
3. **Verify Authorization Lockdown**:
   * Confirm Pages 10, 11, 12 have Authorization Scheme = `IS_SUPER_ADMIN`.
   * Confirm Pages 7, 8 have Authorization Scheme = `IS_ADMIN`.
4. **Run Automated Test Script**:
   * Run `security_schemes_and_tests.sql` in SQLcl to verify authentication function and authorization matrix.
5. **Test in Browser**:
   * Log in as `EMP001` $\to$ verify App 100 access only.
   * Log in as `HR001` $\to$ adjust balance on Page 8; verify access denied on Page 10.
   * Log in as `ADMIN001` $\to$ create a new employee on Page 10 and assign roles on Page 11.

---

## ❓ Common Questions & Pitfalls
* **Q: How does Custom Authentication set `:APP_USER`?**
  * *A*: When `APEX_AUTHENTICATION.LOGIN` succeeds, the APEX engine automatically establishes a valid session and registers the authenticated username as `:APP_USER` (or `V('APP_USER')`).
* **Q: Why call `HR_LEAVE_PKG.ADJUST_BALANCE` instead of writing an `UPDATE` statement in APEX?**
  * *A*: Packaging data modifications guarantees audit logging, enforces role assertions (`ASSERT_ADMIN`), locks affected balance rows, and prevents client-side bypass.
* **Q: What happens if an unauthorized user attempts to submit a Create/Edit form on Page 10?**
  * *A*: APEX evaluates the `IS_SUPER_ADMIN` authorization scheme before processing the request, immediately blocking execution and displaying an Access Denied error.

---

## ⏭️ Next Episode
* **[Lecture 07: APEX Workflow Engine Design](../07_apex_workflow_design/lecture_notes.md)**
