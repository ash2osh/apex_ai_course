prompt === My Tasks using documented APEX 26.1 runtime views ===
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

prompt Task definitions: LEAVE_MANAGER_APPROVAL and LEAVE_HR_APPROVAL.
