#!/usr/bin/env bash
set -euo pipefail

course_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
app_root="${course_root}/apps/DEMO"

if [[ ! -d "${course_root}/.git" ]]; then
  printf '%s\n' 'Run this example only after the course overlay is copied into APEX_PROJECT_TEMPLATE.' >&2
  exit 1
fi

sql -name demo <<SQL
apex export -split -applicationid 100 -dir "${app_root}/100"
apex export -split -applicationid 200 -dir "${app_root}/200"
exit
SQL

git -C "${course_root}" status --short
