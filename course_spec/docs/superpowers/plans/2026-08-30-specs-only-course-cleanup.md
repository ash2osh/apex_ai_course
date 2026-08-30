# Specs-Only Course Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the current course overlay into an internally consistent specification-only package.

**Architecture:** Retain two design files directly under each App ID, durable context, course documentation, lectures, and decks. Recoverably remove generated APEX runtime source and deployable database implementation, then make documentation, generators, decks, and tests describe later template-driven generation.

**Tech Stack:** Markdown, JSON, Python 3 standard library tests, Bash, Node.js ES modules, OOXML PowerPoint.

**Spec:** `docs/superpowers/specs/2026-08-30-specs-only-course-cleanup-design.md`

## Global Constraints

- Work inline in `/home/ash/projects/wf_tut_specs`; do not create a Git worktree.
- This directory is not a Git repository, so commit steps are recorded as skipped.
- Retain `application-spec.md` and `app-ux-contract.json` directly under each App ID.
- Remove `ai_generate/` and all generated APEX runtime/configuration artifacts recoverably.
- Keep self-contained teaching examples; remove wrappers that depend only on removed implementation.
- Preserve template-owned paths and do not create `.env` or `database/DEMO/`.

---

### Task 1: Freeze the specs-only repository contract

**Files:**
- Modify: `tests/test_course_structure.py`
- Replace: `tests/test_sql_contracts.py` with `tests/test_specs_only_contracts.py`
- Modify: `tests/test_content_consistency.py`

**Interfaces:**
- Consumes: repository paths and `docs/course/course-manifest.json`
- Produces: executable assertions for retained specifications and forbidden implementation artifacts

- [x] Add tests requiring exactly `application-spec.md` and `app-ux-contract.json` beneath each App ID, absence of `ai_generate`, absence of generated `.apx`/`.apex` content, and absence of public references to removed implementation paths.
- [x] Run the focused tests and verify they fail because implementation artifacts and references still exist.

### Task 2: Relocate specifications and recoverably remove implementation

**Files:**
- Move: `apps/DEMO/100/.apexlang/application-spec.md` to `apps/DEMO/100/application-spec.md`
- Move: `apps/DEMO/100/.apexlang/app-ux-contract.json` to `apps/DEMO/100/app-ux-contract.json`
- Move: App 200 equivalents
- Recoverably remove: `ai_generate/`
- Recoverably remove: every other file/directory below `apps/DEMO/100/` and `apps/DEMO/200/`
- Recoverably remove: four lecture wrappers that only invoke `ai_generate`

**Interfaces:**
- Consumes: the four approved specification artifacts
- Produces: specs-only App 100/App 200 directories and a temporary recovery archive path

- [x] Validate the exact source paths and destination roots.
- [x] Create a uniquely named `/tmp/wf-tut-specs-recovery.*` directory.
- [x] Relocate the four retained files, then move implementation-only targets into the recovery directory.
- [x] Run focused structure tests; expected remaining failures are documentation/reference failures only.

### Task 3: Rewrite public course positioning and handoffs

**Files:**
- Modify: `docs/course/README.md`
- Modify: `docs/course/deployment.md`
- Modify: `docs/course/app-200-workflow-handoff.md`
- Modify: `docs/course/course-manifest.json`
- Modify: `docs/course/template-configuration.md`
- Modify: `app_context/**/*.md`
- Modify: affected root and lecture Markdown files

**Interfaces:**
- Consumes: target design identity and app specification paths
- Produces: documentation that clearly distinguishes target design from included artifacts

- [x] Replace install/import/export instructions for included artifacts with post-copy generation and guarded validation instructions.
- [x] Remove all public references to `ai_generate`, `.apexlang` spec locations, existing task-definition source, and included generated apps.
- [x] Preserve target counts and identifiers as design requirements.
- [x] Run documentation consistency tests until green.

### Task 4: Align generators, deck source, and affected decks

**Files:**
- Modify: `scripts/sync_course_assets.py`
- Modify: `scripts/edit_lecture_decks.mjs`
- Modify: affected `lectures/*/slides.pptx`
- Modify: `generate_pptx_slides.py` only if its inventory assumptions require it

**Interfaces:**
- Consumes: specs-only manifest and lecture inventory
- Produces: portable inventory checks and decks with no implementation-included claims

- [x] Update generator checks to require the four direct app specification files and reject implementation artifacts.
- [x] Update deck text that claims canonical SQL or editable generated apps are included.
- [x] Rebuild affected decks with `@oai/artifact-tool` and run overflow plus visual QA.
- [x] Run generator/deck contract checks.

