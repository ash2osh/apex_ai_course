from __future__ import annotations

import unittest
import zipfile

from tests.support import ROOT, load_manifest


class PptxContractTests(unittest.TestCase):
    def test_every_episode_has_one_valid_deck_at_the_indexed_path(self) -> None:
        manifest = load_manifest()
        episodes = sorted(path for path in (ROOT / "lectures").iterdir() if path.is_dir())
        self.assertEqual(manifest["counts"]["episodes"], len(episodes))
        for episode in episodes:
            decks = list(episode.glob("*.pptx"))
            self.assertEqual([episode / "slides.pptx"], decks)
            with zipfile.ZipFile(decks[0]) as archive:
                self.assertIsNone(archive.testzip())
                self.assertIn("[Content_Types].xml", archive.namelist())
                self.assertIn("ppt/presentation.xml", archive.namelist())

    def test_no_decks_are_written_beside_episode_directories(self) -> None:
        self.assertEqual([], list((ROOT / "lectures").glob("*.pptx")))


if __name__ == "__main__":
    unittest.main()
