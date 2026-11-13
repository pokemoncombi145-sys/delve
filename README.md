# Delve v3

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/pokemoncombi145-sys/delve/main/delve_v3.lua"))()
```

Current version: **v5.10.4**. See [CHANGELOG.md](CHANGELOG.md) for what changed in each update.

## Features
- **Dodging.** Plans a path over the floor tiles out of attack zones, avoids corners, and learns from every hit you take.
- **Targeting.** Mines ores first and fights on boss stages or when mobs are a real threat. Uses your sword's range so it doesn't waste movement.
- **Relics.** Picks while tabbed out and before the timer runs out. Keeps a codex of every relic seen and learns which relics and combos make your runs better.
- **Index, Equipment and Stats.** Read on launch to learn drop odds and sources, your gear and your lifetime stats.
- **Discord posts.** A "Run Complete" post after each run with real numbers from the results screen, plus alerts for rare drops and new Index entries.
- **Autosave.** Every setting is restored the next time you load the script.

## Files it writes (in your executor's `workspace` folder)
| File | What's in it |
|---|---|
| `DelveSettings.json` | your settings |
| `DelveBrain.json` | everything learned: relics, codex, Index, gear, dodging |
| `DelveRuns.jsonl` | one line per run |
| `DelveDrops.jsonl` | one line per rare drop |
| `DelveMechanics.jsonl` | one line per new mechanic discovered |
| `DelveReasoning.txt` | why it fought, mined or picked each relic |
| `DelveDeaths.jsonl` | the last 5 seconds before each death |
| `DelveBackups/` | the newest 8 copies of the brain file |

## Load automatically (Volt auto-execute)
Put `delve_autoexec.lua` in `%LOCALAPPDATA%\Volt\autoexec`. Every time you join Delve it waits for the game to load, then 10 seconds, then loads the latest script from this repo. It does nothing in other games. Turn on **Auto Farm** in the Farm tab and it will start your stage from the hub on its own.

## Screenshots in Discord posts
Roblox scripts can't take screenshots, so a small helper on your PC does it. The script drops a "job" file in your executor's `workspace\DelveWebhook` folder when a run ends; the helper sees it, screenshots your main monitor and posts it to Discord with the run stats.

1. In Discord: Server Settings → Integrations → Webhooks → New Webhook → pick the channel → **Copy Webhook URL**.
2. In the script's **Webhook** tab: paste the URL, turn the webhook on, and press **Send test**.
3. Download `delve_webhook_helper.ps1` and `Start Delve Screenshots.bat` into the same folder (with Volt they're already in `%LOCALAPPDATA%\Volt\scripts`).
4. Double-click **Start Delve Screenshots.bat** and leave that window open (minimised is fine) while you play. Close it to stop.

Without the helper, runs are still posted, just without a picture. If Windows asks about running the file, choose **More info → Run anyway** (it's a plain text script you can open in Notepad). Manual start instead of the .bat:
```
powershell -ExecutionPolicy Bypass -File .\delve_webhook_helper.ps1
```
