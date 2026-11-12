# Delve v3

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/pokemoncombi145-sys/delve/main/delve_v3.lua"))()
```

Current version: **v4.0.2**. See [CHANGELOG.md](CHANGELOG.md) for what changed in each update.

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

## Screenshots in Discord posts
Keep this running on your PC while you play:
```
powershell -ExecutionPolicy Bypass -File .\delve_webhook_helper.ps1
```
