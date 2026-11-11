# agent-os

Self-hosted multi-agent stack. You message a Telegram bot; a Manager agent delegates to specialists that use many models, the web and tools, and keep running while you're offline.

```
Telegram -> SwarmClaw (agents, delegation, schedules, memory, MCP)
                |
                v
            OmniRoute (one /v1 endpoint -> Claude/Gemini/Kimi/DeepSeek/Qwen/etc, with fallback)
```

SwarmClaw runs on :3456, OmniRoute on :20128. Both bound for a Linux box with Docker.

## 1. Get a host (the only manual part)

Agents only run while the machine is on, so you need an always-on Linux VPS. Minimum realistic spec: 2 vCPU / 4 GB RAM / 30 GB disk.

- Oracle Cloud Always Free ARM VM: historically the best free option. Capacity and sign-up rules change, so check current availability.
- Cheap paid VPS (roughly a few USD/month) if free tiers won't verify your card or are out of capacity.
- GitHub Codespaces / your laptop: fine for testing, not always-on.

## 2. Install

```bash
git clone https://github.com/barryralphh/agent-os.git && cd agent-os
bash scripts/setup.sh      # installs Docker if missing, creates .env, starts OmniRoute + SwarmClaw
```

Run it twice if it stops to ask you to edit `.env` or re-login.

## 3. Wire it up (about 10 minutes, in the UIs)

1. **OmniRoute** (`:20128`): log in with `INITIAL_PASSWORD`, add provider keys (start with free tiers: Gemini, Groq, Mistral, etc.), then create an **API key**. Make 2-3 *combos* (e.g. `smart`, `fast`, `code`) with fallback order.
2. **SwarmClaw** (`:3456`): add a custom OpenAI-compatible provider -> Base URL `http://host.docker.internal:20128/v1`, key = the OmniRoute API key. If SwarmClaw runs outside Docker, use `http://localhost:20128/v1`.
3. **Telegram**: create a bot with @BotFather, paste the token into SwarmClaw's Telegram connector, and restrict it to your own Telegram user ID.
4. **Agents**: create the roster from `agents/team.md`. Start with 3.
5. **MCP tools**: add Tavily + Playwright from `mcp/mcp-servers.json`.
6. **Monitoring (optional)**: Langfuse cloud free tier; self-hosting it needs several extra services, so skip until needed.

## 4. Rules that save you pain

- Don't expose :3456 or :20128 to the internet raw. Use a Cloudflare Tunnel / Tailscale / reverse proxy with auth. OmniRoute holds all your provider keys.
- Agents get scoped tokens only (fine-grained GitHub PAT, one repo), never your main account.
- Keep "ask before irreversible actions" in the Manager prompt.
- Free model quotas are rate-limited; fallback combos matter.
- Postgres is optional: `docker compose --profile db up -d`. SwarmClaw keeps its own state in `swarmclaw/data`; back that folder up.

## 5. Later (only if you actually need it)

Hermes Agent, Browser Use, n8n, Flowise, Ollama. Don't add them before the 3-agent loop works.

## Updating

```bash
docker compose pull && docker compose up -d      # OmniRoute
cd swarmclaw && git pull && docker compose up -d --build   # SwarmClaw
```
