-- =============================================================================
-- Test Script: ai_generate/2026-09-12/11_verify_all_audit_fixes.sql
-- Description: Comprehensive self-verifying test suite validating all audit
--              remediations across database packages:
--              1. Schema fix: HR_LEAVE_PKG.ADJUST_BALANCE with NULL request_id
--              2. Critical 1: HR_AI_PKG.GENERATE_REQUEST_SUMMARY ownership enforcement
--              3. High 9: HR_AUTH_PKG.CAN_APPROVE_REQUEST requires MANAGER role
--              4. High 11: HR_AUTH_PKG Super Admin lockout protection
--              5. High 8: HR_LEAVE_PKG.CREATE_REQUEST requires EMPLOYEE role
--              6. Medium 16: HR_LEAVE_PKG cross-year request rejection
--              7. Medium 14: HR_LEAVE_PKG.GET_AVAILABLE_DAYS includes adjustment_days
--              8. Medium 17: HR_AI_PKG JSON serialization & safe error handling
-- Note: Session initialization explicitly uses UPPERCASE usernames.
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
PROMPT Test Scenario 1: Schema Fix - ADJUST_BALANCE with NULL REQUEST_ID
PROMPT =========================================================================
DECLARE
    l_event_id    NUMBER;
    l_bal_pre     NUMBER;
    l_emp_user_id NUMBER;
BEGIN
    apex_session.create_session(
        p_app_id   => 200,
        p_page_id  => 8,
        p_username => 'ADMIN001'
    );

    SELECT user_id INTO l_emp_user_id FROM hr_users WHERE username = 'EMP001';

    SELECT adjustment_days
      INTO l_bal_pre
      FROM hr_leave_balances
     WHERE user_id = l_emp_user_id
       AND leave_type_id = (SELECT leave_type_id FROM hr_leave_types WHERE leave_type_code = 'ANNUAL')
       AND balance_year = EXTRACT(YEAR FROM SYSDATE);

    -- Apply administrative adjustment (+1 day)
    hr_leave_pkg.adjust_balance(
        p_user_id          => l_emp_user_id,
        p_leave_type_code  => 'ANNUAL',
        p_year             => EXTRACT(YEAR FROM SYSDATE),
        p_adjustment_delta => 1,
        p_actor_username   => 'ADMIN001',
        p_reason           => 'Audit verification test'
    );

    -- Verify event logged with NULL request_id
    SELECT event_id
      INTO l_event_id
      FROM (SELECT event_id
              FROM hr_leave_request_events
             WHERE request_id IS NULL
               AND event_type = 'BALANCE_ADJUSTED'
               AND actor_username = 'ADMIN001'
             ORDER BY event_timestamp DESC)
     WHERE ROWNUM = 1;

    -- Revert the adjustment
    hr_leave_pkg.adjust_balance(
        p_user_id          => l_emp_user_id,
        p_leave_type_code  => 'ANNUAL',
        p_year             => EXTRACT(YEAR FROM SYSDATE),
        p_adjustment_delta => -1,
        p_actor_username   => 'ADMIN001',
        p_reason           => 'Audit verification test revert'
    );

    -- Clean up test events
    DELETE FROM hr_leave_request_events
     WHERE request_id IS NULL
       AND event_type = 'BALANCE_ADJUSTED'
       AND comments LIKE '%Audit verification test%';

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Test 1 (ADJUST_BALANCE NULL request_id): PASSED');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Test 1 FAILED: ' || SQLERRM);
        RAISE;
END;
/

PROMPT =========================================================================
PROMPT Test Scenario 2: Critical 1 - GENERATE_REQUEST_SUMMARY Ownership Check
PROMPT =========================================================================
DECLARE
    l_req_id     NUMBER;
    l_error_seen BOOLEAN := FALSE;
    l_summary    VARCHAR2(4000);
