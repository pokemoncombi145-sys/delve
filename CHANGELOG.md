# Changelog

Newest first. The version is shown in the script window title (`Delve v5.9.1 | Brain`).

## v5.9.1: Fix ":4369 attempt to perform arithmetic (add) on number and boolean"
- Since v5.5 the wind-up dodge read the mob's wind-up time from a line that ended with a boss-fight check, so outside boss fights the "time" was `true` instead of a number and `windupAt + true` errored. While the error repeated, the early (wind-up) dodge never ran, which also fits the hits that only got a roll afterwards. The time and the boss check are now separate.

## v5.9: Equipment set switching removed
- Removed everything that changed equipment sets through the T menu: set switching in and between runs, selling ores with set 3, and the per-set race check. The Gear tab and its settings are gone. Switching through the menu wasn't reliable (swap cooldowns, no swaps mid-run), so this waits until the game adds hotkeys for sets.
- Kept: the Index/Stats/Equipment scan (which still reads your worn race and its perks), the click safety fixes from v5.8.2, and the v5.8.3 fixes (real bosses only, no rolls right after a hit, shorter attack rolls).

## v5.8.3: Fixes from the first v5.8.2 session (not yet verified in gameplay)
**What the logs showed:** after the race check, set 3 and set 1 failed ("timed out") so the damage set stayed on while mining; both in-run switch attempts found the set swap on cooldown; all 9 attack rolls targeted mobs 25-28 st away (learned roll distance at its 20 st cap); 4 of 5 hits were followed 20-80 ms later by a roll; and normal mobs (Ghoul, Rockback, Mummy, Yeti) were treated as bosses, saving 340 m and 880 m as boss floors.

