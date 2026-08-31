
  CREATE OR REPLACE EDITIONABLE PACKAGE "DEMO"."HR_LEAVE_PKG" AS
    FUNCTION calculate_days(
        p_start_date IN DATE,
        p_end_date   IN DATE
    ) RETURN NUMBER;

    FUNCTION get_available_days(
        p_user_id       IN NUMBER,
        p_leave_type_id IN NUMBER,
        p_year          IN NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE)
    ) RETURN NUMBER;

    FUNCTION get_available_days(
        p_username        IN VARCHAR2,
        p_leave_type_code IN VARCHAR2,
        p_year            IN NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE)
    ) RETURN NUMBER;

    FUNCTION validate_overlap(
        p_user_id            IN NUMBER,
        p_start_date         IN DATE,
        p_end_date           IN DATE,
        p_exclude_request_id IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN;

    PROCEDURE record_event(
        p_request_id     IN NUMBER,
        p_event_type     IN VARCHAR2,
        p_from_status    IN VARCHAR2,
        p_to_status      IN VARCHAR2,
        p_actor_username IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE create_request(
        p_username        IN VARCHAR2,
        p_leave_type_code IN VARCHAR2,
        p_start_date      IN DATE,
        p_end_date        IN DATE,
        p_reason          IN VARCHAR2 DEFAULT NULL,
        p_request_id      OUT NUMBER
    );

    PROCEDURE approve_request(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE reject_request(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE cancel_request(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_reason         IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE adjust_balance(
        p_user_id          IN NUMBER,
        p_leave_type_code  IN VARCHAR2,
        p_year             IN NUMBER,
        p_adjustment_delta IN NUMBER,
        p_actor_username   IN VARCHAR2,
        p_reason           IN VARCHAR2
    );
END hr_leave_pkg;
/
