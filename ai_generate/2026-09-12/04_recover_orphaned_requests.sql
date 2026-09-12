-- =============================================================================
-- Script: ai_generate/2026-09-12/04_recover_orphaned_requests.sql
-- Purpose:
--   1. Update HR_AUTH_PKG.CAN_CANCEL_REQUEST:
--      - Admins can cancel any pending/workflow_error request (operational recovery).
--      - Employees can cancel their own pending requests if start_date >= sysdate.
--   2. Update HR_LEAVE_PKG.CANCEL_REQUEST:
--      - Check workflow state before attempting apex_workflow.terminate.
--      - Only terminate if workflow state is ACTIVE or SUSPENDED to prevent
--        internal APEX rollback from wiping out uncommitted DML.
--   3. Cancel orphaned requests (109, 129, 209, 210) with terminated workflows.
--   4. Recover reserved pending days back to available balance for EMP001.
--   5. Record audit events and verify clean state.
-- =============================================================================

SET DEFINE OFF;
SET SERVEROUTPUT ON SIZE UNLIMITED;

-- Verify database identity
PROMPT >>> Verifying database identity before execution...
DECLARE
    l_db_name      VARCHAR2(128);
    l_session_user VARCHAR2(128);
BEGIN
    SELECT sys_context('USERENV', 'DB_NAME'), sys_context('USERENV', 'SESSION_USER')
      INTO l_db_name, l_session_user
      FROM dual;
    DBMS_OUTPUT.PUT_LINE('Connected to: ' || l_db_name || ' as user: ' || l_session_user);
    IF UPPER(l_session_user) NOT IN ('DEMO', 'ADMIN001') THEN
        RAISE_APPLICATION_ERROR(-20099, 'Execution aborted: unexpected session user ' || l_session_user);
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- Step 1: Update HR_AUTH_PKG Body
-- -----------------------------------------------------------------------------
PROMPT >>> Updating HR_AUTH_PKG body with admin cleanup authorization...

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

        -- For secondary HR approval tier, only Admin / HR Admin can approve
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

END hr_auth_pkg;
/

-- -----------------------------------------------------------------------------
-- Step 2: Update HR_LEAVE_PKG Body with safe workflow termination
-- -----------------------------------------------------------------------------
PROMPT >>> Updating HR_LEAVE_PKG body with safe cancel_request implementation...

