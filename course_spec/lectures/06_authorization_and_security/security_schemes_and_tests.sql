set serveroutput on size unlimited

prompt ============================================================================
prompt APEX Authorization Schemes Reference Expressions
prompt ============================================================================
prompt IS_EMPLOYEE:        return hr_auth_pkg.is_employee(:APP_USER);
prompt IS_MANAGER:         return hr_auth_pkg.is_manager(:APP_USER);
prompt IS_ADMIN:           return hr_auth_pkg.is_admin(:APP_USER);
prompt IS_SUPER_ADMIN:     return hr_auth_pkg.is_super_admin(:APP_USER);
prompt CAN_CANCEL_REQUEST: return hr_auth_pkg.can_cancel_request(:APP_USER, to_number(:P6_REQUEST_ID));
prompt CAN_APPROVE:        return hr_auth_pkg.can_approve_request(:APP_USER, to_number(:P4_REQUEST_ID));
prompt ============================================================================

declare
    procedure assert_true(p_value boolean, p_message varchar2) is
    begin
        if not p_value then
            raise_application_error(-20901, 'Assertion Failed (Expected TRUE): ' || p_message);
        end if;
    end;

    procedure assert_false(p_value boolean, p_message varchar2) is
    begin
        if p_value then
            raise_application_error(-20902, 'Assertion Failed (Expected FALSE): ' || p_message);
        end if;
    end;
begin
    dbms_output.put_line('--- Running Episode 6 Authorization & Security Verification ---');

    -- 1. EMP001 (Regular Employee)
    assert_true(hr_auth_pkg.is_employee('EMP001'), 'EMP001 must have EMPLOYEE access');
    assert_false(hr_auth_pkg.is_admin('EMP001'), 'EMP001 must not have ADMIN access');
    assert_false(hr_auth_pkg.is_super_admin('EMP001'), 'EMP001 must not have SUPER_ADMIN access');
    dbms_output.put_line('  [PASS] EMP001 role matrix verified.');

    -- 2. MGR001 (Manager)
    assert_true(hr_auth_pkg.is_employee('MGR001'), 'MGR001 must have EMPLOYEE access');
    assert_true(hr_auth_pkg.is_manager('MGR001'), 'MGR001 must have MANAGER access');
    assert_false(hr_auth_pkg.is_super_admin('MGR001'), 'MGR001 must not have SUPER_ADMIN access');
    dbms_output.put_line('  [PASS] MGR001 role matrix verified.');

    -- 3. HR001 (HR Administrator)
    assert_true(hr_auth_pkg.is_employee('HR001'), 'HR001 must have EMPLOYEE access');
    assert_true(hr_auth_pkg.is_admin('HR001'), 'HR001 must have ADMIN access');
    assert_false(hr_auth_pkg.is_super_admin('HR001'), 'HR001 must not have SUPER_ADMIN access');
    dbms_output.put_line('  [PASS] HR001 role matrix verified.');

    -- 4. ADMIN001 (Super Administrator)
    assert_true(hr_auth_pkg.is_employee('ADMIN001'), 'ADMIN001 must have EMPLOYEE access');
    assert_true(hr_auth_pkg.is_admin('ADMIN001'), 'ADMIN001 must have ADMIN access');
    assert_true(hr_auth_pkg.is_super_admin('ADMIN001'), 'ADMIN001 must have SUPER_ADMIN access');
    dbms_output.put_line('  [PASS] ADMIN001 role matrix verified.');

    dbms_output.put_line('--- All Episode 6 Authorization Checks Passed Successfully ---');
end;
/
