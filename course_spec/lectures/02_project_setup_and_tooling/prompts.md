# Episode 2: Coding-Agent Prompts and Tooling Guide

## Prompt 1: audit the overlay

```text
Review this course as an additive overlay for APEX_PROJECT_TEMPLATE.
Confirm that course-owned files are limited to the two direct app specification pairs,
app_context, docs/course, lectures, and course-specific tests/scripts.
Report any file that would overwrite a template-owned guard, environment file,
automation script, AGENTS.md, .agents, .github, or ignore file. Do not modify files.
```

## Prompt 2: validate course identity

```text
Read docs/course/course-manifest.json and template-configuration.md.
Verify APEX 26.1.4, ORDS 26.1.1+, Database 19c RU 19.18+, workspace/schema DEMO,
SQLcl connection demo, App IDs 100 and 200, 9 tables, 5 packages, 4 roles,
and 7 AI tools. Report every mismatch. Do not connect or deploy.
```

## Read-only commands for the initialized template repository

```bash
sql -name demo
bash tests/run_static_tests.sh
python3 scripts/sync_course_assets.py --check
python3 generate_pptx_slides.py --check
```

Inside SQLcl, verify identity before requesting any guarded write:

```sql
select user, sys_context('USERENV', 'CURRENT_SCHEMA') from dual;
```

Expected values: `DEMO`, `DEMO`.
