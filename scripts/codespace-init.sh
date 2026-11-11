#!/usr/bin/env bash
# Runs once when the Codespace is created.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  cp .env.example .env
  # Use Codespaces secrets if set, else generate random passwords
  PW="${OMNIROUTE_PASSWORD:-$(openssl rand -hex 12)}"
  PGPW="$(openssl rand -hex 12)"
  sed -i "s|^INITIAL_PASSWORD=.*|INITIAL_PASSWORD=${PW}|" .env
  sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${PGPW}|" .env
  [ -n "${TAVILY_API_KEY:-}" ] && sed -i "s|^TAVILY_API_KEY=.*|TAVILY_API_KEY=${TAVILY_API_KEY}|" .env
  echo "OmniRoute login password: ${PW}  (also saved in .env)"
fi

docker compose up -d

[ -d swarmclaw ] || git clone https://github.com/swarmclawai/swarmclaw.git swarmclaw
( cd swarmclaw && mkdir -p data && touch .env.local && docker compose up -d --build )

echo "Ready. Open the Ports tab: 3456 = SwarmClaw, 20128 = OmniRoute."
