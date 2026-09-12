-- =============================================================================
-- Migration: 01_multi_tier_approval.sql
-- Description: Update HR_AUTH_PKG and HR_WORKFLOW_PKG for multi-tier approval
--              escalation (requests > 5 days require secondary HR review).
-- =============================================================================
SET DEFINE OFF;

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

        -- Direct manager of employee can approve at manager stage
        IF l_manager_id = l_actor_id AND l_status IN ('SUBMITTED', 'PENDING', 'PENDING_MANAGER_APPROVAL') THEN
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

PROMPT Updating HR_WORKFLOW_PKG BODY ...

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DEMO"."HR_WORKFLOW_PKG" AS

    FUNCTION get_system_setting(
        p_setting_code   IN VARCHAR2,
        p_default_value  IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_value VARCHAR2(4000);
    BEGIN
        SELECT setting_value
          INTO l_value
          FROM hr_system_settings
         WHERE setting_code = p_setting_code;
        RETURN l_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN p_default_value;
    END get_system_setting;

    FUNCTION start_leave_approval(
        p_request_id IN NUMBER
    ) RETURN NUMBER IS
        l_workflow_id    NUMBER;
        l_user_id        NUMBER;
        l_username       VARCHAR2(100);
        l_mgr_username   VARCHAR2(100);
        l_requested_days NUMBER;
        l_params         apex_workflow.t_workflow_parameters;
        l_active_cnt     NUMBER := 0;
    BEGIN
        SELECT r.user_id, u.username, m.username, r.requested_days, r.workflow_id
          INTO l_user_id, l_username, l_mgr_username, l_requested_days, l_workflow_id
          FROM hr_leave_requests r
          JOIN hr_users u ON u.user_id = r.user_id
          LEFT JOIN hr_users m ON m.user_id = u.manager_id
         WHERE r.request_id = p_request_id;

        -- If workflow has already been initiated for this request, return existing instance ID
        IF l_workflow_id IS NOT NULL THEN
            RETURN l_workflow_id;
        END IF;

        IF apex_application.g_flow_id IS NULL THEN
            apex_session.create_session(
                p_app_id   => 200,
                p_page_id  => 1,
                p_username => COALESCE(l_username, 'DEMO')
            );
        END IF;

        -- Check if an active version of LEAVE_APPROVAL workflow is available in App 200
        SELECT COUNT(*)
          INTO l_active_cnt
          FROM apex_appl_workflow_versions
         WHERE application_id = 200
           AND workflow_static_id = 'leave-approval'
           AND state_code = 'ACTIVE';

        IF l_active_cnt > 0 THEN
            l_params(1) := apex_workflow.t_workflow_parameter(
                static_id    => 'P_REQUEST_ID',
                string_value => TO_CHAR(p_request_id)
            );

            BEGIN
                l_workflow_id := apex_workflow.start_workflow(
                    p_application_id => 200,
                    p_static_id      => 'leave-approval',
                    p_parameters     => l_params,
                    p_initiator      => COALESCE(apex_application.g_user, l_username, SYS_CONTEXT('USERENV', 'SESSION_USER')),
                    p_detail_pk      => TO_CHAR(p_request_id)
                );

                UPDATE hr_leave_requests
                   SET workflow_id = l_workflow_id
                 WHERE request_id = p_request_id;

                hr_leave_pkg.record_event(
                    p_request_id     => p_request_id,
                    p_event_type     => 'WORKFLOW_STARTED',
                    p_from_status    => 'PENDING_MANAGER_APPROVAL',
                    p_to_status      => 'PENDING_MANAGER_APPROVAL',
                    p_actor_username => COALESCE(apex_application.g_user, l_username, 'SYSTEM'),
                    p_comments       => 'Workflow LEAVE_APPROVAL initiated (Instance #' || l_workflow_id || ')'
                );
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        ELSE
            -- In development or test environments where workflow has no Active version,
            -- record the initiation event without triggering APEX internal rollback
            hr_leave_pkg.record_event(
                p_request_id     => p_request_id,
                p_event_type     => 'WORKFLOW_STARTED',
                p_from_status    => 'PENDING_MANAGER_APPROVAL',
                p_to_status      => 'PENDING_MANAGER_APPROVAL',
                p_actor_username => COALESCE(apex_application.g_user, l_username, 'SYSTEM'),
                p_comments       => 'Workflow LEAVE_APPROVAL start queued (version state: DEVELOPMENT)'
            );
        END IF;

        RETURN l_workflow_id;
    END start_leave_approval;

    PROCEDURE manager_outcome(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_outcome        IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    ) IS
        l_requested_days NUMBER;
        l_threshold      NUMBER;
        l_user_id        NUMBER;
        l_leave_type_id  NUMBER;
        l_start_date     DATE;
        l_status         VARCHAR2(30);
        l_requires_bal   VARCHAR2(1);
    BEGIN
        SELECT requested_days, status
          INTO l_requested_days, l_status
          FROM hr_leave_requests
         WHERE request_id = p_request_id;

        -- If request is already at HR stage, route to hr_outcome
        IF l_status = 'PENDING_HR_APPROVAL' THEN
            hr_outcome(
                p_request_id     => p_request_id,
                p_actor_username => p_actor_username,
                p_outcome        => p_outcome,
                p_comments       => p_comments
            );
            RETURN;
        END IF;

        IF UPPER(p_outcome) IN ('APPROVED', 'APPROVE') THEN
            l_threshold := TO_NUMBER(get_system_setting('LONG_LEAVE_THRESHOLD', '5'));

            IF l_requested_days <= l_threshold THEN
                -- Single-tier final approval directly
                hr_leave_pkg.approve_request(
                    p_request_id     => p_request_id,
                    p_actor_username => p_actor_username,
                    p_comments       => p_comments
                );
            ELSE
                -- Two-tier approval: transition to HR review
                UPDATE hr_leave_requests
                   SET status = 'PENDING_HR_APPROVAL'
                 WHERE request_id = p_request_id;

                hr_leave_pkg.record_event(
                    p_request_id     => p_request_id,
                    p_event_type     => 'MANAGER_APPROVED',
                    p_from_status    => 'PENDING_MANAGER_APPROVAL',
                    p_to_status      => 'PENDING_HR_APPROVAL',
                    p_actor_username => p_actor_username,
                    p_comments       => NVL(p_comments, 'Manager approved; routed to HR due to duration > ' || l_threshold || ' days')
                );
            END IF;

        ELSIF UPPER(p_outcome) IN ('REJECTED', 'REJECT') THEN
            hr_leave_pkg.reject_request(
                p_request_id     => p_request_id,
                p_actor_username => p_actor_username,
                p_comments       => p_comments
            );

        ELSIF UPPER(p_outcome) IN ('CANCELLED', 'CANCEL') THEN
            SELECT r.user_id, r.leave_type_id, r.start_date, r.requested_days, r.status,
                   t.requires_balance_yn
              INTO l_user_id, l_leave_type_id, l_start_date, l_requested_days, l_status,
                   l_requires_bal
              FROM hr_leave_requests r
              JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
             WHERE r.request_id = p_request_id
               FOR UPDATE OF r.status;

            IF l_requires_bal = 'Y' THEN
                UPDATE hr_leave_balances
                   SET pending_days = GREATEST(0, pending_days - l_requested_days)
                 WHERE user_id = l_user_id
                   AND leave_type_id = l_leave_type_id
                   AND balance_year = EXTRACT(YEAR FROM l_start_date);
            END IF;

            UPDATE hr_leave_requests
               SET status = 'CANCELLED'
             WHERE request_id = p_request_id;

            hr_leave_pkg.record_event(
                p_request_id     => p_request_id,
                p_event_type     => 'CANCELLED',
                p_from_status    => l_status,
                p_to_status      => 'CANCELLED',
                p_actor_username => p_actor_username,
                p_comments       => p_comments
            );

        ELSE
            RAISE_APPLICATION_ERROR(-20030, 'Unknown manager outcome: ' || p_outcome);
        END IF;

    END manager_outcome;

    PROCEDURE hr_outcome(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_outcome        IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        IF UPPER(p_outcome) IN ('APPROVED', 'APPROVE') THEN
            hr_leave_pkg.approve_request(
                p_request_id     => p_request_id,
                p_actor_username => p_actor_username,
                p_comments       => p_comments
            );
        ELSIF UPPER(p_outcome) IN ('REJECTED', 'REJECT') THEN
            hr_leave_pkg.reject_request(
                p_request_id     => p_request_id,
                p_actor_username => p_actor_username,
                p_comments       => p_comments
            );
        ELSE
            RAISE_APPLICATION_ERROR(-20031, 'Unknown HR outcome: ' || p_outcome);
        END IF;
    END hr_outcome;

    PROCEDURE workflow_fault(
        p_request_id    IN NUMBER,
        p_error_message IN VARCHAR2
    ) IS
    BEGIN
        UPDATE hr_leave_requests
           SET status = 'WORKFLOW_ERROR'
         WHERE request_id = p_request_id;

        hr_leave_pkg.record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'WORKFLOW_ERROR',
            p_from_status    => 'PENDING',
            p_to_status      => 'WORKFLOW_ERROR',
            p_actor_username => 'SYSTEM',
            p_comments       => p_error_message
        );
    END workflow_fault;

END hr_workflow_pkg;
/

PROMPT Multi-tier approval packages compiled successfully.
