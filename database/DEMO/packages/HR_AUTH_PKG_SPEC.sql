
  CREATE OR REPLACE EDITIONABLE PACKAGE "DEMO"."HR_AUTH_PKG" AS
    FUNCTION hash_password(p_username IN VARCHAR2, p_password IN VARCHAR2, p_salt IN VARCHAR2) RETURN VARCHAR2;
    PROCEDURE set_password(p_username IN VARCHAR2, p_password IN VARCHAR2);
    FUNCTION authenticate(p_username IN VARCHAR2, p_password IN VARCHAR2) RETURN BOOLEAN;

    FUNCTION has_role(p_username IN VARCHAR2, p_role_code IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION is_employee(p_username IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN;
    FUNCTION is_manager(p_username IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN;
    FUNCTION is_admin(p_username IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN;
    FUNCTION is_super_admin(p_username IN VARCHAR2 DEFAULT NULL) RETURN BOOLEAN;
    FUNCTION can_approve_request(p_actor_username IN VARCHAR2, p_request_id IN NUMBER) RETURN BOOLEAN;
    FUNCTION can_cancel_request(p_actor_username IN VARCHAR2, p_request_id IN NUMBER) RETURN BOOLEAN;

    PROCEDURE assert_role(p_username IN VARCHAR2, p_role_code IN VARCHAR2);
    PROCEDURE assert_admin(p_username IN VARCHAR2);
    PROCEDURE assert_super_admin(p_username IN VARCHAR2);
END hr_auth_pkg;
/