CREATE OR REPLACE PACKAGE BODY hr_leave_pkg AS

    FUNCTION calculate_days(
        p_start_date IN DATE,
        p_end_date   IN DATE
    ) RETURN NUMBER IS
        l_days NUMBER;
    BEGIN
        IF p_start_date IS NULL OR p_end_date IS NULL OR p_start_date > p_end_date THEN
            RETURN 0;
        END IF;

        -- Count working days excluding standard weekend (Friday/Saturday)
        SELECT COUNT(*)
          INTO l_days
          FROM (
              SELECT p_start_date + LEVEL - 1 AS dt
                FROM dual
             CONNECT BY LEVEL <= (TRUNC(p_end_date) - TRUNC(p_start_date) + 1)
          ) d
         WHERE TO_CHAR(d.dt, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') NOT IN ('FRI', 'SAT');

        RETURN l_days;
    END calculate_days;

    FUNCTION get_available_days(
        p_user_id       IN NUMBER,
        p_leave_type_id IN NUMBER,
        p_year          IN NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE)
    ) RETURN NUMBER IS
        l_entitlement NUMBER := 0;
        l_adjustment  NUMBER := 0;
        l_used        NUMBER := 0;
        l_pending     NUMBER := 0;
    BEGIN
        SELECT entitlement_days, adjustment_days, used_days, pending_days
          INTO l_entitlement, l_adjustment, l_used, l_pending
          FROM hr_leave_balances
         WHERE user_id = p_user_id
           AND leave_type_id = p_leave_type_id
           AND balance_year = p_year;

        RETURN (l_entitlement + l_adjustment - l_used - l_pending);
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
        l_cnt NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO l_cnt
          FROM hr_leave_requests
         WHERE user_id = p_user_id
           AND status NOT IN ('REJECTED', 'CANCELLED', 'WORKFLOW_ERROR')
           AND (p_exclude_request_id IS NULL OR request_id != p_exclude_request_id)
           AND TRUNC(start_date) <= TRUNC(p_end_date)
           AND TRUNC(end_date)   >= TRUNC(p_start_date);

        RETURN (l_cnt > 0);
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
        p_request_id      OUT NUMBER,
        p_workflow_id     OUT NUMBER
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

        -- 8. Initiate APEX 24.1 Workflow
        BEGIN
            p_workflow_id := hr_workflow_pkg.start_leave_workflow(
                p_request_id     => p_request_id,
                p_user_id        => l_user_id,
                p_leave_type_id  => l_leave_type_id,
                p_requested_days => l_requested_days,
                p_start_date     => p_start_date,
                p_end_date       => p_end_date,
                p_reason         => p_reason
            );

            UPDATE hr_leave_requests
               SET workflow_id = p_workflow_id
             WHERE request_id = p_request_id;

            record_event(
                p_request_id     => p_request_id,
                p_event_type     => 'WORKFLOW_STARTED',
                p_from_status    => 'PENDING_MANAGER_APPROVAL',
                p_to_status      => 'PENDING_MANAGER_APPROVAL',
                p_actor_username => UPPER(p_username),
                p_comments       => 'Workflow LEAVE_APPROVAL initiated (Instance #' || p_workflow_id || ')'
            );
        EXCEPTION
            WHEN OTHERS THEN
                record_event(
                    p_request_id     => p_request_id,
                    p_event_type     => 'WORKFLOW_ERROR',
                    p_from_status    => 'PENDING_MANAGER_APPROVAL',
                    p_to_status      => 'PENDING_MANAGER_APPROVAL',
                    p_actor_username => UPPER(p_username),
                    p_comments       => 'Workflow initiation notice: ' || SQLERRM
                );
        END;

    END create_request;

    PROCEDURE approve_manager(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    ) IS
        l_user_id        NUMBER;
        l_requested_days NUMBER;
        l_status         VARCHAR2(30);
    BEGIN
        SELECT user_id, requested_days, status
          INTO l_user_id, l_requested_days, l_status
          FROM hr_leave_requests
         WHERE request_id = p_request_id
           FOR UPDATE;

        IF NOT hr_auth_pkg.can_approve_request(p_actor_username, p_request_id) THEN
            RAISE_APPLICATION_ERROR(-20020, 'Not authorized to approve this leave request at manager stage');
        END IF;

        IF l_status NOT IN ('SUBMITTED', 'PENDING', 'PENDING_MANAGER_APPROVAL') THEN
            RAISE_APPLICATION_ERROR(-20021, 'Request is not in a manager-approvable status: ' || l_status);
        END IF;

        IF l_requested_days > 5 THEN
            UPDATE hr_leave_requests
               SET status     = 'PENDING_HR_APPROVAL',
                   updated_at = SYSTIMESTAMP,
                   updated_by = NVL(p_actor_username, hr_user_pkg.current_username)
             WHERE request_id = p_request_id;

            record_event(
                p_request_id     => p_request_id,
                p_event_type     => 'MANAGER_APPROVED',
                p_from_status    => l_status,
                p_to_status      => 'PENDING_HR_APPROVAL',
                p_actor_username => p_actor_username,
                p_comments       => NVL(p_comments, 'Manager approved; routed to HR due to duration > 5 days')
            );
        ELSE
            approve_final(
                p_request_id     => p_request_id,
                p_actor_username => p_actor_username,
                p_comments       => p_comments
            );
        END IF;

    END approve_manager;

    PROCEDURE approve_final(
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
        SELECT r.user_id, r.leave_type_id, r.start_date, r.requested_days, r.status,
               t.requires_balance_yn
          INTO l_user_id, l_leave_type_id, l_start_date, l_requested_days, l_status,
               l_requires_bal
          FROM hr_leave_requests r
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.request_id = p_request_id
           FOR UPDATE OF r.status;

        IF NOT hr_auth_pkg.can_approve_request(p_actor_username, p_request_id) THEN
            RAISE_APPLICATION_ERROR(-20022, 'Not authorized for final approval');
        END IF;

        IF l_requires_bal = 'Y' THEN
            l_year := EXTRACT(YEAR FROM l_start_date);
            UPDATE hr_leave_balances
               SET used_days    = used_days + l_requested_days,
                   pending_days = GREATEST(0, pending_days - l_requested_days),
                   updated_at   = SYSTIMESTAMP,
                   updated_by   = NVL(p_actor_username, hr_user_pkg.current_username)
             WHERE user_id       = l_user_id
               AND leave_type_id = l_leave_type_id
               AND balance_year  = l_year;
        END IF;

        UPDATE hr_leave_requests
           SET status     = 'APPROVED',
               updated_at = SYSTIMESTAMP,
               updated_by = NVL(p_actor_username, hr_user_pkg.current_username)
         WHERE request_id = p_request_id;

        record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'APPROVED',
            p_from_status    => l_status,
            p_to_status      => 'APPROVED',
            p_actor_username => p_actor_username,
            p_comments       => p_comments
        );

    END approve_final;

    PROCEDURE reject_request(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_reason         IN VARCHAR2
    ) IS
        l_user_id        NUMBER;
        l_leave_type_id  NUMBER;
        l_start_date     DATE;
        l_requested_days NUMBER;
        l_status         VARCHAR2(30);
        l_requires_bal   VARCHAR2(1);
        l_year           NUMBER;
    BEGIN
        IF p_reason IS NULL OR TRIM(p_reason) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20023, 'Rejection reason is mandatory');
        END IF;

        SELECT r.user_id, r.leave_type_id, r.start_date, r.requested_days, r.status,
               t.requires_balance_yn
          INTO l_user_id, l_leave_type_id, l_start_date, l_requested_days, l_status,
               l_requires_bal
          FROM hr_leave_requests r
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.request_id = p_request_id
           FOR UPDATE OF r.status;

        IF l_requires_bal = 'Y' THEN
            l_year := EXTRACT(YEAR FROM l_start_date);
            UPDATE hr_leave_balances
               SET pending_days = GREATEST(0, pending_days - l_requested_days),
                   updated_at   = SYSTIMESTAMP,
                   updated_by   = NVL(p_actor_username, hr_user_pkg.current_username)
             WHERE user_id       = l_user_id
               AND leave_type_id = l_leave_type_id
               AND balance_year  = l_year;
        END IF;

        UPDATE hr_leave_requests
           SET status     = 'REJECTED',
               updated_at = SYSTIMESTAMP,
               updated_by = NVL(p_actor_username, hr_user_pkg.current_username)
         WHERE request_id = p_request_id;

        record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'REJECTED',
            p_from_status    => l_status,
            p_to_status      => 'REJECTED',
            p_actor_username => p_actor_username,
            p_comments       => p_reason
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
        l_workflow_id    NUMBER;
        l_status         VARCHAR2(30);
        l_requires_bal   VARCHAR2(1);
        l_year           NUMBER;
        l_wf_state       VARCHAR2(30);
    BEGIN
        -- 1. Lock and validate request
        SELECT r.user_id, r.leave_type_id, r.start_date, r.requested_days, r.workflow_id, r.status,
               t.requires_balance_yn
          INTO l_user_id, l_leave_type_id, l_start_date, l_requested_days, l_workflow_id, l_status,
               l_requires_bal
          FROM hr_leave_requests r
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.request_id = p_request_id
           FOR UPDATE OF r.status;

        -- 2. Authorization check
        IF NOT hr_auth_pkg.can_cancel_request(p_actor_username, p_request_id) THEN
            RAISE_APPLICATION_ERROR(-20024, 'Request cannot be cancelled or actor is not authorized');
        END IF;

        -- 3. Terminate active APEX workflow instance if currently running
        -- Only terminate when in ACTIVE or SUSPENDED state to prevent internal APEX rollback
        IF l_workflow_id IS NOT NULL THEN
            BEGIN
                SELECT state_code
                  INTO l_wf_state
                  FROM apex_workflows
                 WHERE workflow_id = l_workflow_id;

                IF l_wf_state IN ('ACTIVE', 'SUSPENDED') THEN
                    IF apex_application.g_flow_id IS NULL THEN
                        apex_session.create_session(
                            p_app_id   => 200,
                            p_page_id  => 1,
                            p_username => COALESCE(p_actor_username, 'DEMO')
                        );
                    END IF;

                    apex_workflow.terminate(
                        p_instance_id => l_workflow_id
                    );
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL; -- Workflow already terminated, completed, or not found
            END;
        END IF;

        -- 4. Release reserved pending days back to available balance
        IF l_requires_bal = 'Y' THEN
            l_year := EXTRACT(YEAR FROM l_start_date);
            UPDATE hr_leave_balances
               SET pending_days = GREATEST(0, pending_days - l_requested_days),
                   updated_at   = SYSTIMESTAMP,
                   updated_by   = NVL(p_actor_username, hr_user_pkg.current_username)
             WHERE user_id       = l_user_id
               AND leave_type_id = l_leave_type_id
               AND balance_year  = l_year;
        END IF;

        -- 5. Update Request Status
        UPDATE hr_leave_requests
           SET status     = 'CANCELLED',
               updated_at = SYSTIMESTAMP,
               updated_by = NVL(p_actor_username, hr_user_pkg.current_username)
         WHERE request_id = p_request_id;

        -- 6. Record Event
        record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'CANCELLED',
            p_from_status    => l_status,
            p_to_status      => 'CANCELLED',
            p_actor_username => p_actor_username,
            p_comments       => NVL(p_reason, 'Leave request cancelled by employee')
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

        record_event(
            p_request_id     => NULL,
            p_event_type     => 'BALANCE_ADJUSTED',
            p_from_status    => NULL,
            p_to_status      => NULL,
            p_actor_username => p_actor_username,
            p_comments       => 'Adjusted ' || p_leave_type_code || ' by ' || p_adjustment_delta ||
                                ' days for user_id ' || p_user_id || ' (Year ' || p_year || '). Reason: ' || p_reason
        );

    END adjust_balance;

