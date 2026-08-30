# Lecture 02: APEX Project Template & Developer Tooling

## Lecture metadata

- Episode: 2 of 14
- Target duration: 15–20 minutes
- Baseline: Oracle APEX 26.1.4, ORDS 26.1.1+, Oracle Database 19c RU 19.18+
- Course identity: workspace/schema `DEMO`, saved SQLcl connection `demo`, Apps 100 and 200
- Related: [`docs/course/README.md`](../../docs/course/README.md), [`template-configuration.md`](../../docs/course/template-configuration.md)

## Learning objectives

By the end of this lecture, viewers can:

1. Explain why this folder is an additive overlay for `APEX_PROJECT_TEMPLATE`.
2. Separate course-owned source from template-owned automation and generated metadata.
3. Configure the new repository through its `/init` workflow without publishing `.env`.
4. Validate database identity through the saved connection `demo` before any write.
5. Follow the guarded edit, validate, deploy, test, and backup cycle.

## Repository layout

```text
new-template-repository/
├── apps/DEMO/100/          # App 100 specification and UX contract only
├── apps/DEMO/200/          # App 200 specification and UX contract only
├── app_context/100/        # Durable App 100 context
├── app_context/200/        # Durable App 200 context
├── database/DEMO/          # Template-managed metadata backup; never hand-edited
├── docs/course/            # Course entry point and configuration
└── lectures/               # Notes, prompts, demos, and decks
```

The package must preserve the template's `AGENTS.md`, `.agents/`, `.github/`, environment loaders, guards, export/backup scripts, and ignore files. It supplies requirements and teaching examples only. Database implementation, APEX runtime source, and `database/DEMO/` are generated later through the initialized template's guarded workflows.

## Configuration demo

After copying this folder into a fresh repository created from `APEX_PROJECT_TEMPLATE`:

1. Run the template `/init` workflow.
2. Enter the values documented in `docs/course/template-configuration.md`.
3. Keep credentials in the template's local environment mechanism; never commit `.env`.
4. Confirm that SQLcl has a saved connection named `demo`.

Read-only identity check:

```bash
sql -name demo
```

```sql
select user as session_user,
       sys_context('USERENV', 'CURRENT_SCHEMA') as current_schema
  from dual;
```

Both values must be `DEMO`. Stop if the connection, service, session user, or current schema differs from the initialized template configuration.

## Guarded development loop

```text
Read specs and app context
          ↓
Generate SQL or APEX source from the frozen specifications
          ↓
Run static and check-only validation
          ↓
Obtain template write-guard approval
          ↓
Deploy and run database tests
          ↓
Export APEX / refresh database metadata
          ↓
Review the Git diff
```

This standalone course folder intentionally does not deploy, import, export, or back up anything. Those actions happen only after it is inside the initialized template repository and its guards approve the exact target.

## Live demo checklist

1. Open `docs/course/README.md` and the course manifest.
2. Show the two APEXlang roots and two app-context folders.
3. Show the canonical dated SQL unit.
4. Show that no `.env` or hand-authored `database/DEMO/` content is shipped.
5. Run the read-only SQLcl identity check in the initialized template repository.
6. Run `bash tests/run_static_tests.sh`.

## Common pitfalls

- Do not copy course files over template-owned controls.
- Do not invent credentials or rename the saved connection.
- Do not edit `database/DEMO/` by hand.
- Do not import either APEX app merely because local source validation passes.
- Do not run database writes from the standalone overlay.

## Next episode

[Lecture 03: Database Model & Core PL/SQL Packages](../03_database_design_and_packages/lecture_notes.md)
