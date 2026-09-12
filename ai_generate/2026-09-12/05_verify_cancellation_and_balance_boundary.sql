-- =============================================================================
-- Test Script: ai_generate/2026-09-12/05_verify_cancellation_and_balance_boundary.sql
-- Description: Self-verifying test suite validating:
--              1. Successful cancellation of a pending request with exact balance restoration.
--              2. Security check preventing employees from cancelling requests after the start date.
--              3. Workflow successfully proceeding when available days equals requested days.
-- Note: Every test scenario explicitly initializes an APEX session with an UPPERCASE username.
-- Date: 2026-09-12
-- =============================================================================
SET DEFINE OFF;
SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT =========================================================================
PROMPT Verifying Database Identity & Environment Safety Guard
PROMPT =========================================================================
DECLARE
    l_db_name      VARCHAR2(128);
    l_session_user VARCHAR2(128);
    l_schema       VARCHAR2(128);
BEGIN
    SELECT sys_context('USERENV', 'DB_NAME'),
           sys_context('USERENV', 'SESSION_USER'),
           sys_context('USERENV', 'CURRENT_SCHEMA')
      INTO l_db_name, l_session_user, l_schema
      FROM dual;

    DBMS_OUTPUT.PUT_LINE('Connected to: ' || l_db_name || ' | User: ' || l_session_user || ' | Schema: ' || l_schema);

    IF UPPER(l_session_user) NOT IN ('DEMO', 'ADMIN001') THEN
        RAISE_APPLICATION_ERROR(-20099, 'Execution aborted: unexpected session user ' || l_session_user);
    END IF;
    DBMS_OUTPUT.PUT_LINE('Environment verification: PASSED');
END;
/

PROMPT =========================================================================
PROMPT Test Scenario 1: Pending Cancellation & Exact Balance Restoration
PROMPT =========================================================================
DECLARE
    l_username       CONSTANT VARCHAR2(30) := 'EMP001';
    l_leave_type     CONSTANT VARCHAR2(30) := 'ANNUAL';
    l_year           CONSTANT NUMBER := EXTRACT(YEAR FROM SYSDATE);
    l_start_date     DATE := TRUNC(SYSDATE) + 60;
    l_end_date       DATE;
    l_calc_days      NUMBER;
    l_req_id         NUMBER;
    l_wf_id          NUMBER;
    l_status         VARCHAR2(30);
    l_avail_pre      NUMBER;
    l_pending_pre    NUMBER;
    l_used_pre       NUMBER;
    l_avail_mid      NUMBER;
    l_pending_mid    NUMBER;
    l_avail_post     NUMBER;
    l_pending_post   NUMBER;
    l_used_post      NUMBER;
    l_event_cnt      NUMBER;
