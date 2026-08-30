# App 100 AI Agent

`EMPLOYEE_HR_AGENT` exposes seven AI tools returning `CLOB` JSON: `GET_MY_PROFILE`, `GET_LEAVE_BALANCE`, `GET_MY_LEAVE_REQUESTS`, `GET_LEAVE_REQUEST`, `CALCULATE_LEAVE_DAYS`, `CREATE_LEAVE_REQUEST`, and `CANCEL_LEAVE_REQUEST`.

Tools derive identity from the APEX session. The create and cancel tools require APEX 26.1 on-demand user approval. `LEAVE_SUMMARY_AGENT` is separate and is called by `HR_AI_PKG.GENERATE_REQUEST_SUMMARY` through `APEX_AI.GENERATE(p_agent_static_id => ...)`.
