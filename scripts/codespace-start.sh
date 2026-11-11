#!/usr/bin/env bash
# Runs every time the Codespace starts/resumes.
cd "$(dirname "$0")/.."
[ -f .env ] && docker compose up -d
[ -d swarmclaw ] && ( cd swarmclaw && docker compose up -d )
exit 0
