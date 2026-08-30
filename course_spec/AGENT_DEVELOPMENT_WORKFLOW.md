# AI-Assisted Development Workflow

> **Delivery mode:** This repository contains specifications and teaching examples only. It must not be treated as an installable database or an importable APEX application export.

## Goal

Use these specifications inside `APEX_PROJECT_TEMPLATE` as the development foundation for AI-assisted Oracle APEX work.

## Repository Areas

```text
apps/DEMO/100/application-spec.md
apps/DEMO/100/app-ux-contract.json
apps/DEMO/200/application-spec.md
apps/DEMO/200/app-ux-contract.json
app_context/
```

## app_context

Recommended project files:

```text
app_context/
  architecture.md
  authorization.md
  database-model.md
  leave-workflow.md
  ai-agent.md
  demo-scenarios.md
```

The purpose is to provide durable project knowledge to the coding agent.

## Development Loop

```text
Requirement
   |
   v
Read app_context
   |
   v
Inspect dependency graph
   |
   v
Plan change
   |
   v
Modify Database / APEX
   |
   v
Validate
   |
   v
Export
   |
   v
Graphify Update
   |
   v
Git Diff
   |
   v
Commit
```

## Initial Setup

Typical flow:

```text
git clone <repository>
cd <repository>
/init
```

Then configure project environment and SQLcl saved connections.

## Before Development

Create architecture context.

Example requirement:

```text
Build two APEX applications.

App 100:
Employee Self Service

App 200:
HR Administration

Roles:
EMPLOYEE
ADMIN
SUPER_ADMIN
```

## Agent Prompt Example — Database

```text
Read the project context.

Design and implement the database objects required for leave management.

Use the project naming conventions.

Business logic must be placed in reusable PL/SQL packages instead of duplicated in APEX page processes.
```

## Agent Prompt Example — Employee App

```text
Read the project context and current database implementation.

Implement the Employee Self Service leave request pages.

Employees must only access their own leave data.

Reuse existing PL/SQL business logic.
```

## Agent Prompt Example — Workflow

```text
Analyze the current leave request implementation.

Add an APEX Workflow for leave approval.

The workflow must validate the request, create a manager approval task, process approval or rejection, update request status, and update leave balance after approval.
```

## Agent Prompt Example — AI Tools

```text
Implement employee HR AI Tools according to app_context/ai-agent.md.

All employee-scoped tools must derive the employee identity from the authenticated session.

Do not accept arbitrary employee IDs for self-service actions.
```

## Graphify Workflow

After domain changes:

```text
graphify update .
```

After changes to `app_context`:

```text
graphify extract .
```

Use graph queries for impact analysis.

Example questions:

```text
What reads HR_LEAVE_REQUESTS?

What writes HR_LEAVE_REQUESTS?

What APEX pages call HR_LEAVE_PKG?

Trace the path from the leave request page to the approval workflow.
```

## Requirement Change Example

Requirement:

```text
Requests longer than five days require a second HR approval.
```

Recommended agent instruction:

```text
Analyze the existing leave workflow and all affected components.

Identify the minimum safe changes required.

Update workflow logic, database code, documentation, and tests.

Do not duplicate approval logic.

Validate the resulting project and show the affected files.
```

## Export and Review

After changes:

```text
Export APEX applications.
Backup supported database metadata.
Update Graphify.
Review Git diff.
Run project tests.
```

## Tutorial Message

The purpose of the coding agent is not only to generate code.

It should be able to:

- Understand architecture
- Trace dependencies
- Modify existing functionality
- Respect authorization
- Reuse business logic
- Validate changes
- Maintain project consistency
