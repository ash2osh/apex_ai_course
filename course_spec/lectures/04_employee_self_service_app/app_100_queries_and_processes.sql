prompt === App 100 balance report: identity is derived from the APEX session ===
select t.leave_type_code,
       t.leave_type_name,
       b.balance_year,
       b.entitlement_days,
       b.used_days,
       b.pending_days,
       b.entitlement_days - b.used_days - b.pending_days as available_days
  from hr_leave_balances b
  join hr_leave_types t on t.leave_type_id = b.leave_type_id
 where b.user_id = hr_user_pkg.current_user_id
 order by b.balance_year desc, t.display_order;

prompt === Page 4 process (run only in a valid App 100 submit request) ===
declare
    l_request_id  number;
    l_workflow_id number;
begin
    hr_leave_pkg.create_request(
        p_username        => :APP_USER,
        p_leave_type_code => :P4_LEAVE_TYPE_CODE,
        p_start_date      => :P4_START_DATE,
        p_end_date        => :P4_END_DATE,
        p_reason          => :P4_REASON,
        p_request_id      => l_request_id);
    l_workflow_id := hr_workflow_pkg.start_leave_approval(
        p_request_id => l_request_id);
    :P4_REQUEST_ID := l_request_id;
    :P4_WORKFLOW_ID := l_workflow_id;
    commit;
end;
/
