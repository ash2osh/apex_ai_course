-- =============================================================================
-- Test Script: 03_verify_cancellation.sql
-- Description: Self-verifying test suite for safe employee request cancellation:
--              1. Balance reservation and restoration upon cancellation.
--              2. Audit event recording in HR_LEAVE_REQUEST_EVENTS.
--              3. Security check preventing non-owner from cancelling.
--              4. Policy check allowing same-day cancellation.
--              5. Policy check blocking past-date leave cancellation.
--              6. Policy check blocking cancellation of approved requests.
-- Date: 2026-09-12
-- =============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;

DECLARE
    l_req_id        NUMBER;
    l_wf_id         NUMBER;
    l_avail_before  NUMBER;
    l_avail_during  NUMBER;
    l_avail_after   NUMBER;
    l_calc_days     NUMBER;
    l_year          NUMBER := EXTRACT(YEAR FROM SYSDATE);
    l_status        VARCHAR2(30);
    l_event_cnt     NUMBER;
    l_error_raised  BOOLEAN;
BEGIN
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('Starting Test Suite: Safe Employee Request Cancellation');
    DBMS_OUTPUT.PUT_LINE('====================================================');

    -- -------------------------------------------------------------------------
    -- Test 1: Employee Cancellation with Balance Restoration & Audit Event
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- Test 1: Leave Creation & Balance Reservation ---');
    l_avail_before := hr_leave_pkg.get_available_days('EMP001', 'EMERGENCY', l_year);
    l_calc_days := hr_leave_pkg.calculate_days(TRUNC(SYSDATE) + 5, TRUNC(SYSDATE) + 6);

    hr_leave_pkg.create_request(
        p_username        => 'EMP001',
        p_leave_type_code => 'EMERGENCY',
        p_start_date      => TRUNC(SYSDATE) + 5,
        p_end_date        => TRUNC(SYSDATE) + 6,
        p_reason          => 'Unit test cancellation request',
        p_request_id      => l_req_id,
        p_workflow_id     => l_wf_id
    );

    l_avail_during := hr_leave_pkg.get_available_days('EMP001', 'EMERGENCY', l_year);
    IF l_avail_during != (l_avail_before - l_calc_days) THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL Test 1: Balance reservation incorrect during submission.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS Test 1: Created request #' || l_req_id || ', balance reserved (' || l_avail_during || ' available).');

    -- -------------------------------------------------------------------------
    -- Test 2: Security Gate (Non-Owner Cancellation Blocked)
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- Test 2: Security Gate (Non-Owner Cancellation) ---');
    IF hr_auth_pkg.can_cancel_request('EMP002', l_req_id) THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL Test 2: EMP002 should NOT be authorized to cancel EMP001 request.');
    END IF;

    l_error_raised := FALSE;
    BEGIN
        hr_leave_pkg.cancel_request(l_req_id, 'EMP002', 'Unauthorized cancel');
    EXCEPTION
        WHEN OTHERS THEN
            l_error_raised := TRUE;
    END;

    IF NOT l_error_raised THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL Test 2: cancel_request should raise error for unauthorized actor.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS Test 2: Non-owner cancellation correctly blocked.');

    -- -------------------------------------------------------------------------
    -- Test 3: Owner Cancellation, Balance Restoration & Audit Event
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- Test 3: Owner Cancellation & Balance Restoration ---');
    IF NOT hr_auth_pkg.can_cancel_request('EMP001', l_req_id) THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL Test 3: Owner should be authorized to cancel pending request.');
    END IF;

    hr_leave_pkg.cancel_request(
        p_request_id     => l_req_id,
        p_actor_username => 'EMP001',
        p_reason         => 'Cancelled by test suite'
    );

    SELECT status INTO l_status FROM hr_leave_requests WHERE request_id = l_req_id;
    IF l_status != 'CANCELLED' THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL Test 3: Request status is ' || l_status || ', expected CANCELLED.');
    END IF;

    l_avail_after := hr_leave_pkg.get_available_days('EMP001', 'EMERGENCY', l_year);
    IF l_avail_after != l_avail_before THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL Test 3: Balance not restored! Before: ' || l_avail_before || ', After: ' || l_avail_after);
    END IF;

    SELECT COUNT(*) INTO l_event_cnt
      FROM hr_leave_request_events
     WHERE request_id = l_req_id
       AND event_type = 'CANCELLED'
       AND to_status = 'CANCELLED';
    IF l_event_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL Test 3: CANCELLED audit event not recorded.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS Test 3: Cancellation succeeded, balance restored (' || l_avail_after || ' days), event logged.');

    -- -------------------------------------------------------------------------
    -- Test 4: Same-Day Cancellation Policy (Allowed)
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- Test 4: Same-Day Cancellation Policy ---');
    UPDATE hr_leave_requests
       SET start_date = TRUNC(SYSDATE),
           end_date   = TRUNC(SYSDATE) + 1,
           status     = 'PENDING_MANAGER_APPROVAL'
     WHERE request_id = l_req_id;

    IF NOT hr_auth_pkg.can_cancel_request('EMP001', l_req_id) THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL Test 4: Same-day cancellation should be permitted by policy.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS Test 4: Same-day cancellation correctly permitted.');

    -- -------------------------------------------------------------------------
    -- Test 5: Past Leave Date Boundary (Blocked)
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- Test 5: Past Leave Date Boundary ---');
    UPDATE hr_leave_requests
       SET start_date = TRUNC(SYSDATE) - 2,
           end_date   = TRUNC(SYSDATE) - 1,
           status     = 'PENDING_MANAGER_APPROVAL'
     WHERE request_id = l_req_id;

    IF hr_auth_pkg.can_cancel_request('EMP001', l_req_id) THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL Test 5: Past leave cancellation should be blocked.');
    END IF;

    l_error_raised := FALSE;
    BEGIN
        hr_leave_pkg.cancel_request(l_req_id, 'EMP001', 'Attempt cancel past leave');
    EXCEPTION
        WHEN OTHERS THEN
            l_error_raised := TRUE;
    END;

    IF NOT l_error_raised THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL Test 5: cancel_request should raise error for past leave date.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS Test 5: Past leave cancellation correctly blocked.');

    -- -------------------------------------------------------------------------
    -- Test 6: Approved Leave Cancellation (Blocked)
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- Test 6: Approved Leave Status ---');
    UPDATE hr_leave_requests
       SET start_date = TRUNC(SYSDATE) + 5,
           end_date   = TRUNC(SYSDATE) + 6,
           status     = 'APPROVED'
     WHERE request_id = l_req_id;

    IF hr_auth_pkg.can_cancel_request('EMP001', l_req_id) THEN
        RAISE_APPLICATION_ERROR(-20099, 'FAIL Test 6: Approved leave cancellation should be blocked.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('PASS Test 6: Approved leave cancellation correctly blocked.');

    -- Rollback all test modifications
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('ALL TESTS PASSED! Test transactions rolled back cleanly.');
    DBMS_OUTPUT.PUT_LINE('====================================================');
END;
/

EXIT;