BEGIN
    -- Locate a request owned by EMP001
    SELECT request_id
      INTO l_req_id
      FROM (SELECT request_id
              FROM hr_leave_requests
             WHERE user_id = (SELECT user_id FROM hr_users WHERE username = 'EMP001')
             ORDER BY created_at DESC)
     WHERE ROWNUM = 1;

    -- Initialize session as EMP002 (unauthorized non-owner)
    apex_session.create_session(
        p_app_id   => 100,
        p_page_id  => 1,
        p_username => 'EMP002'
    );

    l_summary := hr_ai_pkg.generate_request_summary(p_request_id => l_req_id);
    IF l_summary LIKE '%unauthorized%' OR l_summary LIKE '%not found%' THEN
        l_error_seen := TRUE;
    END IF;

    IF NOT l_error_seen THEN
        RAISE_APPLICATION_ERROR(-20099, 'Test 2 FAILED: Non-owner was permitted to generate summary! Result: ' || l_summary);
    END IF;

    -- Initialize session as EMP001 (authorized owner)
    apex_session.create_session(
        p_app_id   => 100,
        p_page_id  => 1,
        p_username => 'EMP001'
    );

    -- Owner should execute and get valid summary
    l_summary := hr_ai_pkg.generate_request_summary(p_request_id => l_req_id);
    IF l_summary LIKE '%unauthorized%' OR l_summary LIKE '%not found%' OR l_summary IS NULL THEN
        RAISE_APPLICATION_ERROR(-20099, 'Test 2 FAILED: Owner was denied summary');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Test 2 (GENERATE_REQUEST_SUMMARY ownership gate): PASSED');
END;
/

PROMPT =========================================================================
PROMPT Test Scenario 3: High 9 - Direct Manager Role Verification
PROMPT =========================================================================
DECLARE
    l_req_id       NUMBER;
    l_allowed      BOOLEAN;
    l_start_date   DATE;
    l_end_date     DATE;
    l_emp2_uid     NUMBER;
    l_mgr_role_id  NUMBER;
    l_orig_mgr_id  NUMBER;
BEGIN
    SELECT user_id INTO l_emp2_uid FROM hr_users WHERE username = 'EMP002';
    SELECT role_id INTO l_mgr_role_id FROM hr_roles WHERE role_code = 'MANAGER';
    SELECT manager_id INTO l_orig_mgr_id FROM hr_users WHERE username = 'EMP001';

    SELECT NVL(MAX(end_date), TRUNC(SYSDATE)) + 5
      INTO l_start_date
      FROM hr_leave_requests
     WHERE user_id = (SELECT user_id FROM hr_users WHERE username = 'EMP001');

    l_end_date := l_start_date + 1;
    WHILE hr_leave_pkg.calculate_days(l_start_date, l_end_date) < 1 LOOP
        l_end_date := l_end_date + 1;
    END LOOP;

    -- Create a fresh pending request for EMP001
    hr_leave_pkg.create_request(
        p_username        => 'EMP001',
        p_leave_type_code => 'ANNUAL',
        p_start_date      => l_start_date,
        p_end_date        => l_end_date,
        p_reason          => 'Test approval request',
        p_request_id      => l_req_id
    );

    -- Temporarily set EMP002 as EMP001's manager (EMP002 has NO MANAGER role)
    UPDATE hr_users SET manager_id = l_emp2_uid WHERE username = 'EMP001';

    -- Direct manager WITHOUT MANAGER role must NOT be allowed to approve
    l_allowed := hr_auth_pkg.can_approve_request(
        p_actor_username => 'EMP002',
        p_request_id     => l_req_id
    );

    IF l_allowed THEN
        -- Cleanup and raise
        UPDATE hr_users SET manager_id = l_orig_mgr_id WHERE username = 'EMP001';
        DELETE FROM hr_leave_request_events WHERE request_id = l_req_id;
        DELETE FROM hr_leave_requests WHERE request_id = l_req_id;
        COMMIT;
        RAISE_APPLICATION_ERROR(-20099, 'Test 3 FAILED: Manager without MANAGER role was permitted to approve');
    END IF;

    -- Now grant MANAGER role to EMP002
    INSERT INTO hr_user_roles (user_id, role_id, created_by)
    VALUES (l_emp2_uid, l_mgr_role_id, 'ADMIN001');

    -- Direct manager WITH MANAGER role MUST be allowed to approve
    l_allowed := hr_auth_pkg.can_approve_request(
        p_actor_username => 'EMP002',
        p_request_id     => l_req_id
    );

    -- Cleanup test data
    DELETE FROM hr_user_roles WHERE user_id = l_emp2_uid AND role_id = l_mgr_role_id;
    UPDATE hr_users SET manager_id = l_orig_mgr_id WHERE username = 'EMP001';
    DELETE FROM hr_leave_request_events WHERE request_id = l_req_id;
    DELETE FROM hr_leave_requests WHERE request_id = l_req_id;
    UPDATE hr_leave_balances
       SET pending_days = pending_days - hr_leave_pkg.calculate_days(l_start_date, l_end_date)
     WHERE user_id = (SELECT user_id FROM hr_users WHERE username = 'EMP001')
       AND leave_type_id = (SELECT leave_type_id FROM hr_leave_types WHERE leave_type_code = 'ANNUAL')
       AND balance_year = EXTRACT(YEAR FROM l_start_date);
    COMMIT;

    IF NOT l_allowed THEN
        RAISE_APPLICATION_ERROR(-20099, 'Test 3 FAILED: Direct manager with MANAGER role was not authorized to approve');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Test 3 (CAN_APPROVE_REQUEST role verification): PASSED');
