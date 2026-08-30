prompt === Verify APEX AI Agents in App 100 ===
select application_id, static_id, name
  from apex_appl_ai_agents
 where application_id = 100
   and static_id in ('EMPLOYEE_HR_AGENT', 'LEAVE_SUMMARY_AGENT')
 order by static_id;

prompt Employee assistant identity comes from APP_USER through HR_AI_PKG; prompts never accept another username.
