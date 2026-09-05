prompt === Task Definition LEAVE_MANAGER_APPROVAL Configuration ===

prompt --- Participant: Potential Owner (SQL Query using :T_REQUEST_ID) ---
SELECT UPPER(m.username)
  FROM hr_leave_requests r
  JOIN hr_users e ON e.user_id = r.user_id
  JOIN hr_users m ON m.user_id = e.manager_id
 WHERE r.request_id = :T_REQUEST_ID
   AND m.active_yn = 'Y';

prompt --- Participant: Business Administrator (SQL Query using :T_REQUEST_ID) ---
SELECT DISTINCT UPPER(u.username)
  FROM hr_users u
  JOIN hr_user_roles ur ON ur.user_id = u.user_id
  JOIN hr_roles ro      ON ro.role_id = ur.role_id
 WHERE ro.role_code IN ('ADMIN', 'SUPER_ADMIN')
   AND u.active_yn = 'Y'
   AND u.user_id != (
       SELECT req.user_id
         FROM hr_leave_requests req
        WHERE req.request_id = :T_REQUEST_ID
   );

prompt --- Action 1: ON APPROVED (Event: Complete, Outcome: Approved) ---
begin
    hr_workflow_pkg.manager_outcome(
        p_request_id     => :T_REQUEST_ID,
        p_actor_username => coalesce(:APEX$TASK_OWNER, :APP_USER),
        p_outcome        => 'APPROVED',
        p_comments       => :APEX$TASK_COMMENTS
    );
end;
/

prompt --- Action 2: ON REJECT (Event: Complete, Outcome: Rejected) ---
begin
    hr_workflow_pkg.manager_outcome(
        p_request_id     => :T_REQUEST_ID,
        p_actor_username => coalesce(:APEX$TASK_OWNER, :APP_USER),
        p_outcome        => 'REJECTED',
        p_comments       => :APEX$TASK_COMMENTS
    );
end;
/

prompt --- Action 3: ON CANCEL (Event: Cancel) ---
begin
    hr_workflow_pkg.manager_outcome(
        p_request_id     => :T_REQUEST_ID,
        p_actor_username => coalesce(:APEX$TASK_OWNER, :APP_USER),
        p_outcome        => 'CANCELLED',
        p_comments       => :APEX$TASK_COMMENTS
    );
end;
/

prompt === My Tasks Inbox Runtime Query (Page 2, App 200) ===
select distinct t.task_id,
       t.task_def_name,
       t.subject,
       t.state_code,
       t.actual_owner,
       p.participant_type
  from apex_tasks t
  join apex_task_participants p on p.task_id = t.task_id
 where upper(p.participant) = upper(:APP_USER)
 order by t.task_id desc;