END hr_leave_pkg;
/

PROMPT >>> Checking compilation status for HR_LEAVE_PKG...
DECLARE
    l_status VARCHAR2(30);
BEGIN
    SELECT status INTO l_status FROM user_objects WHERE object_name = 'HR_LEAVE_PKG' AND object_type = 'PACKAGE BODY';
    DBMS_OUTPUT.PUT_LINE('HR_LEAVE_PKG body status: ' || l_status);
    IF l_status != 'VALID' THEN
        RAISE_APPLICATION_ERROR(-20097, 'HR_LEAVE_PKG compilation failed with status ' || l_status);
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- Step 3: Cancel Orphaned Requests & Recover Pending Days
-- -----------------------------------------------------------------------------
PROMPT >>> Processing orphaned requests with terminated/faulted workflows...
DECLARE
    CURSOR c_orphaned IS
        SELECT r.request_id,
               r.user_id,
               u.username,
               r.leave_type_id,
               t.leave_type_code,
               r.requested_days,
               r.start_date,
               r.workflow_id,
               w.state_code AS workflow_state
          FROM hr_leave_requests r
          JOIN hr_users u ON u.user_id = r.user_id
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
          JOIN apex_workflows w ON w.workflow_id = r.workflow_id
         WHERE w.state_code IN ('TERMINATED', 'FAULTED')
           AND r.status IN ('SUBMITTED', 'PENDING', 'PENDING_MANAGER_APPROVAL', 'PENDING_HR_APPROVAL', 'WORKFLOW_ERROR')
         ORDER BY r.request_id ASC;

    l_count NUMBER := 0;
