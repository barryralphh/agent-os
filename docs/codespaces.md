# Running in GitHub Codespaces

1. Repo page -> **Code** -> **Codespaces** -> **Create codespace on main**.
2. Wait for setup to finish (a few minutes, it builds SwarmClaw). The terminal prints your OmniRoute password.
3. **Ports** tab -> open 20128 (OmniRoute) and 3456 (SwarmClaw). Keep ports **Private**.
4. Continue with README section 3 (provider keys, Telegram, agents).

## Limits you need to know

- Codespaces is **not always-on**. It stops after an idle timeout (default 30 min, adjustable in your GitHub settings up to a few hours) and when it stops, your agents and Telegram bot go offline. Resuming restarts the containers automatically.
- Free personal accounts get a monthly quota of core-hours and storage; running 24/7 will exhaust it. Check your billing page for current numbers.
- Data persists in the Codespace disk while the codespace exists, but deleting it deletes everything. Back up `swarmclaw/data` and the OmniRoute volume.
- Don't try to keep it alive with Actions cron pings or keep-alive tricks: it burns quota and risks your account.

Good for building and testing. For true 24/7, move to a VPS (README section 1) using the same repo.