| Change | Why |
|---|---|
| Only real bosses (the game's boss flag, the HUD or the stage name) count as a boss. A mob with 5x the others' health is still fought ("big mob") but isn't a boss. Boss floors learned with the old rule are cleared (brain backed up first). | The loose rule switched sets, marked normal floors as boss floors, disabled attack rolls and blocked wind-up dodges against every other mob. |
| No strike roll or zone roll within 0.3 s after you were hit by it. Wind-up dodges are no longer blocked by a false "boss". | Rolling after the damage landed only wasted the roll and its invincibility. |
| Roll distance measured 0.3 s after the roll (was 0.45 s, which included walking), capped at 12 st and re-learned. Attack rolls only target mobs within about 12 st. | Rolls toward mobs 25-28 st away pulled it off the ores. |
| In the hub, a set switch waits up to 20 s for the game's swap cooldown (was 8 s). Switching sets during runs is paused, with a new Gear tab toggle "Switch sets during runs (experimental)" to try it. | The race check swapped sets back to back and timed out; in-run swaps were always on cooldown. |

**How to check:** no "strike roll" right after a "hit" in `dodge_log.txt`; no attack roll above 12 st; "set 3 completed" in the race check; only real bosses (e.g. Worldheart) in "boss" lines. To test in-run swaps: during a run press "Switch to set 1" in the Gear tab; if the log says "set swap on cooldown", the game blocks it mid-run.

## v5.8.2: Two gaps in the v5.8.1 safety fixes (from code review; not yet verified in gameplay)
- **Queued attack roll at a boss start.** A roll queued just before a boss appeared could still fire, because the queued roll ran before the boss check. Now a boss fight cancels any queued attack roll (and its lean toward the target) first, and right before spending a queued roll it re-checks for an incoming attack, a mob windup and a predicted boss attack; if any is present the roll is cancelled and kept for defence.
- **Set clicks after it became unsafe.** The click helper could keep retrying (events, virtual mouse, real mouse, each with a wait) without re-checking safety or the 8 s limit. It now takes an abort check that runs before every attempt and while waiting; set switches during runs stop as soon as it becomes unsafe or the deadline passes ("became unsafe while clicking" / "timed out while clicking"). Opening the Equipment tab uses the same check.

## v5.8.1: Priority 1 safety fixes (not yet verified in gameplay)
- **Safe set switching in runs.** The T menu is only opened when no attack is incoming, you aren't standing at a hazard, and no enemy is within striking distance (10 st, or its learned reach + 4). Safety is checked again right before clicking. If it isn't safe, the switch is skipped (logged at most every 10 s) and retried when it is; it is never forced.
- **Switch at floor starts.** Floors where a boss appeared are remembered (`bossFloors`), so set 2 goes on at the start of that floor next time instead of mid-fight.
- **Bounded switch with recovery.** Each switch has an 8 s limit. The menu is always closed if the switch opened it (T, then the menu's own dismiss as a fallback), also after errors. A failed switch marks the active set as unknown and backs off 30 s (up to 120 s) before trying again. Selling only proceeds when set 3 was confirmed by the switch, and the menu is closed after selling even on error.
- **Switch log.** Every switch is logged as attempted, completed (with duration), skipped (with the reason it wasn't safe) or failed (with why and the button colours). Counts are kept for the run reports.
- **No attack rolls in boss fights.** Offensive rolls are off while a boss is up; defensive rolls are unchanged, and race roll perks (Onibi Step, Flame Dash…) still trigger on them.
- **Brain backups.** `DelveBackups/DelveBrain_<date>_<reason>.json` before any migration or reset, and on load at most every 6 hours. The newest 8 are kept.

## v5.8: Scan notices
- Everything that takes a while now pops up "... in progress" when it starts and "... finished in 12.3 s" (or "1m 05s") with a short result when it ends: the Index/Stats/Equipment/Races scan, the per-load race check ("2 of 3 sets confirmed"), selling ores ("Sold +$1,733,355,148") and the mining stats scan you start yourself. Durations are also written to the reasoning log. Quiet automatic re-reads during runs stay quiet.

## v5.7.1: Race details captured once
- During the race check, a race's perks are read only the first time it's worn; races already captured are skipped (logged as "perks already known").
- Races you showed are pre-filled so they don't need visiting: Andros, Olympian, Dactyl, Titan, Dryad and Hydra (complete), plus Shura and Drakon (partial; the rest is read the first time they're worn). Races you don't own are never needed: the dropdown per set decides which races are used.

## v5.7: Race per set, checked once
- Gear tab: a **race dropdown for each set** (set 1 mining: Drakon, set 2 damage: Shura, set 3 selling: Drakon by default; "Don't change" skips a set). Shiny versions (e.g. "Shiny Dactyl") match too.
- **Once per load, in the hub, before the first run:** it switches to each set, makes sure that set wears its race (Races > slot > WEAR, confirmed by "(WORN)"), reads the race's perks, then goes back to set 1. Auto Farm waits for this check before starting a run.
- It **never opens Races during or between runs** after that. Selling no longer changes races (set 3 already has its race).
- Attack rolls know each set's race: switching to set 2 mid-run turns on Shura's roll perk (Onibi Step); Drakon has Flame Dash, Olympian Radiant Dash. Perks read from the race page replace these defaults.

## v5.6: Equipment sets, auto-sell, races
New **Gear** tab. Uses the game's own equipped-item sets (T menu > Equipment > Equipped Items **1 / 2 / 3**), checking the set's button turned green after each switch.

- **Set 1 (mining)** is the default in runs. **Set 2 (damage)** goes on for boss fights, and on any floor where mobs land 4+ hits within 30 s (for a minute). It switches at most once every 20 s, and the reason is logged.
- **Set 3 (selling)**: every 5 runs (adjustable), between runs: set 3 > Backpack > Sell items > Ores > Select all > Accept, then it reads the "+$…" amount, logs it and goes back to set 1. It only sells from the Backpack's ore screen (never the Equipment tab's sell), and stops if the total is $0 or set 3 isn't confirmed green.
- **Races (hub only)**: wears the set's race between runs (set 1: Drakon, set 3: Drakon for selling, editable) via Races > a slot > the race page's WEAR, confirmed by "(WORN)". While there it reads that race's perks (so attack rolls know about roll perks like Onibi Step / Flame Dash). It refuses to click anything that says reroll, buy, R$, Robux, spin or gift.
- First visit saves the race page layout to `DelveGuiDump_racepage.txt`.
- Gear tab buttons: **Sell ores now**, **Switch to set 1 / 2 / 3**.

## v5.5: Learning audit, stage 2 (Worldheart)
**Evidence:** 6 of 8 recorded deaths are Worldheart at 9,060 m. In 5 of 6, the script switched to a Heart Pylon 33-100 studs away, crossed the arena, got stuck, and was one-shot (268-380 damage vs 230-264 max HP) with no roll. In the latest one the roll fired 90 ms after the hit.

| Change | Why |
|---|---|
| A priority target (pylon, learned add, still mob) more than 12 studs away is only chased when the straight way there is free of attack zones, burning floor and void. Otherwise it holds safe ground and fights what's near, and goes when the way is clear (logged as "holding safe ground"). | The deaths came from the crossing, not from fighting the pylon. |
| In a boss fight, small mobs' swings no longer use up the roll, and zone rolls start 0.08 s earlier. | The killing blows landed with no roll, or just before it. |
| "Did killing that add help?" needs 1.5 s of boss damage (was 2 s) with half the samples hitting (was 70%), measured over 6 s after the kill (was 4 s). | The verdict was never reached for Heart Pylons. |
| Death black box: a small sample every 0.25 s (HP, position, mode, target and distance, zones you're in, roll ready, timer, stuck count) for the last 5 s, written to `DelveDeaths.jsonl` only when you die. | So every death can be explained from data, not guessed. |

## v5.4.1: Stage 1 check-up (2 runs on v5.4)
**What the v5.4 logs showed**
- Floor mapping fixed: "floor mapped" about once per floor (64 lines) instead of 13,126; only 1 stuck event outside the boss fight, against 16 in a row before.
- Attacks are now learned separately: 28 distinct attack types seen in the Worldheart fight instead of 1.
- Learned values are sane: i-frames 0.35 s, roll timing within 0.05 s, sword reach 11.9 st (was 119).
- Boss-add learning now reaches verdicts (killing a Void Shade didn't help Worldheart damage).
- New best depth: 12,660 m.

**Fixed**
- "Hits not landing, moving closer" fired on almost every new target (its timer carried over from the previous target), so the fighting distance was pinned 4 studs short. The timer now restarts per target, the adjustment is capped at 2.5 studs, and it wears off when not fighting.

## v5.4: Learning audit, stage 1 (fix the learning data)
Based on an audit of 30 runs, the brain file, ~15,000 reasoning-log lines and the dodge log. No new features; this makes the existing learning trustworthy.

| Problem found | Evidence | Change |
|---|---|---|
| Every attack shared one learning bucket | nearly all hazards are named `Hazards/Part`; that bucket sat at its caps (+2.84 st, roll 0.35 s early) | Attacks are fingerprinted by shape, size class and colour, so each type learns separately. Old attack and boss-pattern data reset. |
| Dodge timing only moved one way | roll timing at its cap despite 157 clean dodges; i-frame estimate stuck at the 0.6 s cap | Clean dodges ease timing back; a hit inside the roll shortens the i-frame estimate; i-frames move slowly instead of ratcheting; a missed roll only counts when the roll was ready and the attack was visible in time; every attack lesson fades 10% per run. |
| Relic category weights all at the 2.5 cap | 6 of 9 categories at exactly 2.5 | Weights are kept relative (average 1), so they keep telling categories apart. Reset. |
| Quick exits taught it wrong lessons | runs of 38-64 s at 340-550 m counted as bad runs (z -1.7 to -2.5) | Only runs that died, showed a results screen or lasted 2+ minutes teach it. Each run is compared with your last 20 real runs at similar gear power, not every run ever. Replaying the 30 runs: deep runs now range 1.1-2.1 instead of all hitting the 2.5 cap. |
| Pillar blocks still wiped | "floor mapped" logged 13,126 times | The floor map is tied to the floor (run id + depth); it rebuilds at most once a second, and blocked pillars are kept until the next floor. Pillars are scanned once per floor. |
| Sword reach learned as 119 studs | proc/lightning damage counted as sword hits; "hits not landing at 187 st" | Only hits within believable sword reach count (max 20 st), "not landing" only within fighting distance, bad value reset. |
| Boss "predictions" forced bad moves | 591 forced "step out" moves from the lumped attack data | Pattern-based pre-moves paused; the roll is only held for a prediction seen 5+ times that comes true 60%+ of the time. |

Kept as-is: saved learning across restarts, relic learning with confidence weighting, relic/draft reading, depth fix, death-screen reader, reasoning log.

## v5.3: Stationary boss mechanics
- While a boss is up, any other "mob" near it that hasn't moved for 3 seconds (pylons, totems, crystals) is treated as part of the boss mechanic and attacked first. A pop-up and the reasoning log say which one.
- Priority order: adds learned to make the boss vulnerable > stationary things > anything else when the boss is shielded. If killing a stationary thing turns out not to help, the boss study learns that and stops prioritising it; it also gives up on one after 25 s in case it can't be destroyed.

## v5.2: The real pillar bug, close mobs (from the v5.1 logs)
**What the logs showed:** "floor mapped: 6 pillars" was logged several times a second. The game refreshes the floor tile list constantly, and every refresh rebuilt the map from scratch, which **wiped every blocked pillar**. So it pushed into the same pillar 16 times in a row until the timer hit 0:00 and the tunnel caved in. This is also why the older unstick fixes never stuck.

**Fixed**
- The floor map (and the pillars blocked on it) is only rebuilt when the floor really changes (different size or position). Pillars found on a floor stay blocked for that whole floor. This also removes a constant rebuild that cost performance.
- If it gets stopped at the same spot 3+ times, it backs off at an angle before routing again.
- **Mobs right next to you are always fought** (within your circle distance, 5-9 studs), even in the timer danger zone, then it goes straight back to mining.

## v5.1: Pillars and chests (from the v5.0 logs)
**What the logs showed:** every "detour" around a pillar was 1 tile long (it aimed a few studs ahead instead of at the chest/ore), so it walked straight back into the same pillar up to 8 times in a row. The mining-stat re-read also fired every 2-3 s because buff counters like "BLOODRUSH 3/10" kept changing, which caused the "Delve stats" pop-up spam.

**Fixed**
- **Pillars are mapped per floor.** When a floor loads it finds the tall solid parts standing on it (pillars, posts, stalls) and blocks their tiles for the whole floor. Chests, ores, rocks and mobs are never blocked.
- **Walking to chests and ores routes around pillars.** If a blocked tile is on the straight line, it follows a path over the floor tiles to the actual chest or ore.
- **If it still gets stuck,** it finds the exact part in the way, blocks it for the rest of the floor and routes to the real target (not a point a few studs ahead).
- **Chests after a fight:** chest walking uses the same pillar-aware route, so it reaches the chest after the boss/mobs die.
- Mining range is re-read only when a range/radius/reach buff actually changes, and the "Delve stats" pop-up no longer shows for those automatic re-reads.

## v5.0: Boss study, reasoning log, unsticking, live ranges
**Boss study (live)**
- Measures how fast the boss really loses HP while you hit it, compared with your normal damage on other mobs. If the boss is barely taking damage (Worldheart with its Heart Pylons up), it switches to the other targets on the field first.
- Learns which adds make a boss vulnerable: when killing one makes boss damage jump, that add is a priority target for that boss in every later run (and one that doesn't help is dropped).

**Reasoning log**
- `DelveReasoning.txt` in the Volt workspace explains every decision: why it's fighting or mining (boss, mob stage, threat distance, timer danger zone…), which target and why (priority boss mechanic), the full score breakdown of every relic draft and why it picked, forks, traders, boss findings, getting stuck, range changes.
- Brain tab: **Show recent reasoning (combat + relics)** shows the last lines.

**No more getting stuck on pillars**
- When it stops moving against something, it blocks that spot for longer (8 s, more each time it gets stuck at the same place, and the tiles beside it from the 2nd time) and walks a detour over the floor tiles around it, instead of walking straight back into it.

**Ranges adapt live**
- **Mining:** whenever ACTIVE BUFFS change (new relic, blessing, "+50% MINING RANGE"), it re-reads the game's live mining range and radius.
- **Sword:** it learns the farthest distance your hits actually land at (per sword, saved), so range relics let it fight from further out; if swings stop landing, it moves closer until they do.

## v4.9.1: Mythic drops to Discord
- Drop alerts (pop-up and Discord, with a screenshot when the helper runs) now go out for **Mythic tier or higher**, whatever the odds (e.g. Moonlit Glowcap, Mythic, 1 in 6,000). Lower tiers are no longer posted.
- Drops that show no tier (from chat) still count at 1 in 100,000 or rarer.

## v4.9: Danger learning, boss patterns, perfect dodges, correct depth
**Learns every attack type**
- Each attack zone gets a signature (what kind of attack it is). A hit inside it gives that attack type more room and adjusts its roll timing; a death gives a much bigger push. Similar attacks are respected from then on. Clean dodges relax it again so it doesn't get over-cautious.
- **Perfect dodges:** it learns how long the roll's invincibility lasts and, per attack type, whether rolls came too early (hit after the i-frames ended: roll later) or too late (roll earlier), so the roll lands right as the attack hits.

**Boss mechanics**
- **Ring attacks:** a small circle inside a big boss circle is treated as the safe spot, so it moves in close to the boss instead of running for the edge. If it still gets hit in there twice, it stops trusting that ring for that attack.
- **Boss attack patterns:** for each boss it records which attack comes after which and how long after. Live in the fight it predicts the next attack: it keeps the roll ready, steps into the safe ring before a ring attack, or steps out before a big circle centred on the boss.
- **"YOU DIED TO <boss>"** is read from the death screen; that boss's last attack gets extra room next time.

**Dangerous floors**
- Damage with no attack or mob to explain it (lava strips, glowing floor) marks the kind of floor you stood on. After 2 such hits it's avoided like an attack zone. Standing on it safely un-learns it.

**Relics**
- A clearly better relic beats set chasing: if another card is 35+ points better on its own, the set card loses its set bonus (keeps half if it would complete the set).

**Depth and run score**
- Fixed depth with commas ("9,060 M" read as 9 or a checkpoint like 880 m). The run uses the deepest of the results screen, player list and HUD.
- A new personal best depth gets extra credit, so relics and choices from your best runs are learned as the good ones.

**Discord**
- Rare drop posts already include a screenshot when the helper runs; the helper now checks 4 times a second so the drop is still on screen. Restart `Start Delve Screenshots.bat` to get this.
- Brain tab: **Show danger learned (attacks, floors, bosses)**.

## v4.7: Smarter relic priorities
- **Reads ACTIVE BUFFS** (right side of the screen) during runs: sets in progress ("1/4 STORM", "1/5 FROST") and the effects you already have.
- **Relic order of importance:**
  1. **Second chance** (revive, cheat death, survive a fatal hit, extra life…): big bonus when you don't have one yet, small one if you already do.
  2. **Weapon power, mine power, swing / attack speed:** 1.6x weight.
  3. **Survivability and more time** (max health, damage taken, heals, shields, rows of time, slower collapse): 1.35x weight.
- **Builds your sets:** a relic from a set already on the right side gets a bonus that grows with progress, plus a large bonus when it completes the set.
- Everything learned from past runs (how each relic, combo and effect did) still adds on top.
- Fixed: hidden leftover text on relic cards (e.g. a hidden "+30%") was counted as an effect, and set labels like "ASSASSIN 2/2" weren't read.

## v4.6.1: Tool switching fixed
- **Fixed: it stopped switching between pickaxe and sword** (stood at ores holding the sword, at mobs holding the pickaxe). The v4.5 attack-roll code reused the name of the tool-switch function, so the tool switch never ran. Renamed; switching works again.
- **Floor goals in the depth line** ("DEPTH 340 M - 1 MOB LEFT") are now read, so it fights the remaining mobs on floors that need them dead, even under 10 s on the timer.

## v4.6: Game font in the window
- The script window now uses the game's own pixel font for every label, button and text box (read from the game's HUD, the same font as the pop-ups). Elements added later get it too.
- Setting: **Use the game's font in this window** (Settings tab). Turning it off puts the original font back.

## v4.5: Auto Farm, cleaner UI, game-style pop-ups, attack rolls
**Auto Farm (Farm tab)**
- **Auto Farm: start a stage from the hub.** Pick a stage (Delve, Grasslands, Sun Flats, Frostbite, Mycelia, Pirates Cove, Infernia, The Abyss) or type another name. In the hub it clicks **GO MINE!**, scrolls the stage list left or right to your stage, selects it and clicks **CLICK TO DESCEND** (for Delve it clicks the Delve panel). The farm switches on once the run loads.
- Locked stages ("LEVEL 60 TO ENTER") are skipped for 5 minutes. **Start the stage now** button.
- The first time, the GO MINE layout is saved to `DelveGuiDump_gomine.txt`.

**Auto-execute**
- New `delve_autoexec.lua` for Volt's `autoexec` folder: only runs in Delve, waits for the game to load plus 10 s, then loads the script.
- The window now starts **closed** (Right Shift or **Open Delve** shows it). Setting: **Start with this window closed**.

**Cleaner UI**
- 10 tabs down to 7: **Farm, Mining, Combat, Relics, Brain, Discord, Settings**. Duplicate and tuning-only settings are gone; the learning and safety features they controlled are built in and always on (relic learning, dodge learning, tile pathfinding, corner avoidance, windup learning, ping compensation, sword range detection).
- Removed rarely useful test buttons.

**Pop-ups**
- New game-style pop-ups bottom-right: the game's own pixel font, dark card, coloured title by type (drops gold, relics blue, traders/farm green, paths teal, discoveries purple, errors red). Up to 5 stacked, click to dismiss. Setting: **Game-style pop-ups**.

**Combat: attack rolls**
- Reads your race and perks from the **Races** tab during the T-menu scan (e.g. Shura: Onibi Step II, "your roll drops 3 spirit flames that hunt the nearest mobs").
- When your race has a roll perk, it rolls **into** the target whenever nothing is about to hit you. The roll is kept for dodging while an attack zone or windup is up, and it never rolls off the map or into a hazard. The roll distance is learned from real rolls. Setting: **Attack rolls** (Auto / Always / Off; Always without a perk only uses it to close the gap).

**Drops**
- Only drops of **1 in 100,000 or rarer** are announced (pop-up and Discord). Adjustable: **Rare drop = 1 in at least**.

## v4.4: Learns new mechanics
- **Mechanic discovery.** The brain now notices anything new the game shows and remembers it:
  - **rooms** from the relic window header (Pick a relic, A Trader in the Dark, The Tunnel Forks, A Blessing Shrine, and any future ones);
  - **card types** (Rare, Blessing, Trader, Next 5 rooms…);
  - **effects** it can't classify by keyword (for example "Sword lightning, 3 mobs");
  - **floor objectives** shown next to the delve timer;
  - **new screens** the game opens. The layout of a new screen is saved to `DelveGuiDump_new_<name>.txt` so it can be supported properly.
- **It learns from them.** Every run where a mechanic showed up feeds its score (how that run went compared to your average). Effects it doesn't understand are then valued by those results when they come up on a card again.
- A pop-up announces each new discovery (toggle: **Announce new mechanics found**), they're logged to `DelveMechanics.jsonl`, and the Run Complete post lists **New mechanics found**.
- Brain tab button: **Show mechanics learned**.
- **Start Delve Screenshots.bat**: double-click to run the Discord screenshot helper. README has step-by-step setup.

## v4.3: Delve timer danger zone, forks, blessings
- **Floor timer.** Reads the delve countdown under DELVE ("0:30"). At **10 s or less** it stops chasing mobs and spends the time on ores, unless the floor needs mobs dead (boss, guardian, or an objective like slay / kill / defeat / clear / elites). Adjustable: **Delve timer danger zone** slider (0-30 s, Targeting tab).
- **Tunnel forks** ("THE TUNNEL FORKS"). Smart mode takes the **Cursed Path** (+luck, more elites) when healthy, and the **Safe Path** (slower collapse) when HP is under 70%, you're taking lots of hits, the timer got under 10 s twice this run, or past runs show the cursed path going badly. Setting: **Tunnel fork path** (Smart / Safe / Cursed).
- "-15% COLLAPSE" now counts as good (slower collapse); it used to score as a minus.
- **Blessing shrines** are picked like relics, ranked by what each blessing does.
- **Rare drop spam fixed.** Each rare item alerts (pop-up and Discord) once per run; repeats are counted. The Run Complete post lists **Rare drops** with totals (e.g. Emerald x6) and **Timer close calls**.
- The first time a delve timer is seen, the HUD layout is saved to `DelveGuiDump_hud.txt` so floor objectives can be read exactly.

## v4.2: Second relic slides and traders
- **Second slides.** Deeper runs show a new set of relics right after the first pick, in the same window. It used to count as the same draft (same card slots and tiers) and nothing was picked. Each card's name is now part of the check, so every new slide gets picked too.
- **Traders** ("A TRADER IN THE DARK"). Trader cards (tier "TRADER", "RARE RELIC") are now recognised, with their price. It buys the best offer if it scores at least the **Trader: only buy if score is at least** setting (default 5), then the next worthwhile one, and presses **WALK ON BY** when nothing is left worth buying. A buy that doesn't go through after 6 tries (for example, not enough cash) is skipped.
- New Brain/Relic settings: **Buy from traders (else walk on by)** and the trader minimum score.
- Cards are read straight from the relic window's layout (`Panel > Main > CardN`), so it's faster and doesn't depend on tier words.

## v4.1: Scan every 10 runs
- The Index / Stats / Equipment scan no longer runs on every launch. It runs **after every 10 finished runs** (mine or delve), between runs, and the very first time if it has never scanned.
- New Brain tab slider: **Scan every this many runs** (1-50, default 10). The **Scan Index + Equipment now** button still scans whenever you want.
- The run counter is saved in the brain, so it carries over between sessions.

## v4.0.2: Skip items already scanned
- Items studied before are never clicked again. v4.0 would have re-studied all 177 once to clear the FIELD STONE bug; instead the bad row is now removed from the saved data in place (from 176 items; STONE keeps it because Field Stone really drops it), and those items count as done.
- The Index grid is read in one pass when all tiles are already loaded. It only scrolls through the list if tiles are missing, so a launch with nothing new finishes in seconds.
- The "Scan done" pop-up shows how many items were new and how many were skipped.

## v4.0.1
- The first scan after launch now starts after **10 s** instead of 20 s.

## v4.0: Instant relic picks, works tabbed out, clean Index sources
**Fixed**
- **Relics weren't taken.** The relic layout file shows each card has two buttons: `Hit` (the whole card) and `Action` (a **TAKE** button that stays hidden until the card is selected). v3.9 clicked the hidden TAKE button. It now clicks `Hit`, then presses TAKE the moment it appears.
- **"FIELD STONE 1 in 1.4" listed under every Index item.** That was a hidden template row (`SourceRow`) in the sources list. Only the real `Row`s are read now (`Source`, `Area`, `Odds`), including ranges like "1 IN 2 - 1 IN 1". The source table is rebuilt and every item is studied again once.

**Changed**
- **Relic picks are instant.** No delay and no waiting for the cards to stop moving. If the draft is still open, it retries every 0.35 s and adds a virtual mouse click from the 3rd try. The real mouse is only used from the 6th try, and only while Roblox is focused.
- **Works while Roblox isn't focused.** Relic picks, menu tabs and Index items use direct click events and the virtual mouse, which go straight to the game. When tabbed out, the T menu is opened with a virtual key press sent to Roblox only (never to the window you're using). If that doesn't work, it clicks the backpack button on the hotbar.
- **Card reading uses the real fields:** Title, Tier, Bonus, Stat, Archetype ("ECHO SET 0/5") and Note.
- **More Index detail saved:** rarity line, mined count, flavour text, attributes and composition lines when shown.

**Confirmed from the v3.9 run:** all 177 found Index items were studied, with sources for each (for example Drake Gold 1 in 260: Dragon's Hoard 1 in 40, Ash Rock 1 in 1000, The Elder Dragon 1 in 6.8…), plus all 12 zones, 27 Your Stats and 46 Lifetime stats.

## v3.9: Reads every Index item, real relic clicks
**Fixed**
- **Index read 0 items.** The layout file from v3.8 showed how the Index is built: `ScrollingFrame > Row > Tile { ItemName, Count "1 IN 2", Hit button }`, with `Header { Title "GRASSLANDS", Tally "22/23" }` between rows. v3.9 reads tiles by that exact structure, so every item gets its name, odds and zone. It clicks each tile's `Hit` button, waits for the item to appear in the detail panel, then scrolls the "drops from" list to the end (Field Stone, Copper Vein, Quartz Geode, Rockback, Chests…).
- **Relics weren't really clicked.** Relic cards now get the same click methods as the menu tabs: every click event on the card's button, the card itself and its frame, then a virtual mouse click, then the real mouse.
- **Picks counted that never happened.** A relic only counts as picked if the draft closed within 1.5 s of the click. Before, a draft the game closed on its own timer was counted as the script's pick.

**Changed**
- **Waits 20 s after launch** before the first scan, so the game is fully loaded.
- **Minimises the script window** before scanning so it isn't in the way.
- **Smaller, more useful layout files.** They skip 3D item previews and long repeated rows. New: `DelveGuiDump_index_detail.txt` (the item detail panel) and `DelveGuiDump_relic.txt` (the relic draft, saved the first time one opens).

**Confirmed working (from v3.8 data)**
- The tabs open. Stats are read correctly: all 27 Your Stats (Cinderclaw +37 at 14,418, Nightbloom Rapier +43 at 905, Mine Power 20,820, Mining Range 1.4 cells…) and all 46 Lifetime stats. The Index total reads 177/277.

## v3.8: Tabs actually get clicked
**Fixed**
- **The scan opened the T menu but never switched to Index, Stats or Equipment**, so nothing was read. These tabs don't respond to the button-click events v3.7 used.

**Changed**
- **Verified clicking.** Each tab, and each Index item, is now clicked with increasingly real methods until the screen confirms it worked:
  1. every click event the button has (mouse down/up/click/activated, plus a simulated mouse press);
  2. a virtual mouse click at the tab's centre;
  3. a real mouse click (only when Roblox is focused and Background mode is off).

  After each attempt it waits for that window's title (INDEX / STATS / EQUIPMENT), or the item's name in the detail panel, before moving on.
- **Window detection** only accepts the title at the top of a window, so the tab labels in the bottom bar can't be mistaken for an open window.
- **Menu layout file.** The first time the menu is open it writes `DelveGuiDump_menu.txt`. If a tab still can't be opened, the "Scan done" pop-up says which one.

## v3.7: Careful one-time scan, no more frame drops
**Fixed**
- **Frame drops.** v3.6 kept searching the whole screen every few seconds after its scan, and checked every new label as you moved. Now:
  - the Index/Stats/Equipment scan runs **once per launch** (or when you press Scan), then stops;
  - drop pop-ups are caught only from text that newly appears **during a run**, handled in small batches;
  - the relic prompt and the results screen are found from that same new text, instead of a screen search a few times a second.
- **Rare drop posted from the Index screen** (CRIMSON HORN). Drops now only count during a run, never while a menu is open, and only from pop-ups that show a tier word (Uncommon, Rare, Epic…).
- **Stats paired across panels** (RACE = 1,137,902). Stats are now read row by row inside each panel, so a value always belongs to its own row.
- **Index read 0 items.** Rewritten: it finds the window by its title and reads each item tile as a whole, so names and odds split across several labels are joined.

**Changed**
- **Index scan is slow and careful.** It scrolls the grid top to bottom, then clicks every found item it hasn't studied, waits for the detail panel to show that item, and scrolls the "drops from" list to the end. Sources are mobs or rocks with their zone and odds (for example Ghoul, Grasslands, 1 in 5.8). Items already studied are skipped next launch.
- **Stats scan** scrolls both panels (Your Stats and Lifetime) to the end, keeping sub-sections such as Bosses.
- **Your Stats are used.** Pickaxe and sword names with their power, mine power, weapon power, attack speed, mining range (applied if the memory scan found none), walk speed and max health.
- **Discord run post** shows a short Lifetime summary (cash earned, best run, deepest delve, runs, rocks, materials, mobs, bosses, chests, runes, time mining, index) and your Loadout.
- **Rare drop post** lists where the item drops from.
- **Menu layout files.** Each scan writes `DelveGuiDump_index.txt`, `DelveGuiDump_stats.txt` and `DelveGuiDump_equipment.txt` to the workspace, so the readers can be fixed against the real menu if anything reads wrong.
- One-time brain cleanup clears the bad v3.6 index and lifetime data so it can be read again properly.

## v3.6: Index, Equipment, Stats and rare drops
**Added**
- **Index reader.** On launch it opens the T menu and reads every Index entry: name, zone, "1 in N" and whether you've found it. Entries scrolled out of view are read too, so it doesn't need to scroll.
- **Drop sources.** Outside a run, it selects each found entry it hasn't studied yet and reads which rocks drop it and how often (for example Field Stone 1 in 1.4, Copper Vein 1 in 33). Entries it has already studied are skipped on later launches.
- **Equipment reader.** Reads luck, power, damage and health, plus the selected item's power, swing speed, range and crit chance. It only reads this tab and never clicks in it, so it can't equip or sell anything.
- **Stats reader.** Reads your lifetime stats from the Stats tab.
- **Rare drop alerts on Discord.** Covers new Index entries, Epic tier or higher, anything at or above a "1 in N" threshold (500 by default), anything in the top % rarest of your Index (3% by default), and your own finds announced in Roblox chat (for example "1 out of 200,000"). Rare drops are also logged to `DelveDrops.jsonl`.
- **Gear memory.** Remembers mining radius and reach for each pickaxe and attack range for each sword. When you swap, it applies the known stats immediately and re-reads the game's numbers.
- **Run comparison by gear power.** Each run is scored against earlier runs made at a similar power, so upgrading your gear doesn't make relics from older runs look bad.
- The Discord run post now includes your gear stats and lifetime stats.
- Brain tab buttons: **Scan Index + Equipment now**, **Show index knowledge**.

**Changed**
- In combat, when it's already at the right distance from the target and there's nothing to dodge, it stands still and attacks instead of circling.
- Mining is unchanged: every rock is still mined. The Index is only used to judge how rare a drop is.

## v3.5: Accurate run results
- Depth and wave are read from the player list stats ("180 M" / "4 W") instead of guessed from on-screen text.
- Cash change uses the exact HUD counter ("$9,129,811,875") rather than the rounded "$9.13B".
- At the end of a run it waits for the **TRIP COMPLETE** screen to settle, then reads depth, cash value, rocks mined, XP, materials and level.
- Run scores and learning use those numbers.
- The Discord post title is now "Run Complete - Delve 50m" and adds trip value, cash change, rocks, XP, materials, level, time, outcome and % of time spent fighting.

## v3.4: Relic detection fix
- Ore-drop pop-ups ("Jade · 1 in 565 · x8") were being mistaken for relic cards and clicked.
- It now only looks for cards while "PICK A RELIC" is on screen, ignores anything containing "1 in N", and requires cards to be draft-sized.
- On load, the brain removes the fake relic entries it learned from those pop-ups (a one-time cleanup).

## v3.3: Relic picker speed
- When Roblox isn't focused or the menu is open, it clicks the card's button directly, so picks work while tabbed out.
- Relic picking keeps running even when Roblox stops drawing frames while tabbed out.
- It checks for a draft every 50 ms, waits less before clicking, and reads the countdown: with 3 s or less left it picks immediately, including relics it has never seen.
- The brain is saved after every pick and at the end of every run.

## v3.2: Fixes, Volt, GitHub
- Fixed "Malformed string" compile errors in the Brain tab.
- Added VirtualInputManager fallbacks for any input function an executor lacks (checked against Volt's API).
- The webhook helper defaults to Volt's workspace folder.
- Moved hosting to this repo.

## v3.1: Brain features
- **Relic codex.** Every relic seen is saved with its tier, effects and set. It learns which relics do well separately for Delve and wave runs, and learns combos.
- **Settings autosave** to `DelveSettings.json`. The farm switches itself back on if it was on when you left.
- **Smart targeting.** Ores first; it fights on boss stages, mob stages, when no ores are left, when a mob is close (learned distance) or when you're swarmed. Below the low-HP setting it stops chasing.
- **Discord "Run Complete" posts**, with a screenshot when `delve_webhook_helper.ps1` is running.
- **Run history** in `DelveRuns.jsonl`.

## v3.0: First version
- **Dodging.** Plans a path over the floor tiles out of attack zones, avoids corners and map edges, and routes around rocks and spots where it got stuck.
- **Learns from hits.** Adjusts its safety margin, learns each mob's real reach and tunes roll timing.
- **Relic picker that learns.** Reads tier, stats and sets, waits for the cards to settle before clicking, checks the click worked and retries another way if not.
