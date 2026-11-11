# agent-os

A self-hosted team of AI agents you control from Telegram.

## The goal

Message one Telegram bot. A **Manager** agent breaks the job down and hands pieces to **specialist agents** (research, dev, browser, analysis, QA, monitoring). They use **different AI models** (Claude, Gemini, Kimi, DeepSeek, Qwen...), browse the web, use tools, save their progress, and **keep working while you're offline**.

No single project does all of this, so this repo glues several together:

| Layer | Project | Job |
|---|---|---|
| Command centre | SwarmClaw | agents, delegation, schedules, memory, Telegram connector, MCP |
| Model gateway | OmniRoute | one `/v1` endpoint -> many providers, with fallback |
| Isolation | Docker | sandboxes for agents |
| Tools | MCP (Tavily, Playwright, GitHub) | web search, browser, repos |
| Control | Telegram | your remote + notifications |
| Monitoring (optional) | Langfuse cloud | traces and failures |
| Persistence (optional) | PostgreSQL | durable project data |

```
Telegram -> SwarmClaw -> OmniRoute -> model providers
               |-> MCP tools (web, browser, GitHub)
```

## Status: what's done vs what you must do

**Done (in this repo):** docker-compose for OmniRoute (+ optional Postgres), setup scripts, Codespaces auto-boot, agent roster and prompts, MCP config, scheduled workflow that restarts the Codespace.

**Not done: needs you** (nobody can do these for you: they need your accounts/secrets)

- [ ] Create a GitHub token with the `codespace` scope and save it as repo secret **`CODESPACES_PAT`** (Settings -> Secrets and variables -> Actions)
- [ ] Create a Codespace (Code -> Codespaces -> Create) or run the **keep-codespace-running** workflow once from the Actions tab, which creates one
- [ ] In your GitHub Codespaces settings, set idle timeout to the max (240 min)
- [ ] Get provider API keys (free tiers: Gemini, Groq, Mistral, etc.) and add them in the OmniRoute dashboard
- [ ] Create a Telegram bot with @BotFather, put the token in SwarmClaw, lock it to your own Telegram user ID
- [ ] Get a Tavily API key (tavily.com) for web search
- [ ] In SwarmClaw: add OmniRoute as a custom OpenAI-compatible provider, then create the agents from `agents/team.md` (start with 3)
- [ ] Test the loop: message the bot, watch Manager -> Researcher -> reply
- [ ] For real 24/7: move to an always-on VPS with `bash scripts/setup.sh`

## How to run

### Codespaces (build/test)
Code -> Codespaces -> Create codespace on main. It starts everything and prints your OmniRoute password. Open ports 20128 (OmniRoute) and 3456 (SwarmClaw) from the Ports tab, keep them **Private**. See `docs/codespaces.md`.

### VPS (always-on)
```bash
git clone https://github.com/barryralphh/agent-os.git && cd agent-os
bash scripts/setup.sh
```
Minimum: 2 vCPU / 4 GB RAM. Run twice if it stops to ask for `.env` edits or a re-login.

### Wiring (about 10 min, in the UIs)
1. **OmniRoute** `:20128`: log in, add provider keys, create an API key, make 2-3 combos (`smart`, `fast`, `code`) with fallback.
2. **SwarmClaw** `:3456`: custom OpenAI-compatible provider, Base URL `http://host.docker.internal:20128/v1` (or `http://localhost:20128/v1` outside Docker), key = the OmniRoute API key.
3. **Telegram** connector: bot token + your user ID only.
4. **Agents**: from `agents/team.md`. **MCP**: from `mcp/mcp-servers.json`.

## Limits (read this)

- **Codespaces is not 24/7.** It sleeps when idle, and free accounts get a monthly core-hour quota (roughly 2-3 days of continuous running on a 2-core machine). The workflow restarts it, but the quota still ends it. Check your billing page for current numbers.
- **GitHub Actions can't host the agents** (6-hour job cap, no persistent state). It's only used to restart the Codespace.
- Free model tiers are rate-limited; fallback combos matter.
- Back up `swarmclaw/data` and the OmniRoute volume.

## Security

This repo is public. It contains **no secrets**: `.env`, `.env.local` and `data/` are gitignored. Never commit keys.

- Don't expose ports 3456/20128 publicly. OmniRoute holds all your provider keys. Use Private Codespace ports, Tailscale, or a Cloudflare Tunnel with auth.
- Give agents scoped tokens only (fine-grained GitHub PAT for one repo), never your main account.
- Manager prompt requires asking before irreversible actions (delete, spend, publish, force-push).
- Telegram bot must be restricted to your user ID, or anyone who finds it can command your agents.

## Later (only if needed)
Hermes Agent, Browser Use, n8n, Flowise, Ollama. Not before the 3-agent loop works.

## Updating
```bash
docker compose pull && docker compose up -d                 # OmniRoute
cd swarmclaw && git pull && docker compose up -d --build    # SwarmClaw
```
