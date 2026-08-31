
  CREATE OR REPLACE EDITIONABLE PACKAGE "DEMO"."HR_AI_PKG" AS
    FUNCTION get_my_profile RETURN CLOB;

    FUNCTION get_leave_balance(
        p_leave_type_code IN VARCHAR2 DEFAULT 'ANNUAL'
    ) RETURN CLOB;

    FUNCTION get_my_leave_requests(
        p_status    IN VARCHAR2 DEFAULT NULL,
        p_date_from IN DATE DEFAULT NULL,
        p_date_to   IN DATE DEFAULT NULL
    ) RETURN CLOB;

    FUNCTION get_leave_request(
        p_request_id IN NUMBER
    ) RETURN CLOB;

    FUNCTION calculate_leave_days(
        p_start_date IN DATE,
        p_end_date   IN DATE
    ) RETURN CLOB;

    FUNCTION create_leave_request(
        p_leave_type_code IN VARCHAR2,
        p_start_date      IN DATE,
        p_end_date        IN DATE,
        p_reason          IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    FUNCTION cancel_leave_request(
        p_request_id IN NUMBER,
        p_reason     IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    FUNCTION generate_request_summary(
        p_request_id IN NUMBER
    ) RETURN CLOB;
END hr_ai_pkg;
/
