# Episode 5: Coding Agent Prompts & Security Setup

## 🤖 Coding Agent Prompts (Authorization Schemes)

### Prompt 1: APEX Authorization Schemes PL/SQL
```text
Read ../../AUTHORIZATION_MODEL.md.
Write the PL/SQL boolean functions for the following APEX Authorization Schemes:
1. IS_EMPLOYEE
2. IS_ADMIN
3. IS_SUPER_ADMIN
4. CAN_APPROVE_LEAVE
Implement these functions inside HR_AUTH_PKG with robust error handling.
```

### Prompt 2: Security Validation Tests
```text
Generate a PL/SQL test script to verify that:
1. EMP001 cannot access admin functions or approve leave.
2. HR001 can access company-wide HR functions but cannot manage protected roles or settings.
3. ADMIN001 has SUPER_ADMIN access to protected administration pages.
```
