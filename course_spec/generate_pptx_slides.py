#!/usr/bin/env python3
"""Compatibility entry point for the Node-based deck editor and checker."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="validate deck inventory and OOXML")
    mode.add_argument("--write", action="store_true", help="apply manifest-driven deck edits")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    mode = "--write" if args.write else "--check"
    result = subprocess.run(
        ["node", str(ROOT / "scripts" / "edit_lecture_decks.mjs"), mode],
        cwd=ROOT,
        check=False,
    )
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
