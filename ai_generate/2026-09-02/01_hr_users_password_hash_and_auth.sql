-- ============================================================================
-- 01_hr_users_password_hash_and_auth.sql
-- Episode 6: Custom Authentication & Salted SHA512 Password Hashing
-- ============================================================================
SET DEFINE OFF;

PROMPT Adding PASSWORD_HASH and PASSWORD_SALT columns to HR_USERS...

DECLARE
    v_col_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_col_count
      FROM user_tab_cols
     WHERE table_name = 'HR_USERS'
       AND column_name = 'PASSWORD_HASH';

    IF v_col_count = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE hr_users ADD (password_hash VARCHAR2(512 CHAR), password_salt VARCHAR2(128 CHAR))';
        DBMS_OUTPUT.PUT_LINE('Added PASSWORD_HASH and PASSWORD_SALT columns to HR_USERS.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('PASSWORD_HASH column already exists on HR_USERS.');
    END IF;
END;
/

PROMPT Updating HR_AUTH_PKG Specification...

CREATE OR REPLACE PACKAGE hr_auth_pkg AS
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
END hr_auth_pkg;
/

PROMPT Updating HR_AUTH_PKG Body...

CREATE OR REPLACE PACKAGE BODY hr_auth_pkg AS

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
        WHEN OTHERS THEN
            RETURN FALSE;
    END authenticate;

    FUNCTION has_role(p_username IN VARCHAR2, p_role_code IN VARCHAR2) RETURN BOOLEAN IS
        l_cnt PLS_INTEGER;
        l_uname VARCHAR2(100);
    BEGIN
        l_uname := NVL(p_username, hr_user_pkg.current_username);
        IF l_uname IS NULL OR p_role_code IS NULL THEN
            RETURN FALSE;
        END IF;

        SELECT COUNT(*)
          INTO l_cnt
          FROM hr_user_roles ur
          JOIN hr_users u ON u.user_id = ur.user_id
          JOIN hr_roles r ON r.role_id = ur.role_id
         WHERE UPPER(u.username) = UPPER(TRIM(l_uname))
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
        RETURN has_role(p_username, 'MANAGER') OR has_role(p_username, 'ADMIN') OR has_role(p_username, 'SUPER_ADMIN');
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
        l_actor      VARCHAR2(100);
    BEGIN
        l_actor := NVL(p_actor_username, hr_user_pkg.current_username);
        IF l_actor IS NULL OR p_request_id IS NULL THEN
            RETURN FALSE;
        END IF;

        -- Super Admins and HR Admins can approve company-wide
        IF is_admin(l_actor) THEN
            RETURN TRUE;
        END IF;

        l_actor_id := hr_user_pkg.get_user_id(l_actor);
        IF l_actor_id IS NULL THEN
            RETURN FALSE;
        END IF;

        SELECT r.user_id, u.manager_id
          INTO l_req_userid, l_manager_id
          FROM hr_leave_requests r
          JOIN hr_users u ON u.user_id = r.user_id
         WHERE r.request_id = p_request_id;

        -- Direct manager of employee
        IF l_manager_id = l_actor_id THEN
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

        -- Only cancellable if still pending / submitted and start date has not passed
        IF l_status IN ('SUBMITTED', 'PENDING', 'PENDING_MANAGER_APPROVAL', 'PENDING_HR_APPROVAL')
           AND l_start_date >= TRUNC(SYSDATE) THEN
            RETURN TRUE;
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

END hr_auth_pkg;
/

PROMPT Initializing passwords for existing users to 'oracle'...

BEGIN
    FOR r IN (SELECT username FROM hr_users) LOOP
        hr_auth_pkg.set_password(r.username, 'oracle');
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Seeded default passwords (oracle) for all HR_USERS successfully.');
END;
/

