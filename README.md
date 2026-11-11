# agent-os

A self-hosted team of AI agents you control from Telegram.

## The goal

Message one Telegram bot. A **Manager** agent breaks the job down and hands pieces to **specialist agents** (research, dev, browser, analysis, QA, monitoring). They use **different AI models** (Claude, Gemini, Kimi, DeepSeek, Qwen...), browse the web, use tools, save their progress, and **keep working while you're offline**.

No single project does all of this, so this repo glues several together:

| Layer | Project | Job |
|---|---|---|
| Command centre | SwarmClaw | where the agents live: delegation, schedules, memory, Telegram connector, MCP |
| Model gateway | OmniRoute | gives agents models: one `/v1` endpoint -> many providers, with fallback. It does NOT create agents |
| Isolation | Docker | sandboxes for agents |
| Tools | MCP (Tavily, Playwright, GitHub) | web search, browser, repos |
| Control | Telegram | your remote + notifications |
| Monitoring (optional) | Langfuse cloud | traces and failures |
| Persistence (optional) | PostgreSQL | durable project data |

```
Telegram -> SwarmClaw (agents) -> OmniRoute (models) -> providers
               |-> MCP tools (web, browser, GitHub)
```

## Progress checklist

**Done**
- [x] Repo, docker-compose, setup scripts, Codespaces auto-boot, agent prompts, MCP config
- [x] `CODESPACES_PAT` secret added
- [x] `keep-codespace-running` workflow green; Codespace is up

**Left (in this order)**
- [ ] 1. Set Codespace idle timeout to max (2 min)
- [ ] 2. OmniRoute: log in, add a provider key, create an API key
- [ ] 3. SwarmClaw: add OmniRoute as a provider
- [ ] 4. SwarmClaw: create Manager, Researcher, Dev agents
- [ ] 5. Telegram: make the bot, connect it, lock it to your ID
- [ ] 6. Tavily key + MCP tools
- [ ] 7. Test with one small task
- [ ] 8. Later: move to an always-on VPS

## How to do the remaining steps

Open your Codespace at github.com/codespaces. Use the **Ports** tab at the bottom: port **3456** = SwarmClaw, port **20128** = OmniRoute. Click the globe icon next to a port to open it. Keep ports **Private**.

### 1. Idle timeout
github.com -> profile picture -> Settings -> Codespaces -> "Default idle timeout" -> set to the max (240 minutes) -> Save.

### 2. OmniRoute: models
1. Open port 20128.
2. Log in. The password is the `INITIAL_PASSWORD` line in the `.env` file in the Codespace (it was also printed in the setup terminal).
3. Add a provider. Easiest free start: a **Gemini** key from aistudio.google.com (Get API key). Optionally also Groq or Mistral, which have free tiers.
4. Create an **API key** in OmniRoute and copy it. This is what SwarmClaw will use.
5. Optional: create combos (e.g. `smart`, `fast`, `code`) that list several models in fallback order.

### 3. SwarmClaw: connect the models
1. Open port 3456.
2. Find Providers (or Settings -> Providers) and add a custom **OpenAI-compatible** provider.
3. Base URL: `http://host.docker.internal:20128/v1` (if that fails, try `http://localhost:20128/v1`).
4. API key: the OmniRoute key from step 2.
5. Use the provider's health check / test button if there is one.

### 4. SwarmClaw: create the agents
OmniRoute does not create agents. You make them here, one by one, copying text from `agents/team.md`:
1. Create an agent named **Manager**; paste the Manager prompt; pick your OmniRoute provider and a strong model or `smart` combo.
2. Create **Researcher** (Researcher prompt) and **Dev** (Dev prompt) the same way.
3. Let the Manager delegate to the other two (look for delegation / team / sub-agents settings).
4. Add Browser, Analyst, QA, Monitor only after these three work.

### 5. Telegram
1. In Telegram, message **@BotFather** -> `/newbot` -> pick a name and a username ending in `bot` -> copy the token. Keep it private.
2. Message **@userinfobot** -> it replies with your numeric ID. Copy it.
3. In SwarmClaw -> Connectors -> Telegram: paste the token, put your ID in the allowed users list, assign it to the **Manager**.
4. Open your bot in Telegram, press Start, send "hi".
5. If you can't find an allowlist option, do not leave the bot running: anyone who finds it could command your agents.

### 6. Web search and browser tools
1. Get a free key at tavily.com.
2. In SwarmClaw's MCP settings, add the servers from `mcp/mcp-servers.json` (Tavily and Playwright). Put the Tavily key in the `env` field in the app, not in this repo.
3. Give the Researcher the Tavily tool.

### 7. Test
In Telegram send the Manager something small: "Research the 3 best free LLM APIs and send me a 5-line summary." Expect Manager -> Researcher -> reply. If it stalls, check OmniRoute's dashboard for errors (rate limit or bad key is the usual cause).

### 8. VPS (for real 24/7)
```bash
git clone https://github.com/barryralphh/agent-os.git && cd agent-os
bash scripts/setup.sh
```
Minimum 2 vCPU / 4 GB RAM. Run twice if it asks for `.env` edits or a re-login. Then repeat steps 2-6 there.

## Limits (read this)

- **Codespaces is not 24/7.** It sleeps when idle; free accounts get a monthly core-hour quota (roughly 2-3 days of continuous running on a 2-core machine). The workflow restarts it, but the quota still ends it. Check your billing page for current numbers.
- **GitHub Actions can't host the agents** (6-hour job cap, no persistent state). It's only used to restart the Codespace.
- Free model tiers are rate-limited; fallback combos matter.
- Agents are unreliable on long, vague jobs. Give small, clear tasks and expect to nudge them.
- Back up `swarmclaw/data` and the OmniRoute volume.

## Security

This repo is public. It contains **no secrets**: `.env`, `.env.local` and `data/` are gitignored. Never commit keys or tokens.

- Don't expose ports 3456/20128 publicly. OmniRoute holds all your provider keys.
- Give agents scoped tokens only (fine-grained GitHub PAT for one repo), never your main account.
- Manager prompt requires asking before irreversible actions (delete, spend, publish, force-push).
- Telegram bot must be restricted to your user ID.
- If `CODESPACES_PAT` ever leaks, delete it in GitHub -> Settings -> Developer settings -> Tokens and make a new one.

## Later (only if needed)
Hermes Agent, Browser Use, n8n, Flowise, Ollama. Not before the 3-agent loop works.

## Updating
```bash
docker compose pull && docker compose up -d                 # OmniRoute
cd swarmclaw && git pull && docker compose up -d --build    # SwarmClaw
```