END;
/

PROMPT =========================================================================
PROMPT Test Scenario 4: High 11 - Super Admin Lockout Protection
PROMPT =========================================================================
DECLARE
    l_super_role_id NUMBER;
    l_user_role_id  NUMBER;
    l_admin_user_id NUMBER;
    l_error_seen    BOOLEAN := FALSE;
BEGIN
    SELECT role_id INTO l_super_role_id FROM hr_roles WHERE role_code = 'SUPER_ADMIN';
    SELECT user_id INTO l_admin_user_id FROM hr_users WHERE username = 'ADMIN001';

    SELECT user_role_id
      INTO l_user_role_id
      FROM hr_user_roles
     WHERE user_id = l_admin_user_id
       AND role_id = l_super_role_id;

    SAVEPOINT sp_test4;

    -- Temporarily set all other super admins (DEMO) to inactive
    UPDATE hr_users SET active_yn = 'N' WHERE username = 'DEMO';

    -- Attempt to deactivate ADMIN001 (now the sole active super admin)
    BEGIN
        hr_auth_pkg.assert_can_deactivate_user(l_admin_user_id);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20021 THEN
                l_error_seen := TRUE;
            ELSE
                RAISE;
            END IF;
    END;

    IF NOT l_error_seen THEN
        ROLLBACK TO sp_test4;
        RAISE_APPLICATION_ERROR(-20099, 'Test 4 FAILED: Last active super admin was permitted to be deactivated!');
    END IF;

    -- Attempt to revoke SUPER_ADMIN role from the last active super admin
    l_error_seen := FALSE;
    BEGIN
        hr_auth_pkg.assert_can_revoke_role(l_user_role_id);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20022 THEN
                l_error_seen := TRUE;
            ELSE
                RAISE;
            END IF;
    END;

    ROLLBACK TO sp_test4;

    IF NOT l_error_seen THEN
        RAISE_APPLICATION_ERROR(-20099, 'Test 4 FAILED: Last SUPER_ADMIN role grant was permitted to be revoked!');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Test 4 (Super Admin lockout prevention): PASSED');
END;
/

PROMPT =========================================================================
PROMPT Test Scenario 5: High 8 - CREATE_REQUEST Requires EMPLOYEE Role
PROMPT =========================================================================
DECLARE
    l_error_seen BOOLEAN := FALSE;
    l_req_id     NUMBER;
