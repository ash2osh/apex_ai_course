from __future__ import annotations

import ast
import subprocess
import sys
import unittest

from tests.support import ROOT


class GeneratorTests(unittest.TestCase):
    def test_python_generators_are_portable_and_guarded(self) -> None:
        for name in ("populate_lecture_assets.py", "generate_pptx_slides.py", "scripts/sync_course_assets.py"):
            path = ROOT / name
            self.assertTrue(path.is_file(), name)
            source = path.read_text(encoding="utf-8")
            ast.parse(source, filename=str(path))
            self.assertIn('if __name__ == "__main__"', source)
            self.assertNotIn("from pptx", source)
            self.assertNotIn("import pptx", source)

    def test_importing_python_entry_points_has_no_side_effects(self) -> None:
        for module in ("populate_lecture_assets", "generate_pptx_slides"):
            result = subprocess.run(
                [sys.executable, "-c", f"import {module}"],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual("", result.stdout)

    def test_generators_expose_check_and_write_modes(self) -> None:
        for command in (
            [sys.executable, "scripts/sync_course_assets.py", "--help"],
            [sys.executable, "populate_lecture_assets.py", "--help"],
            [sys.executable, "generate_pptx_slides.py", "--help"],
        ):
            result = subprocess.run(command, cwd=ROOT, check=False, capture_output=True, text=True)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn("--check", result.stdout)
            self.assertIn("--write", result.stdout)

    def test_course_inventory_check_accepts_specs_only_packages(self) -> None:
        result = subprocess.run(
            [sys.executable, "scripts/sync_course_assets.py", "--check"],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("Course asset inventory is synchronized.", result.stdout)


if __name__ == "__main__":
    unittest.main()
