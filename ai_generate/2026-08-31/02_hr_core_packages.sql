-- =============================================================================
-- Script: 02_hr_core_packages.sql
-- Date:   2026-08-31
-- Target: Oracle Database 19c / APEX 26.1 / DEMO Schema
-- Scope:  Creates package specifications and bodies for:
--         1. HR_USER_PKG
--         2. HR_AUTH_PKG
--         3. HR_LEAVE_PKG
--         4. HR_WORKFLOW_PKG
--         5. HR_AI_PKG
-- =============================================================================

SET DEFINE OFF;
SET SERVEROUTPUT ON;

-- =============================================================================
-- 1. HR_USER_PKG (Specification)
-- =============================================================================
CREATE OR REPLACE PACKAGE hr_user_pkg AS
    FUNCTION current_username RETURN VARCHAR2;
    FUNCTION current_user_id RETURN NUMBER;
    FUNCTION get_user_id(p_username IN VARCHAR2) RETURN NUMBER;
    FUNCTION get_username(p_user_id IN NUMBER) RETURN VARCHAR2;
    FUNCTION get_manager_id(p_user_id IN NUMBER) RETURN NUMBER;
    FUNCTION get_manager_username(p_user_id IN NUMBER) RETURN VARCHAR2;
    FUNCTION is_active_user(p_username IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION is_active_user(p_user_id IN NUMBER) RETURN BOOLEAN;
END hr_user_pkg;
/

-- =============================================================================
-- 2. HR_AUTH_PKG (Specification)
-- =============================================================================
CREATE OR REPLACE PACKAGE hr_auth_pkg AS
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

-- =============================================================================
-- 3. HR_LEAVE_PKG (Specification)
-- =============================================================================
CREATE OR REPLACE PACKAGE hr_leave_pkg AS
    FUNCTION calculate_days(
        p_start_date IN DATE,
        p_end_date   IN DATE
    ) RETURN NUMBER;

    FUNCTION get_available_days(
        p_user_id       IN NUMBER,
        p_leave_type_id IN NUMBER,
        p_year          IN NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE)
    ) RETURN NUMBER;

    FUNCTION get_available_days(
        p_username        IN VARCHAR2,
        p_leave_type_code IN VARCHAR2,
        p_year            IN NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE)
    ) RETURN NUMBER;

    FUNCTION validate_overlap(
        p_user_id            IN NUMBER,
        p_start_date         IN DATE,
        p_end_date           IN DATE,
        p_exclude_request_id IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN;

    PROCEDURE record_event(
        p_request_id     IN NUMBER,
        p_event_type     IN VARCHAR2,
        p_from_status    IN VARCHAR2,
        p_to_status      IN VARCHAR2,
        p_actor_username IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE create_request(
        p_username        IN VARCHAR2,
        p_leave_type_code IN VARCHAR2,
        p_start_date      IN DATE,
        p_end_date        IN DATE,
        p_reason          IN VARCHAR2 DEFAULT NULL,
        p_request_id      OUT NUMBER
    );

    PROCEDURE approve_request(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE reject_request(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE cancel_request(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_reason         IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE adjust_balance(
        p_user_id          IN NUMBER,
        p_leave_type_code  IN VARCHAR2,
        p_year             IN NUMBER,
        p_adjustment_delta IN NUMBER,
        p_actor_username   IN VARCHAR2,
        p_reason           IN VARCHAR2
    );
END hr_leave_pkg;
/

-- =============================================================================
-- 4. HR_WORKFLOW_PKG (Specification)
-- =============================================================================
CREATE OR REPLACE PACKAGE hr_workflow_pkg AS
    FUNCTION get_system_setting(
        p_setting_code   IN VARCHAR2,
        p_default_value  IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION start_leave_approval(
        p_request_id IN NUMBER
    ) RETURN NUMBER;

    PROCEDURE manager_outcome(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_outcome        IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE hr_outcome(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_outcome        IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE workflow_fault(
        p_request_id    IN NUMBER,
        p_error_message IN VARCHAR2
    );
END hr_workflow_pkg;
/

-- =============================================================================
-- 5. HR_AI_PKG (Specification)
-- =============================================================================
CREATE OR REPLACE PACKAGE hr_ai_pkg AS
    FUNCTION get_my_profile RETURN CLOB;

    FUNCTION get_leave_balance(
        p_leave_type_code IN VARCHAR2 DEFAULT 'ANNUAL'
    ) RETURN CLOB;

    FUNCTION get_my_leave_requests(
        p_status    IN VARCHAR2 DEFAULT NULL,
        p_date_from IN DATE DEFAULT NULL,
        p_date_to   IN DATE DEFAULT NULL
    ) RETURN CLOB;

    FUNCTION get_leave_request(
        p_request_id IN NUMBER
    ) RETURN CLOB;

    FUNCTION calculate_leave_days(
        p_start_date IN DATE,
        p_end_date   IN DATE
    ) RETURN CLOB;

    FUNCTION create_leave_request(
        p_leave_type_code IN VARCHAR2,
        p_start_date      IN DATE,
        p_end_date        IN DATE,
        p_reason          IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    FUNCTION cancel_leave_request(
        p_request_id IN NUMBER,
        p_reason     IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    FUNCTION generate_request_summary(
        p_request_id IN NUMBER
    ) RETURN CLOB;
END hr_ai_pkg;
/

-- =============================================================================
-- 1. HR_USER_PKG (Body)
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY hr_user_pkg AS

    FUNCTION current_username RETURN VARCHAR2 IS
        l_user VARCHAR2(100);
    BEGIN
        l_user := COALESCE(
            SYS_CONTEXT('APEX$SESSION', 'APP_USER'),
            SYS_CONTEXT('USERENV', 'SESSION_USER'),
            USER
        );
        RETURN UPPER(TRIM(l_user));
    END current_username;

    FUNCTION current_user_id RETURN NUMBER IS
        l_user_id NUMBER;
        l_uname   VARCHAR2(100);
    BEGIN
        l_uname := current_username;
        SELECT user_id
          INTO l_user_id
          FROM hr_users
         WHERE UPPER(username) = l_uname
           AND active_yn = 'Y';
        RETURN l_user_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END current_user_id;

    FUNCTION get_user_id(p_username IN VARCHAR2) RETURN NUMBER IS
        l_user_id NUMBER;
    BEGIN
        IF p_username IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT user_id
          INTO l_user_id
          FROM hr_users
         WHERE UPPER(username) = UPPER(TRIM(p_username));
        RETURN l_user_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_user_id;

    FUNCTION get_username(p_user_id IN NUMBER) RETURN VARCHAR2 IS
        l_username VARCHAR2(100);
    BEGIN
        IF p_user_id IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT username
          INTO l_username
          FROM hr_users
         WHERE user_id = p_user_id;
        RETURN l_username;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_username;

    FUNCTION get_manager_id(p_user_id IN NUMBER) RETURN NUMBER IS
        l_manager_id NUMBER;
    BEGIN
        IF p_user_id IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT manager_id
          INTO l_manager_id
          FROM hr_users
         WHERE user_id = p_user_id;
        RETURN l_manager_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_manager_id;

    FUNCTION get_manager_username(p_user_id IN NUMBER) RETURN VARCHAR2 IS
        l_mgr_username VARCHAR2(100);
    BEGIN
        IF p_user_id IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT m.username
          INTO l_mgr_username
          FROM hr_users u
          JOIN hr_users m ON m.user_id = u.manager_id
         WHERE u.user_id = p_user_id;
        RETURN l_mgr_username;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_manager_username;

    FUNCTION is_active_user(p_username IN VARCHAR2) RETURN BOOLEAN IS
        l_cnt PLS_INTEGER;
    BEGIN
        IF p_username IS NULL THEN
            RETURN FALSE;
        END IF;

        SELECT COUNT(*)
          INTO l_cnt
          FROM hr_users
         WHERE UPPER(username) = UPPER(TRIM(p_username))
           AND active_yn = 'Y';
        RETURN (l_cnt > 0);
    END is_active_user;

    FUNCTION is_active_user(p_user_id IN NUMBER) RETURN BOOLEAN IS
        l_cnt PLS_INTEGER;
    BEGIN
        IF p_user_id IS NULL THEN
            RETURN FALSE;
        END IF;

        SELECT COUNT(*)
          INTO l_cnt
          FROM hr_users
         WHERE user_id = p_user_id
           AND active_yn = 'Y';
        RETURN (l_cnt > 0);
    END is_active_user;

END hr_user_pkg;
/

-- =============================================================================
-- 2. HR_AUTH_PKG (Body)
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY hr_auth_pkg AS

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

-- =============================================================================
-- 3. HR_LEAVE_PKG (Body)
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY hr_leave_pkg AS

    FUNCTION calculate_days(
        p_start_date IN DATE,
        p_end_date   IN DATE
    ) RETURN NUMBER IS
        l_days  NUMBER := 0;
        l_curr  DATE;
        l_day_n NUMBER;
    BEGIN
        IF p_start_date IS NULL OR p_end_date IS NULL THEN
            RETURN 0;
        END IF;

        IF TRUNC(p_end_date) < TRUNC(p_start_date) THEN
            RAISE_APPLICATION_ERROR(-20010, 'End date cannot be prior to start date');
        END IF;

        l_curr := TRUNC(p_start_date);
        WHILE l_curr <= TRUNC(p_end_date) LOOP
            -- 1 = Sunday, 7 = Saturday in standard Oracle format
            l_day_n := TO_NUMBER(TO_CHAR(l_curr, 'D'));
            IF l_day_n NOT IN (1, 7) THEN
                l_days := l_days + 1;
            END IF;
            l_curr := l_curr + 1;
        END LOOP;

        RETURN l_days;
    END calculate_days;

    FUNCTION get_available_days(
        p_user_id       IN NUMBER,
        p_leave_type_id IN NUMBER,
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

    FUNCTION get_available_days(
        p_username        IN VARCHAR2,
        p_leave_type_code IN VARCHAR2,
        p_year            IN NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE)
    ) RETURN NUMBER IS
        l_user_id       NUMBER;
        l_leave_type_id NUMBER;
    BEGIN
        l_user_id := hr_user_pkg.get_user_id(p_username);
        IF l_user_id IS NULL THEN
            RETURN 0;
        END IF;

        SELECT leave_type_id
          INTO l_leave_type_id
          FROM hr_leave_types
         WHERE UPPER(leave_type_code) = UPPER(TRIM(p_leave_type_code));

        RETURN get_available_days(l_user_id, l_leave_type_id, p_year);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END get_available_days;

    FUNCTION validate_overlap(
        p_user_id            IN NUMBER,
        p_start_date         IN DATE,
        p_end_date           IN DATE,
        p_exclude_request_id IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN IS
        l_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM hr_leave_requests
         WHERE user_id = p_user_id
           AND status NOT IN ('REJECTED', 'CANCELLED')
           AND (p_exclude_request_id IS NULL OR request_id != p_exclude_request_id)
           AND TRUNC(start_date) <= TRUNC(p_end_date)
           AND TRUNC(end_date)   >= TRUNC(p_start_date);

        RETURN (l_count > 0);
    END validate_overlap;

    PROCEDURE record_event(
        p_request_id     IN NUMBER,
        p_event_type     IN VARCHAR2,
        p_from_status    IN VARCHAR2,
        p_to_status      IN VARCHAR2,
        p_actor_username IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        INSERT INTO hr_leave_request_events (
            request_id,
            event_type,
            from_status,
            to_status,
            actor_username,
            comments,
            event_timestamp
        ) VALUES (
            p_request_id,
            p_event_type,
            p_from_status,
            p_to_status,
            NVL(p_actor_username, hr_user_pkg.current_username),
            p_comments,
            SYSTIMESTAMP
        );
    END record_event;

    PROCEDURE create_request(
        p_username        IN VARCHAR2,
        p_leave_type_code IN VARCHAR2,
        p_start_date      IN DATE,
        p_end_date        IN DATE,
        p_reason          IN VARCHAR2 DEFAULT NULL,
        p_request_id      OUT NUMBER
    ) IS
        l_user_id        NUMBER;
        l_leave_type_id  NUMBER;
        l_requires_bal   VARCHAR2(1);
        l_type_active    VARCHAR2(1);
        l_requested_days NUMBER;
        l_year           NUMBER;
        l_balance_id     NUMBER;
        l_entitlement    NUMBER;
        l_adjustment     NUMBER;
        l_used           NUMBER;
        l_pending        NUMBER;
        l_available      NUMBER;
    BEGIN
        -- 1. Resolve User
        l_user_id := hr_user_pkg.get_user_id(p_username);
        IF l_user_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20011, 'Invalid or unknown user: ' || p_username);
        END IF;

        IF NOT hr_user_pkg.is_active_user(l_user_id) THEN
            RAISE_APPLICATION_ERROR(-20012, 'Employee account is inactive');
        END IF;

        -- 2. Resolve Leave Type
        BEGIN
            SELECT leave_type_id, requires_balance_yn, active_yn
              INTO l_leave_type_id, l_requires_bal, l_type_active
              FROM hr_leave_types
             WHERE UPPER(leave_type_code) = UPPER(TRIM(p_leave_type_code));
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20013, 'Invalid leave type: ' || p_leave_type_code);
        END;

        IF l_type_active != 'Y' THEN
            RAISE_APPLICATION_ERROR(-20014, 'Selected leave type is inactive');
        END IF;

        -- 3. Validate Dates & Compute Days
        IF p_start_date IS NULL OR p_end_date IS NULL THEN
            RAISE_APPLICATION_ERROR(-20015, 'Start date and end date are required');
        END IF;

        l_requested_days := calculate_days(p_start_date, p_end_date);
        IF l_requested_days <= 0 THEN
            RAISE_APPLICATION_ERROR(-20016, 'Requested duration must be at least 1 working day');
        END IF;

        -- 4. Check Overlap
        IF validate_overlap(l_user_id, p_start_date, p_end_date) THEN
            RAISE_APPLICATION_ERROR(-20017, 'Leave request overlaps with an existing active request');
        END IF;

        l_year := EXTRACT(YEAR FROM p_start_date);

        -- 5. Atomic Balance Reservation with Row-Level Lock
        IF l_requires_bal = 'Y' THEN
            BEGIN
                SELECT balance_id, entitlement_days, adjustment_days, used_days, pending_days
                  INTO l_balance_id, l_entitlement, l_adjustment, l_used, l_pending
                  FROM hr_leave_balances
                 WHERE user_id = l_user_id
                   AND leave_type_id = l_leave_type_id
                   AND balance_year = l_year
                   FOR UPDATE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20018, 'No leave balance allocated for year ' || l_year);
            END;

            l_available := l_entitlement + l_adjustment - l_used - l_pending;
            IF l_available < l_requested_days THEN
                RAISE_APPLICATION_ERROR(-20019,
                    'Insufficient leave balance. Available: ' || l_available ||
                    ' day(s), Requested: ' || l_requested_days || ' day(s)');
            END IF;

            -- Reserve pending days atomically
            UPDATE hr_leave_balances
               SET pending_days = pending_days + l_requested_days
             WHERE balance_id = l_balance_id;
        END IF;

        -- 6. Insert Request
        INSERT INTO hr_leave_requests (
            user_id,
            leave_type_id,
            start_date,
            end_date,
            requested_days,
            reason,
            status
        ) VALUES (
            l_user_id,
            l_leave_type_id,
            TRUNC(p_start_date),
            TRUNC(p_end_date),
            l_requested_days,
            p_reason,
            'PENDING_MANAGER_APPROVAL'
        ) RETURNING request_id INTO p_request_id;

        -- 7. Record Lifecycle Event
        record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'SUBMITTED',
            p_from_status    => 'DRAFT',
            p_to_status      => 'PENDING_MANAGER_APPROVAL',
            p_actor_username => UPPER(p_username),
            p_comments       => p_reason
        );

    END create_request;

    PROCEDURE approve_request(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    ) IS
        l_user_id        NUMBER;
        l_leave_type_id  NUMBER;
        l_start_date     DATE;
        l_requested_days NUMBER;
        l_status         VARCHAR2(30);
        l_requires_bal   VARCHAR2(1);
        l_year           NUMBER;
    BEGIN
        -- 1. Lock and validate request
        SELECT r.user_id, r.leave_type_id, r.start_date, r.requested_days, r.status,
               t.requires_balance_yn
          INTO l_user_id, l_leave_type_id, l_start_date, l_requested_days, l_status,
               l_requires_bal
          FROM hr_leave_requests r
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.request_id = p_request_id
           FOR UPDATE OF r.status;

        IF l_status NOT IN ('SUBMITTED', 'PENDING', 'PENDING_MANAGER_APPROVAL', 'PENDING_HR_APPROVAL') THEN
            RAISE_APPLICATION_ERROR(-20020, 'Request is not in an approvable state: ' || l_status);
        END IF;

        -- 2. Authorization check
        IF NOT hr_auth_pkg.can_approve_request(p_actor_username, p_request_id) THEN
            RAISE_APPLICATION_ERROR(-20021, 'Actor is not authorized to approve this leave request');
        END IF;

        -- 3. Atomic Balance Transition: PENDING -> USED
        IF l_requires_bal = 'Y' THEN
            l_year := EXTRACT(YEAR FROM l_start_date);
            UPDATE hr_leave_balances
               SET pending_days = GREATEST(0, pending_days - l_requested_days),
                   used_days    = used_days + l_requested_days
             WHERE user_id = l_user_id
               AND leave_type_id = l_leave_type_id
               AND balance_year = l_year;
        END IF;

        -- 4. Update Request Status
        UPDATE hr_leave_requests
           SET status = 'APPROVED'
         WHERE request_id = p_request_id;

        -- 5. Record Event
        record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'APPROVED',
            p_from_status    => l_status,
            p_to_status      => 'APPROVED',
            p_actor_username => p_actor_username,
            p_comments       => p_comments
        );

    END approve_request;

    PROCEDURE reject_request(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    ) IS
        l_user_id        NUMBER;
        l_leave_type_id  NUMBER;
        l_start_date     DATE;
        l_requested_days NUMBER;
        l_status         VARCHAR2(30);
        l_requires_bal   VARCHAR2(1);
        l_year           NUMBER;
    BEGIN
        -- 1. Lock and validate request
        SELECT r.user_id, r.leave_type_id, r.start_date, r.requested_days, r.status,
               t.requires_balance_yn
          INTO l_user_id, l_leave_type_id, l_start_date, l_requested_days, l_status,
               l_requires_bal
          FROM hr_leave_requests r
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.request_id = p_request_id
           FOR UPDATE OF r.status;

        IF l_status NOT IN ('SUBMITTED', 'PENDING', 'PENDING_MANAGER_APPROVAL', 'PENDING_HR_APPROVAL') THEN
            RAISE_APPLICATION_ERROR(-20022, 'Request is not in a rejectable state: ' || l_status);
        END IF;

        -- 2. Authorization check
        IF NOT hr_auth_pkg.can_approve_request(p_actor_username, p_request_id) THEN
            RAISE_APPLICATION_ERROR(-20023, 'Actor is not authorized to reject this leave request');
        END IF;

        -- 3. Release reserved pending days
        IF l_requires_bal = 'Y' THEN
            l_year := EXTRACT(YEAR FROM l_start_date);
            UPDATE hr_leave_balances
               SET pending_days = GREATEST(0, pending_days - l_requested_days)
             WHERE user_id = l_user_id
               AND leave_type_id = l_leave_type_id
               AND balance_year = l_year;
        END IF;

        -- 4. Update Request Status
        UPDATE hr_leave_requests
           SET status = 'REJECTED'
         WHERE request_id = p_request_id;

        -- 5. Record Event
        record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'REJECTED',
            p_from_status    => l_status,
            p_to_status      => 'REJECTED',
            p_actor_username => p_actor_username,
            p_comments       => p_comments
        );

    END reject_request;

    PROCEDURE cancel_request(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_reason         IN VARCHAR2 DEFAULT NULL
    ) IS
        l_user_id        NUMBER;
        l_leave_type_id  NUMBER;
        l_start_date     DATE;
        l_requested_days NUMBER;
        l_status         VARCHAR2(30);
        l_requires_bal   VARCHAR2(1);
        l_year           NUMBER;
    BEGIN
        -- 1. Lock and validate request
        SELECT r.user_id, r.leave_type_id, r.start_date, r.requested_days, r.status,
               t.requires_balance_yn
          INTO l_user_id, l_leave_type_id, l_start_date, l_requested_days, l_status,
               l_requires_bal
          FROM hr_leave_requests r
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.request_id = p_request_id
           FOR UPDATE OF r.status;

        -- 2. Authorization check
        IF NOT hr_auth_pkg.can_cancel_request(p_actor_username, p_request_id) THEN
            RAISE_APPLICATION_ERROR(-20024, 'Request cannot be cancelled or actor is not authorized');
        END IF;

        -- 3. Release reserved pending days
        IF l_requires_bal = 'Y' THEN
            l_year := EXTRACT(YEAR FROM l_start_date);
            UPDATE hr_leave_balances
               SET pending_days = GREATEST(0, pending_days - l_requested_days)
             WHERE user_id = l_user_id
               AND leave_type_id = l_leave_type_id
               AND balance_year = l_year;
        END IF;

        -- 4. Update Request Status
        UPDATE hr_leave_requests
           SET status = 'CANCELLED'
         WHERE request_id = p_request_id;

        -- 5. Record Event
        record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'CANCELLED',
            p_from_status    => l_status,
            p_to_status      => 'CANCELLED',
            p_actor_username => p_actor_username,
            p_comments       => p_reason
        );

    END cancel_request;

    PROCEDURE adjust_balance(
        p_user_id          IN NUMBER,
        p_leave_type_code  IN VARCHAR2,
        p_year             IN NUMBER,
        p_adjustment_delta IN NUMBER,
        p_actor_username   IN VARCHAR2,
        p_reason           IN VARCHAR2
    ) IS
        l_leave_type_id NUMBER;
        l_balance_id    NUMBER;
    BEGIN
        -- 1. Authorization check
        hr_auth_pkg.assert_admin(p_actor_username);

        IF p_reason IS NULL OR TRIM(p_reason) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20025, 'Audit reason is mandatory for balance adjustment');
        END IF;

        SELECT leave_type_id
          INTO l_leave_type_id
          FROM hr_leave_types
         WHERE UPPER(leave_type_code) = UPPER(TRIM(p_leave_type_code));

        BEGIN
            SELECT balance_id
              INTO l_balance_id
              FROM hr_leave_balances
             WHERE user_id = p_user_id
               AND leave_type_id = l_leave_type_id
               AND balance_year = p_year
               FOR UPDATE;

            UPDATE hr_leave_balances
               SET adjustment_days = adjustment_days + p_adjustment_delta
             WHERE balance_id = l_balance_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO hr_leave_balances (
                    user_id,
                    leave_type_id,
                    balance_year,
                    entitlement_days,
                    used_days,
                    pending_days,
                    adjustment_days
                ) VALUES (
                    p_user_id,
                    l_leave_type_id,
                    p_year,
                    0,
                    0,
                    0,
                    p_adjustment_delta
                );
        END;

    END adjust_balance;

END hr_leave_pkg;
/

-- =============================================================================
-- 4. HR_WORKFLOW_PKG (Body)
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY hr_workflow_pkg AS

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
    BEGIN
        SELECT r.user_id, u.username, m.username, r.requested_days
          INTO l_user_id, l_username, l_mgr_username, l_requested_days
          FROM hr_leave_requests r
          JOIN hr_users u ON u.user_id = r.user_id
          LEFT JOIN hr_users m ON m.user_id = u.manager_id
         WHERE r.request_id = p_request_id;

        -- Generate a synthetic or APEX workflow instance ID
        l_workflow_id := NVL(TO_NUMBER(TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3')), p_request_id + 1000);

        UPDATE hr_leave_requests
           SET workflow_id = l_workflow_id
         WHERE request_id = p_request_id;

        hr_leave_pkg.record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'WORKFLOW_STARTED',
            p_from_status    => 'PENDING_MANAGER_APPROVAL',
            p_to_status      => 'PENDING_MANAGER_APPROVAL',
            p_actor_username => 'SYSTEM',
            p_comments       => 'Workflow LEAVE_APPROVAL initiated (Instance #' || l_workflow_id || ')'
        );

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
    BEGIN
        IF UPPER(p_outcome) IN ('APPROVED', 'APPROVE') THEN
            l_threshold := TO_NUMBER(get_system_setting('LONG_LEAVE_THRESHOLD', '5'));

            SELECT requested_days
              INTO l_requested_days
              FROM hr_leave_requests
             WHERE request_id = p_request_id;

            IF l_requested_days <= l_threshold THEN
                -- Final approval directly
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

-- =============================================================================
-- 5. HR_AI_PKG (Body)
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY hr_ai_pkg AS

    FUNCTION get_my_profile RETURN CLOB IS
        l_user_id NUMBER;
        l_json    VARCHAR2(4000);
    BEGIN
        l_user_id := hr_user_pkg.current_user_id;
        IF l_user_id IS NULL THEN
            RETURN '{"error": "No authenticated session or user profile not found"}';
        END IF;

        SELECT JSON_OBJECT(
            'user_id'     VALUE u.user_id,
            'username'    VALUE u.username,
            'full_name'   VALUE u.full_name,
            'email'       VALUE u.email,
            'department'  VALUE d.department_name,
            'manager'     VALUE NVL(m.full_name, 'None')
        )
          INTO l_json
          FROM hr_users u
          LEFT JOIN hr_departments d ON d.department_id = u.department_id
          LEFT JOIN hr_users m ON m.user_id = u.manager_id
         WHERE u.user_id = l_user_id;

        RETURN TO_CLOB(l_json);
    END get_my_profile;

    FUNCTION get_leave_balance(
        p_leave_type_code IN VARCHAR2 DEFAULT 'ANNUAL'
    ) RETURN CLOB IS
        l_user_id NUMBER;
        l_json    VARCHAR2(4000);
        l_year    NUMBER := EXTRACT(YEAR FROM SYSDATE);
    BEGIN
        l_user_id := hr_user_pkg.current_user_id;
        IF l_user_id IS NULL THEN
            RETURN '{"error": "No authenticated session"}';
        END IF;

        SELECT JSON_OBJECT(
            'leave_type'   VALUE t.leave_type_code,
            'year'         VALUE b.balance_year,
            'entitlement'  VALUE b.entitlement_days,
            'used'         VALUE b.used_days,
            'pending'      VALUE b.pending_days,
            'adjustment'   VALUE b.adjustment_days,
            'available'    VALUE (b.entitlement_days + b.adjustment_days - b.used_days - b.pending_days)
        )
          INTO l_json
          FROM hr_leave_balances b
          JOIN hr_leave_types t ON t.leave_type_id = b.leave_type_id
         WHERE b.user_id = l_user_id
           AND UPPER(t.leave_type_code) = UPPER(TRIM(p_leave_type_code))
           AND b.balance_year = l_year;

        RETURN TO_CLOB(l_json);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '{"error": "No balance record found for leave type ' || p_leave_type_code || ' in year ' || l_year || '"}';
    END get_leave_balance;

    FUNCTION get_my_leave_requests(
        p_status    IN VARCHAR2 DEFAULT NULL,
        p_date_from IN DATE DEFAULT NULL,
        p_date_to   IN DATE DEFAULT NULL
    ) RETURN CLOB IS
        l_user_id NUMBER;
        l_json    CLOB;
    BEGIN
        l_user_id := hr_user_pkg.current_user_id;
        IF l_user_id IS NULL THEN
            RETURN '{"error": "No authenticated session"}';
        END IF;

        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'request_id'     VALUE r.request_id,
                'leave_type'     VALUE t.leave_type_code,
                'start_date'     VALUE TO_CHAR(r.start_date, 'YYYY-MM-DD'),
                'end_date'       VALUE TO_CHAR(r.end_date, 'YYYY-MM-DD'),
                'requested_days' VALUE r.requested_days,
                'status'         VALUE r.status,
                'reason'         VALUE r.reason,
                'ai_summary'     VALUE r.ai_summary
            )
            ORDER BY r.start_date DESC
            RETURNING CLOB
        )
          INTO l_json
          FROM hr_leave_requests r
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.user_id = l_user_id
           AND (p_status IS NULL OR UPPER(r.status) = UPPER(TRIM(p_status)))
           AND (p_date_from IS NULL OR r.start_date >= p_date_from)
           AND (p_date_to IS NULL OR r.end_date <= p_date_to);

        RETURN NVL(l_json, '[]');
    END get_my_leave_requests;

    FUNCTION get_leave_request(
        p_request_id IN NUMBER
    ) RETURN CLOB IS
        l_user_id NUMBER;
        l_json    CLOB;
    BEGIN
        l_user_id := hr_user_pkg.current_user_id;

        SELECT JSON_OBJECT(
            'request_id'     VALUE r.request_id,
            'employee'       VALUE u.full_name,
            'username'       VALUE u.username,
            'leave_type'     VALUE t.leave_type_code,
            'start_date'     VALUE TO_CHAR(r.start_date, 'YYYY-MM-DD'),
            'end_date'       VALUE TO_CHAR(r.end_date, 'YYYY-MM-DD'),
            'requested_days' VALUE r.requested_days,
            'status'         VALUE r.status,
            'reason'         VALUE r.reason,
            'ai_summary'     VALUE r.ai_summary,
            'timeline'       VALUE (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'event_type' VALUE e.event_type,
                        'from_status' VALUE e.from_status,
                        'to_status' VALUE e.to_status,
                        'actor' VALUE e.actor_username,
                        'comments' VALUE e.comments,
                        'timestamp' VALUE TO_CHAR(e.event_timestamp, 'YYYY-MM-DD HH24:MI:SS')
                    )
                    ORDER BY e.event_timestamp ASC
                    RETURNING CLOB
                )
                FROM hr_leave_request_events e
                WHERE e.request_id = r.request_id
            )
            RETURNING CLOB
        )
          INTO l_json
          FROM hr_leave_requests r
          JOIN hr_users u ON u.user_id = r.user_id
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.request_id = p_request_id
           AND (r.user_id = l_user_id OR hr_auth_pkg.is_admin);

        RETURN l_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '{"error": "Leave request #' || p_request_id || ' not found or unauthorized"}';
    END get_leave_request;

    FUNCTION calculate_leave_days(
        p_start_date IN DATE,
        p_end_date   IN DATE
    ) RETURN CLOB IS
        l_days NUMBER;
    BEGIN
        l_days := hr_leave_pkg.calculate_days(p_start_date, p_end_date);
        RETURN TO_CLOB(JSON_OBJECT(
            'start_date'     VALUE TO_CHAR(p_start_date, 'YYYY-MM-DD'),
            'end_date'       VALUE TO_CHAR(p_end_date, 'YYYY-MM-DD'),
            'requested_days' VALUE l_days
        ));
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('{"error": "' || SQLERRM || '"}');
    END calculate_leave_days;

    FUNCTION create_leave_request(
        p_leave_type_code IN VARCHAR2,
        p_start_date      IN DATE,
        p_end_date        IN DATE,
        p_reason          IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB IS
        l_username   VARCHAR2(100);
        l_request_id NUMBER;
        l_wf_id      NUMBER;
        l_days       NUMBER;
    BEGIN
        l_username := hr_user_pkg.current_username;
        IF l_username IS NULL THEN
            RETURN '{"error": "No authenticated session"}';
        END IF;

        hr_leave_pkg.create_request(
            p_username        => l_username,
            p_leave_type_code => p_leave_type_code,
            p_start_date      => p_start_date,
            p_end_date        => p_end_date,
            p_reason          => p_reason,
            p_request_id      => l_request_id
        );

        l_wf_id := hr_workflow_pkg.start_leave_approval(p_request_id => l_request_id);
        l_days  := hr_leave_pkg.calculate_days(p_start_date, p_end_date);

        RETURN TO_CLOB(JSON_OBJECT(
            'status'         VALUE 'SUCCESS',
            'request_id'     VALUE l_request_id,
            'workflow_id'    VALUE l_wf_id,
            'requested_days' VALUE l_days,
            'message'        VALUE 'Leave request #' || l_request_id || ' submitted successfully'
        ));
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('{"status": "ERROR", "message": "' || SQLERRM || '"}');
    END create_leave_request;

    FUNCTION cancel_leave_request(
        p_request_id IN NUMBER,
        p_reason     IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB IS
        l_username VARCHAR2(100);
    BEGIN
        l_username := hr_user_pkg.current_username;
        IF l_username IS NULL THEN
            RETURN '{"error": "No authenticated session"}';
        END IF;

        hr_leave_pkg.cancel_request(
            p_request_id     => p_request_id,
            p_actor_username => l_username,
            p_reason         => p_reason
        );

        RETURN TO_CLOB(JSON_OBJECT(
            'status'     VALUE 'SUCCESS',
            'request_id' VALUE p_request_id,
            'message'    VALUE 'Leave request #' || p_request_id || ' cancelled successfully'
        ));
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('{"status": "ERROR", "message": "' || SQLERRM || '"}');
    END cancel_leave_request;

    FUNCTION generate_request_summary(
        p_request_id IN NUMBER
    ) RETURN CLOB IS
        l_full_name      VARCHAR2(150);
        l_leave_type     VARCHAR2(100);
        l_days           NUMBER;
        l_start_date     DATE;
        l_end_date       DATE;
        l_reason         VARCHAR2(4000);
        l_summary        VARCHAR2(4000);
    BEGIN
        SELECT u.full_name, t.leave_type_name, r.requested_days,
               r.start_date, r.end_date, r.reason
          INTO l_full_name, l_leave_type, l_days,
               l_start_date, l_end_date, l_reason
          FROM hr_leave_requests r
          JOIN hr_users u ON u.user_id = r.user_id
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.request_id = p_request_id;

        l_summary := l_full_name || ' requests ' || l_days || ' day(s) of ' ||
                     LOWER(l_leave_type) || ' from ' || TO_CHAR(l_start_date, 'DD-Mon-YYYY') ||
                     ' through ' || TO_CHAR(l_end_date, 'DD-Mon-YYYY') ||
                     CASE WHEN l_reason IS NOT NULL THEN ' for: ' || l_reason ELSE '.' END;

        UPDATE hr_leave_requests
           SET ai_summary = l_summary
         WHERE request_id = p_request_id;

        RETURN TO_CLOB(l_summary);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN TO_CLOB('Request #' || p_request_id || ' not found.');
    END generate_request_summary;

END hr_ai_pkg;
/

PROMPT >>> Packages compiled. Verifying status...
COLUMN object_name FORMAT A30
COLUMN object_type FORMAT A20
COLUMN status FORMAT A15

SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name IN ('HR_USER_PKG', 'HR_AUTH_PKG', 'HR_LEAVE_PKG', 'HR_WORKFLOW_PKG', 'HR_AI_PKG')
 ORDER BY object_name, object_type;
