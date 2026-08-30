prompt === App 100 caller-owned workflow start transaction ===
declare
    l_workflow_id number;
begin
    l_workflow_id := hr_workflow_pkg.start_leave_approval(
        p_request_id => :P4_REQUEST_ID);
    :P4_WORKFLOW_ID := l_workflow_id;
    commit;
end;
/

prompt === Manager Human Task completion action ===
begin
    hr_workflow_pkg.manager_outcome(
        p_request_id     => :APEX$TASK_PK,
        p_actor_username => :APEX$TASK_OWNER,
        p_outcome        => :APEX$TASK_OUTCOME,
        p_comments       => :APEX$TASK_COMMENTS);
end;
/
