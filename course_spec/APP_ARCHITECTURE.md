# Application Architecture

> This document specifies the target architecture. Generated applications and database implementation are not included in this repository.

## Overview

The system contains two Oracle APEX applications that share the same Oracle schema.

```text
                ORACLE DATABASE
                      |
              Shared Application Schema
                      |
          +-----------+-----------+
          |                       |
          v                       v
 Employee Self Service       HR Administration
      APEX App                    APEX App
```

## Employee Self Service Application

### Purpose

Provide employees with self-service HR functionality.

### Main Pages

1. Dashboard
2. My Profile
3. My Leave Balance
4. Submit Leave Request
5. My Leave Requests
6. Leave Request Details
7. Workflow Timeline
8. HR AI Assistant
9. HR AI Agent

### Main Capabilities

- Employees can see only their own information.
- Employees can submit leave requests.
- Employees can view request status.
- Employees can cancel eligible requests.
- Managers may also use this application as employees.

## HR Administration Application

### Purpose

Provide administrative and approval functionality.

### Main Pages

1. Dashboard
2. My Tasks
3. Pending Leave Requests
4. Leave Request Details
5. Employees
6. Employee Leave History
7. Leave Types
8. Leave Balances
9. Workflow Monitor
10. Users
11. Roles
12. System Settings

## Shared Components

Recommended reusable database packages:

```text
HR_USER_PKG
HR_AUTH_PKG
HR_LEAVE_PKG
HR_WORKFLOW_PKG
HR_AI_PKG
HR_UTIL_PKG
```

## Shared Security Principle

The database layer must enforce important business rules.

Do not rely only on hidden APEX pages, buttons, or navigation items for security.

## Data Ownership

```text
EMPLOYEE
   |
   +-- LEAVE BALANCES
   |
   +-- LEAVE REQUESTS
   |
   +-- USER ROLES
```

## High-Level Request Flow

```text
Employee
   |
   v
Submit Leave
   |
   v
HR_LEAVE_PKG
   |
   v
LEAVE_REQUESTS
   |
   v
APEX WORKFLOW
   |
   v
APPROVAL TASK
   |
   v
Manager/Admin
```
