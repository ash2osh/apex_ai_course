# Generation and Validation Handoff

This repository contains specifications, not deployable database or APEX implementation. Perform the following work only after copying it into a fresh, initialized `APEX_PROJECT_TEMPLATE` repository.

## 1. Initialize the target repository

Run the template `/init` workflow with [template-configuration.md](template-configuration.md). Preserve template-owned `AGENTS.md`, `.agents/`, `.github/`, environment loaders, guards, export/backup scripts, and ignore files.

Verify the saved SQLcl connection `demo` read-only. The session user and current schema must both be `DEMO`; stop on any mismatch.

## 2. Generate database implementation

Use [DATABASE_MODEL.md](../../DATABASE_MODEL.md), [AUTHORIZATION_MODEL.md](../../AUTHORIZATION_MODEL.md), [LEAVE_WORKFLOW.md](../../LEAVE_WORKFLOW.md), the app-context files, and the course manifest as the frozen requirements.

Generate Oracle Database 19c RU 19.18-compatible source inside the template's normal guarded source area. The target contains nine tables, five package specifications and bodies, deterministic natural-key seed data, migrations, installation tests, and no transaction control inside reusable package code.

Before executing generated DDL or PL/SQL, obtain the template write guard for the exact `tables` and `code` scopes. Compile, inspect `USER_ERRORS`, and run the generated database tests twice to demonstrate repeatability.

## 3. Generate APEX applications

Use the two direct specification pairs:

- `apps/DEMO/100/application-spec.md` and `app-ux-contract.json`
- `apps/DEMO/200/application-spec.md` and `app-ux-contract.json`

Materialize editable APEXlang/runtime source only inside the initialized template repository. Resolve live component and plug-in metadata through connection `demo`; do not guess unsupported component properties.

Format, compiler-audit, and run live check-only validation for both applications. Validation does not authorize import. Import App 100 or App 200 only after a separate explicit approval.

## 4. Generate workflow, tasks, and AI components

Follow [app-200-workflow-handoff.md](app-200-workflow-handoff.md) for workflow `LEAVE_APPROVAL` and both Human Task definitions. Generate the two AI Agents and seven package-backed tools from the app specifications and [AI_AGENT_TOOLS.md](../../AI_AGENT_TOOLS.md).

The parsing schema `DEMO` requires `CREATE JOB` for Workflow and Human Tasks. A configured APEX AI service is required for the target AI components.

## 5. Refresh template-managed outputs

After approved deployment and import, use the template's export and metadata-backup workflows. Never hand-edit `database/DEMO/`, and never treat generated exports as source owned by this standalone specifications package.
