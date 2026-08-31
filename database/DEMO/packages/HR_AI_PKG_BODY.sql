
  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DEMO"."HR_AI_PKG" AS

    FUNCTION get_my_profile RETURN CLOB IS
        l_user_id NUMBER;
        l_json    VARCHAR2(4000);
    BEGIN
        l_user_id := hr_user_pkg.current_user_id;
        IF l_user_id IS NULL THEN
            RETURN '{"error": "No authenticated session or user profile not found"}';
        END IF;

        SELECT JSON_OBJECT(
            'user_id'     VALUE u.user_id,
            'username'    VALUE u.username,
            'full_name'   VALUE u.full_name,
            'email'       VALUE u.email,
            'department'  VALUE d.department_name,
            'manager'     VALUE NVL(m.full_name, 'None')
        )
          INTO l_json
          FROM hr_users u
          LEFT JOIN hr_departments d ON d.department_id = u.department_id
          LEFT JOIN hr_users m ON m.user_id = u.manager_id
         WHERE u.user_id = l_user_id;

        RETURN TO_CLOB(l_json);
    END get_my_profile;

    FUNCTION get_leave_balance(
        p_leave_type_code IN VARCHAR2 DEFAULT 'ANNUAL'
    ) RETURN CLOB IS
        l_user_id NUMBER;
        l_json    VARCHAR2(4000);
        l_year    NUMBER := EXTRACT(YEAR FROM SYSDATE);
    BEGIN
        l_user_id := hr_user_pkg.current_user_id;
        IF l_user_id IS NULL THEN
            RETURN '{"error": "No authenticated session"}';
        END IF;

        SELECT JSON_OBJECT(
            'leave_type'   VALUE t.leave_type_code,
            'year'         VALUE b.balance_year,
            'entitlement'  VALUE b.entitlement_days,
            'used'         VALUE b.used_days,
            'pending'      VALUE b.pending_days,
            'adjustment'   VALUE b.adjustment_days,
            'available'    VALUE (b.entitlement_days + b.adjustment_days - b.used_days - b.pending_days)
        )
          INTO l_json
          FROM hr_leave_balances b
          JOIN hr_leave_types t ON t.leave_type_id = b.leave_type_id
         WHERE b.user_id = l_user_id
           AND UPPER(t.leave_type_code) = UPPER(TRIM(p_leave_type_code))
           AND b.balance_year = l_year;

        RETURN TO_CLOB(l_json);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '{"error": "No balance record found for leave type ' || p_leave_type_code || ' in year ' || l_year || '"}';
    END get_leave_balance;

    FUNCTION get_my_leave_requests(
        p_status    IN VARCHAR2 DEFAULT NULL,
        p_date_from IN DATE DEFAULT NULL,
        p_date_to   IN DATE DEFAULT NULL
    ) RETURN CLOB IS
        l_user_id NUMBER;
        l_json    CLOB;
    BEGIN
        l_user_id := hr_user_pkg.current_user_id;
        IF l_user_id IS NULL THEN
            RETURN '{"error": "No authenticated session"}';
        END IF;

        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'request_id'     VALUE r.request_id,
                'leave_type'     VALUE t.leave_type_code,
                'start_date'     VALUE TO_CHAR(r.start_date, 'YYYY-MM-DD'),
                'end_date'       VALUE TO_CHAR(r.end_date, 'YYYY-MM-DD'),
                'requested_days' VALUE r.requested_days,
                'status'         VALUE r.status,
                'reason'         VALUE r.reason,
                'ai_summary'     VALUE r.ai_summary
            )
            ORDER BY r.start_date DESC
            RETURNING CLOB
        )
          INTO l_json
          FROM hr_leave_requests r
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.user_id = l_user_id
           AND (p_status IS NULL OR UPPER(r.status) = UPPER(TRIM(p_status)))
           AND (p_date_from IS NULL OR r.start_date >= p_date_from)
           AND (p_date_to IS NULL OR r.end_date <= p_date_to);

        RETURN NVL(l_json, '[]');
    END get_my_leave_requests;

    FUNCTION get_leave_request(
        p_request_id IN NUMBER
    ) RETURN CLOB IS
        l_user_id NUMBER;
        l_json    CLOB;
    BEGIN
        l_user_id := hr_user_pkg.current_user_id;

        SELECT JSON_OBJECT(
            'request_id'     VALUE r.request_id,
            'employee'       VALUE u.full_name,
            'username'       VALUE u.username,
            'leave_type'     VALUE t.leave_type_code,
            'start_date'     VALUE TO_CHAR(r.start_date, 'YYYY-MM-DD'),
            'end_date'       VALUE TO_CHAR(r.end_date, 'YYYY-MM-DD'),
            'requested_days' VALUE r.requested_days,
            'status'         VALUE r.status,
            'reason'         VALUE r.reason,
            'ai_summary'     VALUE r.ai_summary,
            'timeline'       VALUE (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'event_type' VALUE e.event_type,
                        'from_status' VALUE e.from_status,
                        'to_status' VALUE e.to_status,
                        'actor' VALUE e.actor_username,
                        'comments' VALUE e.comments,
                        'timestamp' VALUE TO_CHAR(e.event_timestamp, 'YYYY-MM-DD HH24:MI:SS')
                    )
                    ORDER BY e.event_timestamp ASC
                    RETURNING CLOB
                )
                FROM hr_leave_request_events e
                WHERE e.request_id = r.request_id
            )
            RETURNING CLOB
        )
          INTO l_json
          FROM hr_leave_requests r
          JOIN hr_users u ON u.user_id = r.user_id
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.request_id = p_request_id
           AND (r.user_id = l_user_id OR hr_auth_pkg.is_admin);

        RETURN l_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '{"error": "Leave request #' || p_request_id || ' not found or unauthorized"}';
    END get_leave_request;

    FUNCTION calculate_leave_days(
        p_start_date IN DATE,
        p_end_date   IN DATE
    ) RETURN CLOB IS
        l_days NUMBER;
    BEGIN
        l_days := hr_leave_pkg.calculate_days(p_start_date, p_end_date);
        RETURN TO_CLOB(JSON_OBJECT(
            'start_date'     VALUE TO_CHAR(p_start_date, 'YYYY-MM-DD'),
            'end_date'       VALUE TO_CHAR(p_end_date, 'YYYY-MM-DD'),
            'requested_days' VALUE l_days
        ));
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('{"error": "' || SQLERRM || '"}');
    END calculate_leave_days;

    FUNCTION create_leave_request(
        p_leave_type_code IN VARCHAR2,
        p_start_date      IN DATE,
        p_end_date        IN DATE,
        p_reason          IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB IS
        l_username   VARCHAR2(100);
        l_request_id NUMBER;
        l_wf_id      NUMBER;
        l_days       NUMBER;
    BEGIN
        l_username := hr_user_pkg.current_username;
        IF l_username IS NULL THEN
            RETURN '{"error": "No authenticated session"}';
        END IF;

        hr_leave_pkg.create_request(
            p_username        => l_username,
            p_leave_type_code => p_leave_type_code,
            p_start_date      => p_start_date,
            p_end_date        => p_end_date,
            p_reason          => p_reason,
            p_request_id      => l_request_id
        );

        l_wf_id := hr_workflow_pkg.start_leave_approval(p_request_id => l_request_id);
        l_days  := hr_leave_pkg.calculate_days(p_start_date, p_end_date);

        RETURN TO_CLOB(JSON_OBJECT(
            'status'         VALUE 'SUCCESS',
            'request_id'     VALUE l_request_id,
            'workflow_id'    VALUE l_wf_id,
            'requested_days' VALUE l_days,
            'message'        VALUE 'Leave request #' || l_request_id || ' submitted successfully'
        ));
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('{"status": "ERROR", "message": "' || SQLERRM || '"}');
    END create_leave_request;

    FUNCTION cancel_leave_request(
        p_request_id IN NUMBER,
        p_reason     IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB IS
        l_username VARCHAR2(100);
    BEGIN
        l_username := hr_user_pkg.current_username;
        IF l_username IS NULL THEN
            RETURN '{"error": "No authenticated session"}';
        END IF;

        hr_leave_pkg.cancel_request(
            p_request_id     => p_request_id,
            p_actor_username => l_username,
            p_reason         => p_reason
        );

        RETURN TO_CLOB(JSON_OBJECT(
            'status'     VALUE 'SUCCESS',
            'request_id' VALUE p_request_id,
            'message'    VALUE 'Leave request #' || p_request_id || ' cancelled successfully'
        ));
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('{"status": "ERROR", "message": "' || SQLERRM || '"}');
    END cancel_leave_request;

    FUNCTION generate_request_summary(
        p_request_id IN NUMBER
    ) RETURN CLOB IS
        l_full_name      VARCHAR2(150);
        l_leave_type     VARCHAR2(100);
        l_days           NUMBER;
        l_start_date     DATE;
        l_end_date       DATE;
        l_reason         VARCHAR2(4000);
        l_summary        VARCHAR2(4000);
    BEGIN
        SELECT u.full_name, t.leave_type_name, r.requested_days,
               r.start_date, r.end_date, r.reason
          INTO l_full_name, l_leave_type, l_days,
               l_start_date, l_end_date, l_reason
          FROM hr_leave_requests r
          JOIN hr_users u ON u.user_id = r.user_id
          JOIN hr_leave_types t ON t.leave_type_id = r.leave_type_id
         WHERE r.request_id = p_request_id;

        l_summary := l_full_name || ' requests ' || l_days || ' day(s) of ' ||
                     LOWER(l_leave_type) || ' from ' || TO_CHAR(l_start_date, 'DD-Mon-YYYY') ||
                     ' through ' || TO_CHAR(l_end_date, 'DD-Mon-YYYY') ||
                     CASE WHEN l_reason IS NOT NULL THEN ' for: ' || l_reason ELSE '.' END;

        UPDATE hr_leave_requests
           SET ai_summary = l_summary
         WHERE request_id = p_request_id;

        RETURN TO_CLOB(l_summary);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN TO_CLOB('Request #' || p_request_id || ' not found.');
    END generate_request_summary;

END hr_ai_pkg;
/
