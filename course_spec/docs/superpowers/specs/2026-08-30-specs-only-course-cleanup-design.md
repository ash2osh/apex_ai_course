# Specs-Only Course Cleanup Design

## Goal

Convert this repository from a partially runnable Oracle APEX course overlay into a specification-only course package for later insertion into `APEX_PROJECT_TEMPLATE`.

## Retained artifacts

- `apps/DEMO/100/application-spec.md`
- `apps/DEMO/100/app-ux-contract.json`
- `apps/DEMO/200/application-spec.md`
- `apps/DEMO/200/app-ux-contract.json`
- `app_context/`
- Root architecture and feature specifications
- `docs/course/`
- Lecture notes, prompts, self-contained teaching examples, and decks
- Portable course generators and specs-only consistency tests

## Removed artifacts

- All generated App 100 and App 200 runtime source: `.apx` files, pages, shared components, deployments, supporting objects, icons, `.apex` runtime configuration, and the now-unneeded `.apexlang` directories after their two specification files are relocated
- The complete `ai_generate/` deployable database implementation
- Lecture wrappers whose only behavior is invoking removed `ai_generate` files
- Tests that require deployable SQL, PL/SQL package bodies, or generated APEX applications
- The obsolete implementation-focused repair design and plan
- Generated cache and inspection sidecar files

Deleted material is moved to an explicitly named temporary recovery directory rather than permanently erased.

## Documentation contract

The repository describes the target system: Oracle APEX 26.1.4, workspace/schema `DEMO`, saved SQLcl connection `demo`, Apps 100 and 200, nine target tables, five target packages, four roles, seven AI tools, workflow `LEAVE_APPROVAL`, and two Human Task definitions.

Documentation must state that the target implementation is not included. Database objects, packages, APEX applications, workflow, tasks, and AI components are generated and validated only after copying the specifications into an initialized `APEX_PROJECT_TEMPLATE` repository. No document may provide an install/import command for absent artifacts or claim that the standalone repository can deploy, compile, export, or back up the target system.

## Lecture contract

Lecture notes and prompts remain instructional. Self-contained SQL examples may remain when they illustrate a design contract and do not depend on removed files. Wrapper scripts that reference `ai_generate` are removed, and episode inventories identify missing executable implementation as intentional in a specs-only package.

The deck-generation source and affected decks are updated so they describe specifications and later template-driven generation instead of included canonical SQL or editable generated applications.

## Test contract

The revised suite must verify:

1. Exactly the four retained app specification artifacts exist below `apps/DEMO/`.
2. No generated `.apx`, deployment, supporting-object, icon, or `.apex` configuration file remains.
3. `ai_generate/` is absent.
4. No public documentation, generator, test, or lecture wrapper references removed implementation paths.
5. The target design identity and counts remain consistent.
6. Every lecture retains notes, prompts, and one valid deck.
7. Generators remain portable and side-effect-free.
8. No template-owned protected file is introduced.

## Deferred implementation

After these specifications are copied into the template repository, a future guarded phase will generate database source and APEXlang runtime components, perform database compilation and tests, validate both applications, request explicit import approval, and refresh template-managed exports/backups.
