#!/usr/bin/env bash
# One-shot setup for a fresh Linux VPS (Ubuntu/Debian). Run: bash scripts/setup.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v docker >/dev/null 2>&1; then
  echo "[*] Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER" || true
  echo "[!] Log out/in once so docker works without sudo, then re-run this script."
  exit 0
fi

[ -f .env ] || { cp .env.example .env; echo "[!] Created .env. Edit it (set INITIAL_PASSWORD), then re-run."; exit 0; }

echo "[*] Starting OmniRoute (model gateway) on :20128 ..."
docker compose up -d

echo "[*] Installing SwarmClaw (agent command centre) ..."
if [ ! -d swarmclaw ]; then
  git clone https://github.com/swarmclawai/swarmclaw.git swarmclaw
fi
cd swarmclaw
mkdir -p data
touch .env.local
docker compose up -d --build

cat <<'EOF'

Done.
  OmniRoute dashboard : http://localhost:20128   (add provider keys, create an API key)
  SwarmClaw UI        : http://localhost:3456

Next: follow README.md section 3 to wire SwarmClaw -> OmniRoute and connect Telegram.
EOF