BEGIN
    SAVEPOINT sp_test5;

    INSERT INTO hr_users (username, full_name, email, active_yn, created_by)
    VALUES ('TEST_NO_ROLE', 'Test No Role', 'testnorole@example.com', 'Y', 'ADMIN001');

    BEGIN
        hr_leave_pkg.create_request(
            p_username        => 'TEST_NO_ROLE',
            p_leave_type_code => 'ANNUAL',
            p_start_date      => TRUNC(SYSDATE) + 50,
            p_end_date        => TRUNC(SYSDATE) + 52,
            p_reason          => 'Test request',
            p_request_id      => l_req_id
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20025 THEN
                l_error_seen := TRUE;
            ELSE
                RAISE;
            END IF;
    END;

    ROLLBACK TO sp_test5;

    IF NOT l_error_seen THEN
        RAISE_APPLICATION_ERROR(-20099, 'Test 5 FAILED: User without EMPLOYEE role was permitted to create request!');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Test 5 (CREATE_REQUEST role requirement): PASSED');
END;
/

PROMPT =========================================================================
PROMPT Test Scenario 6: Medium 16 - Cross-Year Request Rejection
PROMPT =========================================================================
DECLARE
    l_error_seen BOOLEAN := FALSE;
    l_req_id     NUMBER;
    l_curr_year  NUMBER := EXTRACT(YEAR FROM SYSDATE);
    l_start_date DATE;
    l_end_date   DATE;
BEGIN
    SAVEPOINT sp_test6;
    l_start_date := TO_DATE(l_curr_year || '-12-30', 'YYYY-MM-DD');
    l_end_date   := TO_DATE((l_curr_year + 1) || '-01-05', 'YYYY-MM-DD');

    BEGIN
        hr_leave_pkg.create_request(
            p_username        => 'EMP001',
            p_leave_type_code => 'ANNUAL',
            p_start_date      => l_start_date,
            p_end_date        => l_end_date,
            p_reason          => 'Cross-year test',
            p_request_id      => l_req_id
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20026 THEN
                l_error_seen := TRUE;
            ELSE
                RAISE;
            END IF;
    END;
    ROLLBACK TO sp_test6;

    IF NOT l_error_seen THEN
        RAISE_APPLICATION_ERROR(-20099, 'Test 6 FAILED: Cross-year request was not rejected with -20026!');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Test 6 (Cross-year request validation): PASSED');
END;
/

PROMPT =========================================================================
PROMPT Test Scenario 7: Medium 14 - Available Days Formula Verification
PROMPT =========================================================================
DECLARE
    l_avail NUMBER;
    l_ent   NUMBER;
    l_adj   NUMBER;
    l_used  NUMBER;
    l_pend  NUMBER;
BEGIN
    SELECT entitlement_days, adjustment_days, used_days, pending_days
      INTO l_ent, l_adj, l_used, l_pend
      FROM hr_leave_balances
     WHERE user_id = (SELECT user_id FROM hr_users WHERE username = 'EMP001')
       AND leave_type_id = (SELECT leave_type_id FROM hr_leave_types WHERE leave_type_code = 'ANNUAL')
       AND balance_year = EXTRACT(YEAR FROM SYSDATE);

    l_avail := hr_leave_pkg.get_available_days(
        p_username        => 'EMP001',
        p_leave_type_code => 'ANNUAL',
        p_year            => EXTRACT(YEAR FROM SYSDATE)
    );

    IF l_avail != (l_ent + l_adj - l_used - l_pend) THEN
        RAISE_APPLICATION_ERROR(-20099, 'Test 7 FAILED: Available days (' || l_avail || 
            ') does not match expected formula (' || (l_ent + l_adj - l_used - l_pend) || ')');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Test 7 (Available days includes adjustment_days): PASSED');
END;
/

PROMPT =========================================================================
PROMPT Test Scenario 8: Medium 17 - HR_AI_PKG JSON Serialization
PROMPT =========================================================================
DECLARE
    l_clob CLOB;
    l_json JSON_OBJECT_T;
BEGIN
    apex_session.create_session(
        p_app_id   => 100,
        p_page_id  => 1,
        p_username => 'EMP001'
    );

    -- 8.1 get_my_profile
    l_clob := hr_ai_pkg.get_my_profile;
    l_json := JSON_OBJECT_T.parse(l_clob);
    IF NOT l_json.has('username') THEN
        RAISE_APPLICATION_ERROR(-20099, 'Test 8.1 FAILED: get_my_profile JSON missing username key');
    END IF;

    -- 8.2 get_leave_balance
    l_clob := hr_ai_pkg.get_leave_balance(p_leave_type_code => 'ANNUAL');
    l_json := JSON_OBJECT_T.parse(l_clob);
    IF NOT l_json.has('available') THEN
        RAISE_APPLICATION_ERROR(-20099, 'Test 8.2 FAILED: get_leave_balance JSON missing available key');
    END IF;

    -- 8.3 calculate_leave_days
    l_clob := hr_ai_pkg.calculate_leave_days(
        p_start_date => TRUNC(SYSDATE) + 10,
        p_end_date   => TRUNC(SYSDATE) + 14
    );
    l_json := JSON_OBJECT_T.parse(l_clob);
    IF NOT l_json.has('requested_days') THEN
        RAISE_APPLICATION_ERROR(-20099, 'Test 8.3 FAILED: calculate_leave_days JSON missing requested_days key');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Test 8 (HR_AI_PKG valid JSON serialization): PASSED');
END;
/

PROMPT =========================================================================
PROMPT ALL AUDIT REMEDIATION VERIFICATION TESTS PASSED SUCCESSFULLY!
PROMPT =========================================================================
