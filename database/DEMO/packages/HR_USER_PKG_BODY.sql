
  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "DEMO"."HR_USER_PKG" AS

    FUNCTION current_username RETURN VARCHAR2 IS
        l_user VARCHAR2(100);
    BEGIN
        l_user := COALESCE(
            SYS_CONTEXT('APEX$SESSION', 'APP_USER'),
            SYS_CONTEXT('USERENV', 'SESSION_USER'),
            USER
        );
        RETURN UPPER(TRIM(l_user));
    END current_username;

    FUNCTION current_user_id RETURN NUMBER IS
        l_user_id NUMBER;
        l_uname   VARCHAR2(100);
    BEGIN
        l_uname := current_username;
        SELECT user_id
          INTO l_user_id
          FROM hr_users
         WHERE UPPER(username) = l_uname
           AND active_yn = 'Y';
        RETURN l_user_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END current_user_id;

    FUNCTION get_user_id(p_username IN VARCHAR2) RETURN NUMBER IS
        l_user_id NUMBER;
    BEGIN
        IF p_username IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT user_id
          INTO l_user_id
          FROM hr_users
         WHERE UPPER(username) = UPPER(TRIM(p_username));
        RETURN l_user_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_user_id;

    FUNCTION get_username(p_user_id IN NUMBER) RETURN VARCHAR2 IS
        l_username VARCHAR2(100);
    BEGIN
        IF p_user_id IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT username
          INTO l_username
          FROM hr_users
         WHERE user_id = p_user_id;
        RETURN l_username;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_username;

    FUNCTION get_manager_id(p_user_id IN NUMBER) RETURN NUMBER IS
        l_manager_id NUMBER;
    BEGIN
        IF p_user_id IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT manager_id
          INTO l_manager_id
          FROM hr_users
         WHERE user_id = p_user_id;
        RETURN l_manager_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_manager_id;

    FUNCTION get_manager_username(p_user_id IN NUMBER) RETURN VARCHAR2 IS
        l_mgr_username VARCHAR2(100);
    BEGIN
        IF p_user_id IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT m.username
          INTO l_mgr_username
          FROM hr_users u
          JOIN hr_users m ON m.user_id = u.manager_id
         WHERE u.user_id = p_user_id;
        RETURN l_mgr_username;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_manager_username;

    FUNCTION is_active_user(p_username IN VARCHAR2) RETURN BOOLEAN IS
        l_cnt PLS_INTEGER;
    BEGIN
        IF p_username IS NULL THEN
            RETURN FALSE;
        END IF;

        SELECT COUNT(*)
          INTO l_cnt
          FROM hr_users
         WHERE UPPER(username) = UPPER(TRIM(p_username))
           AND active_yn = 'Y';
        RETURN (l_cnt > 0);
    END is_active_user;

    FUNCTION is_active_user(p_user_id IN NUMBER) RETURN BOOLEAN IS
        l_cnt PLS_INTEGER;
    BEGIN
        IF p_user_id IS NULL THEN
            RETURN FALSE;
        END IF;

        SELECT COUNT(*)
          INTO l_cnt
          FROM hr_users
         WHERE user_id = p_user_id
           AND active_yn = 'Y';
        RETURN (l_cnt > 0);
    END is_active_user;

END hr_user_pkg;
/
