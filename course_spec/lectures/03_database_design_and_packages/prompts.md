# Episode 3: Coding Agent Prompts & Database Design

## 🤖 Coding Agent Prompts (Database & PL/SQL Generation)

### Prompt 1: Generate Relational Tables & Constraints
```text
Read ../../DATABASE_MODEL.md and ../../APP_ARCHITECTURE.md.
Generate Oracle Database 19c-compatible DDL for all nine canonical `HR_` tables:
HR_USERS, HR_ROLES, HR_USER_ROLES, HR_DEPARTMENTS, HR_LEAVE_TYPES,
HR_LEAVE_BALANCES, HR_LEAVE_REQUESTS, HR_LEAVE_REQUEST_EVENTS, HR_SYSTEM_SETTINGS.
Include foreign keys, primary keys, and audit columns (CREATED_AT, CREATED_BY, UPDATED_AT, UPDATED_BY).
```

### Prompt 2: Generate Core PL/SQL Packages
```text
Implement specifications and package bodies for:
1. HR_USER_PKG (User resolution & profile helpers)
2. HR_AUTH_PKG (Role evaluation & security checks)
3. HR_LEAVE_PKG (Calculations, overlap check, create/approve/cancel transactions)
4. HR_WORKFLOW_PKG (APEX Workflow start, outcome, and fault callbacks)
5. HR_AI_PKG (Session-bounded AI tool wrappers)
Enforce atomic balance reservations and row-level locking.
```
