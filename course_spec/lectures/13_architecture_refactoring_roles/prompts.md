# Episode 13: Coding Agent Prompts & Role Refactoring

## 🤖 Coding Agent Prompts (Separating MANAGER Role)

### Prompt 1: Graphify Role Query
```text
Graphify Query:
"Identify all APEX authorization schemes, navigation menus, and PL/SQL functions that check the ADMIN role."
```

### Prompt 2: Execute Role Separation Refactor
```text
Refactor the authorization model to separate MANAGER from ADMIN:
1. Insert MANAGER role into HR_ROLES.
2. Reassign MGR001 from ADMIN to MANAGER.
3. Update HR_AUTH_PKG.CAN_APPROVE_REQUEST to enforce direct team hierarchy checks.
4. Update APEX authorization schemes IS_ADMIN and CAN_APPROVE_LEAVE.
```