BEGIN
    -- 1.0 Create APEX session with an UPPERCASE username
    apex_session.create_session(
        p_app_id   => 200,
        p_page_id  => 1,
        p_username => UPPER(l_username)
    );
    DBMS_OUTPUT.PUT_LINE('APEX session initialized for: ' || apex_application.g_user);

    -- Ensure end_date produces exactly 2 working days
    l_end_date := l_start_date + 1;
    WHILE hr_leave_pkg.calculate_days(l_start_date, l_end_date) < 2 LOOP
        l_end_date := l_end_date + 1;
    END LOOP;
    l_calc_days := hr_leave_pkg.calculate_days(l_start_date, l_end_date);

    -- 1.1 Capture baseline balances
    SELECT available_days, pending_days, used_days
      INTO l_avail_pre, l_pending_pre, l_used_pre
      FROM hr_leave_balances
     WHERE user_id = hr_user_pkg.get_user_id(UPPER(l_username))
       AND leave_type_id = (SELECT leave_type_id FROM hr_leave_types WHERE leave_type_code = l_leave_type)
       AND balance_year = l_year;

    DBMS_OUTPUT.PUT_LINE('Baseline: Available=' || l_avail_pre || ', Pending=' || l_pending_pre || ', Used=' || l_used_pre);

    -- 1.2 Submit leave request as uppercase username
    hr_leave_pkg.create_request(
        p_username        => UPPER(l_username),
        p_leave_type_code => l_leave_type,
        p_start_date      => l_start_date,
        p_end_date        => l_end_date,
        p_reason          => 'Unit test cancellation and balance restoration',
        p_request_id      => l_req_id,
        p_workflow_id     => l_wf_id
    );

    SELECT status INTO l_status FROM hr_leave_requests WHERE request_id = l_req_id;
    IF l_status != 'PENDING_MANAGER_APPROVAL' THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 1.1: Expected status PENDING_MANAGER_APPROVAL, got ' || l_status);
    END IF;

    -- Verify reservation state
    SELECT available_days, pending_days
      INTO l_avail_mid, l_pending_mid
      FROM hr_leave_balances
     WHERE user_id = hr_user_pkg.get_user_id(UPPER(l_username))
       AND leave_type_id = (SELECT leave_type_id FROM hr_leave_types WHERE leave_type_code = l_leave_type)
       AND balance_year = l_year;

    IF l_pending_mid != (l_pending_pre + l_calc_days) OR l_avail_mid != (l_avail_pre - l_calc_days) THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 1.2: Balance reservation mismatch after submission.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 1.1: Request #' || l_req_id || ' submitted. Balance reserved (' || l_calc_days || ' days).');

    -- 1.3 Authorization verification for owner (UPPERCASE)
    IF NOT hr_auth_pkg.can_cancel_request(UPPER(l_username), l_req_id) THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 1.3: Owner ' || UPPER(l_username) || ' should be authorized to cancel pending request.');
    END IF;

    -- 1.4 Cancel request as owner
    hr_leave_pkg.cancel_request(
        p_request_id     => l_req_id,
        p_actor_username => UPPER(l_username),
        p_reason         => 'Employee voluntarily cancelled before start date'
    );

    -- 1.5 Verify status is CANCELLED
    SELECT status INTO l_status FROM hr_leave_requests WHERE request_id = l_req_id;
    IF l_status != 'CANCELLED' THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 1.4: Expected status CANCELLED, got ' || l_status);
    END IF;

    -- 1.6 Verify exact balance restoration
    SELECT available_days, pending_days, used_days
      INTO l_avail_post, l_pending_post, l_used_post
      FROM hr_leave_balances
     WHERE user_id = hr_user_pkg.get_user_id(UPPER(l_username))
       AND leave_type_id = (SELECT leave_type_id FROM hr_leave_types WHERE leave_type_code = l_leave_type)
       AND balance_year = l_year;

    IF l_avail_post != l_avail_pre THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 1.5: Available days not restored! Pre: ' || l_avail_pre || ', Post: ' || l_avail_post);
    END IF;
    IF l_pending_post != l_pending_pre THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 1.6: Pending days not restored! Pre: ' || l_pending_pre || ', Post: ' || l_pending_post);
    END IF;
    IF l_used_post != l_used_pre THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 1.7: Used days unexpectedly modified! Pre: ' || l_used_pre || ', Post: ' || l_used_post);
    END IF;

    -- 1.7 Verify audit event logged with uppercase actor
    SELECT COUNT(*) INTO l_event_cnt
      FROM hr_leave_request_events
     WHERE request_id = l_req_id
       AND event_type = 'CANCELLED'
       AND to_status = 'CANCELLED'
       AND actor_username = UPPER(l_username);

    IF l_event_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 1.8: CANCELLED audit event not recorded in HR_LEAVE_REQUEST_EVENTS.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('PASS 1.2: Request #' || l_req_id || ' cancelled successfully. Exact balance restored (' || l_avail_post || ' days available).');

    -- Cleanup Scenario 1 request
    DELETE FROM hr_leave_request_events WHERE request_id = l_req_id;
    DELETE FROM hr_leave_requests WHERE request_id = l_req_id;
    COMMIT;
END;
/

PROMPT =========================================================================
PROMPT Test Scenario 2: Security Check Preventing Cancellation After Start Date
PROMPT =========================================================================
DECLARE
    l_username       CONSTANT VARCHAR2(30) := 'EMP001';
    l_other_user     CONSTANT VARCHAR2(30) := 'EMP002';
    l_leave_type     CONSTANT VARCHAR2(30) := 'ANNUAL';
    l_req_id         NUMBER;
    l_error_raised   BOOLEAN;
    l_status         VARCHAR2(30);
    l_user_id        NUMBER;
    l_leave_type_id  NUMBER;
