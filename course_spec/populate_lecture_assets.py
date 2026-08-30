#!/usr/bin/env python3
"""Compatibility entry point for the manifest-driven course asset synchronizer."""

from __future__ import annotations

from scripts.sync_course_assets import main


if __name__ == "__main__":
    raise SystemExit(main())
