# Oracle APEX AI + Workflow Masterclass

This is a specification-only course package for a target system built with Oracle APEX 26.1.4 (ORDS 26.1.1 minimum) in workspace/schema `DEMO`, using SQLcl saved connection `demo`:

- App 100 — Employee Self Service, nine specified pages.
- App 200 — HR Administration, twelve specified pages.
- Target database design — nine tables and five packages.
- Target security and AI design — four roles and seven AI tools.
- Target orchestration — workflow `LEAVE_APPROVAL`, Human Tasks `LEAVE_MANAGER_APPROVAL` and `LEAVE_HR_APPROVAL`, and AI Agents `EMPLOYEE_HR_AGENT` and `LEAVE_SUMMARY_AGENT`.

Generated APEX applications, database DDL, package bodies, seed data, migrations, and installers are intentionally not included.

## Included design artifacts

- [App 100 application specification](../../apps/DEMO/100/application-spec.md)
- [App 100 UX contract](../../apps/DEMO/100/app-ux-contract.json)
- [App 200 application specification](../../apps/DEMO/200/application-spec.md)
- [App 200 UX contract](../../apps/DEMO/200/app-ux-contract.json)
- Durable app knowledge under `app_context/100/` and `app_context/200/`
- Fourteen lecture packages indexed in [lectures/README.md](../../lectures/README.md)
- Target identity in [course-manifest.json](course-manifest.json)

## Use with APEX_PROJECT_TEMPLATE

1. Create a new public repository from `ash2osh/APEX_PROJECT_TEMPLATE`.
2. Copy this specification package over the fresh checkout without replacing template-owned files.
3. Run the template `/init` workflow with [template-configuration.md](template-configuration.md).
4. Follow [generation-and-validation.md](deployment.md) to generate implementation inside the initialized repository.

The App 200 workflow contract is detailed in [app-200-workflow-handoff.md](app-200-workflow-handoff.md). The template-managed `database/DEMO/` mirror remains generated output and must not be authored by this specifications repository.