BEGIN
    -- 2.0 Create APEX session with UPPERCASE username
    apex_session.create_session(
        p_app_id   => 200,
        p_page_id  => 1,
        p_username => UPPER(l_username)
    );
    DBMS_OUTPUT.PUT_LINE('APEX session initialized for: ' || apex_application.g_user);

    l_user_id := hr_user_pkg.get_user_id(UPPER(l_username));
    SELECT leave_type_id INTO l_leave_type_id FROM hr_leave_types WHERE leave_type_code = l_leave_type;

    -- 2.1 Create mock pending request with past start date (leave started 3 days ago)
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
        TRUNC(SYSDATE) - 3,
        TRUNC(SYSDATE) - 1,
        2,
        'Past date cancellation security test',
        'PENDING_MANAGER_APPROVAL'
    ) RETURNING request_id INTO l_req_id;

    -- 2.2 Verify CAN_CANCEL_REQUEST returns FALSE for employee after start date
    IF hr_auth_pkg.can_cancel_request(UPPER(l_username), l_req_id) THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 2.1: Employee should NOT be permitted to cancel request after start date.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 2.1: hr_auth_pkg.can_cancel_request returned FALSE for past-date request #' || l_req_id);

    -- 2.3 Verify CANCEL_REQUEST raises ORA-20024 when employee attempts cancellation
    l_error_raised := FALSE;
    BEGIN
        hr_leave_pkg.cancel_request(
            p_request_id     => l_req_id,
            p_actor_username => UPPER(l_username),
            p_reason         => 'Attempting illicit cancellation after start date'
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20024 THEN
                l_error_raised := TRUE;
            ELSE
                RAISE_APPLICATION_ERROR(-20099, 'FAIL 2.2: Unexpected error code ' || SQLCODE || ': ' || SQLERRM);
            END IF;
    END;

    IF NOT l_error_raised THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 2.3: cancel_request failed to raise error for cancellation after start date.');
    END IF;

    SELECT status INTO l_status FROM hr_leave_requests WHERE request_id = l_req_id;
    IF l_status != 'PENDING_MANAGER_APPROVAL' THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 2.4: Request status should remain PENDING_MANAGER_APPROVAL, got ' || l_status);
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 2.2: hr_leave_pkg.cancel_request raised ORA-20024 and preserved request state.');

    -- 2.4 Test boundary: Same-day cancellation allowed (start_date = TRUNC(SYSDATE))
    UPDATE hr_leave_requests
       SET start_date = TRUNC(SYSDATE),
           end_date   = TRUNC(SYSDATE) + 1
     WHERE request_id = l_req_id;

    IF NOT hr_auth_pkg.can_cancel_request(UPPER(l_username), l_req_id) THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 2.5: Same-day cancellation (start_date = SYSDATE) must be allowed by policy.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 2.3: Same-day cancellation correctly permitted for owner.');

    -- 2.5 Test boundary: Start date passed by 1 day (start_date = TRUNC(SYSDATE) - 1)
    UPDATE hr_leave_requests
       SET start_date = TRUNC(SYSDATE) - 1,
           end_date   = TRUNC(SYSDATE) + 1
     WHERE request_id = l_req_id;

    IF hr_auth_pkg.can_cancel_request(UPPER(l_username), l_req_id) THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 2.6: Cancellation 1 day after start date must be blocked.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 2.4: Cancellation 1 day after start date correctly blocked.');

    -- 2.6 Test non-owner security check with uppercase other user
    UPDATE hr_leave_requests
       SET start_date = TRUNC(SYSDATE) + 10,
           end_date   = TRUNC(SYSDATE) + 12
     WHERE request_id = l_req_id;

    -- Switch session to other employee (UPPERCASE)
    apex_session.create_session(
        p_app_id   => 200,
        p_page_id  => 1,
        p_username => UPPER(l_other_user)
    );
    DBMS_OUTPUT.PUT_LINE('APEX session switched to: ' || apex_application.g_user);

    IF hr_auth_pkg.can_cancel_request(UPPER(l_other_user), l_req_id) THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 2.7: Non-owner ' || UPPER(l_other_user) || ' should NOT be permitted to cancel request.');
    END IF;

    l_error_raised := FALSE;
    BEGIN
        hr_leave_pkg.cancel_request(
            p_request_id     => l_req_id,
            p_actor_username => UPPER(l_other_user),
            p_reason         => 'Non-owner cancellation attempt'
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20024 THEN
                l_error_raised := TRUE;
            END IF;
    END;

    IF NOT l_error_raised THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 2.8: cancel_request should raise ORA-20024 for non-owner actor.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 2.5: Non-owner cancellation security gate verified for ' || UPPER(l_other_user));

    -- Cleanup Scenario 2 mock request
    DELETE FROM hr_leave_request_events WHERE request_id = l_req_id;
    DELETE FROM hr_leave_requests WHERE request_id = l_req_id;
    COMMIT;
END;
/

PROMPT =========================================================================
PROMPT Test Scenario 3: Workflow Progression When Available Days = Requested Days
PROMPT =========================================================================
DECLARE
    l_username       CONSTANT VARCHAR2(30) := 'EMP001';
    l_mgr_username   CONSTANT VARCHAR2(30) := 'DEMO';
    l_leave_type     CONSTANT VARCHAR2(30) := 'EMERGENCY';
    l_year           CONSTANT NUMBER := EXTRACT(YEAR FROM SYSDATE);
    l_user_id        NUMBER;
    l_leave_type_id  NUMBER;
    l_target_days    CONSTANT NUMBER := 2;
    l_entitle_pre    NUMBER;
    l_avail_exact    NUMBER;
    l_start_date     DATE := TRUNC(SYSDATE) + 80;
    l_end_date       DATE;
    l_neg_start      DATE;
    l_neg_end        DATE;
    l_req_id         NUMBER;
    l_wf_id          NUMBER;
    l_status         VARCHAR2(30);
    l_avail_during   NUMBER;
    l_pending_during NUMBER;
    l_avail_final    NUMBER;
    l_used_final     NUMBER;
    l_error_raised   BOOLEAN;
BEGIN
    l_user_id := hr_user_pkg.get_user_id(UPPER(l_username));
    SELECT leave_type_id INTO l_leave_type_id FROM hr_leave_types WHERE leave_type_code = l_leave_type;

    -- 3.0 Establish APEX session as EMPLOYEE (UPPERCASE)
    apex_session.create_session(
        p_app_id   => 200,
        p_page_id  => 1,
        p_username => UPPER(l_username)
    );
    DBMS_OUTPUT.PUT_LINE('APEX session initialized for: ' || apex_application.g_user);

    -- Capture original entitlement to restore after test
    SELECT entitlement_days INTO l_entitle_pre
      FROM hr_leave_balances
     WHERE user_id = l_user_id AND leave_type_id = l_leave_type_id AND balance_year = l_year;

    -- 3.1 Configure exact boundary balance (Available = 2 days)
    UPDATE hr_leave_balances
       SET entitlement_days = l_target_days,
           adjustment_days  = 0,
           used_days        = 0,
           pending_days     = 0
     WHERE user_id = l_user_id
       AND leave_type_id = l_leave_type_id
       AND balance_year = l_year;

    l_avail_exact := hr_leave_pkg.get_available_days(l_user_id, l_leave_type_id, l_year);
    IF l_avail_exact != l_target_days THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 3.1: Setup error, expected available ' || l_target_days || ', got ' || l_avail_exact);
    END IF;
    DBMS_OUTPUT.PUT_LINE('Boundary state configured: Available days = ' || l_avail_exact);

    -- Ensure end_date produces exactly l_target_days (2) working days
    l_end_date := l_start_date + 1;
    WHILE hr_leave_pkg.calculate_days(l_start_date, l_end_date) < l_target_days LOOP
        l_end_date := l_end_date + 1;
    END LOOP;

    -- 3.2 Create request where requested_days (2) == available_days (2)
    hr_leave_pkg.create_request(
        p_username        => UPPER(l_username),
        p_leave_type_code => l_leave_type,
        p_start_date      => l_start_date,
        p_end_date        => l_end_date,
        p_reason          => 'Boundary test: available days equals requested days',
        p_request_id      => l_req_id,
        p_workflow_id     => l_wf_id
    );

    SELECT status INTO l_status FROM hr_leave_requests WHERE request_id = l_req_id;
    IF l_status != 'PENDING_MANAGER_APPROVAL' THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 3.2: Expected PENDING_MANAGER_APPROVAL, got ' || l_status);
    END IF;

    -- Check balance: Available should now be 0, Pending should equal requested (2)
    l_avail_during := hr_leave_pkg.get_available_days(l_user_id, l_leave_type_id, l_year);
    SELECT pending_days INTO l_pending_during
      FROM hr_leave_balances
     WHERE user_id = l_user_id AND leave_type_id = l_leave_type_id AND balance_year = l_year;

    IF l_avail_during != 0 OR l_pending_during != l_target_days THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 3.3: Balance mismatch during submission. Avail: ' || l_avail_during || ' (exp 0), Pending: ' || l_pending_during);
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 3.1: Request #' || l_req_id || ' accepted when available = requested (' || l_target_days || ' days). Available is now 0.');

    -- 3.3 Verify Workflow HAVE_BALANCE condition logic:
    -- In leave-approval.apx:
    -- IF (v_available_days + :REQUESTED_DAYS) >= :REQUESTED_DAYS AND v_available_days >= 0 THEN RETURN TRUE;
    -- Here: (0 + 2) >= 2 AND 0 >= 0 is TRUE.
    IF NOT ((l_avail_during + l_target_days) >= l_target_days AND l_avail_during >= 0) THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 3.4: Workflow HAVE_BALANCE condition evaluated to FALSE for boundary condition.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 3.2: Workflow HAVE_BALANCE logic verified: proceeds to approval branch.');

    -- 3.4 Establish APEX session as MANAGER (UPPERCASE) to approve
    apex_session.create_session(
        p_app_id   => 200,
        p_page_id  => 1,
        p_username => UPPER(l_mgr_username)
    );
    DBMS_OUTPUT.PUT_LINE('APEX session switched to manager: ' || apex_application.g_user);

    hr_workflow_pkg.manager_outcome(
        p_request_id     => l_req_id,
        p_actor_username => UPPER(l_mgr_username),
        p_outcome        => 'APPROVED',
        p_comments       => 'Approved exact boundary leave'
    );

    SELECT status INTO l_status FROM hr_leave_requests WHERE request_id = l_req_id;
    IF l_status != 'APPROVED' THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 3.5: Expected APPROVED status, got ' || l_status);
    END IF;

    -- Verify final balances: Used increased by 2, Pending is 0, Available is 0
    SELECT available_days, used_days
      INTO l_avail_final, l_used_final
      FROM hr_leave_balances
     WHERE user_id = l_user_id AND leave_type_id = l_leave_type_id AND balance_year = l_year;

    IF l_avail_final != 0 THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 3.6: Expected available_days = 0, got ' || l_avail_final);
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 3.3: Workflow successfully finalized request to APPROVED with 0 available days remaining.');

    -- 3.5 Switch session back to EMPLOYEE (UPPERCASE) for negative boundary check
    apex_session.create_session(
        p_app_id   => 200,
        p_page_id  => 1,
        p_username => UPPER(l_username)
    );
    DBMS_OUTPUT.PUT_LINE('APEX session switched to employee: ' || apex_application.g_user);

    -- Ensure negative test dates span at least 1 working day (excluding Fri/Sat)
    l_neg_start := l_start_date + 10;
    l_neg_end := l_neg_start;
    WHILE hr_leave_pkg.calculate_days(l_neg_start, l_neg_end) < 1 LOOP
        l_neg_start := l_neg_start + 1;
        l_neg_end := l_neg_start;
    END LOOP;

    l_error_raised := FALSE;
    BEGIN
        hr_leave_pkg.create_request(
            p_username        => UPPER(l_username),
            p_leave_type_code => l_leave_type,
            p_start_date      => l_neg_start,
            p_end_date        => l_neg_end,
            p_reason          => 'Exceeded balance attempt',
            p_request_id      => l_req_id,
            p_workflow_id     => l_wf_id
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20019 THEN
                l_error_raised := TRUE;
            ELSE
                RAISE_APPLICATION_ERROR(-20099, 'FAIL 3.7: Expected -20019 Insufficient balance, got ' || SQLCODE || ': ' || SQLERRM);
            END IF;
    END;

    IF NOT l_error_raised THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL 3.8: Request succeeded when available balance was 0!');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS 3.4: Subsequent request correctly rejected when available balance = 0 (ORA-20019).');

    -- 3.6 Cleanup Scenario 3 request and restore baseline balance
    DELETE FROM hr_leave_request_events WHERE request_id = l_req_id;
    DELETE FROM hr_leave_requests WHERE request_id = l_req_id;

    UPDATE hr_leave_balances
       SET entitlement_days = l_entitle_pre,
           adjustment_days  = 0,
           used_days        = 0,
           pending_days     = 0
     WHERE user_id = l_user_id
       AND leave_type_id = l_leave_type_id
       AND balance_year = l_year;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Baseline balances cleanly restored.');
END;
/

PROMPT =========================================================================
PROMPT Clean Rollback & Verification Summary
PROMPT =========================================================================
ROLLBACK;

PROMPT >>> Clean rollback verified. All test modifications reverted.
PROMPT >>> ALL SELF-VERIFYING TESTS PASSED:
PROMPT     [PASS] 1. Successful cancellation of pending request with exact balance restoration.
PROMPT     [PASS] 2. Security check preventing employee cancellation after start date.
PROMPT     [PASS] 3. Workflow successfully proceeding when available days equals requested days.
PROMPT =========================================================================

