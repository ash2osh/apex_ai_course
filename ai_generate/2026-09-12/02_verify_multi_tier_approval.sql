-- =============================================================================
-- Verification Script: 02_verify_multi_tier_approval.sql
-- Tests:
-- 1. Single-tier approval (<= 5 days) -> Manager approval finalizes to APPROVED.
-- 2. Two-tier approval (> 5 days) -> Manager approval escalates to PENDING_HR_APPROVAL,
--    manager cannot approve tier 2, HR Admin approval finalizes to APPROVED.
-- 3. Two-tier rejection (> 5 days) -> HR Admin rejection sets REJECTED and releases balance.
-- =============================================================================
SET DEFINE OFF;
SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT =========================================================================
PROMPT Test Scenario 1: Short Request (<= 5 days) -> Single Manager Approval
PROMPT =========================================================================
DECLARE
    l_req_id     NUMBER;
    l_wf_id      NUMBER;
    l_status     VARCHAR2(30);
    l_avail_pre  NUMBER;
    l_avail_mid  NUMBER;
    l_avail_post NUMBER;
    l_used_pre   NUMBER;
    l_used_post  NUMBER;
BEGIN
    SELECT available_days, used_days
      INTO l_avail_pre, l_used_pre
      FROM hr_leave_balances
     WHERE user_id = hr_user_pkg.get_user_id('EMP001')
       AND leave_type_id = 1
       AND balance_year = 2026;

    -- Create 2-day request (Thu Nov 12 to Fri Nov 13, 2026 = 2 days under default Fri/Sat working calendar or 1-2 days)
    hr_leave_pkg.create_request(
        p_username        => 'EMP001',
        p_leave_type_code => 'ANNUAL',
        p_start_date      => DATE '2026-11-01',
        p_end_date        => DATE '2026-11-03',
        p_reason          => 'Scenario 1 short leave automated test',
        p_request_id      => l_req_id,
        p_workflow_id     => l_wf_id
    );

    SELECT status INTO l_status FROM hr_leave_requests WHERE request_id = l_req_id;
    IF l_status = 'PENDING_MANAGER_APPROVAL' THEN
        DBMS_OUTPUT.PUT_LINE('PASS 1.1: Request created in PENDING_MANAGER_APPROVAL (Req #' || l_req_id || ')');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL 1.1: Expected PENDING_MANAGER_APPROVAL, got ' || l_status);
    END IF;

    -- Manager approves
    hr_workflow_pkg.manager_outcome(
        p_request_id     => l_req_id,
        p_actor_username => 'DEMO',
        p_outcome        => 'APPROVED',
        p_comments       => 'Manager approved short leave'
    );

    SELECT status INTO l_status FROM hr_leave_requests WHERE request_id = l_req_id;
    IF l_status = 'APPROVED' THEN
        DBMS_OUTPUT.PUT_LINE('PASS 1.2: Manager approval immediately finalizes to APPROVED for <= 5 days');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL 1.2: Expected APPROVED, got ' || l_status);
    END IF;

    SELECT available_days, used_days
      INTO l_avail_post, l_used_post
      FROM hr_leave_balances
     WHERE user_id = hr_user_pkg.get_user_id('EMP001')
       AND leave_type_id = 1
       AND balance_year = 2026;

    IF (l_used_post > l_used_pre) AND (l_avail_pre - l_avail_post = l_used_post - l_used_pre) THEN
        DBMS_OUTPUT.PUT_LINE('PASS 1.3: Balance updated cleanly (Used: ' || l_used_pre || ' -> ' || l_used_post || ')');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL 1.3: Balance mismatch');
    END IF;

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Scenario 1 clean rollback complete.');
END;
/

PROMPT =========================================================================
PROMPT Test Scenario 2: Long Request (> 5 days) -> Manager + HR Admin Approval
PROMPT =========================================================================
DECLARE
    l_req_id     NUMBER;
    l_wf_id      NUMBER;
    l_status     VARCHAR2(30);
    l_days       NUMBER;
    l_avail_pre  NUMBER;
    l_avail_mid  NUMBER;
    l_avail_post NUMBER;
    l_used_pre   NUMBER;
    l_used_post  NUMBER;
