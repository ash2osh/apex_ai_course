-- =============================================================================
-- Verification Script: 03_verify_packages.sql
-- =============================================================================
SET DEFINE OFF;
SET SERVEROUTPUT ON;

PROMPT =========================================================================
PROMPT 1. Testing HR_USER_PKG & HR_AUTH_PKG
PROMPT =========================================================================
DECLARE
    l_uid NUMBER;
BEGIN
    l_uid := hr_user_pkg.get_user_id('EMP001');
    DBMS_OUTPUT.PUT_LINE('User ID for EMP001: ' || l_uid);
    
    IF hr_auth_pkg.is_employee('EMP001') THEN
        DBMS_OUTPUT.PUT_LINE('PASS: EMP001 is employee');
    END IF;
    
    IF NOT hr_auth_pkg.is_admin('EMP001') THEN
        DBMS_OUTPUT.PUT_LINE('PASS: EMP001 is NOT admin');
    END IF;

    IF hr_auth_pkg.is_admin('HR001') THEN
        DBMS_OUTPUT.PUT_LINE('PASS: HR001 is admin');
    END IF;

    IF hr_auth_pkg.is_super_admin('ADMIN001') THEN
        DBMS_OUTPUT.PUT_LINE('PASS: ADMIN001 is super admin');
    END IF;
END;
/

PROMPT =========================================================================
PROMPT 2. Testing HR_LEAVE_PKG (Calculations & Atomic Transactions)
PROMPT =========================================================================
DECLARE
    l_calc_days  NUMBER;
    l_avail_days NUMBER;
    l_req_id     NUMBER;
BEGIN
    -- Calculation test: Mon Sep 7 to Fri Sep 11 = 5 working days
    l_calc_days := hr_leave_pkg.calculate_days(DATE '2026-09-07', DATE '2026-09-11');
    DBMS_OUTPUT.PUT_LINE('Working days (Mon-Fri): ' || l_calc_days || ' (Expected: 5)');

    -- Check available days for EMP001 before test
    l_avail_days := hr_leave_pkg.get_available_days('EMP001', 'ANNUAL', 2026);
    DBMS_OUTPUT.PUT_LINE('EMP001 Annual Leave available before: ' || l_avail_days || ' (Expected: 14)');

    -- Test Create Request: 2 days (Thu Nov 12 to Fri Nov 13, 2026)
    hr_leave_pkg.create_request(
        p_username        => 'EMP001',
        p_leave_type_code => 'ANNUAL',
        p_start_date      => DATE '2026-11-12',
        p_end_date        => DATE '2026-11-13',
        p_reason          => 'Test Transaction Automated Validation',
        p_request_id      => l_req_id
    );
    DBMS_OUTPUT.PUT_LINE('Created test request ID: ' || l_req_id);

    -- Verify atomic balance reservation
    l_avail_days := hr_leave_pkg.get_available_days('EMP001', 'ANNUAL', 2026);
    DBMS_OUTPUT.PUT_LINE('EMP001 Annual Leave available after reservation: ' || l_avail_days || ' (Expected: 12)');

    -- Test Manager Approval
    hr_workflow_pkg.manager_outcome(
        p_request_id     => l_req_id,
        p_actor_username => 'MGR001',
        p_outcome        => 'APPROVED',
        p_comments       => 'Auto-approved in test harness'
    );

    l_avail_days := hr_leave_pkg.get_available_days('EMP001', 'ANNUAL', 2026);
    DBMS_OUTPUT.PUT_LINE('EMP001 Annual Leave available after approval: ' || l_avail_days || ' (Expected: 12)');

    -- Clean up / Rollback test transaction
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('PASS: HR_LEAVE_PKG transaction completed and rolled back cleanly.');
END;
/

PROMPT =========================================================================
PROMPT 3. Testing HR_AI_PKG (Session-bounded tools & summary generator)
PROMPT =========================================================================
DECLARE
    l_summary CLOB;
    l_calc    CLOB;
BEGIN
    l_calc := hr_ai_pkg.calculate_leave_days(DATE '2026-10-05', DATE '2026-10-09');
    DBMS_OUTPUT.PUT_LINE('AI Tool calculate_leave_days: ' || l_calc);

    l_summary := hr_ai_pkg.generate_request_summary(101);
    DBMS_OUTPUT.PUT_LINE('AI Tool generate_request_summary (Req 101): ' || l_summary);
    
    ROLLBACK;
END;
/

