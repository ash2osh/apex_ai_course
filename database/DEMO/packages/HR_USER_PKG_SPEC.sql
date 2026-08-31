
  CREATE OR REPLACE EDITIONABLE PACKAGE "DEMO"."HR_USER_PKG" AS
    FUNCTION current_username RETURN VARCHAR2;
    FUNCTION current_user_id RETURN NUMBER;
    FUNCTION get_user_id(p_username IN VARCHAR2) RETURN NUMBER;
    FUNCTION get_username(p_user_id IN NUMBER) RETURN VARCHAR2;
    FUNCTION get_manager_id(p_user_id IN NUMBER) RETURN NUMBER;
    FUNCTION get_manager_username(p_user_id IN NUMBER) RETURN VARCHAR2;
    FUNCTION is_active_user(p_username IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION is_active_user(p_user_id IN NUMBER) RETURN BOOLEAN;
END hr_user_pkg;
/