### Task 5: Remove obsolete implementation planning artifacts and verify

**Files:**
- Recoverably remove: `docs/superpowers/specs/2026-08-30-apex-26-course-repair-design.md`
- Recoverably remove: `docs/superpowers/plans/2026-08-30-apex-26-course-repair.md`
- Retain: this cleanup design and plan as the decision record

**Interfaces:**
- Consumes: completed specs-only repository
- Produces: final verified inventory and recovery path

- [x] Remove cache/inspection sidecars from the repository into the recovery directory.
- [x] Scan for secrets, absolute home paths, `ai_generate`, stale `.apexlang` paths, `.apx`, and deploy/install claims.
- [x] Run `python3 scripts/sync_course_assets.py --check`.
- [x] Run `python3 generate_pptx_slides.py --check`.
- [x] Run `bash tests/run_static_tests.sh` and require zero failures.
- [x] Review the final inventory and report the recovery directory. Record commit as `SKIPPED_NON_GIT_WORKSPACE`.

---

## Completion Record

Commit: `SKIPPED_NON_GIT_WORKSPACE` — this directory is not a Git repository (per Global Constraints).

Recovery directory: `/tmp/wf-tut-specs-recovery.H0zxmi` (created during Task 2; reused for Task 5's additional recoverable removals rather than creating a second directory).

**Ruling:** The plan's required sub-skill list names `superpowers:subagent-driven-development` or `superpowers:executing-plans`. Both skills' tooling (`sdd-workspace`, `review-package`) shells out to `git rev-parse`/`git diff` and is unusable in this non-Git workspace, and Tasks 1-4 were found already implemented (from prior session work) when this pass began. Rather than dispatching per-task implementer/reviewer subagents against tooling that cannot function here, this pass verified each task's deliverables directly against the live repository and test suite, fixed the gaps found, and recorded results in this ledger-equivalent section instead of a `.superpowers/sdd/` workspace. Cost if wrong: any deeper defect in Tasks 1-4 that only a fresh-eyes subagent review would have caught went unreviewed by a second party.

**Verification performed this pass (Tasks 1-4 confirmed already done):**
- `apps/DEMO/100/` and `apps/DEMO/200/` contain exactly `application-spec.md` and `app-ux-contract.json`; no `.apexlang`, `.apx`, `.apex`, or other generated runtime files remain.
- `ai_generate/` is absent from the live tree.
- `tests/test_specs_only_contracts.py` replaces `tests/test_sql_contracts.py`.
- `bash tests/run_static_tests.sh` ran green (23/23 after this pass's addition).

**Gaps found and fixed in this pass:**
1. `docs/course/README.md` documented `apexVersion` and other manifest identity values but omitted `ordsMinimum` ("26.1.1") from `course-manifest.json`, failing `test_required_identity_values_are_documented`. Fixed by adding "(ORDS 26.1.1 minimum)" to the system description line.
2. `docs/superpowers/specs/2026-08-30-apex-26-course-repair-design.md` and `docs/superpowers/plans/2026-08-30-apex-26-course-repair.md` (Task 5's named obsolete artifacts) were still present. Moved to the recovery directory.
3. Every `lectures/*/slides.pptx` had a sibling `slides.pptx.inspect.ndjson` — a generated deck-inspection sidecar matching the design's "Generated cache and inspection sidecar files" removed-artifacts category, left behind by Task 4's deck rebuild. Moved all 14 to the recovery directory, and added `tests/test_specs_only_contracts.py::test_no_deck_inspection_sidecars_are_committed` as a regression guard (a parallel `__pycache__`/`*.pyc` assertion was attempted but reverted: running the Python test suite itself regenerates `__pycache__`, so asserting its absence from inside a Python test fails on the check's own side effect).
4. Removed accumulated `__pycache__`/`*.pyc` directories under the repo root, `scripts/`, and `tests/` into the recovery directory (not preserved further — regenerable bytecode has no recovery value).

**Final state:** `bash tests/run_static_tests.sh` — 23/23 passing. `python3 scripts/sync_course_assets.py --check` and `python3 generate_pptx_slides.py --check` both exit 0. Manual scan for secrets, absolute home paths, and stale `ai_generate`/`.apexlang`/`.apx` references outside test files: clean. Manual scan of root-level Markdown and `scripts/edit_lecture_decks.mjs` for deploy/install claims or stale implementation references: clean.
