prompt === Seven package-backed CLOB AI tools ===
select hr_ai_pkg.get_my_profile from dual;
select hr_ai_pkg.get_leave_balance(p_leave_type_code => 'ANNUAL') from dual;
select hr_ai_pkg.get_my_leave_requests from dual;
select hr_ai_pkg.get_leave_request(p_request_id => :REQUEST_ID) from dual;
select hr_ai_pkg.calculate_leave_days(p_start_date => :START_DATE, p_end_date => :END_DATE) from dual;

prompt CREATE_LEAVE_REQUEST and CANCEL_LEAVE_REQUEST are write tools configured for APEX 26.1 on-demand user approval.
