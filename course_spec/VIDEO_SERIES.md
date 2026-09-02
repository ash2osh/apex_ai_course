# Video Series Plan

> The series uses this specification-only package to guide implementation inside an initialized `APEX_PROJECT_TEMPLATE` repository.

## Episode 1 — Project Introduction

Cover:

- Final application preview
- Two-application architecture
- Why Employee Self Service and HR Admin are separated
- Roles
- AI strategy
- Workflow strategy

## Episode 2 — APEX Project Template

Cover:

- Repository structure
- `/init`
- `.env`
- SQLcl saved connections
- `apps`
- `database`
- `app_context`
- Graphify
- Git workflow

## Episode 3 — Database Design

Build:

- Users
- Roles
- User roles
- Departments
- Leave types
- Leave balances
- Leave requests

Create:

- Constraints
- Indexes
- Seed data
- Core PL/SQL packages

## Episode 4 — Employee Self Service

Build:

- Dashboard
- Profile
- Leave balance
- Request form
- My requests
- Request details

## Episode 5 — HR Admin Application

Build:

- Dashboard
- Leave request reports
- Employees
- Leave balances
- Leave types

## Episode 6 — Authorization

Build:

- EMPLOYEE
- MANAGER
- ADMIN
- SUPER_ADMIN

Demonstrate:

- Application protection (App 100 & App 200)
- Navigation protection
- Page protection
- Region & button protection
- Process protection
- Database package authorization

## Episode 7 — APEX Workflow

Build:

- Leave approval workflow
- Validation
- Manager approval
- Approval/rejection paths
- Status updates

## Episode 8 — Human Tasks

Build:

- Approval task
- Potential owner logic
- My Tasks page
- Task details
- Approve
- Reject

## Episode 9 — AI Assistant

Build:

- Generative AI configuration
- HR Assistant
- System prompt
- Quick actions
- Employee-facing AI UX

## Episode 10 — AI Agent and AI Tools

Build:

- Employee HR Agent
- GET_MY_PROFILE
- GET_LEAVE_BALANCE
- GET_MY_LEAVE_REQUESTS
- CALCULATE_LEAVE_DAYS
- CREATE_LEAVE_REQUEST
- CANCEL_LEAVE_REQUEST

## Episode 11 — AI inside Workflow

Build:

- AI summary workflow step
- Workflow state storage
- Approval page integration

## Episode 12 — AI-Assisted Maintenance

Demonstrate a new requirement:

```text
Requests longer than five days require HR approval.
```

Show:

- Graphify impact analysis
- Coding agent plan
- Database changes
- APEX changes
- Tests
- Export
- Git diff

## Episode 13 — Architecture Refactor

New requirement:

```text
MANAGER must become a separate role from ADMIN.
```

Show dependency discovery and safe refactoring.

## Episode 14 — Final End-to-End Demo

Run:

```text
Employee
 -> AI Agent
 -> Leave Request
 -> Workflow
 -> AI Summary
 -> Human Task
 -> Manager
 -> Approval
 -> Balance Update
 -> Employee Status
```
