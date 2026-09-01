-- ============================================================================
-- Script: 01_seed_user_demo.sql
-- Description: Seed user DEMO as an Employee with roles and leave balances
-- Target Schema: DEMO
-- Environment: Non-Production Sandbox / Docker
-- ============================================================================

SET DEFINE OFF;
SET SERVEROUTPUT ON;

DECLARE
    l_user_id      NUMBER;
    l_manager_id   NUMBER;
    l_dept_id      NUMBER;
    l_current_year NUMBER := EXTRACT(YEAR FROM SYSDATE);
    l_req_id       NUMBER;
BEGIN
    -- 1. Resolve manager and department
    SELECT user_id INTO l_manager_id FROM hr_users WHERE username = 'MGR001';
    SELECT department_id INTO l_dept_id FROM hr_departments WHERE department_code = 'DEP_ENG';

    -- Check if DEMO already exists
    BEGIN
        SELECT user_id INTO l_user_id FROM hr_users WHERE username = 'DEMO';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            SELECT COALESCE(MAX(user_id), 0) + 1 INTO l_user_id FROM hr_users;
    END;

    -- 2. Insert or update user DEMO
    MERGE INTO hr_users dest
    USING (
        SELECT l_user_id                   AS user_id,
               'DEMO'                      AS username,
               'Demo Employee'             AS full_name,
               'demo.employee@example.com' AS email,
               l_manager_id                AS manager_id,
               l_dept_id                   AS department_id,
               'Y'                         AS active_yn
          FROM dual
    ) src
    ON (dest.username = src.username)
    WHEN MATCHED THEN
        UPDATE SET dest.full_name     = src.full_name,
                   dest.email         = src.email,
                   dest.manager_id    = src.manager_id,
                   dest.department_id = src.department_id,
                   dest.active_yn     = src.active_yn,
                   dest.updated_at    = SYSTIMESTAMP,
                   dest.updated_by    = 'SYSTEM_SEED'
    WHEN NOT MATCHED THEN
        INSERT (user_id, username, full_name, email, manager_id, department_id, active_yn)
        VALUES (src.user_id, src.username, src.full_name, src.email, src.manager_id, src.department_id, src.active_yn);

    -- Retrieve resolved user_id
    SELECT user_id INTO l_user_id FROM hr_users WHERE username = 'DEMO';
    DBMS_OUTPUT.PUT_LINE('User DEMO seeded with user_id: ' || l_user_id);

    -- 3. Assign EMPLOYEE role (role_id = 1)
    MERGE INTO hr_user_roles dest
    USING (
        SELECT l_user_id AS user_id,
               1         AS role_id
          FROM dual
    ) src
    ON (dest.user_id = src.user_id AND dest.role_id = src.role_id)
    WHEN NOT MATCHED THEN
        INSERT (user_id, role_id) VALUES (src.user_id, src.role_id);

    DBMS_OUTPUT.PUT_LINE('Role EMPLOYEE assigned to user DEMO.');

    -- 4. Seed Leave Balances for current year
    -- ANNUAL (leave_type_id = 1): 21 entitlement, 5 used -> 16 available
    MERGE INTO hr_leave_balances dest
    USING (
        SELECT l_user_id      AS user_id,
               1              AS leave_type_id,
               l_current_year AS balance_year,
               21             AS entitlement_days,
               5              AS used_days,
               0              AS pending_days,
               0              AS adjustment_days
          FROM dual
    ) src
    ON (dest.user_id = src.user_id AND dest.leave_type_id = src.leave_type_id AND dest.balance_year = src.balance_year)
    WHEN MATCHED THEN
        UPDATE SET dest.entitlement_days = src.entitlement_days,
                   dest.used_days        = src.used_days,
                   dest.pending_days     = src.pending_days,
                   dest.adjustment_days  = src.adjustment_days
    WHEN NOT MATCHED THEN
        INSERT (user_id, leave_type_id, balance_year, entitlement_days, used_days, pending_days, adjustment_days)
        VALUES (src.user_id, src.leave_type_id, src.balance_year, src.entitlement_days, src.used_days, src.pending_days, src.adjustment_days);

    -- SICK (leave_type_id = 2): 15 entitlement, 1 used -> 14 available
    MERGE INTO hr_leave_balances dest
    USING (
        SELECT l_user_id      AS user_id,
               2              AS leave_type_id,
               l_current_year AS balance_year,
               15             AS entitlement_days,
               1              AS used_days,
               0              AS pending_days,
               0              AS adjustment_days
          FROM dual
    ) src
    ON (dest.user_id = src.user_id AND dest.leave_type_id = src.leave_type_id AND dest.balance_year = src.balance_year)
    WHEN MATCHED THEN
        UPDATE SET dest.entitlement_days = src.entitlement_days,
                   dest.used_days        = src.used_days,
                   dest.pending_days     = src.pending_days,
                   dest.adjustment_days  = src.adjustment_days
    WHEN NOT MATCHED THEN
        INSERT (user_id, leave_type_id, balance_year, entitlement_days, used_days, pending_days, adjustment_days)
        VALUES (src.user_id, src.leave_type_id, src.balance_year, src.entitlement_days, src.used_days, src.pending_days, src.adjustment_days);

    -- EMERGENCY (leave_type_id = 3): 5 entitlement, 0 used -> 5 available
    MERGE INTO hr_leave_balances dest
    USING (
        SELECT l_user_id      AS user_id,
               3              AS leave_type_id,
               l_current_year AS balance_year,
               5              AS entitlement_days,
               0              AS used_days,
               0              AS pending_days,
               0              AS adjustment_days
          FROM dual
    ) src
    ON (dest.user_id = src.user_id AND dest.leave_type_id = src.leave_type_id AND dest.balance_year = src.balance_year)
    WHEN MATCHED THEN
        UPDATE SET dest.entitlement_days = src.entitlement_days,
                   dest.used_days        = src.used_days,
                   dest.pending_days     = src.pending_days,
                   dest.adjustment_days  = src.adjustment_days
    WHEN NOT MATCHED THEN
        INSERT (user_id, leave_type_id, balance_year, entitlement_days, used_days, pending_days, adjustment_days)
        VALUES (src.user_id, src.leave_type_id, src.balance_year, src.entitlement_days, src.used_days, src.pending_days, src.adjustment_days);

    DBMS_OUTPUT.PUT_LINE('Leave balances initialized for year ' || l_current_year);

    -- 5. Seed Sample Leave Request and Timeline Event for user DEMO
    SELECT COALESCE(MAX(request_id), 100) + 1 INTO l_req_id FROM hr_leave_requests;

    MERGE INTO hr_leave_requests dest
    USING (
        SELECT l_req_id                     AS request_id,
               l_user_id                    AS user_id,
               1                            AS leave_type_id,
               TRUNC(SYSDATE) - 30          AS start_date,
               TRUNC(SYSDATE) - 26          AS end_date,
               5                            AS requested_days,
               'Spring family trip'         AS reason,
               'APPROVED'                   AS status,
               'Demo Employee requested 5 days of annual leave. Approved by Manager.' AS ai_summary,
               9001                         AS workflow_id
          FROM dual
    ) src
    ON (dest.user_id = src.user_id AND dest.reason = src.reason)
    WHEN NOT MATCHED THEN
        INSERT (request_id, user_id, leave_type_id, start_date, end_date, requested_days, reason, status, ai_summary, workflow_id)
        VALUES (src.request_id, src.user_id, src.leave_type_id, src.start_date, src.end_date, src.requested_days, src.reason, src.status, src.ai_summary, src.workflow_id);

    SELECT request_id INTO l_req_id FROM hr_leave_requests WHERE user_id = l_user_id AND reason = 'Spring family trip';

    MERGE INTO hr_leave_request_events dest
    USING (
        SELECT l_req_id                     AS request_id,
               'SUBMITTED'                  AS event_type,
               'DRAFT'                      AS from_status,
               'SUBMITTED'                  AS to_status,
               'DEMO'                       AS actor_username,
               'Submitted leave request'    AS comments,
               SYSTIMESTAMP - INTERVAL '35' DAY AS event_timestamp
          FROM dual
    ) src
    ON (dest.request_id = src.request_id AND dest.event_type = src.event_type)
    WHEN NOT MATCHED THEN
        INSERT (request_id, event_type, from_status, to_status, actor_username, comments, event_timestamp)
        VALUES (src.request_id, src.event_type, src.from_status, src.to_status, src.actor_username, src.comments, src.event_timestamp);

    MERGE INTO hr_leave_request_events dest
    USING (
        SELECT l_req_id                     AS request_id,
               'MANAGER_APPROVED'           AS event_type,
               'SUBMITTED'                  AS from_status,
               'APPROVED'                   AS to_status,
               'MGR001'                     AS actor_username,
               'Approved by direct manager' AS comments,
               SYSTIMESTAMP - INTERVAL '34' DAY AS event_timestamp
          FROM dual
    ) src
    ON (dest.request_id = src.request_id AND dest.event_type = src.event_type)
    WHEN NOT MATCHED THEN
        INSERT (request_id, event_type, from_status, to_status, actor_username, comments, event_timestamp)
        VALUES (src.request_id, src.event_type, src.from_status, src.to_status, src.actor_username, src.comments, src.event_timestamp);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('User DEMO successfully seeded with sample request #' || l_req_id || ' and committed.');
END;
/
