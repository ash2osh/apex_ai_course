
  CREATE OR REPLACE EDITIONABLE PACKAGE "DEMO"."HR_WORKFLOW_PKG" AS
    FUNCTION get_system_setting(
        p_setting_code   IN VARCHAR2,
        p_default_value  IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION start_leave_approval(
        p_request_id IN NUMBER
    ) RETURN NUMBER;

    PROCEDURE manager_outcome(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_outcome        IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE hr_outcome(
        p_request_id     IN NUMBER,
        p_actor_username IN VARCHAR2,
        p_outcome        IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE workflow_fault(
        p_request_id    IN NUMBER,
        p_error_message IN VARCHAR2
    );
END hr_workflow_pkg;
/
