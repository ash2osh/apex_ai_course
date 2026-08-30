# Episode 4: Coding Agent Prompts & UI Queries

## 🤖 Coding Agent Prompts (App 100 Development)

### Prompt 1: Dashboard Balance Cards SQL
```text
Generate the SQL query for the APEX Cards region on Page 1 (Dashboard) of App 100.
The query must return leave type name, entitlement, used, pending, and calculated available days
for the current authenticated user (:APP_USER) in the current calendar year.
```

### Prompt 2: Page 4 Form Submission & Days Calculation
```text
Write the Dynamic Action JavaScript / PL/SQL expression for Page 4 (Submit Leave Request)
to calculate requested days whenever P4_START_DATE or P4_END_DATE changes.
Write the Page Processing PL/SQL block that calls HR_LEAVE_PKG.CREATE_REQUEST.
```
