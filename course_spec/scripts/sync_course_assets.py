#!/usr/bin/env python3
"""Validate or normalize the manifest-owned course asset inventory."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "docs" / "course" / "course-manifest.json"
REQUIRED_EPISODE_FILES = ("lecture_notes.md", "prompts.md", "slides.pptx")


def load_manifest() -> dict:
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def findings() -> list[str]:
    manifest = load_manifest()
    lecture_root = ROOT / "lectures"
    episodes = sorted(path for path in lecture_root.iterdir() if path.is_dir())
    issues: list[str] = []
    if manifest.get("deliveryMode") != "specifications-only":
        issues.append("course manifest deliveryMode must be specifications-only")
    if (ROOT / "ai_generate").exists():
        issues.append("specifications-only package must not contain ai_generate")
    expected_app_files = ["app-ux-contract.json", "application-spec.md"]
    for app_id in (100, 200):
        app_root = ROOT / "apps" / "DEMO" / str(app_id)
        actual = sorted(path.name for path in app_root.iterdir()) if app_root.is_dir() else []
        if actual != expected_app_files:
            issues.append(f"{app_root.relative_to(ROOT)} must contain only {', '.join(expected_app_files)}")
    expected = manifest["counts"]["episodes"]
    if len(episodes) != expected:
        issues.append(f"expected {expected} episode directories; found {len(episodes)}")
    for episode in episodes:
        for name in REQUIRED_EPISODE_FILES:
            if not (episode / name).is_file():
                issues.append(f"missing {episode.relative_to(ROOT) / name}")
        code = list(episode.glob("*.sql")) + list(episode.glob("*.sh"))
        if len(code) > 1:
            issues.append(f"{episode.relative_to(ROOT)} may contain at most one SQL or shell example")
        decks = list(episode.glob("*.pptx"))
        if decks != [episode / "slides.pptx"]:
            issues.append(f"{episode.relative_to(ROOT)} must contain only slides.pptx")
    return issues


def normalize() -> None:
    """Apply only deterministic text normalization owned by this CLI."""
    for path in sorted((ROOT / "lectures").glob("*/lecture_notes.md")):
        source = path.read_text(encoding="utf-8")
        normalized = source.replace("\r\n", "\n").replace("\r", "\n")
        if normalized and not normalized.endswith("\n"):
            normalized += "\n"
        if normalized != source:
            path.write_text(normalized, encoding="utf-8")
    for path in sorted((ROOT / "lectures").glob("*/prompts.md")):
        source = path.read_text(encoding="utf-8")
        normalized = source.replace("\r\n", "\n").replace("\r", "\n")
        if normalized and not normalized.endswith("\n"):
            normalized += "\n"
        if normalized != source:
            path.write_text(normalized, encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="report asset inventory drift without writing")
    mode.add_argument("--write", action="store_true", help="normalize owned Markdown, then verify inventory")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.write:
        normalize()
    issues = findings()
    if issues:
        for issue in issues:
            print(f"ERROR: {issue}", file=sys.stderr)
        return 1
    print("Course asset inventory is synchronized.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
