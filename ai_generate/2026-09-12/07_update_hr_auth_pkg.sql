-- =============================================================================
-- Migration: 07_update_hr_auth_pkg.sql
-- Description: Update HR_AUTH_PKG package specification and body:
--              1. Enforce that direct hierarchy managers must possess the MANAGER role.
--              2. Add guards to prevent deactivation or role revocation of the last active SUPER_ADMIN.
-- Fixes: High Finding 9, High Finding 11
-- Note: Password rules remain in classroom demo mode per user instruction.
-- =============================================================================
SET DEFINE OFF;

PROMPT Updating HR_AUTH_PKG SPECIFICATION ...

CREATE OR REPLACE EDITIONABLE PACKAGE "DEMO"."HR_AUTH_PKG" AS
    FUNCTION hash_password(p_username IN VARCHAR2, p_password IN VARCHAR2, p_salt IN VARCHAR2) RETURN VARCHAR2;
    PROCEDURE set_password(p_username IN VARCHAR2, p_password IN VARCHAR2);
    FUNCTION authenticate(p_username IN VARCHAR2, p_password IN VARCHAR2) RETURN BOOLEAN;

    FUNCTION has_role(p_username IN VARCHAR2, p_role_code IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION is_employee(p_username IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN;
    FUNCTION is_manager(p_username IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN;
    FUNCTION is_admin(p_username IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN;
    FUNCTION is_super_admin(p_username IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN;
    FUNCTION can_approve_request(p_actor_username IN VARCHAR2, p_request_id IN NUMBER) RETURN BOOLEAN;
    FUNCTION can_cancel_request(p_actor_username IN VARCHAR2, p_request_id IN NUMBER) RETURN BOOLEAN;

    PROCEDURE assert_role(p_username IN VARCHAR2, p_role_code IN VARCHAR2);
    PROCEDURE assert_admin(p_username IN VARCHAR2);
    PROCEDURE assert_super_admin(p_username IN VARCHAR2);

    -- Super-Admin lockout protection guards
    PROCEDURE assert_can_deactivate_user(p_user_id IN NUMBER);
    PROCEDURE assert_can_revoke_role(p_user_role_id IN NUMBER);
END hr_auth_pkg;
/

PROMPT Updating HR_AUTH_PKG BODY ...

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DEMO"."HR_AUTH_PKG" AS

    FUNCTION hash_password(p_username IN VARCHAR2, p_password IN VARCHAR2, p_salt IN VARCHAR2) RETURN VARCHAR2 IS
        l_hash VARCHAR2(512);
    BEGIN
        IF p_username IS NULL OR p_password IS NULL OR p_salt IS NULL THEN
            RETURN NULL;
        END IF;
        SELECT STANDARD_HASH(UPPER(TRIM(p_username)) || ':' || p_salt || ':' || p_password, 'SHA512')
          INTO l_hash
          FROM dual;
        RETURN l_hash;
    END hash_password;

    PROCEDURE set_password(p_username IN VARCHAR2, p_password IN VARCHAR2) IS
        l_salt VARCHAR2(128);
        l_hash VARCHAR2(512);
    BEGIN
        IF p_username IS NULL OR p_password IS NULL OR LENGTH(TRIM(p_password)) = 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'Username and non-empty password are required.');
        END IF;
        l_salt := RAWTOHEX(SYS_GUID());
        l_hash := hash_password(p_username, p_password, l_salt);
        UPDATE hr_users
           SET password_salt = l_salt,
               password_hash = l_hash,
               updated_at    = SYSTIMESTAMP,
               updated_by    = COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER)
         WHERE UPPER(username) = UPPER(TRIM(p_username));
    END set_password;

    FUNCTION authenticate(p_username IN VARCHAR2, p_password IN VARCHAR2) RETURN BOOLEAN IS
        l_stored_hash VARCHAR2(512);
        l_salt        VARCHAR2(128);
        l_active_yn   VARCHAR2(1);
        l_calc_hash   VARCHAR2(512);
    BEGIN
        IF p_username IS NULL OR p_password IS NULL OR LENGTH(TRIM(p_password)) = 0 THEN
            RETURN FALSE;
        END IF;

        SELECT password_hash, password_salt, active_yn
          INTO l_stored_hash, l_salt, l_active_yn
          FROM hr_users
         WHERE UPPER(username) = UPPER(TRIM(p_username));

        IF l_active_yn != 'Y' OR l_stored_hash IS NULL OR l_salt IS NULL THEN
            RETURN FALSE;
        END IF;

        l_calc_hash := hash_password(p_username, p_password, l_salt);
        RETURN (l_calc_hash = l_stored_hash);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END authenticate;

    FUNCTION has_role(p_username IN VARCHAR2, p_role_code IN VARCHAR2) RETURN BOOLEAN IS
        l_user   VARCHAR2(100);
        l_cnt    NUMBER;
    BEGIN
        l_user := NVL(p_username, hr_user_pkg.current_username);
        IF l_user IS NULL THEN
            RETURN FALSE;
        END IF;

        SELECT COUNT(*)
          INTO l_cnt
          FROM hr_user_roles ur
          JOIN hr_roles r ON r.role_id = ur.role_id
          JOIN hr_users u ON u.user_id = ur.user_id
         WHERE UPPER(u.username) = UPPER(TRIM(l_user))
           AND UPPER(r.role_code) = UPPER(TRIM(p_role_code))
           AND u.active_yn = 'Y';

        RETURN (l_cnt > 0);
    END has_role;

    FUNCTION is_employee(p_username IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN IS
    BEGIN
        RETURN has_role(p_username, 'EMPLOYEE');
    END is_employee;

    FUNCTION is_manager(p_username IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN IS
    BEGIN
        RETURN has_role(p_username, 'MANAGER');
    END is_manager;

    FUNCTION is_admin(p_username IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN IS
    BEGIN
        RETURN has_role(p_username, 'ADMIN') OR has_role(p_username, 'SUPER_ADMIN');
    END is_admin;

    FUNCTION is_super_admin(p_username IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN IS
    BEGIN
        RETURN has_role(p_username, 'SUPER_ADMIN');
    END is_super_admin;

    FUNCTION can_approve_request(p_actor_username IN VARCHAR2, p_request_id IN NUMBER) RETURN BOOLEAN IS
        l_actor_id   NUMBER;
        l_req_userid NUMBER;
        l_manager_id NUMBER;
        l_status     VARCHAR2(30);
        l_actor      VARCHAR2(100);
    BEGIN
        l_actor := NVL(p_actor_username, hr_user_pkg.current_username);
        IF l_actor IS NULL OR p_request_id IS NULL THEN
            RETURN FALSE;
        END IF;

        -- Super Admins and HR Admins can approve company-wide at any stage
        IF is_admin(l_actor) THEN
            RETURN TRUE;
        END IF;

        l_actor_id := hr_user_pkg.get_user_id(l_actor);
        IF l_actor_id IS NULL THEN
            RETURN FALSE;
        END IF;

        SELECT r.user_id, u.manager_id, r.status
          INTO l_req_userid, l_manager_id, l_status
          FROM hr_leave_requests r
          JOIN hr_users u ON u.user_id = r.user_id
         WHERE r.request_id = p_request_id;

        -- For secondary HR approval tier, only Admin / HR Admin can approve (already returned above)
        IF l_status = 'PENDING_HR_APPROVAL' THEN
            RETURN FALSE;
        END IF;

        -- Direct manager of employee can approve at manager stage ONLY IF they also hold the MANAGER role
        IF l_manager_id = l_actor_id AND has_role(l_actor, 'MANAGER') AND l_status IN ('SUBMITTED', 'PENDING', 'PENDING_MANAGER_APPROVAL') THEN
            RETURN TRUE;
        END IF;

        RETURN FALSE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END can_approve_request;

    FUNCTION can_cancel_request(p_actor_username IN VARCHAR2, p_request_id IN NUMBER) RETURN BOOLEAN IS
        l_actor_id   NUMBER;
        l_req_userid NUMBER;
        l_status     VARCHAR2(30);
        l_start_date DATE;
        l_actor      VARCHAR2(100);
    BEGIN
        l_actor := NVL(p_actor_username, hr_user_pkg.current_username);
        IF l_actor IS NULL OR p_request_id IS NULL THEN
            RETURN FALSE;
        END IF;

        l_actor_id := hr_user_pkg.get_user_id(l_actor);
        IF l_actor_id IS NULL THEN
            RETURN FALSE;
        END IF;

        SELECT user_id, status, start_date
          INTO l_req_userid, l_status, l_start_date
          FROM hr_leave_requests
         WHERE request_id = p_request_id;

        -- Only owner or admin can cancel
        IF l_req_userid != l_actor_id AND NOT is_admin(l_actor) THEN
            RETURN FALSE;
        END IF;

        -- Admins can cancel any pending or workflow error request (operational recovery)
        IF is_admin(l_actor) THEN
            IF l_status IN ('SUBMITTED', 'PENDING', 'PENDING_MANAGER_APPROVAL', 'PENDING_HR_APPROVAL', 'WORKFLOW_ERROR') THEN
                RETURN TRUE;
            END IF;
        ELSE
            -- Employees can cancel only their own pending requests if start date has not passed (same-day allowed)
            IF l_status IN ('SUBMITTED', 'PENDING', 'PENDING_MANAGER_APPROVAL', 'PENDING_HR_APPROVAL')
               AND TRUNC(l_start_date) >= TRUNC(SYSDATE) THEN
                RETURN TRUE;
            END IF;
        END IF;

        RETURN FALSE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END can_cancel_request;

    PROCEDURE assert_role(p_username IN VARCHAR2, p_role_code IN VARCHAR2) IS
    BEGIN
        IF NOT has_role(p_username, p_role_code) THEN
            RAISE_APPLICATION_ERROR(-20001, 'User ' || NVL(p_username, 'ANONYMOUS') || ' lacks required role ' || p_role_code);
        END IF;
    END assert_role;

    PROCEDURE assert_admin(p_username IN VARCHAR2) IS
    BEGIN
        IF NOT is_admin(p_username) THEN
            RAISE_APPLICATION_ERROR(-20002, 'User ' || NVL(p_username, 'ANONYMOUS') || ' lacks administrator privileges');
        END IF;
    END assert_admin;

    PROCEDURE assert_super_admin(p_username IN VARCHAR2) IS
    BEGIN
        IF NOT is_super_admin(p_username) THEN
            RAISE_APPLICATION_ERROR(-20003, 'User ' || NVL(p_username, 'ANONYMOUS') || ' lacks super administrator privileges');
        END IF;
    END assert_super_admin;

    PROCEDURE assert_can_deactivate_user(p_user_id IN NUMBER) IS
        l_is_super_admin NUMBER;
        l_active_count   NUMBER;
    BEGIN
        IF p_user_id IS NULL THEN
            RETURN;
        END IF;

        -- Check if this user is an active SUPER_ADMIN
        SELECT COUNT(*)
          INTO l_is_super_admin
          FROM hr_user_roles ur
          JOIN hr_roles r ON r.role_id = ur.role_id
          JOIN hr_users u ON u.user_id = ur.user_id
         WHERE u.user_id = p_user_id
           AND r.role_code = 'SUPER_ADMIN'
           AND u.active_yn = 'Y';

        IF l_is_super_admin > 0 THEN
            l_active_count := 0;
            FOR rec IN (
                SELECT u.user_id
                  FROM hr_user_roles ur
                  JOIN hr_roles r ON r.role_id = ur.role_id
                  JOIN hr_users u ON u.user_id = ur.user_id
                 WHERE r.role_code = 'SUPER_ADMIN'
                   AND u.active_yn = 'Y'
                   FOR UPDATE OF u.user_id
            ) LOOP
                l_active_count := l_active_count + 1;
            END LOOP;

            IF l_active_count <= 1 THEN
                RAISE_APPLICATION_ERROR(-20021, 'Cannot deactivate the last active SUPER_ADMIN user in the system.');
            END IF;
        END IF;
    END assert_can_deactivate_user;

    PROCEDURE assert_can_revoke_role(p_user_role_id IN NUMBER) IS
        l_is_super_admin NUMBER;
        l_active_count   NUMBER;
    BEGIN
        IF p_user_role_id IS NULL THEN
            RETURN;
        END IF;

        -- Check if this assignment grants SUPER_ADMIN to an active user
        SELECT COUNT(*)
          INTO l_is_super_admin
          FROM hr_user_roles ur
          JOIN hr_roles r ON r.role_id = ur.role_id
          JOIN hr_users u ON u.user_id = ur.user_id
         WHERE ur.user_role_id = p_user_role_id
           AND r.role_code = 'SUPER_ADMIN'
           AND u.active_yn = 'Y';

        IF l_is_super_admin > 0 THEN
            l_active_count := 0;
            FOR rec IN (
                SELECT ur.user_role_id
                  FROM hr_user_roles ur
                  JOIN hr_roles r ON r.role_id = ur.role_id
                  JOIN hr_users u ON u.user_id = ur.user_id
                 WHERE r.role_code = 'SUPER_ADMIN'
                   AND u.active_yn = 'Y'
                   FOR UPDATE OF ur.user_role_id
            ) LOOP
                l_active_count := l_active_count + 1;
            END LOOP;

            IF l_active_count <= 1 THEN
                RAISE_APPLICATION_ERROR(-20022, 'Cannot revoke the last active SUPER_ADMIN role assignment in the system.');
            END IF;
        END IF;
    END assert_can_revoke_role;

END hr_auth_pkg;
/

PROMPT HR_AUTH_PKG updated successfully.

