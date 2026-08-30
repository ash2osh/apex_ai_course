# Lecture 13: Architectural Refactoring — Manager Role Separation

## 📋 Lecture Metadata
* **Episode**: 13 of 14
* **Target Duration**: 15–20 minutes
* **Target Audience**: Solution Architects, Senior APEX Developers, Database Engineers
* **Prerequisites**: Two-stage approval workflow operational (Episode 12)
* **Related Specs**:
  * [`AUTHORIZATION_MODEL.md`](../../AUTHORIZATION_MODEL.md)
  * [`AGENT_DEVELOPMENT_WORKFLOW.md`](../../AGENT_DEVELOPMENT_WORKFLOW.md)
  * [`DEMO_SCENARIOS.md`](../../DEMO_SCENARIOS.md)

---

## 🎯 Key Learning Objectives
By the end of this lecture, viewers will understand:
1. The architectural motivation for splitting `MANAGER` into an independent role from `ADMIN`.
2. How to use Graphify to discover every database package, authorization scheme, APEX page, and navigation item affected by role changes.
3. How to safely refactor `HR_ROLES`, `HR_AUTH_PKG`, APEX Authorization Schemes, and Task potential owners.
4. How to prevent privilege escalation during security model refactoring.

---

## ⏱️ Slide Outline & Timed Talking Points

### 1. The Architectural Flaw in Shared Roles (00:00 – 04:00)
* **What to Show**: Initial Model vs. Target Model:
  * *Initial*: `Sarah Manager` was assigned `ADMIN` role just to approve leave tasks, giving her unintended access to company-wide salary/leave adjustments.
  * *Target Refactor*: Introduce distinct `MANAGER` role. Managers can only approve their own team members' leave and cannot access HR configuration.
* **Talking Points**:
  * "The principle of least privilege dictates that users should only have the exact permissions necessary for their duties."
  * "Giving managers full `ADMIN` access is a common technical debt item we need to refactor."

### 2. Tracing Role Dependencies with Graphify (04:00 – 08:30)
* **What to Show**: Dependency Graph Visualizer / Query:
  ```bash
  graphify query "What APEX pages, authorization schemes, and PL/SQL functions reference the ADMIN role?"
  ```
  * Shows:
    * `HR_AUTH_PKG.IS_ADMIN`
    * APEX Scheme `CAN_APPROVE_LEAVE`
    * Task Definition `LEAVE_MANAGER_APPROVAL`
    * App 200 Navigation Menu
* **Talking Points**:
  * "Without Graphify, changing a security role risks breaking navigation or accidentally locking users out."

### 3. Step-by-Step AI-Guided Refactoring (08:30 – 14:00)
* **What to Show**: The 4-step refactor sequence:
  1. **Database Tier**: Insert `MANAGER` role into `HR_ROLES`; update `MGR001` role mapping from `ADMIN` to `MANAGER`.
  2. **PL/SQL Tier**: Update `HR_AUTH_PKG.CAN_APPROVE_REQUEST` to check `has_role(p_user, 'MANAGER')` and manager hierarchy.
  3. **APEX Security**: Update `IS_ADMIN` and `CAN_APPROVE_LEAVE` authorization schemes.
  4. **Task Definitions**: Ensure potential owner logic routes directly to `MANAGER` role.
* **Talking Points**:
  * "We execute this refactor systematically across all layers."

### 4. Verification & Testing Security Boundaries (14:00 – 17:00)
* **What to Show**:
  * Log in as `MGR001` (Sarah):
    * Can see **My Tasks** and approve team leave.
    * Cannot see **Leave Types**, **Balances Management**, or **System Settings**.
  * Log in as `HR001` (HR Admin):
    * Can manage leave types and balances.
* **Talking Points**:
  * "The refactoring is complete: least privilege is enforced without disrupting in-flight workflows."

### 5. Wrap-up (17:00 – 18:00)
* **Talking Points**:
  * "We have demonstrated how to safely refactor security in an enterprise APEX system."
  * "In Episode 14, our series finale, we run the complete end-to-end system demo from prompt to database audit."

---

## 💻 Refactored `HR_AUTH_PKG` Code Snippet
```sql
FUNCTION can_approve_request(
    p_username   IN VARCHAR2,
    p_request_id IN NUMBER
) RETURN BOOLEAN IS
    l_emp_manager_id NUMBER;
    l_current_user_id NUMBER;
BEGIN
    -- Super admins and HR admins can always approve
    IF is_admin(p_username) THEN
        RETURN TRUE;
    END IF;

    -- Managers can only approve their direct reports
    SELECT u.user_id INTO l_current_user_id 
      FROM hr_users u 
     WHERE UPPER(u.username) = UPPER(p_username);

    SELECT emp.manager_id INTO l_emp_manager_id
      FROM hr_leave_requests r
      JOIN hr_users emp ON r.user_id = emp.user_id
     WHERE r.request_id = p_request_id;

    RETURN (l_emp_manager_id = l_current_user_id);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
END can_approve_request;
```

---

## 🖥️ Live Demo Script
1. Execute migration script to add `MANAGER` role and re-assign `MGR001`.
2. Deploy updated `HR_AUTH_PKG` and authorization schemes.
3. Verify `MGR001` can still approve `EMP001` requests in My Tasks.
4. Verify `MGR001` is blocked from visiting `/admin/leave-types`.

---

## ❓ Common Questions & Pitfalls
* **Q: Will existing active workflow tasks break when roles are updated?**
  * *A*: No, because active tasks resolve potential owners via runtime queries against `MANAGER_ID` and current role definitions.

---

## ⏭️ Next Episode
* **[Lecture 14: End-to-End System Demo & Best Practices Wrap-Up](../14_end_to_end_demo_and_wrap_up/lecture_notes.md)**
