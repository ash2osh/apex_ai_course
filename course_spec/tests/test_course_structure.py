from __future__ import annotations

import unittest

from tests.support import ROOT, load_manifest


class CourseStructureTests(unittest.TestCase):
    def test_manifest_has_exact_course_identity(self) -> None:
        manifest = load_manifest()
        self.assertEqual("26.1.4", manifest["apexVersion"])
        self.assertEqual("26.1.1", manifest["ordsMinimum"])
        self.assertEqual("19c RU 19.18", manifest["databaseMinimum"])
        self.assertEqual("DEMO", manifest["workspace"])
        self.assertEqual("DEMO", manifest["parsingSchema"])
        self.assertEqual("demo", manifest["sqlclConnection"])
        self.assertEqual("specifications-only", manifest["deliveryMode"])
        self.assertEqual([100, 200], [app["id"] for app in manifest["applications"]])
        self.assertEqual([9, 12], [app["pageCount"] for app in manifest["applications"]])
        self.assertEqual(
            {"episodes": 14, "tables": 9, "packages": 5, "roles": 4, "aiTools": 7},
            manifest["counts"],
        )

    def test_deployable_database_tree_is_not_included(self) -> None:
        self.assertFalse((ROOT / "ai_generate").exists())

    def test_only_direct_application_specs_exist(self) -> None:
        for app_id in (100, 200):
            app = ROOT / "apps" / "DEMO" / str(app_id)
            self.assertEqual(
                ["app-ux-contract.json", "application-spec.md"],
                sorted(path.name for path in app.iterdir()),
            )

    def test_app_context_exists(self) -> None:
        shared = ("architecture.md", "authorization.md", "database-model.md", "leave-workflow.md", "demo-scenarios.md")
        for app_id in (100, 200):
            for name in shared:
                self.assertTrue((ROOT / "app_context" / str(app_id) / name).is_file())
        self.assertTrue((ROOT / "app_context" / "100" / "ai-agent.md").is_file())

    def test_all_episode_assets_exist(self) -> None:
        episodes = sorted(path for path in (ROOT / "lectures").iterdir() if path.is_dir())
        self.assertEqual(14, len(episodes))
        for episode in episodes:
            self.assertTrue((episode / "lecture_notes.md").is_file(), episode.name)
            self.assertTrue((episode / "prompts.md").is_file(), episode.name)
            self.assertTrue((episode / "slides.pptx").is_file(), episode.name)

    def test_database_metadata_mirror_is_not_course_authored(self) -> None:
        mirror = ROOT / "database" / "DEMO"
        if mirror.exists():
            self.assertEqual([], [path for path in mirror.rglob("*") if path.is_file()])


if __name__ == "__main__":
    unittest.main()