BEGIN
    SELECT available_days, used_days
      INTO l_avail_pre, l_used_pre
      FROM hr_leave_balances
     WHERE user_id = hr_user_pkg.get_user_id('EMP002')
       AND leave_type_id = 1
       AND balance_year = 2026;

    -- Create 7-day request (Sun Nov 01 to Mon Nov 09, 2026 = 7 working days)
    hr_leave_pkg.create_request(
        p_username        => 'EMP002',
        p_leave_type_code => 'ANNUAL',
        p_start_date      => DATE '2026-11-01',
        p_end_date        => DATE '2026-11-09',
        p_reason          => 'Scenario 2 long leave automated test',
        p_request_id      => l_req_id,
        p_workflow_id     => l_wf_id
    );

    SELECT requested_days, status
      INTO l_days, l_status
      FROM hr_leave_requests
     WHERE request_id = l_req_id;

    DBMS_OUTPUT.PUT_LINE('Created request #' || l_req_id || ' with ' || l_days || ' working days');

    IF l_days > 5 AND l_status = 'PENDING_MANAGER_APPROVAL' THEN
        DBMS_OUTPUT.PUT_LINE('PASS 2.1: Request > 5 days initiated in PENDING_MANAGER_APPROVAL');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL 2.1: Expected > 5 days and PENDING_MANAGER_APPROVAL');
    END IF;

    -- Step 1: Manager approves
    hr_workflow_pkg.manager_outcome(
        p_request_id     => l_req_id,
        p_actor_username => 'DEMO',
        p_outcome        => 'APPROVED',
        p_comments       => 'Manager tier-1 sign-off'
    );

    SELECT status INTO l_status FROM hr_leave_requests WHERE request_id = l_req_id;
    IF l_status = 'PENDING_HR_APPROVAL' THEN
        DBMS_OUTPUT.PUT_LINE('PASS 2.2: Manager approval successfully escalated status to PENDING_HR_APPROVAL');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL 2.2: Expected PENDING_HR_APPROVAL, got ' || l_status);
    END IF;

    -- Test Authorization Gate: Manager CANNOT approve HR-tier task
    IF NOT hr_auth_pkg.can_approve_request('MGR001', l_req_id) THEN
        DBMS_OUTPUT.PUT_LINE('PASS 2.3: Security gate verified: MGR001 is NOT authorized for PENDING_HR_APPROVAL');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL 2.3: Security breach: MGR001 allowed to approve HR stage');
    END IF;

    -- HR Admin IS authorized
    IF hr_auth_pkg.can_approve_request('HR001', l_req_id) THEN
        DBMS_OUTPUT.PUT_LINE('PASS 2.4: HR001 is authorized to approve PENDING_HR_APPROVAL');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL 2.4: HR001 should be authorized to approve HR stage');
    END IF;

    -- Step 2: HR Admin approves
    hr_workflow_pkg.hr_outcome(
        p_request_id     => l_req_id,
        p_actor_username => 'HR001',
        p_outcome        => 'APPROVED',
        p_comments       => 'HR Admin final approval'
    );

    SELECT status INTO l_status FROM hr_leave_requests WHERE request_id = l_req_id;
    IF l_status = 'APPROVED' THEN
        DBMS_OUTPUT.PUT_LINE('PASS 2.5: HR Admin approval finalizes request to APPROVED');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL 2.5: Expected APPROVED, got ' || l_status);
    END IF;

    SELECT available_days, used_days
      INTO l_avail_post, l_used_post
      FROM hr_leave_balances
     WHERE user_id = hr_user_pkg.get_user_id('EMP002')
       AND leave_type_id = 1
       AND balance_year = 2026;

    IF (l_used_post - l_used_pre = l_days) AND (l_avail_pre - l_avail_post = l_days) THEN
        DBMS_OUTPUT.PUT_LINE('PASS 2.6: Balance deducted exactly once (' || l_days || ' days consumed, Available: ' || l_avail_pre || ' -> ' || l_avail_post || ')');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL 2.6: Balance calculation error');
    END IF;

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Scenario 2 clean rollback complete.');
END;
/

PROMPT =========================================================================
PROMPT Test Scenario 3: Long Request (> 5 days) Rejection at HR Stage
PROMPT =========================================================================
DECLARE
    l_req_id     NUMBER;
    l_wf_id      NUMBER;
    l_status     VARCHAR2(30);
    l_days       NUMBER;
    l_avail_pre  NUMBER;
    l_avail_post NUMBER;
    l_used_pre   NUMBER;
    l_used_post  NUMBER;
BEGIN
    SELECT available_days, used_days
      INTO l_avail_pre, l_used_pre
      FROM hr_leave_balances
     WHERE user_id = hr_user_pkg.get_user_id('EMP002')
       AND leave_type_id = 1
       AND balance_year = 2026;

    -- Create 6-day request (Sun Nov 01 to Sun Nov 08, 2026 = 6 working days)
    hr_leave_pkg.create_request(
        p_username        => 'EMP002',
        p_leave_type_code => 'ANNUAL',
        p_start_date      => DATE '2026-11-01',
        p_end_date        => DATE '2026-11-08',
        p_reason          => 'Scenario 3 HR rejection automated test',
        p_request_id      => l_req_id,
        p_workflow_id     => l_wf_id
    );

    SELECT requested_days INTO l_days FROM hr_leave_requests WHERE request_id = l_req_id;

    -- Manager approves -> transitions to PENDING_HR_APPROVAL
    hr_workflow_pkg.manager_outcome(
        p_request_id     => l_req_id,
        p_actor_username => 'DEMO',
        p_outcome        => 'APPROVED',
        p_comments       => 'Manager approved'
    );

    -- HR rejects
    hr_workflow_pkg.hr_outcome(
        p_request_id     => l_req_id,
        p_actor_username => 'HR001',
        p_outcome        => 'REJECTED',
        p_comments       => 'HR Admin rejected due to operational staffing limits'
    );

    SELECT status INTO l_status FROM hr_leave_requests WHERE request_id = l_req_id;
    IF l_status = 'REJECTED' THEN
        DBMS_OUTPUT.PUT_LINE('PASS 3.1: Request status transitioned to REJECTED by HR Admin');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL 3.1: Expected REJECTED, got ' || l_status);
    END IF;

    SELECT available_days, used_days
      INTO l_avail_post, l_used_post
      FROM hr_leave_balances
     WHERE user_id = hr_user_pkg.get_user_id('EMP002')
       AND leave_type_id = 1
       AND balance_year = 2026;

    IF (l_avail_pre = l_avail_post) AND (l_used_pre = l_used_post) THEN
        DBMS_OUTPUT.PUT_LINE('PASS 3.2: Reserved balance released cleanly upon HR rejection (Available remains ' || l_avail_post || ')');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL 3.2: Balance was not released properly on rejection');
    END IF;

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Scenario 3 clean rollback complete.');
END;
/