BEGIN
    FOR r IN c_orphaned LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Cancelling orphaned Request #' || r.request_id || 
            ' for ' || r.username || ' (' || r.leave_type_code || ', ' || 
            r.requested_days || ' days). Workflow #' || r.workflow_id || ' state: ' || r.workflow_state
        );

        hr_leave_pkg.cancel_request(
            p_request_id     => r.request_id,
            p_actor_username => 'DEMO',
            p_reason         => 'Orphaned request recovery: associated workflow #' || r.workflow_id || ' was ' || r.workflow_state
        );

        l_count := l_count + 1;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Total orphaned requests cancelled: ' || l_count);

    -- Reconcile pending_days for all affected balances with remaining active requests
    FOR b IN (
        SELECT DISTINCT user_id, EXTRACT(YEAR FROM start_date) AS yr
          FROM hr_leave_requests
         WHERE request_id IN (109, 129, 209, 210)
    ) LOOP
        UPDATE hr_leave_balances lb
           SET lb.pending_days = (
                   SELECT COALESCE(SUM(r.requested_days), 0)
                     FROM hr_leave_requests r
                    WHERE r.user_id = lb.user_id
                      AND r.leave_type_id = lb.leave_type_id
                      AND EXTRACT(YEAR FROM r.start_date) = lb.balance_year
                      AND r.status IN ('SUBMITTED', 'PENDING', 'PENDING_MANAGER_APPROVAL', 'PENDING_HR_APPROVAL')
               ),
               lb.updated_at = SYSTIMESTAMP,
               lb.updated_by = 'DEMO'
         WHERE lb.user_id = b.user_id
           AND lb.balance_year = b.yr;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Reconciliation committed successfully.');
END;
/

-- -----------------------------------------------------------------------------
-- Step 4: Verification Reporting
-- -----------------------------------------------------------------------------
PROMPT >>> Final Status of Requests 109, 129, 209, 210:
SELECT request_id, user_id, status, requested_days, workflow_id, updated_at
  FROM hr_leave_requests
 WHERE request_id IN (109, 129, 209, 210)
 ORDER BY request_id;

PROMPT >>> Final Balances for Affected Employee (EMP001):
SELECT b.balance_id,
       t.leave_type_code,
       b.entitlement_days,
       b.used_days,
       b.pending_days,
       b.available_days
  FROM hr_leave_balances b
  JOIN hr_leave_types t ON t.leave_type_id = b.leave_type_id
 WHERE b.user_id = 4
   AND b.balance_year = 2026
 ORDER BY t.leave_type_code;

PROMPT >>> Recovery script complete.

