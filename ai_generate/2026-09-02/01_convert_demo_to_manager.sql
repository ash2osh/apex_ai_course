-- ============================================================================
-- Script: 01_convert_demo_to_manager.sql
-- Description: Assign MANAGER role to user DEMO and configure direct reports
-- Target Schema: DEMO
-- ============================================================================

SET DEFINE OFF;
SET SERVEROUTPUT ON;

DECLARE
    l_demo_id NUMBER;
BEGIN
    -- 1. Locate user DEMO
    SELECT user_id INTO l_demo_id FROM hr_users WHERE username = 'DEMO';

    -- 2. Update DEMO user profile
    UPDATE hr_users
       SET full_name  = 'Demo Manager',
           manager_id = 1, -- Samira Administrator
           updated_at = SYSTIMESTAMP,
           updated_by = 'ADMIN_PROMOTION'
     WHERE user_id = l_demo_id;

    -- 3. Grant MANAGER role (role_id = 2) in HR_USER_ROLES
    MERGE INTO hr_user_roles dest
    USING (
        SELECT l_demo_id AS user_id,
               2         AS role_id
          FROM dual
    ) src
    ON (dest.user_id = src.user_id AND dest.role_id = src.role_id)
    WHEN NOT MATCHED THEN
        INSERT (user_id, role_id) VALUES (src.user_id, src.role_id);

    DBMS_OUTPUT.PUT_LINE('Granted MANAGER role to user DEMO (user_id=' || l_demo_id || ').');

    -- 4. Reassign direct reports (EMP001 and EMP002) to report to DEMO
    UPDATE hr_users
       SET manager_id = l_demo_id,
           updated_at = SYSTIMESTAMP,
           updated_by = 'ADMIN_REASSIGN'
     WHERE username IN ('EMP001', 'EMP002');

    DBMS_OUTPUT.PUT_LINE('Reassigned EMP001 and EMP002 to report to DEMO.');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('User DEMO successfully converted to Manager.');
END;
/
