# Changelog

Newest first. The version is shown in the script window title (`Delve v5.31.1 | Brain`).

## v5.31.1: Pale Warden bullet storm (not yet verified in gameplay)
- **Death (Pale Warden, 22,280 m total, 1 HP, on v5.30):** the Warden's second-phase `sanctumstorm` sent one plan with **168 bullets** (6 spiral arms x 16 volleys + 4 rings with a gap, 16 st/s, radius 2, 70 st reach). The bot kept seeing planned hits 0.6-1.2 s out, retreated from 24 to 77 st, rolled 0.11 s before the hit (too late for the i-frames) and was hit inside a drawn bullet. The new hit log said no planned shot covered the spot.
- **Cause:** those bullets are `fromMob`: the game starts each one wherever the boss is when it spawns (HazardView takes the boss's position at spawn), not at the plan's `from` point. The model used `from`, so its bullets were in the wrong place once the boss had moved.
- **Fix:** fromMob shots follow the boss until each one spawns, then their start point is fixed, the same way the client draws them. The plan log line now says how many bullets start at the boss and how far the boss is from the plan's start point.
- The drawn bullets themselves (marble bullets are 0.6 x 0.6 x 1.9) were read as moving attack zones and stretched up to 20 st ahead, which helped fill the screen with 136-190 "zones". With the plan feed on, small solid parts in `workspace.Hazards` are skipped; the plans cover them exactly.
- Bullet lanes in the zone list look 0.6 s ahead (was 1 s) to cut clutter; the exact checks for escapes and rolls still look 1.2 s ahead. On 1-HP runs bullets get 1 st of extra room (was 0.6), since the server judges your position a moment late.
- The hit log now also gives the distance to the nearest planned shot 0.1 s before the hit.

## v5.31: Moves forward the whole time, timer or not (not yet verified in gameplay)
- Removed the "only push forward when the floor timer is low" rule. In a Delve it now always:
  - mines ores ahead (up the road) first and ores behind (toward the collapse) last;
  - with nothing to walk to, heads for the chamber's exit (this replaces the separate v5.29 "nothing to do here" walk);
  - turns back for a missed ore only if it can get there and mine it before that spot collapses. The time left comes from the collapse front in the game's SessionSync event, else the floor timer, else nothing is collapsing (e.g. after the Unmaker);
  - keeps mining an ore already in reach unless the floor under it is about to fall.
- If it's already at the exit and an ore behind can't be reached in time, it waits at the exit instead of walking back into the collapse.
- Log line: `walking up the road (<signal>, <distance>): <reason>`, e.g. `nothing left to walk to` or `ore behind needs 3.1s, the collapse leaves 2.4s`.
- The forward goal is cached for 0.4 s (it's asked every few frames now).
- The "ignore mobs" switch still uses the floor timer (Delve timer setting); only moving forward stopped depending on it.

## v5.30: Reads the game's attack plans and chamber layout (not yet verified in gameplay)
Built from the game's own client code (decompiled exports of ReplicatedStorage and PlayerScripts).

**Attack plans (dodging)**
- The game sends every attack to the client before it lands: `MobPlan` (hazards with shape, size and warn/hit/duration on the server clock), `MobPlanCancel`, and `MobShot` (mob volleys). The script now listens to them (listen only) and checks spots with a copy of the game's own hit test (`Shared.Hazards.test`, player radius 1.2). The copy matched the game's formula on 100,000 random checks.
- **Why the Pale Warden kept killing 1-HP runs:** its moves have no projectiles at all (a 0.45 s charge along a lane, 6 shard circles landing one after another along the charge 0.47-1.07 s later, slab lanes 0.3 s apart, a marching sentence ending in a big circle). The "55-100 projectiles" were the game's own impact debris and smoke puffs, which the scanner read as projectiles and growing attacks. The shards also stay invisible until just before they land.
- With the feed on: debris/smoke/burst parts are ignored; planned attacks show up as zones up to 1.25 s (1.6 s on 1-HP runs) before they land, even before they're drawn; rolls are timed to the exact landing moment.
- **Escapes are checked in time:** the tile planner asks whether each tile gets hit at the moment you'd be on it (walk speed), and the spot you stop on must stay clear for 1.2 s. Same for open-ground escapes (Arena).
- **Roll landing spots:** the roll's i-frames last 0.35 s (Config.Dodge.Iframes); if the planned attacks hit the landing spot after that (e.g. the shards after the charge), it turns toward a clear landing spot first and rolls a frame later.
- Cancelled attacks are dropped the way the game does it (parts not landed yet; pools/trails too when lava is cancelled; shots not spawned yet, or all shots).
- Logging for lead time: each plan (mob, shapes, first hit, delay), each cancel, server-confirmed dodges, and every hit with the plan that covered the spot, how early its cue came, and when the escape and roll started. The death black box records planned hazards and the next planned hit on your spot.
- Toggle: **Use the game's attack plans (exact timing)** (Combat tab).

**Rooms (forward routing)**
- Delve is one straight shaft: rows run along -Z, chambers follow each other along the rows (`Shared/Delve`), and every floor tile is named `Tile_<row>_<col>` at its row's position. Depth label = the current chamber's last row x 10 m (4,760 m = chamber 30 Pale Warden, 9,060 m = 50 Worldheart, 17,520 m = 90 Unmaker, all matching the logs).
- The current chamber comes from the game's `SessionSync` event (also gives the collapse front), else from the depth label when it is exactly a chamber's end. When the chamber and your row agree, forward = the chamber's exit row (next chamber's exit once you're there), routed through the existing floor, obstacle, collapse and hazard checks. Otherwise the old signals (collapse, depth marks, learned direction).
- Portals: the prestige portal is found by the game's `PrestigePortal` tag (sign text as backup) and always comes before walking up the road; the shop uses its sign first, `VesperInGate` tag second.
- Log lines say which signal picked the destination, e.g. `walking up the road (chamber 34 exit, row 512 (session sync; you're at row 501), 88 st)`.
- New Settings button **Check forward goal + attack plans** writes the chamber, rows, forward goal, collapse front and plan-feed status to the reasoning log.

## v5.29: Keeps walking up the road (not yet verified in gameplay)
- **Bug:** it stood still after the Unmaker (17,520 to 17,760 m, no timer) and in a boss room whose boss was out of sight (14,260 m). The forward push only ran when the floor timer was low.
- **Fix:** in Delve, whenever there's nothing to do (no ore to walk to or mine in reach, no fight, no chest), it walks up the road to the farthest safe tile ahead, around hazards. The portal walk-in and mob search still take over when they apply.
- **The road's direction is learned and kept** between runs: the tunnel runs the same way across the map (depth 4,760 m at z -3,670, 9,060 m at z -7,080), so it learns that direction from the first depth mark of a run to the newest. Used when there's no recent collapse or depth movement to go by (e.g. after the Unmaker, where depth goes up while you stand still).
- Toggle renamed: **Keep walking up the road** (Combat tab).

## v5.28.2: "Up the tunnel" points the right way (not yet verified in gameplay)
- **Bug (17,060 m, caved in):** it ran backwards into the cave-in. v5.28 worked out "forward" from the middle of all loaded floor tiles; when earlier segments are still loaded that middle point lies behind you, so "forward" pointed back.
- **Fix:** forward now only comes from where you've been:
  1. away from the tiles that collapsed in the last 20 s, or
  2. the way the depth has been going up (it remembers where the depth went up at each gate; the line from an earlier mark to the newest is the way the tunnel goes).
  - With neither signal it doesn't push at all (keeps mining as before).
  - The goal is the farthest safe tile that way, staying within 40 st of the line (no side pockets).
- The log line now says which signal it used.

## v5.28.1: Pillars, 15 s timer, missed ores (not yet verified in gameplay)
- **Stuck on a pillar again:** when it got stuck it planned a detour, but the v5.23.1 smoothing still eased the detour's turns, keeping part of its heading into the pillar (the edge check doesn't see a pillar it's standing against). Detours, the 3 s after getting stuck, and any moment it isn't actually moving now skip smoothing completely.
- **Timer danger time 15 s** (was 10): it switches to "ignore mobs, ores ahead, head up the tunnel" 5 s earlier. Your saved 10 is moved to 15 once.
- **Missed ores behind it:** instead of "never go back under 5 s", it goes back for an ore behind it as long as it can walk there and mine it with time to spare (distance / walk speed + 1.5 s, under the time left minus 1 s). Otherwise it goes up the tunnel and the log says why.

## v5.28: Up the tunnel on a low timer, rolls through bosses (not yet verified in gameplay)
- **Low floor timer (10 s by default):** it now knows which way is "up the tunnel": away from the tiles that just collapsed (or, before the collapse starts, away from where it came into the room).
  - Ores ahead get priority (x1.6), ores behind toward the collapse go last (x0.25).
  - With nothing left to mine it walks to the far end of the floor around hazards instead of standing still.
  - Under 5 s it won't walk back for an ore behind it.
  - Toggle: **Low timer: head up the tunnel** (Combat tab).
- **Rolls through bosses:** attack rolls used to be off for the whole boss fight. Now it rolls at the current target (boss or pylon), straight through the boss, when it's quiet: no attack zone within 18 st (25 st on a 1-HP run), nothing timed or winding up, and no boss attack predicted for 2 s. Toggle: **Roll through bosses when no attack is near**.

## v5.27: Engages bullet-hell bosses (not yet verified in gameplay)
- **Bug:** against The Pale Warden it spent 40 s at 40-60 st ("attack zone between us, no way around, holding outside") and never closed in. Route planning treated every projectile's flight lane as a wall, and so did the "zone ahead" check, so with a constant bullet stream there was never a way to the boss.
- **Fix:** projectile lanes no longer block routes or the approach (they move, routes are redone every 0.5 s). Only ground attacks (circles, strips, lava) block. The dodge still reacts to any shot that's about to hit, and the longer projectile lanes on 1-HP runs (v5.26) still shape escapes.
- Removed the v5.26 "wait for projectiles to pass" hold: against a boss that never stops firing it would wait forever.
- The log now says when it walks to a chest (to find idle time after a boss).

## v5.26.1: Edge-safe smoothing, no ping when you leave (not yet verified in gameplay)
- **"YOU SLIPPED. BACK ON SOLID GROUND."** right after resuming at 340 m. Likely cause: the v5.23.1 smoothing kept the old heading for up to 0.35 s when the new one reversed it, which near an edge can carry the character off the floor. Now the old heading (or a blended one) is only kept if a ray finds solid floor 4 st ahead; otherwise it turns immediately. The reversal window is 0.3 s.
- **Leaving the game pinged you as a disconnect** (Roblox reports it as "DisconnectClientInitiated"). Leaving or closing the game yourself no longer sends the disconnect ping; real disconnects and kicks still do.

## v5.26: Projectile deaths and Play again (not yet verified in gameplay)
- **Death (The Pale Warden, 4,760 m, 1 HP):** the boss filled the room with projectiles (55 tracked). The bot started an 11 st escape to open ground and was hit 0.1 s later outside any zone it knew about.
  - On fragile runs (max HP 10 or less, e.g. Glass Soul) each projectile's danger lane now reaches **0.95 s** ahead (up to 32 st) instead of 0.6 s (20 st), so escapes don't cross where a shot is about to be.
  - When only projectiles are between it and the target, it waits for them to pass instead of walking around them into the bullet field (the v5.23 walk-around is still used for ground zones).
- **Play again stopped clicking:** F2 also switched "Play again" off and saved it, and re-running the script left an old F2 handler connected, so one press could stop and resume at once (11:06:47 in the log). Your setting ended up saved as off.
  - F2 no longer touches the Play again setting: Play again simply pauses while F2 has farming stopped or Auto Farm is off.
  - Only one F2 handler is ever connected, and presses within 0.4 s count once.
  - Play again is switched back on once (it was turned off by this bug).

## v5.25.1: Review fixes (not yet verified in gameplay)
- Turning **Auto Farm** off during a scan trip could still start a run from the hub afterwards. Off now cancels the trip's restart too.
- **F2** no longer depends on the UI library firing the switch's callback: F2, the switch and the auto-start all go through one function, so F2 always stops and resumes for real.
- The new walk-around (v5.23) also kicked in when the target was already in weapon reach, so it circled instead of hitting. In reach it now stands outside the zone and keeps attacking; it only walks around when out of reach.
- After a restart the switch could show ON while the farm was off. It now shows ON only when the farm is coming back on by itself.
- The help paragraph on the Farm tab had the same title as the switch, so the **i** icon could attach to the wrong one. Renamed to "How it works".
- The font dropdown now shows the new default right after the one-time switch.

## v5.25: Cleaner window (not yet verified in gameplay)
- Window **900 x 700** (was 760 x 640) so long setting names, the **i** icons and text boxes don't overlap.
- **Open Delve** button is box-shaped (square corners) and the fish icon is gone (window and button).
- **Window font** default is now **Game font**: the game's pixel font everywhere, titles at normal weight and all other text one step lighter so it reads easier. Your saved font setting is switched to it once; Mixed and Clean are still in Settings.
- Final review: no script errors in the latest logs; syntax, scope and local-count checks pass; no clicks on reroll/buy/Robux/spin/gift; no personal info in the repo.

## v5.24: One Auto Farm switch (not yet verified in gameplay)
- "Farm enabled" and "Auto Farm: start a stage from the hub" are now **one switch: Auto Farm**. On in a run: farms. On in the hub: starts your stage from GO MINE and the farm turns on once the run loads. Off: stops both.
- **F2** flips the same switch (and pauses Play again while off; F2 again restores it).

## v5.23.1: Smooth movement (not yet verified in gameplay)
- Every walking direction now goes through a smoother: outside dodges, a sudden reversal (more than about 110 degrees) within 0.35 s of the last heading is ignored, and smaller turns are eased. Removes W/S back-and-forth from targets or routes flipping.
- Dodges, escape rolls, attack rolls and forced headings are never smoothed or delayed.

## v5.23: Advances instead of jittering, hover info, F2 stop (not yet verified in gameplay)
- **Bug:** when an attack zone (e.g. the Cloud Golem's beam) sat between it and its target, it stood still, stepped in when the zone moved, dodged back out, and repeated: W/S jitter that burned the timer instead of engaging.
- **Fix:** it now walks **around** the zone toward the target (first safe heading 30-90 degrees off the straight line, checked 3 and 6 st ahead and on the floor map), keeping the same side for 1.5 s so it doesn't flip. It only holds still if every heading is blocked.
- **Info icons:** the explanations are hidden now. A small **i** sits after each setting's name; hover it to see what the setting does and the recommendation.
- **F2 hotkey:** stops all farming (farm, Play again, Auto Farm, scan-trip restarts). Press F2 again to resume exactly as it was.

## v5.22.1: Descend setting can't be overridden (not yet verified in gameplay)
- **Bug:** with After Worldheart set to Descend it took **Ascend**. The fork screen was read with the title "A TRADER IN THE DARK", so the trader logic ran after the fork choice and bought the highest-scoring card (ASCEND 224 vs DESCEND 130).
- **Fix:** whenever Ascend and Descend cards are on screen it's always treated as the fork and your setting is used; the trader logic can't override a fork any more (also for Safe/Cursed forks).

## v5.22: Info under every setting (not yet verified in gameplay)
- Every toggle, slider, dropdown and text box now has an info line saying exactly what it does, plus a recommendation (or "Not recommended to change") so you know what's safe to touch.
- Final review before AFK: syntax, scope and local-count checks pass; no clicks on reroll/buy/Robux/spin/gift; nothing sells to Vesper; no personal info in the repo.

## v5.21: Bigger window, fish icon, Credits, relic study (not yet verified in gameplay)
- **Window:** 760 x 640 (was 620 x 480), so options fit on one line and more show at once.
- **Window font** setting (Settings tab) replaces the old on/off toggle:
  - **Mixed** (default): the game's pixel font for the title and big headings, clean Builder Sans one size up for all option text, so long lines are easy to read.
  - **Game font**: pixel font everywhere (the old look). **Clean**: Builder Sans everywhere.
- **Icon:** the window and the Open Delve button use a fish (the Delve anglerfish) instead of the pickaxe.
- **Credits tab:** GitHub link (with a copy button) and build info.
- **Relic study:** a relic it has never taken gets picked half the time when it scores within 80 of the best card, so the whole relic index gets learned. It never does this instead of a second chance, a luck relic or a set completion, and never at forks or the trader. The old "close 2nd" tries (8%) stay for relics tried fewer than 3 times. Log/pop-up says `never taken before: trying it to learn what it does`.
- Final check: syntax, scope and local-count checks pass; no clicks on reroll/buy/Robux/spin/gift; nothing sells to Vesper; your Discord user ID stays only in your local settings.

## v5.20: Disconnect pings, scan count per session (not yet verified in gameplay)
- **Disconnect ping:** when Roblox shows the "Disconnected" / kick prompt (e.g. Error Code 277), you get pinged on Discord with the message and the depth. With the screenshot helper running, the alert is retried every 15 s for up to 30 minutes, so it still arrives once your internet is back.
- **Roblox closed, crashed or froze:** the script writes a heartbeat every 10 s. If it stops for 2+ minutes while the bot was on, the helper posts "Delve stopped" and pings you (once, until the script is running again). Turn the bot off before closing Roblox if you don't want that ping.
- New toggle: **Ping if disconnected or Roblox closes** (on by default). Needs webhooks on; the Roblox-closed ping needs the helper running. **Restart the helper** to get the new version.
- **Scan count per session:** every time you join, rejoin or re-run the script, the "scan every N runs" count starts over.

## v5.19.1: Descend reads what the run needs (not yet verified in gameplay)
- On the **Descend** path, combat boosts still come first, but mining power, mining range and mine speed relics are weighed against the run's current state:
  - **Mining needed** when your ACTIVE BUFFS add up to less than +100% mining, or the floor timer has dropped into the danger zone since Worldheart. Then mining relics rank close to combat, and a **massive** one (+60% or more) beats the combat picks.
  - **Mining not needed** (plenty of mining buffs, no timer close calls): mining relics drop lower so the run keeps stacking combat and goes faster. A massive mining relic can still win if the combat options are weak.
- The reasoning log says why, e.g. `mining, massive (only +40% mining buffs)` or `mining (+190% mining already, no close calls)`.

## v5.19: Scans happen in the hub; races removed (not yet verified in gameplay)
- **Scan trips:** when a scan is due (every N runs, set by "Scan every" in the UI), the end screen's **RETURN TO HUB** is clicked instead of BACK TO MINE. The Index/Stats/Equipment scan runs in the hub, then the next run is started from GO MINE with your chosen stage, even when Auto Farm is off. If the scan keeps failing for 90 s it starts the run anyway.
- Scans never start on the end screen any more.
- **Races removed:** no more Races tab scan, no race in the stats, no race perk lookups. Attack rolls are now simply **On** or **Off** (the old "Auto"/"Always" count as On, which is what your Onibi Step race had).
- Script check: no script errors in the last session's logs; 17 brief stuck loops over the whole session.

## v5.18.1: Timer beats big mobs (not yet verified in gameplay)
- **Bug (42,840 m run, Prestige II, caved in):** with 5 s left on the floor timer it went after "big mobs" (Crystal Golem, Magma Brute, Prism Sentinel, Glowcap) 25-45 st away for 7 s instead of mining, and the tunnel caved in. The "big mob" rule was checked before the timer danger zone.
- **Fix:** in the timer danger zone (10 s or less by default) big mobs are ignored like any other mob. Real bosses, mob-kill objectives and a mob right on top of you still come first.
- The right-hand portal after the Unmaker leads to **Vesper**, who buys your Mythic and Forsaken items for Strange Orbs. The script never sells anything to Vesper; Prestige stays the default.

## v5.18: Relic priorities follow the Worldheart path (not yet verified in gameplay)
- After Worldheart, the path you take changes the relic order (second chance and luck stay on top):
  - **Descend** (the Hollow, more mobs): combat boosts (weapon power, swing/attack speed, crit, AOE/chain hits, damage) rank right under luck; mining power/range are still good.
  - **Ascend** (the Heavens, more rock): mining power and mining range rank right under luck; combat boosts are still good.
- The path is remembered for the rest of that cycle and resets on prestige and on a new run. Before Worldheart nothing changes.
- The reasoning log shows which path is driving the pick (e.g. `combat (Descend path)`).

## v5.17.3: Walks into the prestige portal (not yet verified in gameplay)
- **Bug:** after the Unmaker the bot stood still in the portal room next to the PRESTIGE II portal. The old portal logic only ran if the Unmaker intro card had been recorded, the room had zero mobs in sight and depth was 15,000+; the first Unmaker kill was on an older version (card never recorded), and the figure by the shop portal counted as a mob.
- **Fix:** portal signs are now caught the moment they appear in the world (plus one scan at start). It walks into the chosen portal whenever no mob is within 25 studs and the portal is within 250 studs. Works for PRESTIGE I, II, III and on.
- Signs attached to a part, an attachment or a model are all handled.
- The right portal is a rare-item shop ("THE $!?#$#*"); the option is now called **Rare shop (?????)**. The script never buys anything there.

## v5.17.1: Lava and prestige count (not yet verified in gameplay)
- **Lava (the orange burn tiles at Worldheart)** tick damage the whole time you stand on them. The escape planner now pays a lot more to cross them (and with Glass Soul, 1 max HP, they're effectively walls), and routes to far targets may only cross them when a tick can't kill you (not on Glass Soul, and HP 60%+). Before, it could cross them after 4 s without a safe route.
- **Prestige doesn't reset the depth** ("DEPTH 26,580 M - PRESTIGE I"): the prestige number is read from that label instead, and recorded with the run.

## v5.17: Portals after the Unmaker (not yet verified in gameplay)
- After the Unmaker two portal rings appear that you walk into: the left one is labelled **PRESTIGE I**, the right one has a garbled label (unknown so far, called **?????**).
- New Relics setting **After the Unmaker (portal)**: Prestige I (default), ?????, or Don't enter. Once the Unmaker has been seen and the room is clear (15,000 m+), it finds the portal labels in the world every 3 s, walks a safe route to the chosen one and steps into it. Logged as "walking into the … portal".
- The first time it finds them, it saves the portal layout to `DelveGuiDump_portals.txt` so detection can be refined.

## v5.16: Prestige and boss cards (not yet verified in gameplay)
**What happened:** the Unmaker ("THE END OF ALL THINGS") was killed at 17,520 m on a Glass Soul run, using the new routing and dodging; then **Prestige I** ("THE DELVE - YOU BEGIN AGAIN") restarted the depth inside the same run. Two new screens were saved: RiftBossCard (the boss intro card) and RelicPoof (just a visual effect).

- **Prestige-aware depth.** The script only tracked the deepest depth, so after a prestige every floor looked like the same floor: the pillar map and the room search would never reset. It now follows the depth right now: when it drops sharply to the start, that's a prestige (pop-up and reasoning log). Floors are told apart by prestige + current depth.
- **Run totals.** A run's depth is the metres of finished prestige cycles plus the current one, and the run record and Discord post show the prestige count.
- **Boss intro cards.** The name on the RiftBossCard ("THE UNMAKER") is remembered as a boss, so boss rules apply from the first fight. Boss names are re-checked every 5 s.

## v5.15: Shooters first, when it matters (not yet verified in gameplay)
- **Learns who shoots.** When a projectile appears within 10 studs of a mob, that mob type is counted as a shooter (saved in the brain). Mobs with a learned reach of 12+ studs count as dangerous at range too.
- **Targets them first only when necessary:** a shooter (3+ shots seen) or long-reach mob within 40 studs gets priority if it fired in the last 8 seconds or you're inside its reach. A quiet shooter far away isn't chased. Logged as "… hits from range: taking it out first".
- Works together with the kill-first rule (mobs that killed you 3+ times) and boss mechanics (pylons). Combat tab toggle: **Take out shooters first when they're a threat** (on).

## v5.14: Less jitter, find every mob (not yet verified in gameplay)
**Jitter (from the dodge log):** 595 of the last 2,156 dodge starts came less than half a second after the previous one: it kept switching between escaping and going back.
- It **commits to the chosen escape spot** for up to 1.2 s (was re-chosen every 0.25 s) while that spot stays safe and isn't reached, and the flank and open-ground searches keep their previous pick while it's still safe.
- **Settle after a dodge:** for 0.6 s after getting out of an attack it finishes the move (or stands and attacks) instead of walking straight back into the zone.

**Boss rooms and kill floors:** far mobs (pylons at the top of a boss room) aren't loaded until you get close. When the HUD says "N MOBS LEFT" and it sees fewer, it moves up the room (to the floor tile farthest from where it came in, then onward) along a safe route until all of them are in sight. A mob within 8 studs is still fought first. Combat tab toggle: **Search the room until all mobs left are found** (on).

## v5.13: Dodge past enemies (not yet verified in gameplay)
- In a fight, when you're inside an attack zone, it first looks for a safe spot **past the enemy**: behind it (on the side away from the attack) or 45/90 degrees around it, at about 80% of your weapon reach, on real floor and outside every zone, at most 16 studs away. It takes the closest one, so it keeps hitting instead of backing out of range and waiting for the attack to end. If the attack is centred on the enemy, "behind" means through to the far side.
- Getting there uses the same walk-or-roll rule: it rolls (with invincibility) only when walking can't make it before the hit.
- If no such spot is safe, it falls back to the normal escape (tile planner, then the open-ground search).
- Combat tab toggle: **Dodge past enemies to keep hitting them** (on). Logged as "dodging past … to stay in reach".

## v5.12: Danger map (see what it sees)
- Settings: **Show what it sees (danger map)** draws, live on the ground, everything the dodge logic detects: **red** attack zones, **orange** burning floor, **yellow** attacks timed to hit you soon, and a **green** marker where it's heading to get safe. Up to 90 zones within 90 studs, refreshed about 7 times a second while farming.
- The marks are local only, can't be touched, collided with or hit by rays, and sit in their own folder, so the script's own detection never mistakes them for hazards or floor. Turning it off removes them.

## v5.11: Open-ground dodging (Arena, map-wide attacks, Glass Soul) (not yet verified in gameplay)
**What the Arena logs showed:** the Arena has no tile floor, so the escape planner had no map and fell back to judging only a few studs in each direction ("dodge start … dir=-0.71,0.71" over and over with 30-110 attack zones up): it walked into corners.

- **Open-ground search.** When there's no tile map (Arena), or the tile planner finds no safe tile (Delve), it checks points every 4 studs within 36 studs: real floor only (a short ray down must hit ground, not a wall or the void), outside every attack zone, scored by distance, walls/void nearby (corners score worst) and attack zones crossed on the way. It goes to the best one.
- **Map-wide attacks.** If every spot is covered, it heads for the spot covered by the fewest attacks and relies on the timed roll.
- **Roll only when needed.** It walks there when walking is fast enough; when it can't get out of the attack in time, it rolls (Q) toward that open ground, only if the landing spot is safe.
- **One-hit runs (Glass Soul, max health 1):** it rolls out sooner (0.25 s of slack instead of 0.05 s; for attacks without a known timing at 45% instead of 60%).

## v5.10.8: Forsaken drops, kill-first learning (from the Pirates Cove session; not yet verified in gameplay)
**What the logs showed:** 22 Pirates Cove wave runs (average wave 139, best 227), 21 deaths, every one a single big hit. 13 were an Elite Powder Gunner shooting from 22-40 studs. The end screen is now read correctly (rocks, XP and materials are in every run). Normal mobs that had killed you once (Powder Gunner, Skeleton Deckhand) were being treated as bosses.

- **Forsaken and Eternal drops** count as tiers above Mythic, so they're announced and posted (red embed). Before, "[FORSAKEN] … Ascension Stone (1 in 1,750,000)" only got through on its odds, with no tier. Drop names are cleaned ("the Broadside Blunderbuss in a chest!" -> "Broadside Blunderbuss") so repeats of the same item are counted, not announced again.
- **Only named bosses** that killed you ("THE WORLDHEART", "THE SPORE MOTHER") are treated as bosses by name.
- **Learned kill-first priority:** a mob type that has killed you 3+ times is targeted first when within 45 studs (up to 30 studs "closer" in the target choice). For you right now that's the Powder Gunner and the Skeleton Deckhand.

## v5.10.6: Learning curve: Delve and Mines apart, 50-run comparison
- The learning curve window now has two graphs: **Delve** (depth per run) and **Mines** (wave reached per run).
- Each shows the last 100 runs with a 10-run average line, and compares the **last 50 runs with the 50 before** (average, hits per run, deaths, best, total runs). Until a mode has 100 runs it says "not enough runs yet" for the comparison.

## v5.10.5: From the overnight logs (not yet verified in gameplay)
**What the overnight logs showed (8 delve runs on v5.10.4, then 18 Mycelia wave runs):**
- **New best depth: 15,300 m**, on the first run after choosing **Descend** (the setting worked). 3 of the 4 delve runs after the first three got past Worldheart.
- **Pylons:** it routed to Heart Pylons around hazards, and learned "Worldheart takes more damage after a Heart Pylon dies: kill it first".
- **Worldheart deaths (3):** two came from walking at the boss with 16 and 27 HP left; one was a single huge hit while standing in two big warning circles.
- **Run posts had no rocks/XP/materials:** the reader matched the "YOU DIED TO" overlay instead of the TRIP COMPLETE screen.

**Fixed**
- The end screen is read by its real layout (RunEnd > Results: title, cash value, rocks mined, XP gained, level, materials). It waits up to 8 s for it and uses the death overlay only if it never shows. The screenshot is taken when it appears.
- Below the low-HP setting (35%) in a boss fight, it stays at least 14 studs (or the boss's learned reach + 6) from the boss and only fights what comes to it, instead of closing in. Getting out of an attack zone still comes first.

## v5.10.4: Overnight stability
- The new route planning in the farm loop is protected: if it ever errors, that target is just skipped for the frame instead of stopping the loop.
- Per-mob caches (routes, path checks, notes) reset after 300 entries so they can't grow over many hours.
- `dodge_log.txt` and `DelveReasoning.txt` rotate at about 3 MB (the previous part is kept as `dodge_log_old.txt` / `DelveReasoning_old.txt`), so a night of AFK can't fill the disk.

## v5.10.3: Reaching the Heart Pylons and the chest (not yet verified in gameplay)
**What the logs showed:** the pylons were seen (110-168 st away) but only targeted when the straight line to them was clear; across the Worldheart arena it always crossed a burn strip or attack zone, so it kept "holding safe ground" (logged dozens of times a second) and drifted away. After Worldheart died, the last 2 mobs were pylons it would never go to, so it stood still, never left the fight, and never walked to the chest.

**Fixed**
- **Routes around hazards.** For far targets it plans a path over the floor tiles that skips tiles inside attack zones and ends on the first tile within weapon reach, then walks it ("routing to HeartPylon around hazards"). If there's no fully safe route for 4 s, it allows crossing lingering ground hazards (burn strips) instead of freezing; it still never walks through an incoming attack, and getting out of a zone you're standing in always comes first.
- Priority targets (pylons) only need such a route, not a clear straight line.
- The chest walk uses the same route around attack zones and burn strips.
- The "holding" note is logged at most every 10 s per target.

## v5.10.2: Relic priority order
1. A second chance you don't have yet.
2. **Luck and drop quantity** (1.8x).
3. **Mining power and range, weapon power and range, swing/attack/mine speed, and area (AOE) effects** like cleave, chain, splash, explosions, lightning, "nearby" / "all mobs" (1.6x). Mining range, radius, reach and mining circle are now in this tier.
4. **Survivability and floor time** (1.35x).

## v5.10.1: Walking into Worldheart's red zone (not yet verified in gameplay)
**What the death record showed:** at 9,060 m it was chasing Worldheart ("why=big mob") straight through big warning circles (in 2-3 of them for 1.5 s), and the moment before the killing hit it read as "in no zone". Three causes:
- **Worldheart wasn't a boss.** It has no boss flag, so since v5.8.3 it counted as a "big mob": no boss rules (roll kept for defence, earlier rolls, boss study, pylon logic).
- **The ring rule was backwards here.** A small circle inside a big one was assumed to be the safe spot; Worldheart's red inner circle is the danger, so standing in it read as safe.
- **Chasing came before dodging.** In combat it moved toward the target before checking whether it was standing in, or about to step into, an attack zone.

**Fixed**
- A boss is also recognised by the **CONTRIBUTION** panel that boss fights show, and by name if it killed you before ("THE WORLDHEART"; elites excluded).
- The inner circle only counts as a safe spot when it isn't red/orange/pink.
- In combat: standing in an attack zone means get out first (no chasing); if the next 3 studs toward the target are inside one, it holds outside the zone (logged "not chasing … holding outside") and still attacks whatever is in reach.

## v5.10: Learning curve window
- Brain tab: **Show learning curve (graph)** opens a separate, draggable window:
  - depth of the last 40 delve runs as bars (green survived, red died, grey not learned from), with a gold line for the 5-run average;
  - hits per run underneath;
  - last 10 runs vs the 10 before: average depth and hits per run (with % change), deaths, best ever, runs recorded.
- Built from `DelveRuns.jsonl`; drawn only when opened, and redrawn after each run while it's open.

## v5.9.6: Path after Worldheart
- After Worldheart ("THE WORLD BREAKS OPEN") the choice is **ASCEND** (the Heavens: mining path, denser rock, richer ore) or **DESCEND** (the Hollow: combat path, more mobs, more elites). The logs showed it always took Ascend by score. New Relics setting **After Worldheart**: Descend (default), Ascend, or Let the brain decide (the old scoring). The pick is announced and logged like a tunnel fork.

## v5.9.5: Luck first
- **Luck and drop quantity are top priority** for relics: 1.8x weight (power/speed 1.6x, survival/time 1.35x). "Quantity" now counts as luck/drops, and the old 0.7x discount on luck is removed. A second chance you don't have yet still comes first.
- **Manageable downsides are forgiven by half** on luck relics: things like slower walk, swing or mining speed. Dangerous downsides (damage taken, health, faster collapse, curses, elites) still count in full.
- If no relic is good, it still takes the best-scoring one (drafts always pick); traders only buy above the minimum score, otherwise walk on by.

## v5.9.4: Discord pings
- Discord tab: **Discord user ID to ping**, plus **Ping on Run Complete** and **Ping on rare drops**. The mention goes in the message text (mentions inside embeds don't notify), and only that one user can be pinged. No bot needed; the webhook does it. The test post pings too.

## v5.9.3: Mining away from the collapse, end-of-run screenshot (not yet verified in gameplay)
- **Collapse awareness.** When floor tiles vanish (the floor collapsing), it remembers where for 20 s. Every ore is still mined (you need them all to progress), but ores within 8 studs of the collapse are mined last (weight x0.1) and within 16 studs later (x0.4), so it works on the ores ahead instead of walking back into the collapse. Walking also treats vanished tiles as holes and routes around them instead of crossing the void.
- **Screenshot of the right screen.** Auto Replay started the next run before the screenshot was taken, so posts showed the next run. Now, as soon as the run ends and the end screen shows (or after 2.5 s), the helper is asked to take the picture right away, Auto Replay waits for it (max 6 s), and the Run Complete post uses that picture.
- The end screen's layout is saved once to `DelveGuiDump_runend.txt`, so its reader can be fixed (the 12,180 m run was read from live tracking: rocks, XP and materials missing).
- **Restart `Start Delve Screenshots.bat`** to get the new helper (it understands the new "take the picture now" request).

## v5.9.2: Hits with no roll (from the first v5.9.1 session; not yet verified in gameplay)
**What the logs showed:** 13 hits in 3 runs; only 2 now had a roll land just after (was 5 of 6), but 12 of 13 had no roll before. Three came while it walked 9-15 studs to safe ground with 0.4-0.7 s left; two had an attack roll fire 10-20 ms after the hit; the death at 6,840 m was an Elite Magma Brute hitting twice (185 + 269) from 9-10 studs with no warning zone and the roll ready, and the death was blamed on the floor. One burst (6 hits in 0.15 s) looked unavoidable.

| Change | Why |
|---|---|
| Inside an attack zone, it compares the time to walk out (distance / your actual walk speed) with the time left. If walking is too slow, or a zone with no known timing is past 60% and walking needs over 0.35 s, it rolls out instead, only if the roll lands outside every zone and on the floor. Logged as "escape roll". | Walking 9-15 studs in 0.4-0.7 s can't work. |
| No attack roll within 1 s of being hit; a queued one is cancelled. | It spent the roll right when follow-up hits were likely. |
| A hit with no warning zone and no strike seen is credited to the nearest mob within 15 studs. After 2 such hits, that mob's reach is raised (max 14 st), so wind-up dodges cover it. The floor is only blamed when no mob is near. Floors learned before (likely mob hits) are cleared, brain backed up first. | The Magma Brute's reach was never learned, so dodges covered about 7 studs, and the death taught it a wrong "dangerous floor". |

**How to check:** "escape roll" lines in `dodge_log.txt`; fewer "hit … rolled=false" right after "escape to open ground"; no "attack roll" right after a "hit"; "learned reach … (unseen strike, 2 hits)" for elites.

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
