prompt === App 100 Page 4 Submit Leave Request Process ===
declare
    l_request_id  number;
    l_workflow_id number;
    l_start_date  date;
    l_end_date    date;
begin
    begin
        l_start_date := to_date(:P4_START_DATE, 'YYYY-MM-DD');
    exception when others then
        l_start_date := to_date(:P4_START_DATE);
    end;
    begin
        l_end_date := to_date(:P4_END_DATE, 'YYYY-MM-DD');
    exception when others then
        l_end_date := to_date(:P4_END_DATE);
    end;

    -- 1. Create request record and reserve balance atomically
    hr_leave_pkg.create_request(
        p_username        => :APP_USER,
        p_leave_type_code => :P4_LEAVE_TYPE_CODE,
        p_start_date      => l_start_date,
        p_end_date        => l_end_date,
        p_reason          => :P4_REASON,
        p_request_id      => l_request_id
    );

    -- 2. Initiate App 200 LEAVE_APPROVAL workflow instance
    l_workflow_id := hr_workflow_pkg.start_leave_approval(
        p_request_id => l_request_id
    );

    :P4_REQUEST_ID := l_request_id;
    :P4_WORKFLOW_ID := l_workflow_id;
    commit;
    apex_application.g_print_success_message := 'Leave request #' || l_request_id || ' submitted successfully.';
end;
/

prompt === HR_WORKFLOW_PKG.start_leave_approval implementation ===
-- Inside HR_WORKFLOW_PKG package body:
/*
function start_leave_approval(
    p_request_id in number
) return number is
    l_workflow_id    number;
    l_user_id        number;
    l_username       varchar2(100);
    l_mgr_username   varchar2(100);
    l_requested_days number;
    l_params         apex_workflow.t_workflow_parameters;
begin
    select r.user_id, u.username, m.username, r.requested_days
      into l_user_id, l_username, l_mgr_username, l_requested_days
      from hr_leave_requests r
      join hr_users u on u.user_id = r.user_id
      left join hr_users m on m.user_id = u.manager_id
     where r.request_id = p_request_id;

    if apex_application.g_flow_id is null then
        apex_session.create_session(
            p_app_id   => 200,
            p_page_id  => 1,
            p_username => coalesce(l_username, 'DEMO')
        );
    end if;

    -- Map parameter static ID (P_REQUEST_ID) as configured in workflow definition
    l_params(1) := apex_workflow.t_workflow_parameter(
        static_id    => 'P_REQUEST_ID',
        string_value => to_char(p_request_id)
    );

    -- Start native workflow instance in App 200
    l_workflow_id := apex_workflow.start_workflow(
        p_application_id => 200,
        p_static_id      => 'leave-approval',
        p_parameters     => l_params,
        p_initiator      => coalesce(apex_application.g_user, l_username, sys_context('USERENV', 'SESSION_USER')),
        p_detail_pk      => to_char(p_request_id)
    );

    update hr_leave_requests
       set workflow_id = l_workflow_id
     where request_id = p_request_id;

    hr_leave_pkg.record_event(
        p_request_id     => p_request_id,
        p_event_type     => 'WORKFLOW_STARTED',
        p_from_status    => 'PENDING_MANAGER_APPROVAL',
        p_to_status      => 'PENDING_MANAGER_APPROVAL',
        p_actor_username => coalesce(apex_application.g_user, l_username, 'SYSTEM'),
        p_comments       => 'Workflow LEAVE_APPROVAL initiated (Instance #' || l_workflow_id || ')'
    );

    return l_workflow_id;
end start_leave_approval;
*/
