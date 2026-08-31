
  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DEMO"."HR_WORKFLOW_PKG" AS

    FUNCTION get_system_setting(
        p_setting_code   IN VARCHAR2,
        p_default_value  IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_value VARCHAR2(4000);
    BEGIN
        SELECT setting_value
          INTO l_value
          FROM hr_system_settings
         WHERE setting_code = p_setting_code;
        RETURN l_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN p_default_value;
    END get_system_setting;

    FUNCTION start_leave_approval(
        p_request_id IN NUMBER
    ) RETURN NUMBER IS
        l_workflow_id    NUMBER;
        l_user_id        NUMBER;
        l_username       VARCHAR2(100);
        l_mgr_username   VARCHAR2(100);
        l_requested_days NUMBER;
    BEGIN
        SELECT r.user_id, u.username, m.username, r.requested_days
          INTO l_user_id, l_username, l_mgr_username, l_requested_days
          FROM hr_leave_requests r
          JOIN hr_users u ON u.user_id = r.user_id
          LEFT JOIN hr_users m ON m.user_id = u.manager_id
         WHERE r.request_id = p_request_id;

        -- Generate a synthetic or APEX workflow instance ID
        l_workflow_id := NVL(TO_NUMBER(TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3')), p_request_id + 1000);

        UPDATE hr_leave_requests
           SET workflow_id = l_workflow_id
         WHERE request_id = p_request_id;

        hr_leave_pkg.record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'WORKFLOW_STARTED',
            p_from_status    => 'PENDING_MANAGER_APPROVAL',
            p_to_status      => 'PENDING_MANAGER_APPROVAL',
            p_actor_username => 'SYSTEM',
            p_comments       => 'Workflow LEAVE_APPROVAL initiated (Instance #' || l_workflow_id || ')'
        );

        RETURN l_workflow_id;
    END start_leave_approval;

    PROCEDURE manager_outcome(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_outcome        IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    ) IS
        l_requested_days NUMBER;
        l_threshold      NUMBER;
    BEGIN
        IF UPPER(p_outcome) IN ('APPROVED', 'APPROVE') THEN
            l_threshold := TO_NUMBER(get_system_setting('LONG_LEAVE_THRESHOLD', '5'));

            SELECT requested_days
              INTO l_requested_days
              FROM hr_leave_requests
             WHERE request_id = p_request_id;

            IF l_requested_days <= l_threshold THEN
                -- Final approval directly
                hr_leave_pkg.approve_request(
                    p_request_id     => p_request_id,
                    p_actor_username => p_actor_username,
                    p_comments       => p_comments
                );
            ELSE
                -- Two-tier approval: transition to HR review
                UPDATE hr_leave_requests
                   SET status = 'PENDING_HR_APPROVAL'
                 WHERE request_id = p_request_id;

                hr_leave_pkg.record_event(
                    p_request_id     => p_request_id,
                    p_event_type     => 'MANAGER_APPROVED',
                    p_from_status    => 'PENDING_MANAGER_APPROVAL',
                    p_to_status      => 'PENDING_HR_APPROVAL',
                    p_actor_username => p_actor_username,
                    p_comments       => NVL(p_comments, 'Manager approved; routed to HR due to duration > ' || l_threshold || ' days')
                );
            END IF;

        ELSIF UPPER(p_outcome) IN ('REJECTED', 'REJECT') THEN
            hr_leave_pkg.reject_request(
                p_request_id     => p_request_id,
                p_actor_username => p_actor_username,
                p_comments       => p_comments
            );
        ELSE
            RAISE_APPLICATION_ERROR(-20030, 'Unknown manager outcome: ' || p_outcome);
        END IF;

    END manager_outcome;

    PROCEDURE hr_outcome(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_outcome        IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        IF UPPER(p_outcome) IN ('APPROVED', 'APPROVE') THEN
            hr_leave_pkg.approve_request(
                p_request_id     => p_request_id,
                p_actor_username => p_actor_username,
                p_comments       => p_comments
            );
        ELSIF UPPER(p_outcome) IN ('REJECTED', 'REJECT') THEN
            hr_leave_pkg.reject_request(
                p_request_id     => p_request_id,
                p_actor_username => p_actor_username,
                p_comments       => p_comments
            );
        ELSE
            RAISE_APPLICATION_ERROR(-20031, 'Unknown HR outcome: ' || p_outcome);
        END IF;
    END hr_outcome;

    PROCEDURE workflow_fault(
        p_request_id    IN NUMBER,
        p_error_message IN VARCHAR2
    ) IS
    BEGIN
        UPDATE hr_leave_requests
           SET status = 'WORKFLOW_ERROR'
         WHERE request_id = p_request_id;

        hr_leave_pkg.record_event(
            p_request_id     => p_request_id,
            p_event_type     => 'WORKFLOW_ERROR',
            p_from_status    => 'PENDING',
            p_to_status      => 'WORKFLOW_ERROR',
            p_actor_username => 'SYSTEM',
            p_comments       => p_error_message
        );
    END workflow_fault;

END hr_workflow_pkg;
/
