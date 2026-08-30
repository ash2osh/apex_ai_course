set serveroutput on

prompt APEX authorization scheme expressions
prompt IS_MANAGER:     return hr_auth_pkg.is_manager(:APP_USER);
prompt IS_ADMIN:       return hr_auth_pkg.is_admin(:APP_USER);
prompt IS_SUPER_ADMIN: return hr_auth_pkg.is_super_admin(:APP_USER);
prompt CAN_APPROVE:    return hr_auth_pkg.can_approve_request(:APP_USER, :P4_REQUEST_ID);

declare
    procedure assert_false(p_value boolean, p_message varchar2) is
    begin
        if p_value then
            raise_application_error(-20901, p_message);
        end if;
    end;
begin
    assert_false(hr_auth_pkg.is_admin('EMP001'), 'EMP001 must not be an administrator.');
    assert_false(hr_auth_pkg.is_super_admin('HR001'), 'HR001 must not be a super administrator.');
    dbms_output.put_line('Episode 5 authorization checks passed.');
end;
/
