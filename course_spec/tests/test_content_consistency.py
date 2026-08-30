from __future__ import annotations

import re
import unittest
from urllib.parse import unquote

from tests.support import ROOT, load_manifest, text_files


class ContentConsistencyTests(unittest.TestCase):
    def test_course_entry_documentation_exists(self) -> None:
        for name in ("README.md", "deployment.md", "template-configuration.md"):
            self.assertTrue((ROOT / "docs" / "course" / name).is_file(), name)

    def test_required_identity_values_are_documented(self) -> None:
        docs = "\n".join(path.read_text(encoding="utf-8") for path in text_files("docs/course/*.md"))
        manifest = load_manifest()
        for value in (
            manifest["apexVersion"],
            manifest["ordsMinimum"],
            manifest["databaseMinimum"],
            manifest["workspace"],
            manifest["sqlclConnection"],
            "100,200",
        ):
            self.assertIn(str(value), docs)

    def test_canonical_counts_and_ids_appear_in_course_docs(self) -> None:
        docs = "\n".join(
            path.read_text(encoding="utf-8")
            for path in text_files("*.md", "docs/course/*.md", "lectures/**/*.md")
            if "docs/superpowers" not in str(path)
        )
        for phrase in (
            "nine tables",
            "five packages",
            "four roles",
            "seven AI tools",
            "LEAVE_APPROVAL",
            "LEAVE_MANAGER_APPROVAL",
            "LEAVE_HR_APPROVAL",
            "EMPLOYEE_HR_AGENT",
            "LEAVE_SUMMARY_AGENT",
        ):
            self.assertIn(phrase.lower(), docs.lower())

    def test_generators_and_public_docs_have_no_machine_specific_home_path(self) -> None:
        for path in text_files("*.py", "scripts/*", "docs/course/*.md", "lectures/**/*.md"):
            if path.suffix.lower() in {".pptx", ".png"}:
                continue
            content = path.read_text(encoding="utf-8", errors="ignore")
            self.assertIsNone(re.search(r"/home/[^/]+/", content), str(path))

    def test_public_course_markdown_has_no_obsolete_course_contracts(self) -> None:
        forbidden = (
            "oracle apex 24.x",
            "oracle apex 23.2+ / 24.x",
            "all 8 tables",
            "the 8 core tables",
            "adm001",
            "sys001",
            "p_workflow_static_id",
            "apex_task_potential_owners",
            "same database schema (`hr_`)",
        )
        for path in text_files("docs/course/*.md", "lectures/**/*.md"):
            content = path.read_text(encoding="utf-8", errors="ignore").lower()
            for phrase in forbidden:
                self.assertNotIn(phrase, content, f"{path}: {phrase}")

    def test_specs_only_docs_do_not_reference_removed_implementation(self) -> None:
        paths = text_files(
            "*.md",
            "app_context/**/*.md",
            "docs/course/*.md",
            "lectures/**/*.md",
            "scripts/edit_lecture_decks.mjs",
        )
        forbidden = (
            "ai_generate",
            ".apexlang/",
            "schema_and_packages.sql",
            "escalation_refactor.sql",
            "role_refactor_migration.sql",
            "e2e_verification_script.sql",
            "install_all.sql",
        )
        for path in paths:
            content = path.read_text(encoding="utf-8", errors="ignore").lower()
            for phrase in forbidden:
                self.assertNotIn(phrase, content, f"{path}: {phrase}")

    def test_public_markdown_relative_links_resolve(self) -> None:
        paths = text_files("*.md", "app_context/**/*.md", "docs/course/*.md", "lectures/**/*.md")
        for path in paths:
            content = path.read_text(encoding="utf-8", errors="ignore")
            for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", content):
                clean = unquote(target.split("#", 1)[0]).strip()
                if not clean or re.match(r"^[a-z][a-z0-9+.-]*:", clean, re.I):
                    continue
                self.assertTrue((path.parent / clean).resolve().exists(), f"{path}: {target}")


if __name__ == "__main__":
    unittest.main()
