# Oracle APEX AI + Workflow Tutorial Plan

> **Delivery mode:** This repository is a specification-only curriculum. It defines the target system but intentionally excludes generated APEX applications and deployable database implementation. Generate and validate those artifacts after copying the package into an initialized `APEX_PROJECT_TEMPLATE` repository.

## Project Goal

Specify and teach a production-style Oracle APEX leave management system that demonstrates:

- Two APEX applications sharing one Oracle schema
- Authentication and authorization
- Employee, Admin, and Super Admin roles
- Leave requests and balances
- APEX Workflow
- APEX Human Tasks
- AI Assistant
- AI Agent and AI Tools
- AI inside workflow
- AI-assisted APEX development using `APEX_PROJECT_TEMPLATE`
- Template-guarded SQLcl generation, validation, export, and deployment workflow
- Graphify-assisted project understanding and impact analysis

## Applications

### Application 1 — Employee Self Service

Primary users:

- Employees
- Managers

Responsibilities:

- View employee profile
- View leave balances
- Submit leave requests
- View submitted requests
- View workflow status
- Cancel eligible requests
- Use HR AI Assistant
- Use HR AI Agent

### Application 2 — HR Administration

Primary users:

- Admin
- Super Admin

Responsibilities:

- Approve or reject leave requests
- View assigned approval tasks
- Manage employees
- Manage leave balances
- Manage leave types
- Monitor workflows
- Manage users and roles
- View HR dashboards and reports

## Main Tutorial Story

A user logs into Employee Self Service and:

1. Reviews their profile.
2. Checks their annual leave balance.
3. Asks the AI Assistant about available leave.
4. Submits a leave request.
5. Starts an APEX Workflow.
6. AI generates a summary for the approver.
7. A manager receives a Human Task.
8. The manager approves or rejects the request.
9. The employee sees the updated workflow status.
10. Approved leave updates the employee balance.

## Tutorial Themes

### AI for the Developer

- Coding agent
- `APEX_PROJECT_TEMPLATE`
- `app_context`
- Graphify
- SQLcl
- Git
- Impact analysis

### AI for the Application User

- HR AI Assistant
- HR AI Agent
- AI Tools

### AI inside the Business Process

- Workflow AI activity
- Approval summaries
- Decision support

## Suggested Series

1. Project setup and architecture
2. Database model
3. Employee Self Service application
4. Authorization and Admin application
5. APEX Workflow and Human Tasks
6. AI Assistant
7. AI Agent and AI Tools
8. AI inside workflow
9. Graphify impact analysis
10. Requirement-change demonstration
