from __future__ import annotations

import unittest

from tests.support import ROOT


class SpecsOnlyContractTests(unittest.TestCase):
    def test_generated_apex_runtime_artifacts_are_absent(self) -> None:
        forbidden = []
        for app_id in (100, 200):
            app = ROOT / "apps" / "DEMO" / str(app_id)
            forbidden.extend(app.rglob("*.apx"))
            forbidden.extend(app.rglob("*.png"))
            forbidden.extend(path for path in app.rglob("*") if path.name in {".apex", ".apexlang"})
        self.assertEqual([], forbidden)

    def test_no_deck_inspection_sidecars_are_committed(self) -> None:
        forbidden = list((ROOT / "lectures").rglob("*.inspect.ndjson"))
        self.assertEqual([], forbidden)

    def test_removed_database_wrappers_are_absent(self) -> None:
        wrappers = (
            "lectures/03_database_design_and_packages/schema_and_packages.sql",
            "lectures/12_ai_assisted_maintenance_and_changes/escalation_refactor.sql",
            "lectures/13_architecture_refactoring_roles/role_refactor_migration.sql",
            "lectures/14_end_to_end_demo_and_wrap_up/e2e_verification_script.sql",
        )
        for relative in wrappers:
            self.assertFalse((ROOT / relative).exists(), relative)


if __name__ == "__main__":
    unittest.main()
