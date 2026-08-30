from __future__ import annotations

import unittest

from tests.support import ROOT


PROTECTED_FILES = {
    "AGENTS.md",
    "self_improve.md",
    ".env",
    ".gitattributes",
    ".gitignore",
    ".graphifyignore",
    "scripts/test_template.sh",
    "scripts/test_template.ps1",
}
PROTECTED_PREFIXES = (".agents/", ".github/")


class OverlayCompatibilityTests(unittest.TestCase):
    def test_course_does_not_own_protected_template_files(self) -> None:
        files = {
            path.relative_to(ROOT).as_posix()
            for path in ROOT.rglob("*")
            if path.is_file() and ".superpowers/sdd/" not in path.as_posix()
        }
        collisions = sorted(
            path for path in files if path in PROTECTED_FILES or path.startswith(PROTECTED_PREFIXES)
        )
        self.assertEqual([], collisions)


if __name__ == "__main__":
    unittest.main()
