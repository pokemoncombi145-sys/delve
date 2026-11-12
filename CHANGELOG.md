# Changelog

Newest first. The version is shown in the script window title (`Delve v4.0 | Brain`).

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
