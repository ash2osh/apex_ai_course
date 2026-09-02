prompt === Pending administrative workload ===
select status, count(*) as request_count, sum(requested_days) as requested_days
  from hr_leave_requests
 group by status
 order by status;

prompt === Page 8 balance adjustment (run only in an authorized App 200 request) ===
begin
    hr_leave_pkg.adjust_balance(
        p_user_id          => :P8_USER_ID,
        p_leave_type_code  => :P8_LEAVE_TYPE_CODE,
        p_year             => :P8_YEAR,
        p_adjustment_delta => :P8_DELTA,
        p_actor_username   => :APP_USER,
        p_reason           => :P8_REASON);
    commit;
end;
/
