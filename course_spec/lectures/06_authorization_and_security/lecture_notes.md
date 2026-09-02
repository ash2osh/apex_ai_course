# Lecture 06: Multi-Tier Authorization & Security Model

## 📋 Lecture Metadata
* **Episode**: 6 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: APEX Developers, Security Architects
* **Prerequisites**: Database Model & Core Packages deployed (Episode 3), Employee App built (Episode 4), HR Admin App built (Episode 5)
* **Related Specs**:
  * [`AUTHORIZATION_MODEL.md`](../../AUTHORIZATION_MODEL.md)
  * [`DATABASE_MODEL.md`](../../DATABASE_MODEL.md)
  * [`EMPLOYEE_APP.md`](../../EMPLOYEE_APP.md)
  * [`ADMIN_APP.md`](../../ADMIN_APP.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. The Role-Based Access Control (RBAC) hierarchy: `EMPLOYEE`, `MANAGER`, `ADMIN`, and `SUPER_ADMIN`.
2. How to create and configure reusable APEX Authorization Schemes in Shared Components across both applications (App 100 & App 200) backed by the pre-existing `HR_AUTH_PKG`.
3. How to implement "Defense in Depth" across both APEX applications:
   * **Application Level**: Restricting application entry (`IS_EMPLOYEE` on App 100, `IS_ADMIN` / `IS_MANAGER` on App 200).
   * **Page Level**: Securing specific pages against URL tampering (e.g. Pages 10–12 in App 200 with `IS_SUPER_ADMIN`).
   * **Region & Component Level**: Protecting buttons (e.g. "Cancel Request" with `CAN_CANCEL_REQUEST`, "Approve/Reject" with `CAN_APPROVE_REQUEST`).
   * **PL/SQL Process & Package Level**: Enforcing database assertions in `HR_AUTH_PKG` and `HR_LEAVE_PKG`.
4. The critical difference between UI conditional display (Server-side Conditions) and declarative Authorization Schemes.
5. How to execute positive and negative security tests across seed users (`EMP001`, `MGR001`, `HR001`, `ADMIN001`).

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. The Threat Model & RBAC Principles (00:00 – 04:00)
* **What to Show**: Access Matrix:
  | Capability | Employee (`EMP001`) | Manager (`MGR001`) | HR Admin (`HR001`) | Super Admin (`ADMIN001`) |
  |---|:---:|:---:|:---:|:---:|
  | Access Employee App (App 100) | Yes | Yes | Yes | Yes |
  | View Own Balance & Requests | Yes | Yes | Yes | Yes |
  | Cancel Own Pending Request | Yes | Yes | Yes | Yes |
  | Access HR Admin App (App 200) | No | Yes (Tasks) | Yes | Yes |
  | Approve / Reject Team Leave | No | Yes (Direct Reports) | Yes (Company-wide) | Yes |
  | Manage Leave Types & Balances | No | No | Yes | Yes |
  | Manage Users, Roles & Settings | No | No | No | Yes |
* **Talking Points**:
  * "Security in Oracle APEX is not just hiding navigation items."
  * "Now that both App 100 and App 200 are built, we must enforce multi-tier security so that unauthorized navigation and forged requests are impossible."
  * "We already built `HR_AUTH_PKG` in Episode 3. In this episode, we connect both APEX applications directly to this package."

### 2. Creating APEX Authorization Schemes in Shared Components (04:00 – 08:30)
* **What to Show**: Shared Components $\to$ Authorization Schemes:
  * `IS_EMPLOYEE`:
    ```sql
    RETURN hr_auth_pkg.is_employee(:APP_USER);
    ```
    *Evaluation Point*: **Once per session**
  * `IS_MANAGER`:
    ```sql
    RETURN hr_auth_pkg.is_manager(:APP_USER);
    ```
    *Evaluation Point*: **Once per session**
  * `IS_ADMIN`:
    ```sql
    RETURN hr_auth_pkg.is_admin(:APP_USER);
    ```
    *Evaluation Point*: **Once per session**
  * `IS_SUPER_ADMIN`:
    ```sql
    RETURN hr_auth_pkg.is_super_admin(:APP_USER);
    ```
    *Evaluation Point*: **Once per session**
  * `CAN_CANCEL_REQUEST`:
    ```sql
    RETURN hr_auth_pkg.can_cancel_request(
        p_actor_username => :APP_USER,
        p_request_id     => TO_NUMBER(:P6_REQUEST_ID)
    );
    ```
    *Evaluation Point*: **Must Not be Cached / Once per page view**
  * `CAN_APPROVE_REQUEST`:
    ```sql
    RETURN hr_auth_pkg.can_approve_request(
        p_actor_username => :APP_USER,
        p_request_id     => TO_NUMBER(:P4_REQUEST_ID)
    );
    ```
    *Evaluation Point*: **Must Not be Cached / Once per page view**
* **Talking Points**:
  * "Evaluation Point matters! Static role checks like `IS_ADMIN` evaluate *Once per session*, minimizing database round-trips."
  * "Contextual or row-level permissions like `CAN_CANCEL_REQUEST` and `CAN_APPROVE_REQUEST` must use *Must Not be Cached* because the decision depends on the current page item value."

### 3. Layered Defense in Action across Both Applications (08:30 – 13:30)
* **What to Show**: Applying security across multiple layers in App 100 and App 200:
  1. **Application Level**:
     * App 100 Security Attribute $\to$ Authorization Scheme = `IS_EMPLOYEE`.
     * App 200 Security Attribute $\to$ Authorization Scheme = `IS_ADMIN` (or `IS_MANAGER`).
  2. **Page Level**:
     * In App 200, protect Pages 10 (Users), 11 (Roles), and 12 (Settings) with `IS_SUPER_ADMIN`.
  3. **Button & Component Level**:
     * On App 100 Page 6 (Leave Request Details), attach `CAN_CANCEL_REQUEST` directly to the **Cancel Request** button.
     * On App 200 Page 4 (Leave Request Details), attach `CAN_APPROVE_REQUEST` to the **Approve** and **Reject** buttons.
  4. **PL/SQL Process & Package Level**:
     * The page processes call `HR_LEAVE_PKG.CANCEL_REQUEST` or approval packages, which internally re-validate `HR_AUTH_PKG` and raise exceptions if violated.
* **Talking Points**:
  * "Why protect both the button and the PL/SQL process? The button authorization prevents unauthorized users from seeing the action. The package-level assertion ensures that even if an attacker manipulates the DOM or bypasses the client, the database transaction is rejected."

### 4. Testing Authorization with Seed Users (13:30 – 17:30)
* **What to Show**: Executing positive and negative authorization tests across both applications:
  * **Login as `EMP001` (Ahmed Employee)**:
    * ✅ Opens App 100 Dashboard and submits a leave request.
    * ✅ Opens own pending request on Page 6: "Cancel Request" button is visible and functional.
    * ❌ Tries navigating to another user's request details or App 200 $\to$ Access Denied.
  * **Login as `MGR001` (Mona Manager)**:
    * ✅ Accesses Employee Self Service + Manager approval tasks in App 200.
  * **Login as `HR001` (Hala HR)**:
    * ✅ Accesses HR Admin App (App 200) with company-wide leave review.
    * ❌ Attempts to access Super Admin user management or system settings $\to$ Access Denied.
  * **Login as `ADMIN001` (Samira Super Admin)**:
    * ✅ Unrestricted access across all apps, configuration, and security settings.
* **Talking Points**:
  * "Always test the negative path. Confirming unauthorized users are blocked is just as essential as confirming authorized workflows succeed."

### 5. Wrap-up (17:30 – 18:30)
* **Talking Points**:
  * "Our APEX authorization schemes are now configured and protecting both applications at every tier."
  * "In Episode 7, we will bring the business process to life by designing the native APEX Workflow engine."

---

## 💻 APEX Configuration Reference

### 1. APEXlang (`.apx`) Shared Components Authorization Schemes
```apx
authorization is-employee (
    name: IS_EMPLOYEE
    type: plSqlFunctionBody
    settings {
        plsqlFunctionBody:
            ```plsql
            return hr_auth_pkg.is_employee(:APP_USER);
            ```
    }
    error {
        errorMessage: Insufficient privileges. Employee access required.
    }
)

authorization is-super-admin (
    name: IS_SUPER_ADMIN
    type: plSqlFunctionBody
    settings {
        plsqlFunctionBody:
            ```plsql
            return hr_auth_pkg.is_super_admin(:APP_USER);
            ```
    }
    error {
        errorMessage: Insufficient privileges. Super Administrator access required.
    }
)

authorization can-cancel-request (
    name: CAN_CANCEL_REQUEST
    type: plSqlFunctionBody
    settings {
        plsqlFunctionBody:
            ```plsql
            return hr_auth_pkg.can_cancel_request(
                p_actor_username => :APP_USER,
                p_request_id     => to_number(:P6_REQUEST_ID)
            );
            ```
    }
    error {
        errorMessage: You do not have permission to cancel this leave request.
    }
)
```

### 2. Page & Button Security Configuration (APEX Page Designer)
* **App 100 Page 6 Button**: `CANCEL_REQUEST` $\to$ Authorization Scheme: `CAN_CANCEL_REQUEST`
* **App 200 Pages 10, 11, 12**: Page Security $\to$ Authorization Scheme: `IS_SUPER_ADMIN`
* **App 200 Page 4 Approval Buttons**: `APPROVE` / `REJECT` $\to$ Authorization Scheme: `CAN_APPROVE_REQUEST`
* **Server-side Process (App 100 Page 6)**:
  ```sql
  BEGIN
      hr_leave_pkg.cancel_request(
          p_actor_username => :APP_USER,
          p_request_id     => TO_NUMBER(:P6_REQUEST_ID)
      );
      apex_message.set_custom_success_message('Leave request has been cancelled.');
  END;
  ```

---

## 🖥️ Live Demo Script
1. **Open APEX App Builder** $\to$ Application 100 & Application 200.
2. **Navigate to Shared Components** $\to$ **Authorization Schemes** in both apps.
3. **Verify / Create Schemes**:
   * `IS_EMPLOYEE` (Expression: `return hr_auth_pkg.is_employee(:APP_USER);`, Evaluation: *Once per session*).
   * `IS_SUPER_ADMIN` (Expression: `return hr_auth_pkg.is_super_admin(:APP_USER);`, Evaluation: *Once per session*).
   * `CAN_CANCEL_REQUEST` (Expression: `return hr_auth_pkg.can_cancel_request(:APP_USER, to_number(:P6_REQUEST_ID));`, Evaluation: *Must Not be Cached*).
4. **Configure Application & Page Security**:
   * App 100 Security Attributes $\to$ Authorization Scheme: `IS_EMPLOYEE`.
   * App 200 Pages 10, 11, 12 $\to$ Authorization Scheme: `IS_SUPER_ADMIN`.
5. **Protect Buttons**:
   * App 100 Page 6 `CANCEL_REQUEST` button $\to$ Authorization Scheme: `CAN_CANCEL_REQUEST`.
6. **Run Verification**:
   * Run `security_schemes_and_tests.sql` in SQLcl to verify authorization logic across all seed accounts.
   * Test in browser with `EMP001` vs `HR001` vs `ADMIN001`.

---

## ❓ Common Questions & Pitfalls
* **Q: Why use an Authorization Scheme on a button instead of a Server-Side Condition?**
  * *A*: Server-Side Conditions only control whether a component renders into HTML. If a condition is manipulated on the client or during an AJAX post, APEX does not validate security. Authorization Schemes are evaluated on every submission and request, guaranteeing tamper resistance.
* **Q: When should an Authorization Scheme be evaluated 'Once per session' vs 'Must Not be Cached'?**
  * *A*: Static role memberships (`IS_ADMIN`, `IS_SUPER_ADMIN`) don't change within a user session; caching them *Once per session* improves performance by eliminating redundant SQL queries. Row-level or item-dependent rules (`CAN_CANCEL_REQUEST`, `CAN_APPROVE_REQUEST`) evaluate specific request IDs and must be set to *Must Not be Cached* (or *Once per page view*).
* **Q: Does APEX authorization replace PL/SQL package security?**
  * *A*: No. APEX authorization provides UI security and friendly UX error handling. PL/SQL packages provide the non-bypassable transactional security boundary for any client (APEX, AI Agents, REST endpoints).

---

## ⏭️ Next Episode
* **[Lecture 07: APEX Workflow Engine Design](../07_apex_workflow_design/lecture_notes.md)**
