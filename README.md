# Delve Brain

An auto-farm for the Roblox game **Delve** that learns from every run: it mines, fights, dodges, picks relics, and keeps adjusting from what worked and what got it killed.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/pokemoncombi145-sys/delve/main/delve_v3.lua"))()
```

Current version: **v5.37** (shown in the window title, `Delve v5.37 | Brain`). Every change, with the evidence behind it, is in [CHANGELOG.md](CHANGELOG.md).

Made for the **Volt** executor at 1920x1080; it falls back to the virtual input manager for anything an executor lacks.

## Status: what has been checked in play
Every release passes a syntax and scope check (Lua parse, the 200-local limit, no unknown globals) and the file GitHub serves is compared byte for byte with the installed copies. That proves the script loads and runs; it doesn't prove a new behaviour works. This table says which features real runs have shown working, from the logs of 13 Nov 2026 (Volt, about 25 runs).

| Feature | Since | Seen working in play? | Evidence |
|---|---|---|---|
| Auto Farm loop: Play again, relic drafts, traders, shrines, forks, boss gifts | v5.x | **Yes** | 12 runs back to back from 15:00 to 19:33; 31 trader buys; Descend taken at every Worldheart fork per your setting |
| Game attack plans (MobPlan feed) | v5.30 | **Yes** | listening in every session, 5,400+ planned attacks read |
| Bullet model (Pale Warden's bullet storm) | v5.31.1 | **Yes** | in the storm the model sat 0.07-0.16 st from the bullets on screen; 10 of 17 checks since v5.33 under 0.55 st (the 7 large ones were next to Cherub / Storm Harpy attacks that fire no bullets: a quirk of the check, not a miss) |
| Boss fights (Worldheart, Pale Warden) | v5.33 | **Yes** | 5 Worldheart and 7 Pale Warden kills since v5.33 with no death to either; a logged donut was escaped straight away |
| Walking into the prestige portal after the Unmaker | v5.33 | **Yes** | 18:17: walked 80 st to the portal and prestiged (slow: 30 s) |
| Recorder (helper with `-Capture`, unattended) | v5.32.1 | **Yes** | saved clips on its own: near misses, a bullet storm and a death, each with matching logs |
| F2 stop / resume | v5.23 | **Yes** (v5.36) | after a clean rejoin one press = one action (20:42:09); before that, the portal walk ignored it and a re-run left two copies answering each press. Not yet watched through a whole pause in a run |
| Prestige detection | v5.16 | **Yes** | every prestige logged |
| Collapse guard: chest skips, ignoring mobs by the collapse front, ores ahead first | v5.34 | Not yet | new; look for `skipping a chest` and `collapse Ns: ignoring mobs` in `DelveReasoning.txt` |
| Collapse log (`session:` lines with your gap and the chamber clock) | v5.34 | Not yet | new; in `dodge_log.txt` |
| Stall watchdog (`DelveStall.txt`, "Delve: stuck" alert) | v5.33 | Not yet | never needed to fire |
| Walking without a floor map / past the last floor tile | v5.33 | Not yet | never needed |
| Discord disconnect and Roblox-closed alerts | v5.20 | Not in these logs | no disconnect or crash while farming happened |
| Index / Stats / Equipment scan every N runs | v3.8 | Not in these logs | the run count since it last ran hadn't been reached |
| Room dump after the end boss (`DelveRoomDump.txt`) | v5.35 | Not yet | the Seraph run had no dump (only the Unmaker counted); v5.36 counts both |
| No fighting at the collapse (danger time) | v5.36 | Not yet | in ore chambers only a mob on top of you is fought near the collapse; gates and bosses are always fought (v5.37) |
| Learned floors, attack patterns, shooters (relearned in v5.37) | v5.37 | Not yet | cleared once with a backup; watch for fewer "hits from range" lines and no "Learned a dangerous floor" in the hub |
| Rare shop (Vesper) portal | v5.30 | Never used | your setting is Prestige; the script never sells there |

Known open issues:
- **Deep runs end in cave-ins.** The collapse speeds up with depth, and Cursed Path adds 30% (3.7 rows/s from about chamber 66, about the bot's whole pace with mining). v5.34 is the first attempt at keeping the lead; choosing Safe Path at forks would help most.
- After a prestige the game once reported the collapse as stopped while it kept moving (58 rows), so the bot saw no danger.
- Two hits 0.4 s apart (the Elder Dragon's double ring in Infernia wave 100) can't both be covered by one roll.
- The walk into the portal is slow (about 3.5 st/s); it gets there.
- The `-269` / `-329` hits with "no planned attack" in the dodge log come from the run ending: one at the cave-in and another about 17 s later as the next run starts. They aren't missed attacks.

## What it does
- **F2** pauses everything (farm, walking, relic picks, Play again, starting a stage) so you can play yourself; F2 again resumes. **F8** saves a recorder clip.
- **Auto Farm.** From the hub it clicks GO MINE!, scrolls to your stage (Delve or any mine), selects it and descends. **Play again when a run ends** repeats it.
- **Mining.** Mines every ore (needed to progress). When the floor starts collapsing, ores near the collapse are mined last and holes in the floor are walked around. Pillars are mapped per floor and routed around. In a Delve it tracks how many seconds the collapse is behind you (the collapse front and the chamber clock): under 12 s it mines ahead first, takes no detours for chests, and only goes back for a missed ore with 3 s to spare.
- **Combat.** Fights mobs that are close or threatening, bosses, and floors that need mobs dead ("2 MOBS LEFT"), searching the room for the ones it can't see yet. Below 15 s on the Delve timer it ignores mobs except those right next to you. Mob types that have killed you 3+ times, and shooters or long-reach mobs that are actively a threat, are taken out first.
- **Dodging.** Rolls out of attack zones (or walks, when walking is fast enough), rolls on a mob's learned wind-up, dodges past an enemy (behind or beside it) to keep hitting it, and keeps the roll for defence in boss fights and right after a hit. Every attack type learns its own safe distance and roll timing. Where there is no tile floor (the Arena) or no safe tile, it scans the real floor for open ground away from walls and rolls there only when walking is too slow; one-hit runs (Glass Soul) roll sooner.
- **Bosses.** Recognised by the game's flag, the CONTRIBUTION panel, the boss intro card or by name (e.g. THE WORLDHEART, THE UNMAKER). The prestige level is read from the depth label and recorded with the run. Lava (burning floor) is avoided, and never crossed when one tick could kill you. It measures how much damage the boss really takes, goes for the things that make it vulnerable (Heart Pylons) along a route around hazards, never walks into an attack zone to chase, and keeps its distance at low HP.
- **Relics.** Reads every draft, trader, blessing and fork, and picks by priority:
  1. a second chance you don't have yet;
  2. luck and drop quantity;
  3. mining power/range, weapon power/range, swing speed and area (AOE) effects;
  4. survivability and floor time.

  Manageable downsides on luck relics count half. Everything is adjusted by what it learned from past runs (per relic, per combo, per category), and it builds the sets you already have going.
- **Paths.** Tunnel forks are chosen by how the run is going; after Worldheart it takes **Descend** (or Ascend, your choice), and relic picks then favour combat boosts on Descend (unless the run is short on mining or a massive mining relic shows up) or mining power/range on Ascend, and after the Unmaker it walks into the **Prestige** portal as soon as it sees one (the nearest, by its tag, model or sign; it walks through the ring if standing in it does nothing, and keeps walking past the last floor tile until a portal is in sight), or the **Rare shop (?????)** portal, where Vesper buys Mythic/Forsaken items for Strange Orbs (the script never sells there), or neither.
- **Index, Stats and Equipment.** Every few runs it returns to the hub and scans the T menu there (with "in progress / finished in" notices) to learn drop odds, your gear and your lifetime stats, then starts the next run.
- **Attack plans and rooms.** Listens to the game's own attack plans (what lands where, and exactly when) so escapes and roll landings are checked against the moment you'd be there (it leaves a spot that gets hit in the next 2.2 s straight away, so big rings like the Worldheart's donut are walked out of in time), and reads the chamber layout so "forward" is always the current chamber's exit.
- **Never stands still for long.** If it hasn't moved and nothing has changed for 25 s while farming a Delve, it writes down what it was doing (`DelveReasoning.txt`, `DelveStall.txt`), skips the ores there and walks on; still stuck after 3 minutes, one Discord alert.
- **Discord.** A Run Complete post with the end-screen screenshot and real stats, alerts with a screenshot for Mythic-or-higher drops (including Forsaken and Eternal), and an optional ping.
- **Learning curve.** A graph window (Brain tab) for Delve and Mines separately: the last 100 runs, a 10-run average, and the last 50 runs against the 50 before.
- **Autosave.** Settings and everything learned are saved and restored; the brain file is backed up automatically.

## Tabs
| Tab | What's there |
|---|---|
| Farm | farm switch, Auto Farm stage, play again, start the stage now |
| Mining | mining, walking, chests, reach and radius, ranges |
| Combat | fighting, chasing, dodging, mob priority, timer danger zone, attack rolls, rolls through bosses, the game's attack plans, keep walking up the road |
| Relics | relic picks, exploring, tunnel forks, after Worldheart, traders |
| Brain | T-menu scans, learning curve, reasoning, what it learned |
| Discord | webhook, screenshot delay, drop posts, ping user ID |
| Settings | window, font, pop-ups, danger map, background mode, tool slots, logs, "Check forward goal + attack plans" button |

## Load automatically (Volt auto-execute)
Put `delve_autoexec.lua` in `%LOCALAPPDATA%\Volt\autoexec`. Every time you join Delve it waits for the game to load, then 10 seconds, then loads the latest script from this repo. It does nothing in other games. Turn on **Auto Farm** in the Farm tab and it starts your stage from the hub on its own.

## Game settings (Settings > Gameplay)
| Setting | Use | Why |
|---|---|---|
| Attack color | **RED** (don't change) | Safe spots inside attacks are told apart by colour, and every learned attack is stored by its colour. Another colour can make red attack centres look safe and throws away what it learned. |
| Camera angle | **TOP-DOWN** | What the script was built and tested with (aim, screenshots). |
| Low GFX camera | OFF | Not tested with the script. |
| Rune popups | **ALL** | Rare-drop posts read the "1 in N" pop-ups. (Forsaken also come through chat.) |
| Mob HP bars | 5 NEAREST or ALL | Mob health is read from the game, not the bars. 5 NEAREST = more FPS. |
| Damage numbers | any | Not read by the script. Fewer = more FPS. |
| Hide flying items / other players / XP popups | ON is fine | Not read by the script, more FPS. |
| Mob ghosts | any | Not read by the script. |
| Name tag, Inventory tiles, Block party invites | any | Not used. |
| Auto sell ores | your choice | The script never sells anything itself. |

## Discord posts and screenshots
1. In Discord: Server Settings → Integrations → Webhooks → New Webhook → pick the channel → **Copy Webhook URL**.
2. In the script's **Discord** tab: paste the URL, turn posting on, and press **Send test post**.
3. Optional: put your Discord user ID in **Discord user ID to ping** to get pinged on Run Complete, rare drops, if you disconnect or Roblox closes while farming (no bot needed; the Roblox-closed ping needs the screenshot helper running), and if the bot has been stuck in place for 3 minutes.
4. For screenshots, keep `delve_webhook_helper.ps1` and `Start Delve Screenshots.bat` in the same folder (with Volt they're in `%LOCALAPPDATA%\Volt\scripts`), double-click **Start Delve Screenshots.bat** and leave that window open while you play.

Roblox scripts can't take screenshots, so the helper does it: the script asks for a picture the moment the end screen shows, and Auto Replay waits a few seconds for it. Without the helper, posts are sent as text. If Windows asks about running the file, choose **More info → Run anyway** (it's a plain text script you can open in Notepad). Manual start:
```
powershell -ExecutionPolicy Bypass -File .\delve_webhook_helper.ps1
```

## Recorder (optional, local)
Start `Start Delve Screenshots.bat`; after 8 s it starts the recorder on its own (press **1** for the plain helper). It works unattended: it keeps the last few seconds of your screen in memory and saves 5 s before and 2 s after to `DelveCaptures\<date>_<time>_<reason>\` in the Volt workspace on every death, hits during boss fights or planned attacks, every bullet storm, near misses, and when you press **F8**. The newest 40 clips are kept. Keep Roblox visible on the main screen while you're away.
- `index.html`: step through the frames; log lines near each frame are highlighted
- `summary.txt`: nearest planned shot (spawn time, boss position at spawn, start point used), your position at the HP loss, the drawn bullet next to you and how far the model was from it, roll / server dodge
- `logs.txt`: dodge and reasoning log lines on the same time line, `impact.json`: the raw record, `death_blackbox.json` on deaths

Nothing is uploaded, and the recorder never affects movement or dodging. Options (edit the .bat): `-Fps 8 -Scale 0.6 -Quality 70 -PreMs 5000 -PostMs 2000 -Keep 40`.

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
| `DelveStall.txt` | the latest "standing still" report: what it was doing, the floor, the portals it can see, the last decisions |
| `DelveRoomDump.txt`, `DelveRoomDump_portal.txt` | what the room after the end boss (Unmaker or Seraph) is made of (floor, portals, parts within 200 st), written after its reward and when a portal walk fails |
| `DelveGuiDump_*.txt` | layouts of game screens, used to fix the readers |

## Safety
- It never clicks anything that says reroll, buy, R$, Robux, spin or gift.
- It doesn't change your equipment sets or sell anything.
- Logs rotate at about 3 MB, so long AFK sessions can't fill the disk.
