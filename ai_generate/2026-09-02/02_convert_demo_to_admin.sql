-- ============================================================================
-- Script: 02_convert_demo_to_admin.sql
-- Description: Assign ADMIN and SUPER_ADMIN roles to user DEMO
-- Target Schema: DEMO
-- ============================================================================

SET DEFINE OFF;
SET SERVEROUTPUT ON;

DECLARE
    l_demo_id NUMBER;
BEGIN
    -- 1. Locate user DEMO
    SELECT user_id INTO l_demo_id FROM hr_users WHERE username = 'DEMO';

    -- 2. Update user DEMO profile
    UPDATE hr_users
       SET full_name     = 'Demo Administrator',
           department_id = 20, -- HR department
           updated_at    = SYSTIMESTAMP,
           updated_by    = 'ADMIN_PROMOTION'
     WHERE user_id = l_demo_id;

    -- 3. Grant ADMIN (role_id = 3) and SUPER_ADMIN (role_id = 4) roles
    MERGE INTO hr_user_roles dest
    USING (
        SELECT l_demo_id AS user_id, 3 AS role_id FROM dual
        UNION ALL
        SELECT l_demo_id AS user_id, 4 AS role_id FROM dual
    ) src
    ON (dest.user_id = src.user_id AND dest.role_id = src.role_id)
    WHEN NOT MATCHED THEN
        INSERT (user_id, role_id) VALUES (src.user_id, src.role_id);

    DBMS_OUTPUT.PUT_LINE('Granted ADMIN and SUPER_ADMIN roles to user DEMO (user_id=' || l_demo_id || ').');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('User DEMO successfully converted to Administrator.');
END;
/
