
  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DEMO"."HR_AUTH_PKG" AS

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
