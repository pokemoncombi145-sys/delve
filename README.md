# Delve Brain

An auto-farm for the Roblox game **Delve** that learns from every run: it mines, fights, dodges, picks relics, and keeps adjusting from what worked and what got it killed.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/pokemoncombi145-sys/delve/main/delve_v3.lua"))()
```

Current version: **v5.21** (shown in the window title, `Delve v5.21 | Brain`). Every change, with the evidence behind it, is in [CHANGELOG.md](CHANGELOG.md).

Made for the **Volt** executor at 1920x1080; it falls back to the virtual input manager for anything an executor lacks.

## What it does
- **Auto Farm.** From the hub it clicks GO MINE!, scrolls to your stage (Delve or any mine), selects it and descends. **Play again when a run ends** repeats it.
- **Mining.** Mines every ore (needed to progress). When the floor starts collapsing, ores near the collapse are mined last and holes in the floor are walked around. Pillars are mapped per floor and routed around.
- **Combat.** Fights mobs that are close or threatening, bosses, and floors that need mobs dead ("2 MOBS LEFT"), searching the room for the ones it can't see yet. Below 10 s on the Delve timer it ignores mobs except those right next to you. Mob types that have killed you 3+ times, and shooters or long-reach mobs that are actively a threat, are taken out first.
- **Dodging.** Rolls out of attack zones (or walks, when walking is fast enough), rolls on a mob's learned wind-up, dodges past an enemy (behind or beside it) to keep hitting it, and keeps the roll for defence in boss fights and right after a hit. Every attack type learns its own safe distance and roll timing. Where there is no tile floor (the Arena) or no safe tile, it scans the real floor for open ground away from walls and rolls there only when walking is too slow; one-hit runs (Glass Soul) roll sooner.
- **Bosses.** Recognised by the game's flag, the CONTRIBUTION panel, the boss intro card or by name (e.g. THE WORLDHEART, THE UNMAKER). The prestige level is read from the depth label and recorded with the run. Lava (burning floor) is avoided, and never crossed when one tick could kill you. It measures how much damage the boss really takes, goes for the things that make it vulnerable (Heart Pylons) along a route around hazards, never walks into an attack zone to chase, and keeps its distance at low HP.
- **Relics.** Reads every draft, trader, blessing and fork, and picks by priority:
  1. a second chance you don't have yet;
  2. luck and drop quantity;
  3. mining power/range, weapon power/range, swing speed and area (AOE) effects;
  4. survivability and floor time.

  Manageable downsides on luck relics count half. Everything is adjusted by what it learned from past runs (per relic, per combo, per category), and it builds the sets you already have going.
- **Paths.** Tunnel forks are chosen by how the run is going; after Worldheart it takes **Descend** (or Ascend, your choice), and relic picks then favour combat boosts on Descend (unless the run is short on mining or a massive mining relic shows up) or mining power/range on Ascend, and after the Unmaker it walks into the **Prestige** portal as soon as its sign appears (or the **Rare shop (?????)** portal, where Vesper buys Mythic/Forsaken items for Strange Orbs; the script never sells there, or neither).
- **Index, Stats and Equipment.** Every few runs it returns to the hub and scans the T menu there (with "in progress / finished in" notices) to learn drop odds, your gear and your lifetime stats, then starts the next run.
- **Discord.** A Run Complete post with the end-screen screenshot and real stats, alerts with a screenshot for Mythic-or-higher drops (including Forsaken and Eternal), and an optional ping.
- **Learning curve.** A graph window (Brain tab) for Delve and Mines separately: the last 100 runs, a 10-run average, and the last 50 runs against the 50 before.
- **Autosave.** Settings and everything learned are saved and restored; the brain file is backed up automatically.

## Tabs
| Tab | What's there |
|---|---|
| Farm | farm switch, Auto Farm stage, play again, start the stage now |
| Mining | mining, walking, chests, reach and radius, ranges |
| Combat | fighting, chasing, dodging, mob priority, timer danger zone, attack rolls |
| Relics | relic picks, exploring, tunnel forks, after Worldheart, traders |
| Brain | T-menu scans, learning curve, reasoning, what it learned |
| Discord | webhook, screenshot delay, drop posts, ping user ID |
| Settings | window, pop-ups, danger map, background mode, tool slots, logs |

## Load automatically (Volt auto-execute)
Put `delve_autoexec.lua` in `%LOCALAPPDATA%\Volt\autoexec`. Every time you join Delve it waits for the game to load, then 10 seconds, then loads the latest script from this repo. It does nothing in other games. Turn on **Auto Farm** in the Farm tab and it starts your stage from the hub on its own.

## Discord posts and screenshots
1. In Discord: Server Settings → Integrations → Webhooks → New Webhook → pick the channel → **Copy Webhook URL**.
2. In the script's **Discord** tab: paste the URL, turn posting on, and press **Send test post**.
3. Optional: put your Discord user ID in **Discord user ID to ping** to get pinged on Run Complete, rare drops, and if you disconnect or Roblox closes while farming (no bot needed; the Roblox-closed ping needs the screenshot helper running).
4. For screenshots, keep `delve_webhook_helper.ps1` and `Start Delve Screenshots.bat` in the same folder (with Volt they're in `%LOCALAPPDATA%\Volt\scripts`), double-click **Start Delve Screenshots.bat** and leave that window open while you play.

Roblox scripts can't take screenshots, so the helper does it: the script asks for a picture the moment the end screen shows, and Auto Replay waits a few seconds for it. Without the helper, posts are sent as text. If Windows asks about running the file, choose **More info → Run anyway** (it's a plain text script you can open in Notepad). Manual start:
```
powershell -ExecutionPolicy Bypass -File .\delve_webhook_helper.ps1
```

## Files it writes (in your executor's `workspace` folder)
| File | What's in it |
|---|---|
| `DelveSettings.json` | your settings |
| `DelveBrain.json` | everything learned: relics, codex, attacks, bosses, mobs, Index, gear |
| `DelveBackups/` | the newest 8 copies of the brain file (before resets and migrations, and every 6 h) |
| `DelveRuns.jsonl` | one line per run (depth or wave, deaths, hits, rocks, XP, relics) |
| `DelveDeaths.jsonl` | the last 5 seconds before each death |
| `DelveDrops.jsonl` | one line per rare drop |
| `DelveMechanics.jsonl` | one line per new mechanic discovered |
| `DelveReasoning.txt` | why it fought, mined or picked each relic (older part in `DelveReasoning_old.txt`) |
| `dodge_log.txt` | every dodge, roll and hit, if "Log dodges to file" is on (older part in `dodge_log_old.txt`) |
| `DelveGuiDump_*.txt` | layouts of game screens, used to fix the readers |

## Safety
- It never clicks anything that says reroll, buy, R$, Robux, spin or gift.
- It doesn't change your equipment sets or sell anything.
- Logs rotate at about 3 MB, so long AFK sessions can't fill the disk.
