set pagesize 100
set linesize 200

prompt === Episode 1: target identity ===
select sys_context('USERENV', 'CURRENT_SCHEMA') as current_schema,
       sys_context('USERENV', 'SESSION_USER') as session_user
  from dual;

prompt === Canonical HR objects ===
select object_type, object_name, status
  from user_objects
 where object_name like 'HR\_%' escape '\'
 order by object_type, object_name;

prompt Expected after installation: nine HR_ tables and five valid package specs/bodies.
