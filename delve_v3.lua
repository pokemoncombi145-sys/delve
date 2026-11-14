local uiNotify = nil;
local function notify(message, title)
	print("[" .. tostring(title) .. "] " .. tostring(message));
	if uiNotify then
		pcall(uiNotify, tostring(message), tostring(title));
	end;
end;

local function start()
notify("Starting…", "Delve v3");
local env = (type(getgenv) == "function" and getgenv()) or _G;
local missingInput;
-- Executor compatibility (Volt, Potassium, etc.): any missing OS-input function is replaced with a
-- VirtualInputManager / window-focus based fallback so the farm still runs instead of refusing to start.
do
	local VIMc;
	pcall(function() VIMc = game:GetService("VirtualInputManager"); end);
	local UISc = game:GetService("UserInputService");
	local focused = true;
	pcall(function()
		UISc.WindowFocused:Connect(function() focused = true; end);
		UISc.WindowFocusReleased:Connect(function() focused = false; end);
	end);
	local digit = { [0] = "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" };
	local special = { [32] = "Space", [16] = "LeftShift", [160] = "LeftShift", [161] = "RightShift", [17] = "LeftControl", [18] = "LeftAlt", [9] = "Tab" };
	local function vkCode(vk)
		local name = special[vk];
		if not name and vk >= 65 and vk <= 90 then name = string.char(vk); end;
		if not name and vk >= 48 and vk <= 57 then name = digit[vk - 48]; end;
		return name and Enum.KeyCode[name];
	end;
	local mx, my = 0, 0;
	local shims = {};
	if type(isrbxactive) ~= "function" then
		shims.isrbxactive = function() return focused; end;
	end;
	if VIMc then
		if type(keypress) ~= "function" then
			shims.keypress = function(vk) local c = vkCode(vk); if c then pcall(VIMc.SendKeyEvent, VIMc, true, c, false, game); end; end;
		end;
		if type(keyrelease) ~= "function" then
			shims.keyrelease = function(vk) local c = vkCode(vk); if c then pcall(VIMc.SendKeyEvent, VIMc, false, c, false, game); end; end;
		end;
		if type(mousemoveabs) ~= "function" then
			shims.mousemoveabs = function(x, y) mx, my = x, y; pcall(VIMc.SendMouseMoveEvent, VIMc, x, y, game); end;
		end;
		if type(mouse1press) ~= "function" then
			shims.mouse1press = function() pcall(VIMc.SendMouseButtonEvent, VIMc, mx, my, 0, true, game, 0); end;
		end;
		if type(mouse1release) ~= "function" then
			shims.mouse1release = function() pcall(VIMc.SendMouseButtonEvent, VIMc, mx, my, 0, false, game, 0); end;
		end;
	end;
	for name, fn in pairs(shims) do
		if type(getgenv) == "function" then pcall(function() getgenv()[name] = fn; end); end;
		pcall(function() _G[name] = fn; end);
	end;
	isrbxactive = isrbxactive or shims.isrbxactive;
	keypress = keypress or shims.keypress;
	keyrelease = keyrelease or shims.keyrelease;
	mousemoveabs = mousemoveabs or shims.mousemoveabs;
	mouse1press = mouse1press or shims.mouse1press;
	mouse1release = mouse1release or shims.mouse1release;
	local required = {
		isrbxactive = isrbxactive, keypress = keypress, keyrelease = keyrelease,
		mousemoveabs = mousemoveabs, mouse1press = mouse1press, mouse1release = mouse1release,
	};
	local shimmed = {};
	for name in pairs(shims) do shimmed[#shimmed + 1] = name; end;
	if #shimmed > 0 then
		notify("Using VirtualInputManager fallback for: " .. table.concat(shimmed, ", "), "Delve");
	end;
	for name in string.gmatch("isrbxactive keypress keyrelease mousemoveabs mouse1press mouse1release", "%S+") do
		if type(required[name]) ~= "function" then
			missingInput = "Executor is missing input function: " .. name .. " (turn on Background mode)";
			notify(missingInput, "Delve");
			break;
		end;
	end;
end;

local instanceIds = setmetatable({}, { __mode = "k" });
local nextId = 0;
local function instanceId(instance)
	local id = instanceIds[instance];
	if not id then
		nextId = nextId + 1;
		id = nextId;
		instanceIds[instance] = id;
	end;
	return id;
end;

local m = {
		on = false,
		mine = true,
		walk = false,
		radius = .69,
		reach = 1.29,
		combat = true,
		chase = true,
		fightDist = 8,
		autoCombatStats = true,
		dodge = true,
		autoRoll = true,
		chests = true,
		centerFarm = false,
		autoReplay = false,
		antiAfk = false,
		dodgeLog = false,
		replayDelay = 2.5,
		chestRange = 120,
		keepAway = 7,
		hitMargin = 1.5,
		meleeReach = 5.5,
		rollLead = .2,
		feat = {},
		cardPick = true,
		-- brain / learning
		relicLearn = true,
		relicExplore = true,
		autoStage = false,
		stage = "Delve",
		stageOther = "",
		startClosed = true,
		niceToasts = true,
		dangerView = false,
		flankDodge = true,
		planFeed = true,
		pushForward = true,
		bossRolls = true,
		exploreForMobs = true,
		rangedFirst = true,
		uiGameFont = true,
		uiFont = "Game font",
		uiFontV = 0,
		replayFixV = 0,
		mechNotify = true,
		dangerTime = 15,
		dangerTimeV = 0,
		forkPath = "Smart",
		afterBossPath = "Descend",
		afterUnmaker = "Prestige portal",
		traderBuy = true,
		traderMinScore = 5,
		relicDelay = .3,
		relicNotify = true,
		dodgeLearn = true,
		smartEscape = true,
		cornerAvoid = true,
		edgeSafe = 6,
		relicCodexNotify = true,
		-- targeting priority (ores first, fight bosses / threats)
		mobPriority = "Smart",
		lowHpPct = 35,
		crowdSize = 5,
		-- settings / run reporting
		autoStartFarm = true,
		webhookOn = false,
		pingUserId = "",
		pingRuns = true,
		pingDrops = true,
		pingDisconnect = true,
		autoRejoin = true,
		vesperPause = true,
		webhookUrl = "",
		webhookDelay = 1.5,
		dropWebhook = true,
		rareDropOdds = 100000,
		attackRoll = "On",
		autoIndexScan = true,
		scanEveryRuns = 10,
		rareTopPct = 3,
		-- new settings
		mineRange = 150,
		autoStats = false,
		reachScale = 1,
		radiusScale = .85,
		centerOre = false,
		minTier = 1,
		skipAfter = 9,
		autoEquip = true,
		pickSlot = 1,
		weaponSlot = 2,
		rollKey = "Q",
		-- center farm / dodge fixes
		centerCleanup = true,
		rollCooldown = 1.05,
		pingComp = true,
		windupLearn = true,
		-- background / silent aim
		background = false,
		silentAim = false,
		bgKeyMethod = "Auto",
		bgMoveMethod = "Both",
		useLearned = true,
	};
local G = env.Delve;
if G and G.stop then
	pcall(G.stop);
end;
-- (v5.36) the previous copy's F2 listener too (older versions didn't drop it when stopped)
if G and G.f2Conn then
	pcall(function() G.f2Conn:Disconnect(); end);
end;
env.Delve = { cfg = (G and G.cfg) or m };
env.DelveLoadedAt = os.time();
local r = env.Delve;
local Q = r.cfg;
local CFG = Q; -- stable alias: much of the original code shadows Q locally
for m, G in pairs(m) do
	if Q[m] == nil then
		Q[m] = G;
	end;
end;
-- AUTOSAVE: every setting (toggles, sliders, dropdowns, webhook, farm on/off) is written to
-- DelveSettings.json whenever it changes and restored on the next load.
do
	local okRead, raw = pcall(function()
		if type(isfile) == "function" and not isfile("DelveSettings.json") then return nil; end;
		return type(readfile) == "function" and readfile("DelveSettings.json") or nil;
	end);
	if okRead and type(raw) == "string" and #raw > 2 then
		local okDec, data = pcall(function() return game:GetService("HttpService"):JSONDecode(raw); end);
		if okDec and type(data) == "table" then
			for k, v in pairs(data) do
				if k == "on" then
					r.savedOn = v == true;
				elseif k == "feat" and type(v) == "table" then
					Q.feat = type(Q.feat) == "table" and Q.feat or {};
					for fk, fv in pairs(v) do
						if type(fv) == "boolean" then Q.feat[fk] = fv; end;
					end;
				elseif m[k] ~= nil and k ~= "feat" and type(v) == type(m[k]) then
					Q[k] = v;
				elseif k == "v3Migrated" or k == "bgMigrated" or k == "rareMigrated" then
					Q[k] = v;
				end;
			end;
			r.settingsLoaded = true;
		end;
	end;
end;
-- REASONING LOG: why it fought / mined / took a relic. DelveReasoning.txt in the workspace + last 40 in memory
r.whyLines = {};
pcall(function()
	if type(isfile) == "function" and isfile("DelveReasoning.txt") and #readfile("DelveReasoning.txt") > 2000000 then
		writefile("DelveReasoning.txt", "");
	end;
end);
r.why = function(kind, text)
	local line = string.format("%s [%s] %s", os.date("%H:%M:%S"), tostring(kind), tostring(text));
	table.insert(r.whyLines, line);
	r.whySize = (r.whySize or 0) + #line + 1;
	if r.whySize > 3000000 then
		r.whySize = 0;
		pcall(function()
			writefile("DelveReasoning_old.txt", readfile("DelveReasoning.txt"));
			writefile("DelveReasoning.txt", "");
		end);
	end;
	while #r.whyLines > 40 do table.remove(r.whyLines, 1); end;
	pcall(function()
		if type(appendfile) == "function" then appendfile("DelveReasoning.txt", line .. "\n");
		elseif type(writefile) == "function" then writefile("DelveReasoning.txt", line .. "\n"); end;
	end);
end;
-- scan notices: tell the user when something that takes a while starts and how long it took
r.scanStart = function(label)
	notify(tostring(label) .. " in progress…", "Delve scan");
	return (type(os) == "table" and os.clock or tick)();
end;
r.scanEnd = function(label, t0, detail)
	local secs = (type(os) == "table" and os.clock or tick)() - (t0 or 0);
	local took = secs >= 60 and string.format("%dm %02ds", math.floor(secs / 60), math.floor(secs % 60)) or string.format("%.1f s", secs);
	notify(string.format("%s finished in %s.%s", tostring(label), took, detail and (" " .. tostring(detail)) or ""), "Delve scan");
	if r.why then r.why("scan", string.format("%s took %s", tostring(label), took)); end;
end;
r.saveSettings = function(force)
	if type(writefile) ~= "function" then return; end;
	local copy = {};
	for k, v in pairs(CFG) do
		local tv = type(v);
		if tv == "number" or tv == "string" or tv == "boolean" then copy[k] = v; end;
	end;
	copy.feat = CFG.feat;
	copy.on = (CFG.on or r.autoStart) and true or false;
	local ok, js = pcall(function() return game:GetService("HttpService"):JSONEncode(copy); end);
	if ok and (force or js ~= r.lastSettingsJson) then
		r.lastSettingsJson = js;
		pcall(writefile, "DelveSettings.json", js);
	end;
end;
-- (v2 forced cardPick off on every load, which is why relic auto-pick never ran)
if not Q.v3Migrated then
	Q.v3Migrated = true;
	Q.cardPick = true;
end;
-- learning and safety features are built in now (no longer settings): always on
for _, k in ipairs({ "relicLearn", "dodgeLearn", "smartEscape", "cornerAvoid", "windupLearn", "pingComp", "autoCombatStats" }) do
	Q[k] = true;
end;
-- (v5.41) settings taken out of the window: automatic now, fixed by the game itself, or needed on:
--   * mining reach and radius: always read from the game (and again whenever your buffs change)
--   * tools: the game binds the pickaxe to 1 and the weapon to 2 (its PickaxeController / WeaponController), and the
--     bot equips them by itself. The old "learned equip remotes" only replayed the message to the server (the game's
--     own equip code also updates the client), so key presses are used; in background mode the way keys are sent
--     still switches by itself when a press doesn't register.
--   * the roll: the game binds it to Q and Space (DodgeController); it presses Q
--   * background key and walk methods: Auto / Both (they find what works by themselves)
--   * the game's attack plans, walking up the road and the dodge log: always on
--   * Vesper's shop: the ping and pause on arrival are always on; "After the Unmaker" picks the portal
for k, v in pairs({ autoStats = true, autoEquip = true, pickSlot = 1, weaponSlot = 2, useLearned = false, rollKey = "Q",
	bgKeyMethod = "Auto", bgMoveMethod = "Both", planFeed = true, pushForward = true, dodgeLog = true, vesperPause = true }) do
	Q[k] = v;
end;
do
	-- (v5.41) the portal choice's new names; an old "Auto" attack-roll value is shown as "On" (it always meant on)
	local oldPortal = { ["Prestige I"] = "Prestige portal", ["Rare shop (?????)"] = "Vesper's shop (?????)", ["Don't enter"] = "Neither" };
	if oldPortal[Q.afterUnmaker] then Q.afterUnmaker = oldPortal[Q.afterUnmaker]; end;
	if Q.attackRoll ~= "Off" then Q.attackRoll = "On"; end;
end;
if not Q.rareMigrated then
	Q.rareMigrated = true;
	Q.rareDropOdds = 100000;
end;
if not Q.bgMigrated then
	Q.bgMigrated = true;
	if Q.bgKeyMethod == "VirtualInputManager" then
		Q.bgKeyMethod = "Auto";
	end;
end;
local e = {
		"mine",
		"walk",
		"combat",
		"chase",
		"dodge",
		"autoRoll",
		"chests",
	};
local function N(m)
	Q.on = m and true or false;
	r.farmOn = Q.on;
	for m, G in ipairs(e) do
		Q[G] = Q.on and Q.feat[G] ~= false;
	end;
end;
N(false);
if r.savedOn and Q.autoStartFarm ~= false then
	r.autoStart = true; -- farm was on last time: turn it back on as soon as a run is loaded
end;
local S = game:GetService("Players") or game.Players;
local w = game:GetService("ReplicatedStorage") or game.ReplicatedStorage;
local q = game:GetService("RunService") or game.RunService;
local l = S.LocalPlayer;
if not l then
	notify("Join Delve before running the script.", "Delve");
	return;
end;
local guiService = game:GetService("GuiService");
local d = (type(os) == "table" and os.clock) or tick;
local function f(m)
	if Q.dodgeLog then
		local line = string.format("%.2f %s\n", d(), m);
		pcall(appendfile, "dodge_log.txt", line);
		if r.logSize == nil then
			r.logSize = 0;
			pcall(function() if isfile("dodge_log.txt") then r.logSize = #readfile("dodge_log.txt"); end; end);
		end;
		r.logSize = r.logSize + #line;
		if r.logSize > 3000000 then
			r.logSize = 0;
			pcall(function()
				writefile("dodge_log_old.txt", readfile("dodge_log.txt"));
				writefile("dodge_log.txt", "");
			end);
		end;
	end;
end;
-- ===================================================================================
-- BRAIN: persistent memory that learns from your runs (saved to DelveBrain.json)
--   relics[name]  -> how runs went when that relic was taken, how often YOU picked it
--   cat[category] -> learned weight per relic stat category (damage, mining, survival...)
--   dodge         -> extra safety margin / roll timing learned from hits you took
--   mobReach[mob] -> real attack reach learned per mob (bosses with big swings)
-- ===================================================================================
-- BRAIN BACKUPS: a copy of DelveBrain.json in DelveBackups/ before any migration or reset, and at most
-- every 6 hours on load. Only the newest 8 are kept.
r.brainBackup = function(tag, raw)
	if type(writefile) ~= "function" then return false; end;
	local ok = pcall(function()
		if raw == nil then
			if type(isfile) == "function" and not isfile("DelveBrain.json") then return; end;
			raw = readfile("DelveBrain.json");
		end;
		if type(raw) ~= "string" or #raw < 3 then error("nothing to back up"); end;
		if type(makefolder) == "function" and not (type(isfolder) == "function" and isfolder("DelveBackups")) then
			pcall(makefolder, "DelveBackups");
		end;
		local safeTag = (tostring(tag or "backup"):gsub("[^%w%-]", "_"));
		writefile(string.format("DelveBackups/DelveBrain_%s_%s.json", os.date("%Y%m%d-%H%M%S"), safeTag), raw);
		if type(listfiles) == "function" and type(delfile) == "function" then
			local files = {};
			for _, f in ipairs(listfiles("DelveBackups")) do
				if tostring(f):find("DelveBrain_", 1, true) then files[#files + 1] = tostring(f); end;
			end;
			table.sort(files); -- names start with the date, so oldest first
			for k = 1, #files - 8 do pcall(delfile, files[k]); end;
		end;
	end);
	return ok;
end;
local brain = {
	file = "DelveBrain.json",
	v = 3,
	relics = {},
	cat = {},
	sets = {},
	runs = {},
	dodge = { extra = 0, leadAdj = 0, hits = 0, dodges = 0 },
	mobReach = {},
	windups = {},
	codex = {},   -- every relic ever seen: name, tier, effects, how it was understood
	pairs = {},   -- relic combos taken in the same run and how those runs went
	catMode = {}, -- category weights learned separately for delve runs and wave runs
	threat = {},  -- how close a mob may get before it's worth stopping mining to fight it
	attacks = {}, -- per attack type: extra distance, earlier roll, hits, deaths (learned from getting hit)
	floorHaz = {},-- floor parts that hurt you (lava strips etc.), learned from unexplained damage
	mech = {},    -- every game mechanic seen (rooms, card types, effects, objectives, screens) and how runs went with it
};
do
	local Http, BRAIN_FILE = game:GetService("HttpService"), brain.file;
	-- (v5.40) SAFE LOAD. A brain file cut off by a crash in the middle of a save used to load as an empty brain
	-- without a word, and the next save wrote that empty brain over it. Now an unreadable file is set aside
	-- (DelveBackups/BrainUnreadable_*.json, not one of the 8 backups) and the last good copy (DelveBrain_prev.json,
	-- checked when it was written) is loaded instead, or else the newest backup that reads; you're told either way.
	-- readBrain: the decoded table and its text; false + text if the file is there but unreadable; nil if missing.
	local function readBrain(name)
		local okR, text = pcall(function()
			if type(isfile) == "function" and not isfile(name) then return nil; end;
			return type(readfile) == "function" and readfile(name) or nil;
		end);
		if not okR or type(text) ~= "string" then return nil, nil; end;
		if #text == 0 and type(isfile) ~= "function" then return nil, nil; end;
		if #text <= 2 then return false, text; end;
		local okDec, data = pcall(Http.JSONDecode, Http, text);
		if okDec and type(data) == "table" then return data, text; end;
		return false, text;
	end;
	local data, raw = readBrain(BRAIN_FILE);
	if data == false then
		local badSize = #raw >= 1024 and string.format("%d KB", math.floor(#raw / 1024)) or string.format("%d bytes", #raw);
		pcall(function()
			if type(makefolder) == "function" and not (type(isfolder) == "function" and isfolder("DelveBackups")) then
				pcall(makefolder, "DelveBackups");
			end;
			writefile(string.format("DelveBackups/BrainUnreadable_%s.json", os.date("%Y%m%d-%H%M%S")), raw);
			-- only the newest 3 unreadable files are kept
			if type(listfiles) == "function" and type(delfile) == "function" then
				local files = {};
				for _, f in ipairs(listfiles("DelveBackups")) do
					if tostring(f):find("BrainUnreadable_", 1, true) then files[#files + 1] = tostring(f); end;
				end;
				table.sort(files);
				for k = 1, #files - 3 do pcall(delfile, files[k]); end;
			end;
		end);
		local from;
		local d2, s2 = readBrain("DelveBrain_prev.json");
		if d2 then
			data, raw, from = d2, s2, "the last good copy (DelveBrain_prev.json)";
		elseif type(listfiles) == "function" then
			local files = {};
			pcall(function()
				for _, f in ipairs(listfiles("DelveBackups")) do
					if tostring(f):find("DelveBrain_", 1, true) then files[#files + 1] = tostring(f); end;
				end;
			end);
			table.sort(files); -- names start with the date: newest last
			for k = #files, 1, -1 do
				local d3, s3 = readBrain(files[k]);
				if d3 then
					data, raw, from = d3, s3, "the backup " .. (files[k]:match("[^/\\]+$") or files[k]);
					break;
				end;
			end;
		end;
		if from then
			r.brainLoadNote = string.format("The brain file was damaged (cut off at %s, most likely Roblox closed during a save). Loaded %s instead; the damaged file is in DelveBackups (BrainUnreadable_...).", badSize, from);
		else
			data, raw = nil, nil;
			r.brainLoadNote = string.format("The brain file was damaged (cut off at %s) and no good copy was found, so the brain starts empty. The damaged file is in DelveBackups (BrainUnreadable_...).", badSize);
		end;
	end;
	if type(data) == "table" then
		for k, v in pairs(data) do
			if type(v) == type(brain[k]) or brain[k] == nil then
				brain[k] = v;
			end;
		end;
		r.brainLoadedSize = #raw;
	end;
	for _, key in ipairs({ "relics", "cat", "sets", "runs", "mobReach", "windups", "codex", "pairs", "catMode", "threat", "mech", "attacks", "floorHaz" }) do
		if type(brain[key]) ~= "table" then brain[key] = {}; end;
	end;
	if type(brain.dodge) ~= "table" then brain.dodge = {}; end;
	if type(data) == "table" and type(raw) == "string" then
		local migrating = (tonumber(brain.learnV) or 0) < 5 or (tonumber(brain.cleanV) or 0) < 3;
		if migrating or os.time() - (tonumber(brain.lastBackupAt) or 0) > 21600 then
			if r.brainBackup(migrating and "before-migration" or "auto", raw) then brain.lastBackupAt = os.time(); end;
		end;
	end;
	if (tonumber(brain.learnV) or 0) == 3 then
		-- v5.9.2: "dangerous floors" were learned from hits that were really unseen mob strikes
		brain.learnV = 4;
		brain.floorHaz = {};
	end;
	if (tonumber(brain.learnV) or 0) == 2 then
		-- v5.8.3: boss floors and roll distance were learned with a wrong "boss" rule / measurement
		brain.learnV = 4;
		brain.bossFloors, brain.floorHaz = {}, {};
		brain.rollDist = nil;
	end;
	if (tonumber(brain.learnV) or 0) < 2 then
		-- v5.4 audit: every attack shared one bucket ("Hazards/Part") so its numbers sat at their caps,
		-- category weights were all at the 2.5 cap, the run baseline mixed abandoned 40 s runs with real
		-- ones, and a sword reach of 119 studs was learned from proc damage. Start those fresh.
		brain.learnV = 4;
		brain.bossFloors, brain.rollDist, brain.floorHaz = {}, nil, {};
		brain.attacks, brain.patterns, brain.swordHit, brain.runs = {}, {}, {}, {};
		brain.cat, brain.catMode = {}, {};
		brain.dodge.iframe = .35;
		brain.dodge.leadAdj = 0;
	end;
	if (tonumber(brain.learnV) or 0) == 4 then
		-- v5.37 (a backup is written to DelveBackups first): floors were blamed for cave-in falls, the health reset
		-- at a run's start and planned attacks (Seg_1, the first floor slab of every run, had 34 "hits" and was
		-- avoided like lava); attack patterns and "seen shooting" counts went up every frame instead of once per
		-- attack (6 million "attacks" for one mob, every mob counted as a shooter). Those three start fresh.
		brain.learnV = 5;
		brain.floorHaz, brain.patterns, brain.ranged = {}, {}, {};
		r.brainMigrated = true;
	end;
	brain.dodge.extra = tonumber(brain.dodge.extra) or 0;
	brain.dodge.leadAdj = tonumber(brain.dodge.leadAdj) or 0;
	brain.dodge.hits = tonumber(brain.dodge.hits) or 0;
	brain.dodge.dodges = tonumber(brain.dodge.dodges) or 0;
	if (tonumber(brain.cleanV) or 0) < 1 then
		brain.cleanV = 1;
		local bad = {};
		for key, cx in pairs(brain.codex) do
			if type(cx) ~= "table" or tostring(cx.desc or ""):upper():find("1 IN %d") then bad[key] = true; end;
		end;
		for key in pairs(bad) do
			brain.codex[key], brain.relics[key], brain.sets[key] = nil, nil, nil;
		end;
		for pk in pairs(brain.pairs) do
			local a2, b2 = tostring(pk):match("^(.-)||(.*)$");
			if (a2 and bad[a2]) or (b2 and bad[b2]) then brain.pairs[pk] = nil; end;
		end;
	end;
	if next(brain.windups) then
		r.windups = r.windups or {};
		for name, dur in pairs(brain.windups) do
			if r.windups[name] == nil and tonumber(dur) then r.windups[name] = tonumber(dur); end;
		end;
	end;
end;
-- (v5.40) SAFE SAVE + SMALLER FILE (brain audit of 14 Nov, proposals A and B):
--   * decimals are cut to 3 places in the file (the brain in memory keeps full precision): about 15% smaller.
--     Only JSON numbers are touched (after : , or [ and before , ] } or an exponent); two passes, because a
--     match takes the comma after it, which the next number in a list needs.
--   * a value that isn't a number (NaN / infinity) would make the whole file unreadable: it's saved as 0.
--   * a save that would shrink the brain to under half of what's on disk is refused (it tells you once, and
--     what it would have written goes to DelveBrain_rejected.json), unless a migration or "Reset everything" did it.
--   * DelveBrain_prev.json: a copy checked by reading it back, at most every 10 minutes; loaded if the main file
--     is ever unreadable.
-- Returns true when written, or false and why.
local brainState = { dirty = false, savedAt = -1e9, prevAt = -1e9, diskSize = r.brainLoadedSize, shrinkOk = r.brainMigrated == true };
local function saveBrain(force)
	local now = d();
	if not force and (not brainState.dirty or now - brainState.savedAt < 15) then return false, "nothing new to save"; end;
	brainState.dirty, brainState.savedAt = false, now;
	if type(writefile) ~= "function" then return false, "this executor has no writefile"; end;
	if type(r.windups) == "table" then
		for name, dur in pairs(r.windups) do brain.windups[tostring(name)] = dur; end;
	end;
	local Http = game:GetService("HttpService");
	local okE, json = pcall(Http.JSONEncode, Http, brain);
	if not okE or type(json) ~= "string" or #json < 3 then
		if r.why and not brainState.encodeNoted then
			brainState.encodeNoted = true;
			r.why("brain", "brain not saved: it couldn't be written as JSON (" .. tostring(json) .. "); the file on disk is unchanged");
		end;
		return false, "it couldn't be written as JSON";
	end;
	for _ = 1, 2 do json = json:gsub("([:,%[]%-?%d+%.%d%d%d)%d+([eE,%]}])", "%1%2"); end;
	if json:find("[:,%[]%-?[iI][nN][fF]") or json:find("[:,%[]%-?[nN][aA][nN]") or json:find("[:,%[]%-?%d%.#") then
		local n1, n2, n3;
		json, n1 = json:gsub("([:,%[])%-?[iI][nN][fF][%a]*([,%]}])", "%10%2");
		json, n2 = json:gsub("([:,%[])%-?[nN][aA][nN][%w%(%)]*([,%]}])", "%10%2");
		json, n3 = json:gsub("([:,%[])%-?%d%.#%u+%d*([,%]}])", "%10%2");
		if n1 + n2 + n3 > 0 and r.why and not brainState.nanNoted then
			brainState.nanNoted = true;
			r.why("brain", "a learned value wasn't a number (NaN or infinity): saved as 0 so the file stays readable");
		end;
	end;
	local disk = tonumber(brainState.diskSize);
	if disk and #json < disk * .5 and not brainState.shrinkOk then
		local msg = string.format("Brain not saved: it would shrink from %d KB to %d KB. The brain on disk is kept; what it would have written is in DelveBrain_rejected.json.",
			math.floor(disk / 1024), math.floor(#json / 1024));
		if not brainState.refusedNoted then
			brainState.refusedNoted = true;
			pcall(writefile, "DelveBrain_rejected.json", json);
			notify(msg, "Delve brain");
			if r.why then r.why("brain", msg); end;
		end;
		-- try again in 5 minutes (sooner on a forced save: a death, a run's end, the Save button)
		brainState.dirty, brainState.savedAt = true, now + 285;
		return false, msg;
	end;
	if not pcall(writefile, "DelveBrain.json", json) then return false, "writing DelveBrain.json failed"; end;
	brainState.diskSize, brainState.shrinkOk = #json, false;
	if now - brainState.prevAt >= 600 then
		brainState.prevAt = now;
		if pcall(Http.JSONDecode, Http, json) then pcall(writefile, "DelveBrain_prev.json", json); end;
	end;
	return true;
end;
local function markBrain() brainState.dirty = true; end;
-- (v5.37) a migrated brain is written on the next save, so the old file isn't migrated (and backed up) again
if r.brainMigrated then markBrain(); end;
-- (v5.40) a damaged brain file: say so once the window is up (log, pop-up, Discord without a ping)
if r.brainLoadNote then
	if r.why then pcall(r.why, "brain", r.brainLoadNote); end;
	task.spawn(function()
		for _ = 1, 40 do
			if uiNotify then break; end;
			task.wait(1);
		end;
		notify(r.brainLoadNote, "Delve brain");
		if r.postEmbed then pcall(r.postEmbed, { title = "Delve: the brain file was damaged", description = r.brainLoadNote, color = 15105570 }, "brain"); end;
	end);
end;
r.brain = brain;
-- current run, used to judge how good the relics picked during it were
local run = { active = false, relics = {}, depth = 0, wave = 0, died = false, hits = 0, combatT = 0, mineT = 0 };
r.run = run;
local z = 8;
local x = 67108864;
-- Input backends. Foreground mode uses the executor's OS-level input (needs Roblox focused).
-- Background mode avoids OS input entirely so the game can sit behind other windows:
--   walking     -> Humanoid:Move every physics step
--   keys        -> VirtualInputManager (or the game's own InputBegan/InputEnded connections)
--   mouse aim   -> silent aim: the mouse values the game reads are spoofed, the real cursor never moves
--   GUI buttons -> fired directly (replay button, relic cards)
local inp = {};
do
	local UIS = game:GetService("UserInputService");
	local VIM;
	pcall(function() VIM = game:GetService("VirtualInputManager"); end);
	-- shared with the metamethod hooks, which are installed once per executor session
	local shared = env.DelveAim;
	if type(shared) ~= "table" then
		shared = {};
		env.DelveAim = shared;
	end;
	shared.mouse = l:GetMouse();
	shared.uis = UIS;
	shared.inset = guiService:GetGuiInset();
	shared.world, shared.view = nil, nil;
	inp.moveVec = nil;
	inp.learned = type(env.DelveLearned) == "table" and env.DelveLearned or {};
	env.DelveLearned = inp.learned;
	inp.keyMode = {};

	local osKeypress, osKeyrelease, osMoveAbs = keypress, keyrelease, mousemoveabs;
	local osDown, osUp, osActive = mouse1press, mouse1release, isrbxactive;

	local digitNames = { [0] = "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" };
	local specialEnums = { [32] = "Space", [16] = "LeftShift", [160] = "LeftShift", [161] = "RightShift", [17] = "LeftControl", [18] = "LeftAlt", [9] = "Tab" };
	local function keyEnum(vk)
		local name = specialEnums[vk];
		if not name and vk >= 65 and vk <= 90 then name = string.char(vk); end;
		if not name and vk >= 48 and vk <= 57 then name = digitNames[vk - 48]; end;
		return name and Enum.KeyCode[name];
	end;

	function inp.active()
		if Q.background == true then return true; end;
		return type(osActive) == "function" and osActive() or false;
	end;
	function inp.focused()
		return type(osActive) == "function" and osActive() or false;
	end;
	function inp.silent()
		return (Q.silentAim == true or Q.background == true) and shared.hooked == true;
	end;

	-- keys ---------------------------------------------------------------
	local function viaConnections(code, down)
		if type(getconnections) ~= "function" then return false; end;
		local input = {
			KeyCode = code,
			UserInputType = Enum.UserInputType.Keyboard,
			UserInputState = down and Enum.UserInputState.Begin or Enum.UserInputState.End,
			Position = Vector3.zero,
			Delta = Vector3.zero,
			IsModifierKeyDown = function() return false; end,
		};
		local fired = false;
		for _, c in ipairs(getconnections(down and UIS.InputBegan or UIS.InputEnded)) do
			local fn = c.Function;
			if type(fn) == "function" then
				task.spawn(fn, input, false);
				fired = true;
			end;
		end;
		return fired;
	end;
	local function viaVim(code, down)
		return VIM ~= nil and (pcall(VIM.SendKeyEvent, VIM, down, code, false, game));
	end;
	local function sendKey(vk, down)
		local code = keyEnum(vk);
		if not code then return false; end;
		local method = Q.bgKeyMethod;
		if method == "Input connections" then
			return viaConnections(code, down);
		elseif method == "VirtualInputManager" then
			return viaVim(code, down) or viaConnections(code, down);
		end;
		-- Auto: VirtualInputManager only reaches the game while Roblox is focused, so when tabbed out use the
		-- game's own input connections. If a tool key stops having an effect, OQ rotates this key's method.
		if inp.focused() then
			return viaVim(code, down) or viaConnections(code, down);
		end;
		local mode = inp.keyMode[vk] or "connections";
		if mode == "vim" then
			return viaVim(code, down) or viaConnections(code, down);
		elseif mode == "both" then
			local a = viaConnections(code, down);
			local b = viaVim(code, down);
			return a or b;
		end;
		return viaConnections(code, down) or viaVim(code, down);
	end;
	local modeOrder = { "connections", "vim", "both" };
	function inp.rotateKey(vk)
		local current = inp.keyMode[vk] or "connections";
		local nextIndex = 1;
		for i, name in ipairs(modeOrder) do
			if name == current then nextIndex = i % #modeOrder + 1; end;
		end;
		inp.keyMode[vk] = modeOrder[nextIndex];
		return inp.keyMode[vk];
	end;
	function inp.key(vk, down)
		if Q.background == true then
			sendKey(vk, down);
		elseif down then
			if osKeypress then osKeypress(vk); end;
		else
			if osKeyrelease then osKeyrelease(vk); end;
		end;
	end;

	-- real mouse (foreground only) -------------------------------------------
	function inp.mouseMove(x, y) if osMoveAbs then osMoveAbs(x, y); end; end;
	function inp.mouseDown() if osDown then osDown(); end; end;
	function inp.mouseUp() if osUp then osUp(); end; end;

	-- GUI buttons ------------------------------------------------------------
	local function fireEvent(signal)
		if type(firesignal) == "function" and pcall(firesignal, signal) then
			return true;
		end;
		if type(getconnections) == "function" then
			local fired = false;
			for _, c in ipairs(getconnections(signal)) do
				if type(c.Fire) == "function" then
					pcall(c.Fire, c);
					fired = true;
				elseif type(c.Function) == "function" then
					task.spawn(c.Function);
					fired = true;
				end;
			end;
			return fired;
		end;
		return false;
	end;
	function inp.clickGui(button)
		if not button then return false; end;
		local target = button:IsA("GuiButton") and button or button:FindFirstChildWhichIsA("GuiButton", true);
		if not target then return false; end;
		return fireEvent(target.Activated) or fireEvent(target.MouseButton1Click);
	end;

	-- walking ----------------------------------------------------------------
	local function humanoid()
		local character = l.Character;
		return character and character:FindFirstChildOfClass("Humanoid"), character;
	end;
	function inp.setMove(x, z)
		inp.moveVec = Vector3.new(x, 0, z);
	end;
	function inp.clearMove()
		if inp.moveVec then
			inp.moveVec = nil;
			local h = humanoid();
			if h then pcall(h.Move, h, Vector3.zero, false); end;
		end;
	end;
	local function applyMove()
		local v = inp.moveVec;
		if not v or not (Q.background == true or inp.testing) then return; end;
		local h, character = humanoid();
		if not h then return; end;
		local method = Q.bgMoveMethod or "Both";
		if method ~= "Velocity" then
			h:Move(v, false);
		end;
		if method ~= "Humanoid:Move" then
			local root = character:FindFirstChild("HumanoidRootPart");
			if root then
				local vel = root.AssemblyLinearVelocity;
				root.AssemblyLinearVelocity = Vector3.new(v.X * h.WalkSpeed, vel.Y, v.Z * h.WalkSpeed);
			end;
		end;
	end;
	-- the default controls write Move(0) on RenderStepped, so ours is written at several points in the frame:
	-- after them on RenderStepped, before physics on Stepped, and again on Heartbeat
	pcall(function() q:UnbindFromRenderStep("DelveMove"); end);
	pcall(function() q:BindToRenderStep("DelveMove", 2000, applyMove); end);
	inp.moveConn = q.Stepped:Connect(applyMove);
	inp.moveConn2 = q.Heartbeat:Connect(applyMove);

	-- silent aim -------------------------------------------------------------
	function inp.setAim(world)
		local camera = workspace.CurrentCamera;
		if not camera then return false; end;
		local p = camera:WorldToViewportPoint(world);
		if p.Z <= 0 then
			shared.world, shared.view, shared.target = nil, nil, nil;
			return false;
		end;
		shared.world = world;
		shared.view = Vector2.new(p.X, p.Y);
		-- Mouse.Target: whatever the camera ray through the aim point hits first (mining may read this)
		local origin = camera.CFrame.Position;
		local delta = world - origin;
		local params = RaycastParams.new();
		params.FilterType = Enum.RaycastFilterType.Exclude;
		params.FilterDescendantsInstances = { l.Character };
		local result = workspace:Raycast(origin, delta.Unit * (delta.Magnitude + 25), params);
		shared.target = result and result.Instance or nil;
		return true;
	end;
	function inp.clearAim()
		shared.world, shared.view, shared.target = nil, nil, nil;
	end;
	local function installHooks()
		if shared.hooked and shared.hookVersion == 2 then return true; end;
		if type(hookmetamethod) ~= "function" or type(newcclosure) ~= "function"
			or type(checkcaller) ~= "function" or type(getnamecallmethod) ~= "function" then
			return shared.hooked == true;
		end;
		local ok = pcall(function()
			local oldIndex;
			oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
				local view = shared.view;
				if view and self == shared.mouse and not checkcaller() then
					if key == "Target" then
						if shared.target then return shared.target; end;
					elseif key == "Hit" then
						return CFrame.new(shared.world);
					elseif key == "X" then
						return view.X;
					elseif key == "Y" then
						return view.Y - shared.inset.Y;
					elseif key == "UnitRay" then
						local origin = workspace.CurrentCamera.CFrame.Position;
						return Ray.new(origin, (shared.world - origin).Unit);
					end;
				end;
				return oldIndex(self, key);
			end));
			local oldNamecall;
			oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
				local view = shared.view;
				if view and self == shared.uis and getnamecallmethod() == "GetMouseLocation" and not checkcaller() then
					return view;
				end;
				return oldNamecall(self, ...);
			end));
		end);
		if ok then
			shared.hooked = true;
			shared.hookVersion = 2;
		end;
		return shared.hooked == true;
	end;
	function inp.ensureSilent()
		if Q.background == true or Q.silentAim == true then
			if not installHooks() then
				notify("Silent aim needs hookmetamethod, newcclosure, checkcaller and getnamecallmethod. One is missing in this executor build, so the real mouse is used.", "Delve");
			end;
		end;
	end;

	-- learn the game's own equip remotes ---------------------------------------
	-- A key press can't reach every game script while tabbed out, so instead record which remotes the game
	-- fires when you swap tools by hand, then replay exactly those calls in background mode.
	local function installRecorder()
		if shared.recHooked then return true; end;
		if type(hookmetamethod) ~= "function" or type(newcclosure) ~= "function"
			or type(checkcaller) ~= "function" or type(getnamecallmethod) ~= "function" then
			return false;
		end;
		local ok = pcall(function()
			local old;
			old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
				local log = shared.remoteLog;
				if log then
					local method = getnamecallmethod();
					if (method == "FireServer" or method == "InvokeServer") and not checkcaller() then
						log[#log + 1] = { t = d(), remote = self, method = method, args = table.pack(...) };
						if #log > 600 then table.remove(log, 1); end;
					end;
				end;
				return old(self, ...);
			end));
		end);
		shared.recHooked = ok;
		return ok;
	end;

	function inp.learn(action, vk)
		if not installRecorder() then
			notify("Learning needs hookmetamethod, newcclosure, checkcaller and getnamecallmethod.", "Delve learn");
			return;
		end;
		local code = keyEnum(vk);
		if not code then return; end;
		shared.remoteLog = {};
		local finished = false;
		local conn;
		conn = UIS.InputBegan:Connect(function(input)
			if finished or input.KeyCode ~= code then return; end;
			finished = true;
			conn:Disconnect();
			local pressAt = d();
			task.delay(.4, function()
				local log = shared.remoteLog or {};
				shared.remoteLog = nil;
				-- remotes that fire constantly before the press are background traffic, not the swap
				local baseline = {};
				for _, call in ipairs(log) do
					if call.t < pressAt - .05 then
						baseline[call.remote] = (baseline[call.remote] or 0) + 1;
					end;
				end;
				local found = {};
				for _, call in ipairs(log) do
					if call.t >= pressAt - .02 and (baseline[call.remote] or 0) < 3 then
						found[#found + 1] = { remote = call.remote, method = call.method, args = call.args };
					end;
				end;
				if #found == 0 then
					notify("Learn '" .. action .. "': nothing fired besides constant background traffic. Try again with the OTHER tool out so the key really swaps.", "Delve learn");
					return;
				end;
				inp.learned[action] = found;
				local names = {};
				for _, call in ipairs(found) do
					names[#names + 1] = call.remote.Name;
				end;
				notify(string.format("Learned '%s': %d remote call%s (%s). Background mode now replays these instead of pressing the key.",
					action, #found, #found == 1 and "" or "s", table.concat(names, ", ")), "Delve learn");
			end);
		end);
		task.delay(10, function()
			if not finished then
				finished = true;
				conn:Disconnect();
				shared.remoteLog = nil;
				notify("Learn '" .. action .. "': no key press seen in 10 seconds. Roblox must be focused while you press it.", "Delve learn");
			end;
		end);
		notify(string.format("Learning '%s'. Click into Roblox and press that tool's key within 10 seconds (have the OTHER tool out first so it really swaps).", action), "Delve learn");
	end;

	function inp.replay(action)
		local list = inp.learned[action];
		if not list or not list[1] then return false; end;
		for _, call in ipairs(list) do
			local remote = call.remote;
			if remote and remote.Parent then
				local args = call.args;
				if call.method == "InvokeServer" then
					task.spawn(function() remote:InvokeServer(table.unpack(args, 1, args.n)); end);
				else
					pcall(function() remote:FireServer(table.unpack(args, 1, args.n)); end);
				end;
			end;
		end;
		return true;
	end;

	function inp.report()
		local function has(fn) return type(fn) == "function" and "yes" or "NO"; end;
		return string.format("hookmetamethod %s | newcclosure %s | checkcaller %s | getnamecallmethod %s | VirtualInputManager %s | getconnections %s | firesignal %s | hooks installed: %s",
			has(hookmetamethod), has(newcclosure), has(checkcaller), has(getnamecallmethod),
			VIM and "yes" or "NO", has(getconnections), has(firesignal), shared.hooked and "yes" or "no");
	end;

	function inp.status()
		local h, character = humanoid();
		return string.format("background=%s silent=%s hooks=%s aimSet=%s target=%s moveVec=%s MoveDirection=%.2f PickaxeOut=%s WeaponDrawn=%s keys=%s move=%s learned weapon/pickaxe=%d/%d",
			tostring(Q.background == true), tostring(inp.silent()), tostring(shared.hooked == true), tostring(shared.view ~= nil),
			tostring(shared.target and shared.target.Name), tostring(inp.moveVec ~= nil),
			h and h.MoveDirection.Magnitude or -1,
			tostring(character and character:GetAttribute("PickaxeOut")), tostring(character and character:GetAttribute("WeaponDrawn")),
			tostring(Q.bgKeyMethod), tostring(Q.bgMoveMethod or "Both"),
			#(inp.learned.weapon or {}), #(inp.learned.pickaxe or {}));
	end;

	-- sends a slot key with the background key method and reports whether the game reacted
	function inp.testEquip(vk, attribute, label)
		local character = l.Character;
		if not character then
			notify("No character yet.", "Delve test");
			return;
		end;
		local before = character:GetAttribute(attribute);
		sendKey(vk, true);
		task.wait(.08);
		sendKey(vk, false);
		task.wait(.7);
		local after = character:GetAttribute(attribute);
		local focused = type(osActive) == "function" and osActive();
		local connections = type(getconnections) == "function" and #getconnections(UIS.InputBegan) or -1;
		notify(string.format("%s: %s %s -> %s | key method %s | Roblox %s | %d InputBegan connections%s",
			label, attribute, tostring(before), tostring(after), tostring(Q.bgKeyMethod),
			focused and "focused" or "tabbed out", connections,
			before == after and " | NO CHANGE: the game did not react to the key" or ""), "Delve test");
	end;

	-- walks forward for one second with the background movement method and reports the distance
	function inp.testWalk()
		local h, character = humanoid();
		local root = character and character:FindFirstChild("HumanoidRootPart");
		local camera = workspace.CurrentCamera;
		if not (h and root and camera) then
			notify("No character or camera yet.", "Delve test");
			return;
		end;
		local look = camera.CFrame.LookVector;
		local flat = Vector3.new(look.X, 0, look.Z).Unit;
		local from = root.Position;
		inp.testing = true;
		inp.setMove(flat.X, flat.Z);
		task.wait(1);
		local moveDirection = h.MoveDirection.Magnitude;
		inp.clearMove();
		inp.testing = false;
		local moved = (root.Position - from) * Vector3.new(1, 0, 1);
		notify(string.format("Walk test: moved %.1f studs in 1s (WalkSpeed %.0f, MoveDirection %.2f, method %s)%s",
			moved.Magnitude, h.WalkSpeed, moveDirection, tostring(Q.bgMoveMethod or "Both"),
			moved.Magnitude < 1 and " | DID NOT MOVE" or ""), "Delve test");
	end;

	function inp.stop()
		pcall(function() q:UnbindFromRenderStep("DelveMove"); end);
		if inp.moveConn then
			inp.moveConn:Disconnect();
			inp.moveConn = nil;
		end;
		if inp.moveConn2 then
			inp.moveConn2:Disconnect();
			inp.moveConn2 = nil;
		end;
		inp.clearMove();
		inp.clearAim();
	end;
end;
-- INPUT-BACKENDS-END
local function farmBlocker()
	if missingInput and Q.background ~= true then return missingInput; end;
	if not w:FindFirstChild("StrataNet") and not workspace:FindFirstChild("StrataPlate") then
		return "Waiting for Delve. Join a run and try again.";
	end;
end;
local function W(m)
	local G, r = 0, nil;
	for m, Q in ipairs(m:GetDescendants()) do
		local e = Q.ClassName;
		if e == "Part" or e == "MeshPart" then
			G = G + 1;
			if not r then
				r = Q.Color;
			end;
		end;
	end;
	local Q = r and string.format("%d,%d,%d", math.floor(r.R + .5), math.floor(r.G + .5), math.floor(r.B + .5)) or "-";
	return G, Q;
end;
local K, o = {}, {};
local F = {};
do
	local m = w:FindFirstChild("Assets");
	local G = m and m:FindFirstChild("Rocks");
	if G then
		for m, G in ipairs(G:GetChildren()) do
			local r, Q = W(G);
			K[r .. (("|" .. Q))] = G.Name;
			if o[r] == nil then
				o[r] = G.Name;
			else
				o[r] = false;
			end;
		end;
	end;
	local r = m and m:FindFirstChild("Mobs");
	if r then
		for m, G in ipairs(r:GetChildren()) do
			F[G.Name] = true;
		end;
	end;
end;
local j = { DelveCursedRock = true, DelveSporeBloom = true };
local R = {
		DelveTimeCrystal = 25,
		DelveTreasureGeode = 25,
		DelveRelicFountain = 15,
		DelveBlastRock = 3,
	};
local function C(m)
	if j[m] then
		return -6;
	end;
	if R[m] then
		return R[m];
	end;
	local G = tonumber(m and m:match("(%d+)$"));
	if not G or G <= 1 then
		return 1;
	end;
	return G * G;
end;
local D = {};
local E = nil;
local a = nil;
local i, s, O = {}, nil, false;
local V = {};
local function orePart(ore)
	if ore:IsA("BasePart") then return ore; end;
	return ore:FindFirstChildWhichIsA("BasePart") or ore:FindFirstChildWhichIsA("BasePart", true);
end;
local function y(m)
	local G = 10;
	local Q = workspace:FindFirstChild("StrataPlate");
	if not Q then
		if E then
			D, E, a = {}, nil, nil;
		end;
		return false;
	end;
	local e = instanceId(Q);
	if e ~= E then
		D, E, a, r.lastAim = {}, e, nil, nil;
		s, i, O, V = nil, {}, true, {};
		r.groundTileCount = nil;
		r.gone = {};
		r.centerFarmTiles, r.centerFarmTile, r.centerFarmChest = nil, nil, nil;
		r.statsFound = false;
	end;
	local N = Q:FindFirstChild("Ground");
	local S = N and N:GetChildren();
	local w = S and ((S[1] and instanceId(S[1])));
	local tileCount = S and #S or 0;
	if w ~= s or tileCount ~= r.groundTileCount then
		local oldTiles, oldCount = i, r.groundTileCount;
		s, i, O, V = w, {}, true, {};
		r.groundTileCount = tileCount;
		for m, G in ipairs(S or {}) do
			local r, Q = G.Name:match("^Tile_(%d+)_(%d+)$");
			if r then
				local m = G.Position;
				r, Q = tonumber(r), tonumber(Q);
				i[#i + 1] = {
						cx = r,
						cz = Q,
						wx = m.X,
						wz = m.Z,
						wy = m.Y,
					};
				V[r * 4096 + Q] = true;
			end;
		end;
		-- the floor is collapsing: remember where tiles just vanished (that side is about to fall away)
		if oldCount and tileCount < oldCount and oldTiles and #oldTiles > 0 then
			local now = d();
			r.gone = type(r.gone) == "table" and r.gone or {};
			local added = 0;
			for _, t in ipairs(oldTiles) do
				if not V[t.cx * 4096 + t.cz] then
					r.gone[#r.gone + 1] = { x = t.wx, z = t.wz, t = now };
					added = added + 1;
				end;
			end;
			while #r.gone > 0 and (now - r.gone[1].t > 25 or #r.gone > 400) do table.remove(r.gone, 1); end;
			if added > 0 then r.collapseAt = now; end;
		end;
	end;
	local q = {};
	for Q, e in ipairs(Q:GetChildren()) do
		local N = e.Name;
		local S = tonumber(N);
		if S then
			q[N] = true;
			local Q = instanceId(e);
			local w = D[N];
			if w and w.addr ~= Q then
				D[N] = nil;
				r.lastAim = nil;
				if #i < 3 then
					a = nil;
				end;
			end;
			if not D[N] then
				local part = orePart(e);
				if part then
					local G = part.Position;
					local r, w;
					if S >= x then
						local m = S - x;
						r = math.floor(m / 1024);
						w = ((m - r * 1024)) + .5;
						r = r + .5;
					else
						r = math.floor(S / 1024);
						w = S - r * 1024;
					end;
					local q, l = W(e);
					local d = K[q .. (("|" .. l))] or o[q] or "?";
					D[N] = {
							cx = r,
							cz = w,
							wx = G.X,
							wy = G.Y,
							wz = G.Z,
							kind = d,
							addr = Q,
							instance = e,
						};
				end;
			else
				local r = D[N];
				local Q = not r.settled or (G > 0 and m - ((r.readAt or 0)) > 3);
				if Q then
					if r.settled then
						G = G - 1;
					end;
					local part = orePart(e);
					local N = part and part.Position;
					if not N then
						D[e.Name] = nil;
					else
						r.readAt = m;
						if math.abs(N.Y - r.wy) < .05 and ((math.abs(N.X - r.wx) < .05 and math.abs(N.Z - r.wz) < .05)) then
							r.stillSince = r.stillSince or m;
							if m - r.stillSince >= 1.5 then
								r.settled = true;
							end;
						else
							r.stillSince, r.settled = nil, false;
							if #i < 3 then
								a = nil;
							end;
						end;
						r.wx, r.wy, r.wz = N.X, N.Y, N.Z;
					end;
				end;
			end;
		end;
	end;
	for m in pairs(D) do
		if not q[m] then
			D[m] = nil;
		end;
	end;
	return true;
end;
r.debugRocks = function()
		local m, G = 0, nil;
		for r, Q in pairs(D) do
			m = m + 1;
			G = G or string.format("%s@%.0f,%.0f,%.0f", r, Q.wx, Q.wy, Q.wz);
		end;
		return m, G, E, a ~= nil;
	end;
local function b(m, G)
	local r = ((m[1] * ((m[5] * m[9] - m[6] * m[8])) - m[2] * ((m[4] * m[9] - m[6] * m[7])))) + m[3] * ((m[4] * m[8] - m[5] * m[7]));
	if math.abs(r) < 1e-09 then
		return nil;
	end;
	local function Q(m, G, r)
		return ((m[1] * ((G[2] * r[3] - G[3] * r[2])) - G[1] * ((m[2] * r[3] - m[3] * r[2])))) + r[1] * ((m[2] * G[3] - m[3] * G[2]));
	end;
	local e, N, S = { m[1], m[4], m[7] }, { m[2], m[5], m[8] }, { m[3], m[6], m[9] };
	return { Q(G, N, S) / r, Q(e, G, S) / r, Q(e, N, G) / r };
end;
local function v(m, G, r, Q)
	local e = {
			0,
			0,
			0,
			0,
			0,
			0,
			0,
			0,
			0,
		};
	local N = { 0, 0, 0 };
	for m, S in ipairs(m) do
		local w, q, l = S[G], S[r], S[Q];
		e[1] = e[1] + w * w;
		e[2] = e[2] + w * q;
		e[3] = e[3] + w;
		e[5] = e[5] + q * q;
		e[6] = e[6] + q;
		e[9] = e[9] + 1;
		N[1] = N[1] + w * l;
		N[2] = N[2] + q * l;
		N[3] = N[3] + l;
	end;
	e[4], e[7], e[8] = e[2], e[3], e[6];
	return b(e, N);
end;
local function n(m)
	if #i >= 3 then
		if O or not a then
			O = false;
			local m, G = v(i, "wx", "wz", "cx"), v(i, "wx", "wz", "cz");
			local r, Q = v(i, "cx", "cz", "wx"), v(i, "cx", "cz", "wz");
			if m and ((G and ((r and Q)))) then
				return {
					toCx = m,
					toCz = G,
					toWx = r,
					toWz = Q,
					y = i[1].wy + 1.8,
				};
			end;
		else
			return a;
		end;
	end;
	if #m < 3 then
		return a;
	end;
	local G = v(m, "wx", "wz", "cx");
	local r = v(m, "wx", "wz", "cz");
	local Q = v(m, "cx", "cz", "wx");
	local e = v(m, "cx", "cz", "wz");
	if not ((G and ((r and ((Q and e)))))) then
		return a;
	end;
	local N = 0;
	for m, G in ipairs(m) do
		N = N + G.wy;
	end;
	return {
		toCx = G,
		toCz = r,
		toWx = Q,
		toWz = e,
		y = N / #m,
	};
end;
local function g(m, G, r)
	return ((m.toCx[1] * G + m.toCx[2] * r)) + m.toCx[3], ((m.toCz[1] * G + m.toCz[2] * r)) + m.toCz[3];
end;
local function Z(m, G, r)
	return Vector3.new(((m.toWx[1] * G + m.toWx[2] * r)) + m.toWx[3], m.y, ((m.toWz[1] * G + m.toWz[2] * r)) + m.toWz[3]);
end;
local k, T, A, h, U = .707, -0.707, -0.707, -0.707, .91;
local function B()
	local m = workspace.CurrentCamera;
	if not m then
		return;
	end;
	local G = m.CFrame;
	local r, Q = G.RightVector, G.LookVector;
	local e = math.sqrt(r.X * r.X + r.Z * r.Z);
	local N = math.sqrt(Q.X * Q.X + Q.Z * Q.Z);
	if e < .001 or N < .001 then
		return;
	end;
	k, T, A, h = r.X / e, r.Z / e, Q.X / N, Q.Z / N;
	U = math.max(.2, math.min(1, -Q.Y));
end;
local function M(m, G)
	local r = m * k + G * T;
	local Q = ((m * A + G * h)) * U;
	return math.sqrt(r * r + Q * Q);
end;
local L = nil;
local X = nil;
local u = nil;
local Y = 0;
local function p(m, G, r, Q, e)
	local N = M(r - m, Q - G);
	if N <= e or N < 1e-06 then
		return r, Q;
	end;
	local S = e / N;
	return m + ((r - m)) * S, G + ((Q - G)) * S;
end;
local function H(m)
	local G = {};
	for m, r in ipairs(m) do
		local Q = math.floor(r.cx) * 4096 + math.floor(r.cz);
		local e = G[Q];
		if not e then
			e = {};
			G[Q] = e;
		end;
		e[#e + 1] = r;
	end;
	return G;
end;
-- Mining coverage uses grid distance. Camera pitch only affects aim reach.
local function miningDistanceSquared(dx, dz)
	return dx * dx + dz * dz;
end;
local function t(m, G, r, Q)
	local e, N = 0, 0;
	local S = math.ceil(Q) + 1;
	local radiusSquared = Q * Q;
	local w, q = math.floor(G), math.floor(r);
	for w = w - S, w + S, 1 do
		for S = q - S, q + S, 1 do
			local q = m[w * 4096 + S];
			if q then
				for m, S in ipairs(q) do
					if miningDistanceSquared(S.cx - G, S.cz - r) <= radiusSquared then
						e = e + S.w;
						if S.w > 0 then
							N = N + 1;
						end;
					end;
				end;
			end;
		end;
	end;
	return e, N;
end;
local function P(m, G, r, Q)
	local e = {};
	local N = math.ceil(2 * r);
	for m, S in ipairs(m) do
		if S.w > 0 then
			e[#e + 1] = { S.cx, S.cz, S.instance };
			if Q then
				for m = -0.5, .5, 1 do
					for G = -0.5, .5, 1 do
						e[#e + 1] = { S.cx + m, S.cz + G };
					end;
				end;
				local m, Q = math.floor(S.cx), math.floor(S.cz);
				for m = m - N, m + N, 1 do
					for Q = Q - N, Q + N, 1 do
						local N = G[m * 4096 + Q];
						if N then
							for m, G in ipairs(N) do
								if G.w > 0 and ((((G.cx > S.cx or (G.cx == S.cx and G.cz > S.cz))) and miningDistanceSquared(G.cx - S.cx, G.cz - S.cz) <= 4 * r * r)) then
									e[#e + 1] = { ((S.cx + G.cx)) / 2, ((S.cz + G.cz)) / 2 };
								end;
							end;
						end;
					end;
				end;
			end;
		end;
	end;
	return e;
end;
local J = {};
local function I(m, G, r, Q, e)
	local N = {};
	for m, S in ipairs(m) do
		local w, q = t(G, S[1], S[2], r);
		if q > 0 and w > 0 then
			N[#N + 1] = {
					ax = S[1],
					az = S[2],
					score = w,
					v = w / ((1 + .04 * M(S[1] - Q, S[2] - e))),
				};
		end;
	end;
	table.sort(N, function(m, G)
		return m.v > G.v;
	end);
	local S = {};
	for m, G in ipairs(N) do
		local Q = true;
		for m, e in ipairs(S) do
			if M(G.ax - e.ax, G.az - e.az) < r * 1.5 then
				Q = false;
				break;
			end;
		end;
		if Q then
			S[#S + 1] = G;
			if #S >= 60 then
				break;
			end;
		end;
	end;
	return S;
end;
local function ml(m, G, r, Q)
	local e, N = {}, {};
	local S, w = G, r;
	if Q then
		e[1], N[Q] = Q, true;
		S, w = m[Q].ax, m[Q].az;
	end;
	while #e < #m do
		local G, r = nil, nil;
		for m, Q in ipairs(m) do
			if not N[m] then
				local e = M(Q.ax - S, Q.az - w);
				if not r or e < r then
					G, r = m, e;
				end;
			end;
		end;
		N[G] = true;
		e[#e + 1] = G;
		S, w = m[G].ax, m[G].az;
	end;
	return e;
end;
local function Gl(m, G, r, Q, e)
	local function N(e)
		if e == 0 then
			return r, Q;
		end;
		local N = m[G[e]];
		return N.ax, N.az;
	end;
	local function S(m, G)
		local r, Q = N(m);
		local e, S = N(G);
		return M(r - e, Q - S);
	end;
	local w = #G;
	local q, l = true, 0;
	while q and l < 20 do
		q, l = false, l + 1;
		for m = e and 2 or 1, w - 1, 1 do
			for r = m + 1, w, 1 do
				local Q = S(m - 1, m) + ((r < w and S(r, r + 1) or 0));
				local e = S(m - 1, r) + ((r < w and S(m, r + 1) or 0));
				if e < Q - 1e-06 then
					local Q, e = m, r;
					while Q < e do
						G[Q], G[e] = G[e], G[Q];
						Q, e = Q + 1, e - 1;
					end;
					q = true;
				end;
			end;
		end;
	end;
	return G;
end;
local function rl(m, G, r, Q)
	local e, N, S = 0, r, Q;
	for G, r in ipairs(G) do
		local Q = m[r];
		e = e + M(Q.ax - N, Q.az - S);
		N, S = Q.ax, Q.az;
	end;
	return e;
end;
local function cQ(m)
	local camera = workspace.CurrentCamera;
	if not camera then return nil; end;
	local G, r = camera:WorldToScreenPoint(m);
	if (not r or (G.X == 0 and G.Y == 0)) and not (inp.silent() and G.Z > 0) then
		return nil;
	end;
	return G;
end;
-- how close a point is to where the floor just collapsed: 1 = right next to it, .5 = near, 0 = safe
local function collapseRisk(x, z)
	local g = r.gone;
	if type(g) ~= "table" or #g == 0 then return 0; end;
	local now, best = d(), math.huge;
	for k = #g, 1, -1 do
		local e = g[k];
		if now - e.t < 20 then
			local dd = (e.x - x) ^ 2 + (e.z - z) ^ 2;
			if dd < best then best = dd; end;
		end;
	end;
	best = math.sqrt(best);
	if best < 8 then return 1; elseif best < 16 then return .5; end;
	return 0;
end;
local function Ql(m, G)
	L, u = nil, nil;
	local e = {};
	-- rock search range (0 = unlimited) and minimum tier filter
	local rng = tonumber(Q.mineRange) or 0;
	local rngSq = rng > 0 and rng * rng or nil;
	local minTier = tonumber(Q.minTier) or 1;
	-- in a Delve: ores up the road (ahead) first, ores behind (toward the collapse) last, all the time
	-- (v5.31; before, only when the floor timer was low)
	local fwd, hurry;
	do
		if Q.pushForward ~= false and run.isDelve and r.forwardInfo then
			local okF, fx, fz = pcall(r.forwardInfo, m.X, m.Z);
			if okF and fx then fwd = { fx, fz }; end;
			-- (v5.34) under 12 s from the collapse / clock: ores behind go (almost) last, ores ahead first
			if fwd and r.collapseState then
				local okC, sc = pcall(r.collapseState, m);
				hurry = okC and sc ~= nil and sc < 12;
			end;
		end;
	end;
	for pass = 1, 2 do
		local hasTarget = false;
		for rockName, r in pairs(D) do
			local Q = r.wy - m.Y;
			if (math.abs(Q) < 6 or (Q >= 6 and (Q < 40 and not r.settled))) and (pass == 2 or not rngSq or (r.wx - m.X) ^ 2 + (r.wz - m.Z) ^ 2 <= rngSq) then
				r.name = rockName;
				local wt = (r.skipUntil and r.skipUntil > G) and 0 or C(r.kind);
				-- every ore still gets mined, but ores next to the collapsing edge go last (it was walking back
				-- into the collapse and falling); ores away from it come first
				if wt > 0 then
					local risk = collapseRisk(r.wx, r.wz);
					if risk > 0 then wt = wt * (risk >= 1 and .1 or .4); end;
					if fwd then
						local pr = (r.wx - m.X) * fwd[1] + (r.wz - m.Z) * fwd[2];
						if pr < -4 then wt = wt * (hurry and .03 or .25); elseif pr > 4 then wt = wt * (hurry and 2.5 or 1.6); end;
					end;
				end;
				if wt > 0 and minTier > 1 then
					local tn = tonumber(tostring(r.kind):match("(%d+)$"));
					if tn and tn < minTier then
						wt = 0;
					end;
				end;
				r.w = wt;
				hasTarget = hasTarget or wt > 0;
				e[#e + 1] = r;
			end;
		end;
		-- nothing in range: if walking is on, widen the search so we walk to the nearest rocks
		if hasTarget or not Q.walk or not rngSq or pass == 2 then
			break;
		end;
		e = {};
	end;
	a = n(e);
	r.rockCount = #e;
	if not r.prevCount or #e < r.prevCount or #e > r.prevCount + 2 then
		r.progressAt = G;
	end;
	r.prevCount = #e;
	if not a or #e == 0 then
		X = nil;
		r.posCount, r.noAimSince = 0, nil;
		return;
	end;
	local N, S = g(a, m.X, m.Z);
	r.cell = { N, S };
	-- center farm: if nothing could be aimed for a moment, drop the safety margins so ores
	-- sitting right at the edge of the mining circle still get hit
	local relax = Q.centerFarm and r.noAimSince and G - r.noAimSince > .4;
	local w = math.max(.3, (tonumber(Q.reach) or 1.29) * (tonumber(Q.reachScale) or 1)) * (relax and 1 or .95);
	local miningRadius = math.max(.1, tonumber(Q.radius) or .69);
	local radiusScale = relax and .97 or math.max(.4, math.min(1, tonumber(Q.radiusScale) or .85));
	local q = miningRadius * radiusScale;
	r.relaxed = relax and true or false;
	local l = H(e);
	local d = 0;
	for m, G in ipairs(e) do
		if G.w > 0 then
			d = d + 1;
		end;
	end;
	local centerOre = Q.centerOre == true;
	local f = not centerOre and (d >= 5 or (Q.centerFarm and d >= 2));
	if r.clusterOn ~= f or r.centerOre ~= centerOre then
		X = nil;
	end;
	r.clusterOn = f;
	r.centerOre = centerOre;
	local z = {};
	for m, G in ipairs(e) do
		if M(G.cx - N, G.cz - S) <= ((w + q)) + .5 then
			z[#z + 1] = G;
		end;
	end;
	local x = nil;
	local bestCenterDistance = math.huge;
	local retryDirect = Q.centerFarm and G - (r.progressAt or G) >= 2;
	local preferDirect = centerOre or retryDirect;
	for pass = 1, (Q.centerFarm and 2 or 1) do
		local direct = (pass == 1 and preferDirect) or (pass == 2 and not preferDirect);
		local cluster = not direct and (f or (Q.centerFarm and d >= 2));
		for _, candidate in ipairs(P(z, l, q, cluster)) do
			local aimX, aimZ = candidate[1], candidate[2];
			local inReach = M(aimX - N, aimZ - S) <= w;
			if not direct then
				aimX, aimZ = p(N, S, aimX, aimZ, w);
				inReach = true;
			end;
			local score, hits = 0, 0;
			local ore = direct and candidate[3] or nil;
			if inReach and Q.centerFarm then
				local part = ore and orePart(ore);
				local point = not direct and Z(a, aimX, aimZ) or (part and part.Position);
				inReach = point and cQ(point);
			end;
			if inReach then score, hits = t(l, aimX, aimZ, q); end;
			if hits > 0 and score > 0 and (not x or score >= x.score - 1e-6) then
				local centerDistance = math.huge;
				for _, rock in ipairs(z) do
					if rock.w > 0 then
						centerDistance = math.min(centerDistance, miningDistanceSquared(rock.cx - aimX, rock.cz - aimZ));
					end;
				end;
				local aimDistance = M(aimX - N, aimZ - S);
				if not x or score > x.score + 1e-6
					or centerDistance < bestCenterDistance - 1e-6
					or (math.abs(centerDistance - bestCenterDistance) <= 1e-6 and aimDistance < x.d)
				then
					x = { ax = aimX, az = aimZ, score = score, n = hits, d = aimDistance, ore = ore };
					bestCenterDistance = centerDistance;
				end;
			end;
		end;
		if x then break; end;
	end;
	L = x;
	r.lastAim = x;
	-- remember whether ores exist that we currently can't aim at (drives the center-farm stray trip)
	r.posCount = d;
	if x then
		r.noAimSince = nil;
	elseif d > 0 then
		r.noAimSince = r.noAimSince or G;
	else
		r.noAimSince = nil;
	end;
	if X then
		X.score = t(l, X.ax, X.az, q);
		if X.score <= 0 then
			X = nil;
		end;
	end;
	if not X or G - Y >= .5 then
		Y = G;
		local m = I(P(e, l, q, f), l, q, N, S);
		if #J > 0 and a then
			local G = {};
			for m, r in ipairs(m) do
				local Q = Z(a, r.ax, r.az);
				local e = false;
				for m, G in ipairs(J) do
					if ((Q.X - G.x)) ^ 2 + ((Q.Z - G.z)) ^ 2 < G.block * G.block then
						e = true;
						break;
					end;
				end;
				if not e then
					G[#G + 1] = r;
				end;
			end;
			m = G;
		end;
		if #m > 0 then
			local G = Gl(m, ml(m, N, S), N, S);
			local r = rl(m, G, N, S);
			local Q = m[G[1]];
			local e = nil;
			if X then
				for G, r in ipairs(m) do
					if M(r.ax - X.ax, r.az - X.az) < q then
						e = rl(m, Gl(m, ml(m, N, S, G), N, S, true), N, S);
						break;
					end;
				end;
			end;
			if not X or not e or r < e * .9 then
				X = {
						ax = Q.ax,
						az = Q.az,
						score = Q.score,
						v = r,
					};
			end;
		end;
	end;
	r.walkGoal = X;
	if not x then
		r.progressAt = G;
	end;
	local K = G - ((r.progressAt or G));
	if K > (tonumber(Q.skipAfter) or 9) and x then
		local stalledRock;
		local closest = math.huge;
		for _, rock in ipairs(e) do
			if rock.w > 0 then
				local distance = miningDistanceSquared(rock.cx - x.ax, rock.cz - x.az);
				if distance <= q * q and distance < closest then
					stalledRock, closest = rock, distance;
				end;
			end;
		end;
		if stalledRock then
			stalledRock.skipUntil = G + 3;
			r.skipped = (r.skipped or 0) + 1;
		end;
		r.progressAt, r.lastAim, r.walkGoal = G, nil, nil;
		L, X, u = nil, nil, nil;
		K = 0;
	end;
	r.stalled = K > 4;
	if X then
		local m = M(X.ax - N, X.az - S);
		if (not x and m > .01) or (r.stalled and m > .35) or (x and m > w * .85 and X.score > x.score * 1.2) then
			u = Z(a, X.ax, X.az);
		end;
	end;
end;
local el = {};
local Nl = nil;
local function Sl(m, G, r, Q)
	local e = G:FindFirstChild("Torso") or G:FindFirstChild("HumanoidRootPart") or G:FindFirstChild("Head");
	local N = e and e.Position;
	if typeof(N) ~= "Vector3" then
		return;
	end;
	if m.t and r - m.t > .001 then
		local G = r - m.t;
		local Q, e = ((N.X - m.x)) / G, ((N.Z - m.z)) / G;
		if math.abs(Q) > 80 or math.abs(e) > 80 then
			Q, e = 0, 0;
		end;
		m.vx = ((m.vx or 0)) * .5 + Q * .5;
		m.vz = ((m.vz or 0)) * .5 + e * .5;
	end;
	m.x, m.y, m.z, m.t = N.X, N.Y, N.Z, r;
	local S = G:GetAttribute("AtkPhase");
	if S ~= m.phase then
		if S == "windup" then
			m.windupAt = r;
		elseif S == "strike" then
			m.strikeAt = r;
			-- learn how long this mob's windup lasts so the roll can be scheduled before the strike lands
			local dv = env.Delve;
			if dv and m.windupAt and m.name then
				local dur = r - m.windupAt;
				if dur > .05 and dur < 4 then
					dv.windups = dv.windups or {};
					local old = dv.windups[m.name];
					dv.windups[m.name] = old and (old * .6 + dur * .4) or dur;
				end;
			end;
		end;
	end;
	m.phase = S;
	if Q or not m.hpT or r - m.hpT > .25 then
		m.hpT = r;
		local Q = G:FindFirstChildOfClass("Humanoid");
		if Q then
			m.hp, m.max = Q.Health, Q.MaxHealth;
		end;
	end;
end;
local function wl(m, G, r)
	m.chk = r;
	if G:GetAttribute("MobId") == nil then
		m.owned = false;
		m.pending = true;
		return;
	end;
	m.pending = nil;
	m.boss = G:GetAttribute("Boss") == true or G:GetAttribute("IsBoss") == true
		or G:GetAttribute("MobType") == "Boss" or tostring(G.Name):lower():find("boss") ~= nil;
	local Q = G:GetAttribute("Owner");
	if Q ~= nil then
		m.owned = Q == l.UserId;
	else
		local r = G:GetAttribute("RunId");
		m.owned = r == nil or r == Nl;
	end;
end;
local ql = {};
local ll = {};
local dl = Q.chestRange;
local function fl(m, G)
	local r = m:FindFirstChild("Body") or m:FindFirstChild("Base") or m.PrimaryPart;
	local Q = r and r.Position;
	if typeof(Q) ~= "Vector3" then
		return nil;
	end;
	if G and ((Q.X - G.X)) ^ 2 + ((Q.Z - G.Z)) ^ 2 > dl * dl then
		return nil;
	end;
	local e = instanceId(m);
	local N = ll[e];
	if N == nil then
		local G = m:GetAttribute("Viewer");
		local r = m:GetAttribute("Owner");
		N = ((G == nil or G == l.UserId)) and ((((r == nil or r == l.UserId)) and not m:GetAttribute("HiddenFor_" .. l.UserId)));
		ll[e] = N;
	end;
	if not N then
		return nil;
	end;
	local S = m:GetAttribute("ChestState");
	if S == "open" then
		return nil;
	end;
	return e, {
		x = Q.X,
		z = Q.Z,
		locked = S ~= "unlocked",
		state = S,
	};
end;
local function zl(m)
	Nl = l:GetAttribute("RunId");
	local G = workspace:GetChildren();
	local r = {};
	local e = l.Character;
	local N = e and e:FindFirstChild("HumanoidRootPart");
	local S = N and N.Position;
	local w = {};
	for G, e in ipairs(G) do
		local N = e.Name;
		if (Q.chests or (Q.on and Q.centerFarm)) and (not F[N] and ((N == "DelveChest" or (e.ClassName == "Model" and e:GetAttribute("ChestRarity") ~= nil)))) then
			local m, G = fl(e, S);
			if m then
				w[m] = G;
			end;
		elseif F[N] then
			local Q = instanceId(e);
			r[Q] = true;
			local N = el[Q];
			if not N then
				N = { name = e.Name };
				el[Q] = N;
			end;
			N.idx = G;
			if N.owned == nil or (not N.owned and m - N.chk > ((N.pending and .4 or 2))) then
				wl(N, e, m);
			end;
			if N.owned then
				Sl(N, e, m);
			end;
		end;
	end;
	for m in pairs(el) do
		if not r[m] then
			el[m] = nil;
		end;
	end;
	ql = w;
	local plate = workspace:FindFirstChild("StrataPlate");
	r.chestScanPlate = plate and instanceId(plate);
end;
local function cl(m)
	local G, r = nil, nil;
	for Q, e in pairs(ql) do
		if not e.locked then
			local Q = ((e.x - m.X)) ^ 2 + ((e.z - m.Z)) ^ 2;
			if not r or Q < r then
				G, r = e, Q;
			end;
		end;
	end;
	return G;
end;
local function xl(m)
	local G = nil;
	for r, Q in pairs(el) do
		if Q.owned then
			G = G or workspace:GetChildren();
			local e = G[Q.idx];
			if not e or instanceId(e) ~= r then
				e = nil;
				for m = math.max(1, Q.idx - 12), math.min(#G, Q.idx + 12), 1 do
					local N = G[m];
					if instanceId(N) == r then
						e, Q.idx = N, m;
						break;
					end;
				end;
			end;
			if e then
				Sl(Q, e, m);
			else
				el[r] = nil;
			end;
		end;
	end;
end;
local function Wl(m, G, r)
	local Q = workspace:GetChildren();
	local e = Q[G.idx];
	if e and instanceId(e) == m then
		G.dead = e:GetAttribute("Dead") and true or false;
	end;
end;
local function Kl(m, G)
	local r = math.min(.15, G - ((m.t or G)));
	return Vector3.new(m.x + ((m.vx or 0)) * r, m.y, m.z + ((m.vz or 0)) * r);
end;
local function ol()
	local m = {};
	for G, r in pairs(el) do
		if r.owned and ((r.x and ((not r.dead and ((r.hp == nil or r.hp > 0)))))) then
			r.addr = G;
			m[#m + 1] = r;
		end;
	end;
	return m;
end;
local Fl = {};
local jl = { "Hazards", "MobTelegraphs", "DelveHazards" };
local function Rl(m)
	local G = math.sqrt(m.X * m.X + m.Z * m.Z);
	if G < .001 then
		return 0, 0;
	end;
	return m.X / G, m.Z / G;
end;
local Cl = {};
local function Dl(m)
	return m > .05 and m < .065;
end;
local function El(m, G)
	local r = { { v = m.RightVector, s = G.X }, { v = m.UpVector, s = G.Y }, { v = m.LookVector, s = G.Z } };
	local Q, e = 1, -1;
	for m, G in ipairs(r) do
		local r = math.abs(G.v.Y);
		if r > e then
			Q, e = m, r;
		end;
	end;
	local N = r[Q].s;
	table.remove(r, Q);
	local S, w = Rl(r[1].v);
	local q, l = Rl(r[2].v);
	local d, f = r[1].s / 2, r[2].s / 2;
	local z = m.Position;
	return {
		x = z.X,
		z = z.Z,
		ax = S,
		az = w,
		bx = q,
		bz = l,
		h1 = d,
		h2 = f,
		circle = math.abs(d - f) <= .06 * math.max(d, f),
	}, N;
end;
local function al(m, G)
	for m, G in pairs(Cl) do
		G.seen = false;
	end;
	local function r(m, G)
		if m.circle and G.circle then
			if ((m.x - G.x)) ^ 2 + ((m.z - G.z)) ^ 2 < .01 and G.h1 < m.h1 - .01 then
				return G.h1 / m.h1;
			end;
		elseif not m.circle and ((not G.circle and ((math.abs(m.h1 - G.h1) < .05 and ((m.bx * G.bx + m.bz * G.bz > .99 and G.h2 < m.h2 - .01)))))) then
			local r, Q = m.x - m.bx * m.h2, m.z - m.bz * m.h2;
			local e, N = G.x - G.bx * G.h2, G.z - G.bz * G.h2;
			if ((r - e)) ^ 2 + ((Q - N)) ^ 2 < .04 then
				return G.h2 / m.h2;
			end;
		end;
		return nil;
	end;
	for Q, e in ipairs(m) do
		local N, S, w = nil, 0, false;
		for m, G in ipairs(m) do
			if Q ~= m then
				local m = r(e, G);
				if m then
					N, S = m, S + 1;
				elseif r(G, e) then
					w = true;
				end;
			end;
		end;
		if S == 1 and not w then
			local m = string.format("%d:%d:%d", math.floor(e.x * 4 + .5), math.floor(e.z * 4 + .5), math.floor(((e.h1 + e.h2)) * 4 + .5));
			local r = Cl[m];
			if not r or N < r.p - .05 then
				r = { p0 = N, t0 = G };
				Cl[m] = r;
			end;
			r.zone, r.p, r.seen = e, N, true;
			if G - r.t0 > .03 and N > r.p0 + .01 then
				r.hitAt = r.t0 + ((((1 - r.p0)) * ((G - r.t0)))) / ((N - r.p0));
			end;
		end;
	end;
	for m, r in pairs(Cl) do
		if not r.seen and G - ((r.hitAt or r.t0)) > .3 then
			Cl[m] = nil;
		end;
	end;
end;
local il = .6;
local sl = 20;
local Ol = 1.5;
local Vl = Q.hitMargin;
local yl = 1.05;
local bl = Q.rollLead;
local vl = Q.meleeReach;
local nl = {};
local function gl(m, G, psz, Q)
	local e = math.max(psz / 2, .6);
	-- fragile run (max HP 10 or less, e.g. Glass Soul): a single projectile ends the run, so each one's
	-- danger lane reaches 0.95 s ahead (up to 32 st) instead of 0.6 s (20 st). A Pale Warden projectile
	-- killed a 1-HP run 0.1 s after it started an 11 st escape through the bullet field.
	if Q - (r.fragileAt or -1e9) > 1 then
		r.fragileAt = Q;
		local hm = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
		r.fragile = hm ~= nil and hm.MaxHealth > 0 and hm.MaxHealth <= 10;
	end;
	-- velocity is sampled over >= 40 ms and cached, so scanning every frame doesn't zero it out
	local N = nl[m];
	if not N or Q - N.t > .5 then
		N = { x = G.X, z = G.Z, t = Q };
		nl[m] = N;
	elseif Q - N.t >= .04 then
		local dt = Q - N.t;
		N.vx, N.vz = (G.X - N.x) / dt, (G.Z - N.z) / dt;
		N.x, N.z, N.t = G.X, G.Z, Q;
	end;
	if N.vx then
		local r2, S = N.vx, N.vz;
		local w = math.sqrt(r2 * r2 + S * S);
		if w > 2 then
			local m2, Q2 = r2 / w, S / w;
			local N2 = r.fragile and math.min(w * .95, 32) or math.min(w * il, sl);
			return {
				x = G.X + (m2 * N2) / 2,
				z = G.Z + (Q2 * N2) / 2,
				ax = m2,
				az = Q2,
				bx = -Q2,
				bz = m2,
				h1 = N2 / 2 + e,
				h2 = e,
				circle = false,
				pm = Ol,
			}, m2, Q2, w;
		end;
	end;
	return {
		x = G.X,
		z = G.Z,
		ax = 1,
		az = 0,
		bx = 0,
		bz = 1,
		h1 = e,
		h2 = e,
		circle = true,
		pm = Ol,
	};
end;
local Zl = .4;
local kl = 20;
local Tl = {};
local function Al(m, G, r, Q, e, N)
	local S = m.x * m.ax + m.z * m.az;
	local w = m.x * m.bx + m.z * m.bz;
	local q, l = m.x + G * N, m.z + r * N;
	local d = q * m.ax + l * m.az;
	local f = q * m.bx + l * m.bz;
	local z = m.h1 + math.max(Q, 0) * N;
	local c = m.h2 + math.max(e, 0) * N;
	local x, W = math.min(S - m.h1, d - z), math.max(S + m.h1, d + z);
	local K, o = math.min(w - m.h2, f - c), math.max(w + m.h2, f + c);
	local F, j = ((x + W)) / 2, ((K + o)) / 2;
	return {
		x = F * m.ax + j * m.bx,
		z = F * m.az + j * m.bz,
		ax = m.ax,
		az = m.az,
		bx = m.bx,
		bz = m.bz,
		h1 = math.min(((W - x)) / 2, m.h1 + kl),
		h2 = math.min(((o - K)) / 2, m.h2 + kl),
		circle = false,
	};
end;
local function hl(m, G, r, Q)
	local e, N = G - m.x, r - m.z;
	return math.abs(e * m.ax + N * m.az) < m.h1 + Q and math.abs(e * m.bx + N * m.bz) < m.h2 + Q;
end;
local function Ul(m, G, r)
	-- growth/velocity is sampled over >= 40 ms and cached (same reason as gl)
	local Q = Tl[m];
	if not Q or r - Q.t > .5 then
		Tl[m] = { x = G.x, z = G.z, h1 = G.h1, h2 = G.h2, t = r };
		return G;
	end;
	local e = r - Q.t;
	if e >= .04 then
		Q.gh1, Q.gh2 = (G.h1 - Q.h1) / e, (G.h2 - Q.h2) / e;
		Q.gx, Q.gz = (G.x - Q.x) / e, (G.z - Q.z) / e;
		Q.x, Q.z, Q.h1, Q.h2, Q.t = G.x, G.z, G.h1, G.h2, r;
	end;
	if G.circle or not Q.gh1 then
		return G;
	end;
	local N, S, w, q = Q.gh1, Q.gh2, Q.gx, Q.gz;
	if N < 1 and (S < 1 and w * w + q * q < 1) then
		return G;
	end;
	return Al(G, w, q, N, S, Zl), w, q, N, S;
end;
local Bl, Ml = {}, -1000000000.0;
local function Ll(m)
	if m - Ml < .1 then
		return Bl;
	end;
	Ml = m;
	Bl = {};
	local G = workspace:FindFirstChild("Plates");
	if G then
		for m, G in ipairs(G:GetChildren()) do
			for m, G in ipairs(G:GetChildren()) do
				if G.Name:sub(1, 7) == "Hazard_" then
					Bl[#Bl + 1] = G;
				end;
			end;
		end;
	end;
	return Bl;
end;
-- DANGER MEMORY
--  * every attack zone gets a signature (its folder/part name); hits and deaths inside it teach that
--    attack type more distance (sx) and an earlier roll (sl), so similar attacks are respected next time
--  * concentric circles: a small circle inside a big boss circle is the safe spot (stand close to the boss)
--  * floor hazards: damage with no attack or mob to explain it marks the floor part under you (lava strips);
--    after 2 such hits that kind of part is avoided like an attack zone
local dangerMem = { floorZones = {}, refreshAt = -1e9, seenParts = setmetatable({}, { __mode = "k" }) };
function dangerMem.tag(z, part, kind)
	if type(z) ~= "table" then return; end;
	if not z.sig then
		-- almost every attack in the game is a part called "Part" in "Hazards", so the name alone
		-- lumped all attacks together. Shape, size class and colour tell them apart.
		local pn = part and part.Parent and part.Parent.Name or "";
		local size = z.circle and (z.h1 or 0) or math.max(z.h1 or 0, z.h2 or 0);
		local bucket = size < 2 and "XS" or size < 4 and "S" or size < 8 and "M" or size < 16 and "L" or "XL";
		local col = "";
		pcall(function() col = part.BrickColor.Name; end);
		z.sig = tostring(kind or "zone") .. ":" .. pn .. "/" .. tostring(part and part.Name or "?") .. ":"
			.. (z.circle and "circle" or "rect") .. "-" .. bucket .. (col ~= "" and (":" .. col) or "");
	end;
	local a = type(brain.attacks) == "table" and brain.attacks[z.sig];
	z.sx = type(a) == "table" and tonumber(a.extra) or 0;
	z.sl = type(a) == "table" and tonumber(a.lead) or 0;
	z.noHole = type(a) == "table" and a.noHole == true or nil;
	if z.color == nil and part then pcall(function() z.color = part.Color; end); end;
	if not z.seenAt and kind ~= "mob" and kind ~= "floor" then
		z.seenAt = d();
		-- (v5.37) the zones are rebuilt every frame: only the first sighting of a part is a new attack
		-- (every frame counted before: millions of "attacks", junk predictions, every mob a "shooter")
		if part then
			if dangerMem.seenParts[part] then return; end;
			dangerMem.seenParts[part] = true;
		end;
		-- with the attack-plan feed, an attack drawn in Hazards is already recorded from its plan (twice made
		-- "plan A, then drawn A 0.05 s later" look like a pattern)
		local hzF = workspace:FindFirstChild("Hazards");
		local planCovers = part ~= nil and hzF ~= nil and r.plan ~= nil and r.plan.hooked == true and CFG.planFeed ~= false and part:IsDescendantOf(hzF);
		if not planCovers then pcall(dangerMem.onAttack, z, z.seenAt); end;
		if kind == "projectile" then
			local shooter, sd;
			for _, mob in pairs(el) do
				if mob.x and mob.name and not mob.dead then
					local dd = (mob.x - z.x) ^ 2 + (mob.z - z.z) ^ 2;
					if dd < 100 and (not sd or dd < sd) then shooter, sd = mob, dd; end;
				end;
			end;
			if shooter then
				local nm = tostring(shooter.name);
				brain.ranged = type(brain.ranged) == "table" and brain.ranged or {};
				brain.ranged[nm] = (tonumber(brain.ranged[nm]) or 0) + 1;
				r.rangedSeen = r.rangedSeen or {};
				r.rangedSeen[nm] = z.seenAt;
			end;
		end;
	end;
end;
function dangerMem.holes(list)
	for _, z in ipairs(list) do z.hole, z.safeHole = nil, nil; end;
	for i, big in ipairs(list) do
		if big.circle and (big.h1 or 0) >= 7 and not big.noHole then
			for j, small in ipairs(list) do
				-- a red / orange / pink inner circle is the danger itself (Worldheart), not a safe spot
				local c = small.color;
				local reddish = c and c.R > c.G + .15 and c.R > c.B - .05;
				if j ~= i and not reddish and small.circle and (small.h1 or 0) < big.h1 * .5 and (small.h1 or 0) >= 1.5
					and (small.x - big.x) ^ 2 + (small.z - big.z) ^ 2 < 2.25 then
					big.hole, small.safeHole = small.h1, true;
				end;
			end;
		end;
	end;
end;
function dangerMem.sigOf(part)
	local okS, sig = pcall(function() return part.Name .. "|" .. tostring(part.BrickColor) .. "|" .. part.Material.Name; end);
	return okS and sig or nil;
end;
function dangerMem.active(sig)
	local rec = type(brain.floorHaz) == "table" and brain.floorHaz[sig];
	return type(rec) == "table" and (tonumber(rec.hits) or 0) >= 2 and (tonumber(rec.hits) or 0) * 3 > (tonumber(rec.safe) or 0);
end;
function dangerMem.partsNear(pos, radius, below)
	local out = {};
	local okQ, parts = pcall(function()
		local op = OverlapParams.new();
		op.FilterType = Enum.RaycastFilterType.Exclude;
		op.FilterDescendantsInstances = { l.Character };
		if below then
			return workspace:GetPartBoundsInBox(CFrame.new(pos - Vector3.new(0, 3, 0)), Vector3.new(3, 4, 3), op);
		end;
		return workspace:GetPartBoundsInRadius(pos, radius, op);
	end);
	for _, part in ipairs(okQ and parts or {}) do
		local sz = part.Size;
		if math.max(sz.X, sz.Z) <= 120 then out[#out + 1] = part; end;
	end;
	return out;
end;
-- rebuild the floor-hazard zones around you (cheap spatial query, once a second)
function dangerMem.refresh(pos, now)
	if now - dangerMem.refreshAt < 1 then return; end;
	dangerMem.refreshAt = now;
	local zones = {};
	if pos and next(brain.floorHaz or {}) then
		for _, part in ipairs(dangerMem.partsNear(pos, 60)) do
			local sig = dangerMem.sigOf(part);
			if sig and dangerMem.active(sig) then
				local okZ, z = pcall(El, part.CFrame, part.Size);
				if okZ and type(z) == "table" then
					z.pm, z.sig, z.floor = Vl, "floor:" .. sig, true;
					zones[#zones + 1] = z;
				end;
			end;
		end;
	end;
	dangerMem.floorZones = zones;
end;
-- which boss is on the field (highest max HP within 80 studs)
function dangerMem.boss(pos)
	local best, bestHp;
	for _, mob in pairs(el) do
		if mob.x and not mob.dead and mob.name then
			local hp = tonumber(mob.max) or 0;
			local near = not pos or (mob.x - pos.X) ^ 2 + (mob.z - pos.Z) ^ 2 < 6400;
			if near and (mob.boss or hp > 0) and (not bestHp or hp > bestHp) then best, bestHp = mob, hp; end;
		end;
	end;
	if best and (best.boss or run.bossNow) then return best; end;
	return nil;
end;
-- a new attack appeared: record it in that boss's pattern and predict the next one
function dangerMem.onAttack(z, now)
	if not z.sig or z.floor then return; end;
	local ch = l.Character;
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart");
	local pos = hrp and hrp.Position;
	local boss = dangerMem.boss(pos);
	if not boss then return; end;
	brain.patterns = type(brain.patterns) == "table" and brain.patterns or {};
	local key = tostring(boss.name);
	-- (v5.37) the colour is left out (the game draws one attack in many colours, which made dozens of "attacks"
	-- per mob), parts of one volley count once, and each boss keeps at most 40 attack types and 12 follow-ups each
	local psig = tostring(z.sig);
	local _, ncol = psig:gsub(":", "");
	if ncol >= 3 then psig = psig:match("^(.*):[^:]*$") or psig; end;
	local live = dangerMem.live;
	if live and live.boss == key and live.psig == psig and now - live.at < .3 then
		live.at = now;
		return;
	end;
	local pt = type(brain.patterns[key]) == "table" and brain.patterns[key] or { n = 0, sigs = {}, trans = {} };
	pt.sigs = type(pt.sigs) == "table" and pt.sigs or {};
	pt.trans = type(pt.trans) == "table" and pt.trans or {};
	local function count(t0)
		local c = 0;
		for _ in pairs(t0) do c = c + 1; end;
		return c;
	end;
	if pt.sigs[psig] == nil and count(pt.sigs) >= 40 then return; end;
	pt.n = (tonumber(pt.n) or 0) + 1;
	local sg = type(pt.sigs[psig]) == "table" and pt.sigs[psig] or { n = 0 };
	sg.n = (tonumber(sg.n) or 0) + 1;
	if z.circle then
		sg.r = math.max(tonumber(sg.r) or 0, z.h1 or 0);
		sg.onBoss = boss.x and (z.x - boss.x) ^ 2 + (z.z - boss.z) ^ 2 < 9 or false;
	end;
	if z.hole then sg.hole = z.hole; end;
	pt.sigs[psig] = sg;
	if live and live.boss == key and live.psig and now - live.at < 20 then
		local row = type(pt.trans[live.psig]) == "table" and pt.trans[live.psig] or {};
		if row[psig] ~= nil or count(row) < 12 then
			local tr = type(row[psig]) == "table" and row[psig] or { n = 0, gap = 0 };
			tr.n = (tonumber(tr.n) or 0) + 1;
			tr.gap = (tonumber(tr.gap) or 0) + (now - live.at);
			row[psig] = tr;
		end;
		pt.trans[live.psig] = row;
	end;
	brain.patterns[key] = pt;
	-- predict: the attack that most often came next, and after how long
	local nextSig, bestN, gap = nil, 0, nil;
	local totalN = 0;
	for ns, tr in pairs(type(pt.trans[psig]) == "table" and pt.trans[psig] or {}) do
		if type(tr) == "table" then
			local n0 = tonumber(tr.n) or 0;
			totalN = totalN + n0;
			if n0 > bestN then nextSig, bestN, gap = ns, n0, (tonumber(tr.gap) or 0) / math.max(n0, 1); end;
		end;
	end;
	dangerMem.live = { boss = key, sig = z.sig, psig = psig, at = now };
	local conf = totalN > 0 and bestN / totalN or 0;
	-- only act on a prediction seen 5+ times that comes true most of the time
	dangerMem.predict = (nextSig and bestN >= 5 and conf >= .6)
		and { boss = key, sig = nextSig, at = now + gap, info = pt.sigs[nextSig], conf = conf } or nil;
end;
-- (v5.37) "seen shooting": once per volley, by name (attack plans) or the mob nearest to where the shots start
-- (MobShot names no mob). With the attack-plan feed the drawn bullets aren't scanned, so this is the source.
r.noteShooter = function(nm, from, t)
	if (nm == nil or nm == "?") and from then
		local best, bd;
		for _, mob in pairs(el) do
			if mob.x and mob.name and not mob.dead then
				local dd = (mob.x - from.X) ^ 2 + (mob.z - from.Z) ^ 2;
				if dd < 144 and (not bd or dd < bd) then best, bd = mob, dd; end;
			end;
		end;
		nm = best and best.name or nil;
	end;
	if nm == nil or nm == "?" then return; end;
	nm = tostring(nm);
	brain.ranged = type(brain.ranged) == "table" and brain.ranged or {};
	brain.ranged[nm] = (tonumber(brain.ranged[nm]) or 0) + 1;
	r.rangedSeen = r.rangedSeen or {};
	r.rangedSeen[nm] = t or d();
end;
local function Xl(m, G)
	Fl = {};
	local e = G or d();
	local N = {};
	local S = {};
	-- (v5.30) with the game's attack plans coming in, small flung parts and puffs in Hazards/MobTelegraphs
	-- are effects (impact debris, smoke, slam bursts), not attacks: they made 55-100 fake "projectiles"
	-- around the Pale Warden. The real shots come from the plans.
	local Pq = r.plan;
	local planOn = Pq ~= nil and Pq.hooked == true and CFG.planFeed ~= false;
	local skipFx, skipSmall = false, false;
	-- (v5.39) the game's plans are read first. A shape drawn in Hazards where a planned attack is, is that attack's
	-- drawing (HazardView), so the plan's exact zone (with its safe middle and its timing) is used instead. The
	-- Worldheart's donut is drawn as full discs plus a "safe" disc, which read as one solid danger circle: the bot
	-- fled to the room's edge (still inside the 171 st donut) instead of into its safe middle (3 deaths on 2026-11-14).
	-- Drawn parts away from every plan still count, as before.
	local planZones, planCl, planCover, skipPlanned = nil, nil, nil, false;
	if planOn then
		local okP, pzs, pcl = pcall(Pq.frame, e, m);
		if okP and pzs then planZones, planCl = pzs, pcl; end;
		-- covered: today's zones, and every plan still on the books (kept 0.5 s after it ends, while its drawing fades)
		planCover = {};
		local function cover(z)
			if type(z) ~= "table" or not (z.x and z.z) then return; end;
			local h1, h2 = tonumber(z.h1) or 0, tonumber(z.h2) or 0;
			local rad = z.circle and h1 or math.sqrt(h1 * h1 + h2 * h2);
			if rad > 0 then planCover[#planCover + 1] = { z.x, z.z, (rad + 3) ^ 2 }; end;
		end;
		for _, z in ipairs(planZones or {}) do cover(z); end;
		for _, pe in ipairs(type(Pq.hz) == "table" and Pq.hz or {}) do cover(pe.zone); end;
	end;
	local function w(G)
		local r, Q = pcall(function()
				return G.Size;
			end);
		if not ((r and typeof(Q) == "Vector3")) then
			return;
		end;
		local w = G.CFrame;
		local q = w.Position;
		if m and ((q.X - m.X)) ^ 2 + ((q.Z - m.Z)) ^ 2 >= 3600 then
			return;
		end;
		if skipFx and G:IsA("Part") and G.Shape == Enum.PartType.Ball then return; end;
		if skipSmall and math.max(Q.X, Q.Y, Q.Z) < 3 and not (Dl(Q.X) or Dl(Q.Y) or Dl(Q.Z)) then return; end;
		if skipPlanned and planCover then
			for _, pc in ipairs(planCover) do
				if (q.X - pc[1]) ^ 2 + (q.Z - pc[2]) ^ 2 <= pc[3] then return; end;
			end;
		end;
		local l = math.max(Q.X, Q.Y, Q.Z) >= 1.5;
		local d = Dl(Q.X) or Dl(Q.Y) or Dl(Q.Z);
		if l or d then
			local r, q = El(w, Q);
			if l then
				local Q, S, w, q, l = Ul(instanceId(G), r, e);
				Fl[#Fl + 1] = Q;
				dangerMem.tag(Q, G, "hazard");
				if S and m then
					for d = 0, 8, 1 do
						local f = (Zl * d) / 8;
						if hl(Al(r, S, w, q, l, f), m.X, m.Z, Vl) then
							N[#N + 1] = { key = "g" .. tostring(instanceId(G)), zone = Q, hitAt = e + f };
							break;
						end;
					end;
				end;
			end;
			if Dl(q) then
				S[#S + 1] = r;
			end;
		end;
		if not l and not skipFx and (not d and ((G.Transparency or 0)) < .95) then
			local r, S, w, l = gl(instanceId(G), q, math.max(Q.X, Q.Y, Q.Z), e);
			Fl[#Fl + 1] = r;
			dangerMem.tag(r, G, "projectile");
			if l and m then
				local Q, d = m.X - q.X, m.Z - q.Z;
				local f = Q * S + d * w;
				local z = math.abs(d * S - Q * w);
				if f > 0 and z < r.h2 + 1.5 then
					N[#N + 1] = { key = "p" .. tostring(instanceId(G)), zone = r, hitAt = e + f / l };
				end;
			end;
		end;
	end;
	local function q(m, G)
		G = G or 0;
		for m, r in ipairs(m:GetChildren()) do
			if G < 2 and ((r.ClassName == "Folder" or r.ClassName == "Model")) then
				q(r, G + 1);
			else
				w(r);
			end;
		end;
	end;
	for m, G in ipairs(jl) do
		local r = workspace:FindFirstChild(G);
		if r then
			skipFx = planOn and (G == "Hazards" or (G == "MobTelegraphs" and Pq.shotHooked == true));
			skipSmall = planOn and G == "Hazards";
			skipPlanned = planOn and G == "Hazards";
			q(r);
		end;
	end;
	skipFx, skipSmall, skipPlanned = false, false, false;
	local l = {};
	for G, r in ipairs(Ll(e)) do
		local Q, e = nil, 0;
		for m, G in ipairs(r:GetChildren()) do
			local r, N = pcall(function()
					return G.Size;
				end);
			if r and typeof(N) == "Vector3" then
				local m, r = math.min(N.X, N.Y, N.Z), math.max(N.X, N.Y, N.Z);
				if r >= 3 and r / 2 > e then
					Q, e = G.Position, r / 2;
				end;
				if m < .2 and (r >= 3 and ((G.Transparency or 0)) < .95) then
					local m, r = El(G.CFrame, N);
					if r < .2 then
						S[#S + 1] = m;
					end;
				end;
			end;
		end;
		if Q and ((not m or ((Q.X - m.X)) ^ 2 + ((Q.Z - m.Z)) ^ 2 < 3600)) then
			Fl[#Fl + 1] = {
					x = Q.X,
					z = Q.Z,
					ax = 1,
					az = 0,
					bx = 0,
					bz = 1,
					h1 = e,
					h2 = e,
					circle = true,
					pm = Vl,
				};
			l[#l + 1] = { x = Q.X, z = Q.Z, block = e + Vl };
			dangerMem.tag(Fl[#Fl], r, "mob");
		end;
	end;
	for _, hz in ipairs(dangerMem.floorZones) do Fl[#Fl + 1] = hz; end;
	pcall(dangerMem.holes, Fl);
	J = l;
	for G, r in ipairs(workspace:GetChildren()) do
		if r.ClassName == "Part" then
			local G = r.Size;
			if typeof(G) == "Vector3" then
				local Q, e = math.min(G.X, G.Y, G.Z), math.max(G.X, G.Y, G.Z);
				if Q < .2 and (e >= 3 and (e <= 30 and ((r.Transparency or 0)) < .95)) then
					local Q = r.Position;
					if not m or ((Q.X - m.X)) ^ 2 + ((Q.Z - m.Z)) ^ 2 < 3600 then
						local m, Q = El(r.CFrame, G);
						if Q < .2 then
							m.pm = Vl;
							Fl[#Fl + 1] = m;
							dangerMem.tag(m, r, "floor");
							S[#S + 1] = m;
						end;
					end;
				end;
			end;
		end;
	end;
	for G, r in pairs(el) do
		if r.owned and (r.x and (not r.dead and ((r.phase == "windup" or r.phase == "strike")))) then
			if not m or ((r.x - m.X)) ^ 2 + ((r.z - m.Z)) ^ 2 < 3600 then
				local learnedReach = (CFG.dodgeLearn ~= false and tonumber(brain.mobReach[tostring(r.name)])) or 0;
				local reachNow = math.max(vl, learnedReach);
				Fl[#Fl + 1] = {
						x = r.x,
						z = r.z,
						ax = 1,
						az = 0,
						bx = 0,
						bz = 1,
						h1 = reachNow,
						h2 = reachNow,
						mob = r.name,
						circle = true,
						pm = 2,
					};
			end;
		end;
	end;
	for m, G in pairs(nl) do
		if e - G.t > 1 then
			nl[m] = nil;
		end;
	end;
	for m, G in pairs(Tl) do
		if e - G.t > 1 then
			Tl[m] = nil;
		end;
	end;
	if planOn then
		if planZones then
			for _, z in ipairs(planZones) do Fl[#Fl + 1] = z; end;
			Pq.cl = planCl;
		else
			Pq.cl = nil;
		end;
	elseif Pq then
		Pq.cl = nil;
	end;
	r.zoneCount = #Fl;
	r.zones = Fl;
	if Q.autoRoll then
		al(S, G or d());
		for m, G in ipairs(N) do
			local r = Cl[G.key];
			Cl[G.key] = {
					zone = G.zone,
					p = 0,
					t0 = r and r.t0 or e,
					hitAt = G.hitAt,
					seen = true,
					rolled = r and r.rolled,
				};
		end;
		-- planned attacks: the exact moment each one lands (the roll timing uses this)
		if planOn and Pq.cl then
			for key, it in pairs(Pq.cl) do
				local old = Cl[key];
				Cl[key] = { zone = it.zone, p = 0, t0 = old and old.t0 or e, hitAt = it.hitAt, seen = true, rolled = old and old.rolled, plan = it.e };
			end;
		end;
	end;
end;
local function ul(m, G, r, Q)
	if m.safeHole then
		return nil;
	end;
	local e, N = G - m.x, r - m.z;
	local S = e * m.ax + N * m.az;
	local w = e * m.bx + N * m.bz;
	if m.circle then
		local G = m.h1 + Q + (m.sx or 0);
		local r = math.sqrt(S * S + w * w);
		if r >= G then
			return nil;
		end;
		if m.hole then
			-- ring attack: the inner circle is safe; push inward when that's closer than the outside
			local inner = m.hole - .6;
			if r < inner then
				return nil;
			end;
			if r - inner < G - r and r > .2 then
				return r - inner, -e / r, -N / r;
			end;
		end;
		if r < .2 then
			return G, m.ax, m.az;
		end;
		return G - r, e / r, N / r;
	end;
	local sx = m.sx or 0;
	local q, l = ((m.h1 + Q + sx)) - math.abs(S), ((m.h2 + Q + sx)) - math.abs(w);
	if q <= 0 or l <= 0 then
		return nil;
	end;
	if q < l then
		local G = S >= 0 and 1 or -1;
		return q, m.ax * G, m.az * G;
	end;
	local d = w >= 0 and 1 or -1;
	return l, m.bx * d, m.bz * d;
end;
local Yl = Q.keepAway;
local pl = {
		W = 87,
		A = 65,
		S = 83,
		D = 68,
	};
local Hl = {};
local function tl(m, G)
	if ((Hl[m] or false)) == G then
		return;
	end;
	Hl[m] = G;
	if G then
		inp.key(pl[m], true);
	else
		inp.key(pl[m], false);
	end;
end;
local function Pl()
	for m in pairs(pl) do
		tl(m, false);
	end;
	inp.clearMove();
end;
local Jl, Il, mQ = 81, 49, 50;
local GQ, rQ = nil, nil;
local function QQ(m, G)
	if GQ then
		return false;
	end;
	inp.key(m, true);
	GQ, rQ = m, G;
	return true;
end;
local function eQ(m)
	-- a roll always wins over a pending tool-equip key press
	if GQ and GQ ~= Jl then
		inp.key(GQ, false);
		GQ = nil;
	end;
	if QQ(Jl, m) then
		r.rolls = ((r.rolls or 0)) + 1;
		return true;
	end;
	return false;
end;
local function NQ(m, G)
	if GQ and ((G or m - rQ >= .05)) then
		inp.key(GQ, false);
		GQ = nil;
	end;
end;
-- ===================================================================================
-- ATTACK PLANS (v5.30). The game tells the client about every attack before it lands:
--   MobPlan {id, t0, style, hazards = {...}, shots = {...}}: each hazard has at/shape/size/dir and
--     warn/hit/dur in seconds after t0 on the server clock (workspace:GetServerTimeNow()).
--   MobPlanCancel {id, at, all, lava}: the parts of that attack that haven't landed yet are off.
--   MobShot {shots = {from, vel, life}} or {lob = {from, target, flight, radius}}: a mob's volley.
-- The bot only listens (the game's HazardView / MobTelegraph draw from these same events) and checks
-- spots with a copy of the game's hit test (ReplicatedStorage.Strata.Shared.Hazards.test), so it knows
-- WHEN each spot gets hit, not just where the drawn shapes are right now. Read from decompiled client
-- code: shapes and timings match the drawing code; the server's exact damage rules can't be seen.
-- ===================================================================================
do
	local P = { hz = {}, shots = {}, lastPlan = -1e9, lastShot = -1e9, plans = 0, hooked = false, unknown = {} };
	r.plan = P;
	local PR = 1.2; -- Hazards.PlayerRadius in the game
	local KNOWN = { circle = true, lane = true, crack = true, cone = true, donut = true, ring = true, sweep = true };
	local function srv()
		local ok, t = pcall(function() return workspace:GetServerTimeNow(); end);
		return ok and t or os.clock();
	end;
	P.srv = srv;
	local function unit(x, z)
		local ln = math.sqrt(x * x + z * z);
		if ln < 1e-6 then return 0, -1; end;
		return x / ln, z / ln;
	end;
	local function angTo(px, pz, dx, dz)
		return ((math.deg(math.atan2(-px, -pz) - math.atan2(-dx, -dz)) + 180) % 360) - 180;
	end;
	-- Shared.Hazards.test: is (x, z) hit by hazard h between a3 and a4 seconds after its hit time
	function P.test(h, x, z, a3, a4)
		if h.visual then return false; end;
		local px, pz = x - h.ax, z - h.az;
		local dur = math.max(h.dur or 0, 1e-6);
		local sh = h.shape;
		if sh == "circle" then
			local rr = (h.r or 0) + PR;
			if not h.vx then return px * px + pz * pz <= rr * rr; end;
			local sx, sz = h.ax + h.vx * a3, h.az + h.vz * a3;
			local ex, ez = h.vx * (a4 - a3), h.vz * (a4 - a3);
			local ll = ex * ex + ez * ez;
			local t = ll > 1e-9 and math.clamp(((x - sx) * ex + (z - sz) * ez) / ll, 0, 1) or 0;
			return (x - sx - ex * t) ^ 2 + (z - sz - ez * t) ^ 2 <= rr * rr;
		elseif sh == "lane" or sh == "crack" then
			local along = px * h.dx + pz * h.dz;
			if math.abs(px * h.dz - pz * h.dx) > (h.w or 0) * .5 + (h.beam and .4 or PR) then return false; end;
			if sh == "lane" then return along >= -PR and along <= (h.len or 0) + PR; end;
			local l0 = (h.len or 0) * math.clamp(a3 / dur, 0, 1);
			local l1 = (h.len or 0) * math.clamp(a4 / dur, 0, 1);
			return along >= l0 - 2 and along <= l1 + PR;
		end;
		local dd = math.sqrt(px * px + pz * pz);
		if sh == "cone" then
			if dd > (h.r or 0) + PR then return false; end;
			if dd < 1.8 then return true; end;
			return math.abs(angTo(px, pz, h.dx, h.dz)) <= (h.angle or 0) * .5 + math.deg(math.asin(math.min(PR / dd, 1)));
		elseif sh == "donut" then
			return dd > (h.inner or 0) and dd <= (h.r or 0) + PR;
		elseif sh == "ring" then
			local r0, r1 = h.r0 or 0, h.r1 or 0;
			local ra = r0 + (r1 - r0) * math.clamp(a3 / dur, 0, 1);
			local rb = r0 + (r1 - r0) * math.clamp(a4 / dur, 0, 1);
			local band = (h.band or 0) * .5 + PR;
			return dd >= math.min(ra, rb) - band and dd <= math.max(ra, rb) + band;
		elseif sh == "sweep" then
			if h.inner and dd < h.inner then return false; end;
			if dd > (h.r or 0) + PR then return false; end;
			if dd < .5 then return true; end;
			local slack = math.deg(math.asin(math.min(((h.w or 0) * .5 + (h.beam and .4 or PR)) / dd, 1)));
			local a0, a1 = h.a0 or 0, h.a1 or 0;
			local aa = a0 + (a1 - a0) * math.clamp(a3 / dur, 0, 1);
			local ab = a0 + (a1 - a0) * math.clamp(a4 / dur, 0, 1);
			local rel = angTo(px, pz, h.dx, h.dz);
			return rel >= math.min(aa, ab) - slack and rel <= math.max(aa, ab) + slack;
		end;
		return false; -- the game's test ignores shapes it doesn't know too
	end;
	local function norm(h)
		local hh = {
			shape = h.shape or (h.trail and "lane") or ((h.pool or h.patch) and "circle") or nil,
			visual = h.visual and true or nil, r = tonumber(h.r), inner = tonumber(h.inner),
			r0 = tonumber(h.r0), r1 = tonumber(h.r1), band = tonumber(h.band), len = tonumber(h.len),
			w = tonumber(h.w), angle = tonumber(h.angle), a0 = tonumber(h.a0), a1 = tonumber(h.a1),
			beam = h.beam and true or nil, dur = tonumber(h.dur), pool = h.pool and true or nil, trail = h.trail and true or nil,
			ax = h.at.X, az = h.at.Z,
		};
		if typeof(h.dir) == "Vector3" then hh.dx, hh.dz = unit(h.dir.X, h.dir.Z); else hh.dx, hh.dz = 0, -1; end;
		if typeof(h.vel) == "Vector3" then hh.vx, hh.vz = h.vel.X, h.vel.Z; end;
		return hh;
	end;
	-- a circle around everything the hazard can touch (quick reject)
	local function bounds(e)
		local hh = e.h;
		local cx, cz = hh.ax, hh.az;
		local reach = math.max(hh.r or 0, hh.r1 or 0, hh.len or 0) + (hh.w or 0) + (hh.band or 0) + PR + 1;
		if hh.shape == "lane" or hh.shape == "crack" then
			local L = hh.len or 0;
			cx, cz = hh.ax + hh.dx * L * .5, hh.az + hh.dz * L * .5;
			reach = L * .5 + (hh.w or 0) * .5 + PR + 2.5;
		elseif hh.vx then
			local D = hh.dur or 0;
			cx, cz = hh.ax + hh.vx * D * .5, hh.az + hh.vz * D * .5;
			reach = (hh.r or 0) + math.sqrt(hh.vx ^ 2 + hh.vz ^ 2) * D * .5 + PR + 1;
		end;
		e.cx, e.cz, e.bound = cx, cz, reach;
	end;
	local function sigFor(style, kind, size)
		local bucket = size < 2 and "XS" or size < 4 and "S" or size < 8 and "M" or size < 16 and "L" or "XL";
		-- shots keep the "projectile:" prefix: they never block routes or the approach (v5.27)
		return (kind == "shot" and "projectile:" or "") .. "plan:" .. tostring(style or "?") .. ":" .. tostring(kind) .. "-" .. bucket;
	end;
	-- zones in the bot's own format (what the escape planner and the roll logic understand)
	local function mkCircle(x, z, rad)
		return { x = x, z = z, ax = 1, az = 0, bx = 0, bz = 1, h1 = rad, h2 = rad, circle = true, pm = Vl, plan = true };
	end;
	local function mkRect(x0, z0, x1, z1, half)
		local dx, dz = x1 - x0, z1 - z0;
		local L = math.sqrt(dx * dx + dz * dz);
		if L < .2 then return mkCircle(x0, z0, half); end;
		local ux, uz = dx / L, dz / L;
		return { x = (x0 + x1) * .5, z = (z0 + z1) * .5, ax = ux, az = uz, bx = -uz, bz = ux, h1 = L * .5, h2 = half, circle = false, pm = Vl, plan = true };
	end;
	local function dress(z, e)
		z.sig, z.seenAt = e.sig, e.seenAt;
		local a = type(brain.attacks) == "table" and brain.attacks[e.sig];
		z.sx = type(a) == "table" and tonumber(a.extra) or 0;
		z.sl = type(a) == "table" and tonumber(a.lead) or 0;
		return z;
	end;
	function P.zoneOf(e, now)
		local hh = e.h;
		local sh = hh.shape or "circle";
		if hh.vx and now >= e.hitAt then
			-- moving circle: from where it is now to where it ends up
			local D = hh.dur or 0;
			local t0 = math.min(now - e.hitAt, D);
			return dress(mkRect(hh.ax + hh.vx * t0, hh.az + hh.vz * t0, hh.ax + hh.vx * D, hh.az + hh.vz * D, hh.r or 1), e);
		end;
		if e.zone then return e.zone; end;
		local z;
		if sh == "lane" or sh == "crack" then
			local L = hh.len or 0;
			z = mkRect(hh.ax, hh.az, hh.ax + hh.dx * L, hh.az + hh.dz * L, (hh.w or 0) * .5);
		elseif sh == "cone" or sh == "sweep" then
			local span = sh == "cone" and (hh.angle or 90) or (math.abs((hh.a1 or 0) - (hh.a0 or 0)) + 20);
			local rad = hh.r or 6;
			if span >= 150 then
				z = mkCircle(hh.ax, hh.az, rad);
			else
				local mid = sh == "cone" and 0 or ((hh.a0 or 0) + (hh.a1 or 0)) * .5;
				local v = CFrame.Angles(0, math.rad(mid), 0) * Vector3.new(hh.dx, 0, hh.dz);
				local half = math.max(rad * math.sin(math.rad(span * .5)), (hh.w or 0) * .5, 1.5);
				z = mkRect(hh.ax, hh.az, hh.ax + v.X * rad, hh.az + v.Z * rad, half);
			end;
		elseif sh == "ring" then
			z = mkCircle(hh.ax, hh.az, (hh.r1 or 6) + (hh.band or 0) * .5);
			local hole = (hh.r0 or 0) - (hh.band or 0) * .5;
			if hole > 2 then z.hole = hole; end;
		elseif sh == "donut" then
			z = mkCircle(hh.ax, hh.az, hh.r or 6);
			if (hh.inner or 0) > 1.5 then z.hole = hh.inner; end;
		else
			z = mkCircle(hh.ax, hh.az, hh.r or 4);
		end;
		dress(z, e);
		e.zone = z;
		pcall(dangerMem.onAttack, z, d());
		return z;
	end;
	function P.shotPos(s, t)
		local el0 = t - s.spawnAt;
		if el0 < 0 or el0 > s.life then return nil; end;
		if s.back and el0 > s.back then
			return s.fx + s.vx * s.back - s.vx * (el0 - s.back), s.fz + s.vz * s.back - s.vz * (el0 - s.back);
		end;
		return s.fx + s.vx * el0, s.fz + s.vz * el0;
	end;
	-- earliest time in [a, b] at which a point moving as (px, pz) + (vx, vz) * (t - t0) is within rr of (x, z).
	-- Solved exactly (a quadratic), not sampled: a 168-bullet storm asked hundreds of these per frame.
	local function segHit(px, pz, vx, vz, t0, a, b, x, z, rr)
		if b < a then return nil; end;
		local dx, dz = px - x, pz - z;
		local A = vx * vx + vz * vz;
		local B = 2 * (vx * dx + vz * dz);
		local C = dx * dx + dz * dz - rr * rr;
		if A < 1e-9 then return C <= 0 and a or nil; end;
		local disc = B * B - 4 * A * C;
		if disc < 0 then return nil; end;
		local sq = math.sqrt(disc);
		local lo = math.max((-B - sq) / (2 * A), a - t0);
		local hi = math.min((-B + sq) / (2 * A), b - t0);
		if lo <= hi then return t0 + lo; end;
		return nil;
	end;
	function P.shotHit(s, x, z, T1, T2)
		if s.visual then return nil; end;
		if s.arc then
			local land = s.spawnAt + s.arc.flight;
			if land >= T1 - .1 and land <= T2 and (x - s.arc.tx) ^ 2 + (z - s.arc.tz) ^ 2 <= ((s.radius or 2) + PR) ^ 2 then return land; end;
			return nil;
		end;
		local a = math.max(T1, s.spawnAt);
		local b = math.min(T2, s.spawnAt + s.life);
		if b < a then return nil; end;
		local rr = (s.radius or 2) + (r.fragile and 1 or .6);
		if s.back and s.back < s.life then
			-- out, then back the same way
			local tb = s.spawnAt + s.back;
			local h1 = segHit(s.fx, s.fz, s.vx, s.vz, s.spawnAt, a, math.min(b, tb), x, z, rr);
			if h1 then return h1; end;
			return segHit(s.fx + s.vx * s.back, s.fz + s.vz * s.back, -s.vx, -s.vz, tb, math.max(a, tb), b, x, z, rr);
		end;
		return segHit(s.fx, s.fz, s.vx, s.vz, s.spawnAt, a, b, x, z, rr);
	end;
	function P.shotZone(s, now)
		if s.arc then
			local land = s.spawnAt + s.arc.flight;
			if now < land - 1.25 or now > land + .3 then return nil; end;
			return dress(mkCircle(s.arc.tx, s.arc.tz, (s.radius or 2) + .5), s);
		end;
		local t0 = math.max(now, s.spawnAt);
		local t1 = math.min(s.spawnAt + s.life, t0 + .6);
		if t1 <= t0 then return nil; end;
		local x0, z0 = P.shotPos(s, t0);
		local x1, z1 = P.shotPos(s, t1);
		if s.back and t0 - s.spawnAt < s.back and t1 - s.spawnAt > s.back then
			x1, z1 = s.fx + s.vx * s.back, s.fz + s.vz * s.back;
		end;
		if not (x0 and x1) then return nil; end;
		return dress(mkRect(x0, z0, x1, z1, (s.radius or 2) + .3), s);
	end;
	-- earliest server time in [T1, T2] at which standing on (x, z) gets hit by a planned attack or shot
	function P.hitAt(x, z, T1, T2)
		local best, bestE;
		for _, e in ipairs(P.hz) do
			local a = math.max(T1, e.hitAt);
			local b = math.min(T2, e.endAt);
			if a <= b + 1e-3 and (not best or a < best) and not e.h.visual then
				local dx, dz = x - e.cx, z - e.cz;
				if dx * dx + dz * dz <= e.bound * e.bound and P.test(e.h, x, z, a - e.hitAt, math.max(a, b) - e.hitAt) then
					best, bestE = a, e;
				end;
			end;
		end;
		for _, sh in ipairs(P.shots) do
			if not best or sh.spawnAt < best then
				local t = P.shotHit(sh, x, z, T1, best and math.min(T2, best) or T2);
				if t and (not best or t < best) then best, bestE = t, sh; end;
			end;
		end;
		return best, bestE;
	end;
	-- zones for this frame (Fl) and timed entries (Cl) for the planned attacks and shots near now
	function P.frame(nowL, pos)
		local now = srv();
		local off = nowL - now;
		if nowL - (P.fragAt or -1e9) > 1 then
			P.fragAt = nowL;
			local hm = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
			r.fragile = hm ~= nil and hm.MaxHealth > 0 and hm.MaxHealth <= 10;
		end;
		for k = #P.hz, 1, -1 do if P.hz[k].endAt < now - .5 then table.remove(P.hz, k); end; end;
		for k = #P.shots, 1, -1 do
			local sh = P.shots[k];
			if sh.spawnAt + (sh.arc and sh.arc.flight + .3 or sh.life) < now - .2 then table.remove(P.shots, k); end;
		end;
		-- fromMob shots: follow the boss until each one spawns, then the start point is fixed (like the client)
		for _, sh in ipairs(P.shots) do
			if sh.fromMob and not sh.fixed then
				local th = sh.thrower;
				local pp = th and th.Parent and th.PrimaryPart;
				if pp then sh.fx, sh.fz = pp.Position.X, pp.Position.Z; end;
				if now >= sh.spawnAt then sh.fixed = true; end;
			end;
			-- capture record: the boss and the start point used at the moment it spawned
			if not sh.spawnSeen and now >= sh.spawnAt then
				sh.spawnSeen = true;
				local th = sh.thrower;
				local pp = th and th.Parent and th.PrimaryPart;
				if pp then sh.bossAtSpawn = { pp.Position.X, pp.Position.Z }; end;
				sh.originUsed = { sh.fx, sh.fz };
			end;
		end;
		-- (v5.32) record only: once a second during a bullet storm, how far the drawn bullets near you are
		-- from the modelled ones (median / max). Nothing here changes movement or dodging.
		if pos and #P.shots > 0 and nowL - (P.chkAt or -1e9) >= 1 then
			P.chkAt = nowL;
			pcall(function()
				local vis = P.visibleBullets(pos.X, pos.Z, 40);
				local errs = {};
				for k = 1, math.min(#vis, 8) do
					local v, me = vis[k], nil;
					for _, sh in ipairs(P.shots) do
						local sx, sz = P.shotPos(sh, now);
						if sx then
							local dd = math.sqrt((sx - v.x) ^ 2 + (sz - v.z) ^ 2);
							if not me or dd < me then me = dd; end;
						end;
					end;
					if me then errs[#errs + 1] = me; end;
				end;
				if #errs > 0 then
					table.sort(errs);
					P.lastCheck = { clock = nowL, n = #errs, median = errs[math.ceil(#errs / 2)], max = errs[#errs] };
					if nowL - (P.chkLogAt or -1e9) >= 3 then
						P.chkLogAt = nowL;
						f(string.format("bullet model check: %d drawn bullets near you, model off by median %.2f st, max %.2f st", #errs, P.lastCheck.median, P.lastCheck.max));
					end;
				end;
			end);
		end;
		if pos and #P.shots > 0 and nowL - (P.nearAt or -1e9) >= 8 then
			local hm = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
			if hm and hm.Health > 0 then
				for _, sh in ipairs(P.shots) do
					if not sh.visual and not sh.arc then
						local sx, sz = P.shotPos(sh, now);
						if sx and (sx - pos.X) ^ 2 + (sz - pos.Z) ^ 2 <= ((sh.radius or 2) + 1.5) ^ 2 then
							P.nearAt = nowL;
							pcall(P.requestCapture, "nearmiss", 0);
							break;
						end;
					end;
				end;
			end;
		end;
		local lead = r.fragile and 1.6 or 1.25;
		local zs, cl = {}, {};
		for _, e in ipairs(P.hz) do
			if not e.h.visual and now >= math.min(e.warnAt, e.hitAt - lead) and now <= e.endAt + .1 then
				local z = P.zoneOf(e, now);
				if z then
					z.hitAt, z.endAt = e.hitAt + off, e.endAt + off;
					zs[#zs + 1] = z;
					if e.hitAt >= now - .05 and e.hitAt - now <= 1.4 then
						cl["plan" .. e.key] = { zone = z, hitAt = e.hitAt + off, e = e };
					end;
				end;
			end;
		end;
		for _, sh in ipairs(P.shots) do
			if not sh.visual and now >= sh.spawnAt - lead then
				local z = P.shotZone(sh, now);
				if z then
					zs[#zs + 1] = z;
					if pos then
						local ht = P.shotHit(sh, pos.X, pos.Z, now, now + 1.2);
						if ht then cl["shot" .. sh.key] = { zone = z, hitAt = ht + off, e = sh }; end;
					end;
				end;
			end;
		end;
		return zs, cl;
	end;
	-- a roll keeps its i-frames for 0.35 s (Config.Dodge.Iframes): after that the landing spot has to be
	-- clear. Returns a better direction only if the current heading lands where a planned attack hits.
	function P.rollDir(G, dir)
		local rd = math.min(12, tonumber(brain.rollDist) or 6);
		local sv = srv();
		local function landingOk(dx, dz)
			local ex, ez = G.X + dx * rd, G.Z + dz * rd;
			if r.navOpenAt then
				local okO, open = pcall(r.navOpenAt, ex, ez);
				if okO and (tonumber(open) or 99) < 1 then return false; end;
			end;
			for _, z in ipairs(Fl) do
				if not z.plan and ul(z, ex, ez, Vl) then return false; end;
			end;
			return P.hitAt(ex, ez, sv + .35, sv + 1.1) == nil;
		end;
		local cx, cz = dir and dir[1] or 0, dir and dir[2] or 0;
		if (cx ~= 0 or cz ~= 0) and landingOk(cx, cz) then return nil; end;
		local best, bs;
		for k = 0, 7 do
			local a = k * math.pi / 4;
			local dx, dz = math.cos(a), math.sin(a);
			if landingOk(dx, dz) then
				local sc = -(dx * cx + dz * cz);
				if not bs or sc < bs then best, bs = { dx, dz }, sc; end;
			end;
		end;
		if best then return best[1], best[2]; end;
		return nil;
	end;
	local function mobName(id)
		if id == nil then return "?", nil; end;
		for _, o in ipairs(workspace:GetChildren()) do
			if o:IsA("Model") and o:GetAttribute("MobId") == id then return o.Name, o; end;
		end;
		return "?", nil;
	end;
	function P.onPlan(p)
		if type(p) ~= "table" or type(p.t0) ~= "number" then return; end;
		local now, nowL = srv(), d();
		P.lastPlan, P.plans = nowL, P.plans + 1;
		local mob, thrower = mobName(p.id);
		local fromMobN, offBoss = 0, nil;
		local first, kinds, nh, ns = math.huge, {}, 0, 0;
		for i, h in ipairs(type(p.hazards) == "table" and p.hazards or {}) do
			if type(h) == "table" and typeof(h.at) == "Vector3" and type(h.hit) == "number" then
				local hh = norm(h);
				local e = { h = hh, id = p.id, mob = mob, style = p.style, key = tostring(p.id) .. ":" .. tostring(p.t0) .. ":" .. i,
					warnAt = p.t0 + (tonumber(h.warn) or 0), hitAt = p.t0 + h.hit, recv = now, seenAt = nowL };
				e.endAt = e.hitAt + (hh.dur or 0);
				e.what = tostring(hh.shape) .. (hh.pool and "/pool" or "") .. (hh.trail and "/trail" or "");
				e.sig = sigFor(p.style, hh.shape or "?", math.max(hh.r or 0, hh.r1 or 0, (hh.len or 0) * .5, (hh.w or 0) * .5));
				bounds(e);
				P.hz[#P.hz + 1] = e;
				if not hh.visual then
					nh = nh + 1;
					first = math.min(first, e.hitAt);
					kinds[e.what] = (kinds[e.what] or 0) + 1;
					local nm = tostring(hh.shape);
					if not KNOWN[nm] and not P.unknown[nm] then
						P.unknown[nm] = true;
						f("plan: hazard shape '" .. nm .. "' isn't known here (the game's hit test ignores it too)");
					end;
				end;
			end;
		end;
		for i, s0 in ipairs(type(p.shots) == "table" and p.shots or {}) do
			if type(s0) == "table" and typeof(s0.from) == "Vector3" then
				local sh = { key = tostring(p.id) .. ":" .. tostring(p.t0) .. ":s" .. i, id = p.id, mob = mob, style = p.style,
					fx = s0.from.X, fz = s0.from.Z, spawnAt = p.t0 + (tonumber(s0.spawn) or 0), life = tonumber(s0.life) or 1,
					radius = tonumber(s0.radius) or 2, back = tonumber(s0.back), visual = s0.visual and true or nil,
					recv = now, seenAt = nowL, what = "shot" };
				if typeof(s0.vel) == "Vector3" then sh.vx, sh.vz = s0.vel.X, s0.vel.Z; else sh.vx, sh.vz = 0, 0; end;
				sh.px0, sh.pz0, sh.thrower = sh.fx, sh.fz, thrower; -- for the capture record: the plan's own start point
				-- "fromMob": the game starts the shot wherever the boss is when it spawns, not at "from"
				-- (a Pale Warden sanctum storm killed a run from bullets the old model put somewhere else)
				if s0.fromMob then
					sh.fromMob = true;
					fromMobN = fromMobN + 1;
					local pp = thrower and thrower.PrimaryPart;
					if pp and not offBoss then offBoss = math.sqrt((pp.Position.X - sh.fx) ^ 2 + (pp.Position.Z - sh.fz) ^ 2); end;
				end;
				if type(s0.arc) == "table" and typeof(s0.arc.to) == "Vector3" then
					sh.arc = { tx = s0.arc.to.X, tz = s0.arc.to.Z, flight = math.max(tonumber(s0.arc.flight) or 1, .05) };
					sh.what = "lob";
				end;
				sh.sig = sigFor(p.style, sh.what, sh.radius);
				P.shots[#P.shots + 1] = sh;
				if not sh.visual then ns = ns + 1; first = math.min(first, sh.spawnAt); end;
			end;
		end;
		-- (v5.37) "seen shooting" from the plan: one volley per plan that has shots
		if ns > 0 and r.noteShooter then pcall(r.noteShooter, mob, nil, nowL); end;
		-- (v5.32.1) a bullet storm (40+ planned shots): one automatic capture covering its first seconds
		if ns >= 40 and first < math.huge then
			local delay = math.max(2, math.min(12, (first - now) + 5));
			task.delay(delay, function() pcall(P.requestCapture, "storm", 0); end);
		end;
		local parts = {};
		for k, v in pairs(kinds) do parts[#parts + 1] = v > 1 and (k .. "x" .. v) or k; end;
		f(string.format("plan #%s %s %s: %d hazards (%s), %d shots, first hit in %.2fs (sent %.2fs ago)%s",
			tostring(p.id), mob, tostring(p.style or ""), nh, table.concat(parts, " "), ns,
			first < math.huge and first - now or -1, now - p.t0,
			fromMobN > 0 and string.format(", %d start at the boss (boss %.1f st from the plan's start point)", fromMobN, offBoss or -1) or ""));
	end;
	function P.onCancel(c)
		if type(c) ~= "table" then return; end;
		local at = tonumber(c.at) or srv();
		local gone = 0;
		for k = #P.hz, 1, -1 do
			local e = P.hz[k];
			if e.id == c.id and (at < e.hitAt or (c.lava and (e.h.pool or e.h.trail))) then table.remove(P.hz, k); gone = gone + 1; end;
		end;
		for k = #P.shots, 1, -1 do
			local sh = P.shots[k];
			if sh.id == c.id and (c.all or sh.spawnAt > at) then table.remove(P.shots, k); gone = gone + 1; end;
		end;
		f(string.format("plan #%s cancelled (%d parts dropped%s%s)", tostring(c.id), gone, c.all and ", all shots" or "", c.lava and ", lava too" or ""));
	end;
	function P.onShot(p)
		if type(p) ~= "table" then return; end;
		local now, nowL = srv(), d();
		P.lastShot = nowL;
		local n = 0;
		if type(p.lob) == "table" and typeof(p.lob.target) == "Vector3" then
			local lb = p.lob;
			local fl = math.max(tonumber(lb.flight) or 1, .05);
			local hh = { shape = "circle", r = tonumber(lb.radius) or 4, ax = lb.target.X, az = lb.target.Z, dx = 0, dz = -1, dur = .2 };
			local e = { h = hh, id = "shot", mob = "?", style = p.style, key = "lob:" .. tostring(now), warnAt = now, hitAt = now + fl,
				recv = now, seenAt = nowL, what = "lob" };
			e.endAt = e.hitAt + .2;
			e.sig = sigFor(p.style, "lob", hh.r);
			bounds(e);
			P.hz[#P.hz + 1] = e;
			n = 1;
		end;
		for i, s0 in ipairs(type(p.shots) == "table" and p.shots or {}) do
			if type(s0) == "table" and typeof(s0.from) == "Vector3" and typeof(s0.vel) == "Vector3" then
				P.shots[#P.shots + 1] = { key = "ms:" .. tostring(now) .. ":" .. i, id = "shot", mob = "?", style = p.style,
					fx = s0.from.X, fz = s0.from.Z, vx = s0.vel.X, vz = s0.vel.Z, spawnAt = now, life = tonumber(s0.life) or 1,
					radius = 2, recv = now, seenAt = nowL, what = "shot", sig = sigFor(p.style, "shot", 2) };
				n = n + 1;
			end;
		end;
		if n > 0 then f(string.format("mob volley: %d %s", n, p.lob and "lob" or "shots")); end;
		-- (v5.37) MobShot names no mob: credit the one nearest to where the shots start (within 12 st)
		if n > 0 and r.noteShooter then
			local from = (type(p.lob) == "table" and typeof(p.lob.from) == "Vector3" and p.lob.from)
				or (type(p.shots) == "table" and type(p.shots[1]) == "table" and typeof(p.shots[1].from) == "Vector3" and p.shots[1].from) or nil;
			if from then pcall(r.noteShooter, nil, from, nowL); end;
		end;
	end;
	function P.onDodged(p)
		P.dodged = (P.dodged or 0) + 1;
		P.lastDodged = { clock = d() };
		local bits = {};
		if type(p) == "table" then
			for k, v in pairs(p) do
				if #bits < 6 then bits[#bits + 1] = tostring(k) .. "=" .. tostring(v); end;
			end;
		end;
		P.lastDodged.info = table.concat(bits, " ");
		f("server: dodged (" .. P.lastDodged.info .. ")");
	end;
	-- ===================================================================================
	-- CAPTURE RECORDS (v5.32). With the helper in capture mode ("Start Delve Screenshots.bat", option 2) the
	-- last seconds of the screen are kept; on a hit, a death or F8 this writes what the dodge code knew at
	-- that moment, so the clip and the model can be compared. It writes files only: nothing here changes
	-- movement or dodging. Times: ms = Unix milliseconds (same clock as the helper), clock = dodge_log time.
	-- ===================================================================================
	-- drawn bullets near you (HazardView's bodies: small, solid, longer than wide, not the smoke balls)
	function P.visibleBullets(px, pz, radius)
		local out = {};
		local fold = workspace:FindFirstChild("Hazards");
		if not fold then return out; end;
		for _, o in ipairs(fold:GetChildren()) do
			if o:IsA("BasePart") and o.Transparency < .5 and not (o:IsA("Part") and o.Shape == Enum.PartType.Ball) then
				local sz = o.Size;
				local mx, mn = math.max(sz.X, sz.Y, sz.Z), math.min(sz.X, sz.Y, sz.Z);
				if mx <= 3 and mn >= .2 and mx >= mn * 2 then
					local p0 = o.Position;
					local dd = (p0.X - px) ^ 2 + (p0.Z - pz) ^ 2;
					if dd <= radius * radius then out[#out + 1] = { x = p0.X, z = p0.Z, d = math.sqrt(dd) }; end;
				end;
			end;
		end;
		table.sort(out, function(a, b) return a.d < b.d; end);
		return out;
	end;
	function P.captureOn()
		local nowL = d();
		if P.capChk and nowL - P.capChk.t < 5 then return P.capChk.on; end;
		local on = false;
		pcall(function()
			if type(isfile) == "function" and isfile("DelveWebhook/capture_on.txt") then
				local t = tonumber((readfile("DelveWebhook/capture_on.txt") or ""):match("%d+"));
				on = t ~= nil and math.abs(os.time() - t) < 20;
			end;
		end);
		P.capChk = { t = nowL, on = on };
		return on;
	end;
	function P.snapshot(reason, loss)
		local ch = l.Character;
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart");
		if not hrp then return nil; end;
		local hum = ch:FindFirstChildOfClass("Humanoid");
		local px, pz = hrp.Position.X, hrp.Position.Z;
		local okT, ms = pcall(function() return DateTime.now().UnixTimestampMillis; end);
		local sv, clk = srv(), d();
		local rec = { reason = reason, version = "v5.32", ms = okT and ms or math.floor(os.time() * 1000), clock = clk, srv = sv,
			loss = loss, hp = hum and hum.Health or nil, player = { x = px, z = pz }, planned = #P.hz, shots = #P.shots };
		local best, bd;
		for _, sh in ipairs(P.shots) do
			local sx, sz = P.shotPos(sh, sv);
			if sx then
				local dd = math.sqrt((sx - px) ^ 2 + (sz - pz) ^ 2);
				if not bd or dd < bd then best, bd = sh, dd; end;
			end;
		end;
		if best then
			local sx, sz = P.shotPos(best, sv);
			rec.nearestShot = {
				key = best.key, mob = best.mob, fromMob = best.fromMob or false,
				spawnMs = rec.ms + math.floor((best.spawnAt - sv) * 1000), spawnBeforeMs = math.floor((sv - best.spawnAt) * 1000),
				bossAtSpawn = best.bossAtSpawn and { x = best.bossAtSpawn[1], z = best.bossAtSpawn[2] } or nil,
				originUsed = best.originUsed and { x = best.originUsed[1], z = best.originUsed[2] } or { x = best.fx, z = best.fz },
				planFrom = best.px0 and { x = best.px0, z = best.pz0 } or nil,
				modeled = { x = sx, z = sz }, distance = bd, radius = best.radius,
				speed = math.sqrt((best.vx or 0) ^ 2 + (best.vz or 0) ^ 2), life = best.life,
			};
		end;
		local vis = P.visibleBullets(px, pz, 30);
		if vis[1] then
			local v, mk, me = vis[1], nil, nil;
			for _, sh in ipairs(P.shots) do
				local sx, sz = P.shotPos(sh, sv);
				if sx then
					local dd = math.sqrt((sx - v.x) ^ 2 + (sz - v.z) ^ 2);
					if not me or dd < me then mk, me = sh.key, dd; end;
				end;
			end;
			rec.visibleBullet = { x = v.x, z = v.z, distance = v.d, modelKey = mk, modelError = me, drawnNearby = #vis };
		end;
		if P.lastCheck then
			rec.bulletCheck = { n = P.lastCheck.n, median = P.lastCheck.median, max = P.lastCheck.max, msAgo = math.floor((clk - P.lastCheck.clock) * 1000) };
		end;
		rec.dodge = {
			rollMsAgo = r.lastRoll and math.floor((clk - r.lastRoll) * 1000) or nil,
			escapeMsAgo = r.escInfo and math.floor((clk - r.escInfo.t) * 1000) or nil,
			serverDodgeMsAgo = P.lastDodged and math.floor((clk - P.lastDodged.clock) * 1000) or nil,
			serverDodgeInfo = P.lastDodged and P.lastDodged.info or nil,
		};
		return rec;
	end;
	function P.requestCapture(reason, loss)
		local nowL = d();
		if reason == "storm" or reason == "nearmiss" then
			if nowL - (P.autoAt or -1e9) < 8 then return nil; end;
			P.autoAt = nowL;
		end;
		if P.capLast and P.capLast.reason == reason and nowL - P.capLast.t < 1 then return nil; end;
		P.capLast = { reason = reason, t = nowL };
		local rec = P.snapshot(reason, loss);
		if not rec then return nil; end;
		local ns, vb = rec.nearestShot, rec.visibleBullet;
		local gap;
		if ns and ns.bossAtSpawn and ns.originUsed then
			gap = math.sqrt((ns.bossAtSpawn.x - ns.originUsed.x) ^ 2 + (ns.bossAtSpawn.z - ns.originUsed.z) ^ 2);
		end;
		f(string.format("capture (%s): nearest planned shot %s%s; drawn bullet %s; roll %s, server dodge %s",
			reason,
			ns and string.format("%.1f st (spawned %.2fs before, start used vs boss at spawn %s apart)", ns.distance, ns.spawnBeforeMs / 1000,
				gap and string.format("%.1f st", gap) or "?") or "none",
			"",
			vb and string.format("%.1f st away, model off by %s", vb.distance, vb.modelError and string.format("%.2f st", vb.modelError) or "?") or "none near you",
			rec.dodge.rollMsAgo and (rec.dodge.rollMsAgo .. " ms ago") or "none",
			rec.dodge.serverDodgeMsAgo and (rec.dodge.serverDodgeMsAgo .. " ms ago") or "none"));
		if P.captureOn() and type(writefile) == "function" then
			pcall(function()
				writefile(string.format("DelveWebhook/cap_%d.json", rec.ms), game:GetService("HttpService"):JSONEncode(rec));
			end);
		end;
		return rec;
	end;
	-- listen (a re-run of the script drops the old listeners first)
	for _, c in ipairs(type(r.planConns) == "table" and r.planConns or {}) do pcall(function() c:Disconnect(); end); end;
	r.planConns = {};
	task.spawn(function()
		local net = game:GetService("ReplicatedStorage"):WaitForChild("StrataNet", 30);
		if not net then return; end;
		local function hook(name, fn)
			local ev = net:WaitForChild(name, 15);
			if not (ev and ev:IsA("RemoteEvent")) then return false; end;
			r.planConns[#r.planConns + 1] = ev.OnClientEvent:Connect(function(...)
				local ok, err = pcall(fn, ...);
				if not ok and not P.errLogged then
					P.errLogged = true;
					f("plan feed error (" .. name .. "): " .. tostring(err));
				end;
			end);
			return true;
		end;
		local okPlan = hook("MobPlan", P.onPlan);
		hook("MobPlanCancel", P.onCancel);
		local okShot = hook("MobShot", P.onShot);
		hook("Dodged", P.onDodged);
		hook("SessionSync", function(p) if r.room and r.room.onSession then r.room.onSession(p); end; end);
		P.hooked = okPlan and true or false;
		P.shotHooked = okShot and true or false;
		f("attack plan feed: " .. (P.hooked and "listening (MobPlan, MobPlanCancel, MobShot, Dodged, SessionSync)" or "not available, using the drawn shapes only"));
	end);
end;
local function SQ(m, G)
	local R0 = r; -- r becomes a number further down
	-- an attack roll is lined up: face the target for a moment so the roll goes into it
	local fd = r.forceDir;
	local dt = r.detour;
	if fd and d() < fd.untilT then
		m, G = fd.x, fd.z;
	elseif dt and m and not r.dodging then
		local hrp = l.Character and l.Character:FindFirstChild("HumanoidRootPart");
		if hrp and d() < dt.untilT then
			local p0 = hrp.Position;
			local wp = dt.path[dt.i];
			while wp and (wp.x - p0.X) ^ 2 + (wp.z - p0.Z) ^ 2 < 2.25 do
				dt.i = dt.i + 1;
				wp = dt.path[dt.i];
			end;
			if wp then m, G = wp.x - p0.X, wp.z - p0.Z; else r.detour = nil; end;
		else
			r.detour = nil;
		end;
	end;
	if not m then
		Pl();
		return;
	end;
	local r = math.sqrt(m * m + G * G);
	if r < .001 then
		Pl();
		return;
	end;
	m, G = m / r, G / r;
	-- SMOOTH MOVEMENT: outside dodges, a sudden reversal (more than ~110 degrees) within 0.35 s of the last
	-- heading is ignored (it keeps going the way it was), and smaller turns are eased. That removes the W/S
	-- back-and-forth from targets/routes flipping. Dodges, rolls and forced headings are never delayed.
	do
		local nowS = d();
		local sm = R0.smoothDir;
		local urgent = R0.dodging or (fd and nowS < fd.untilT) or nowS - (R0.lastDodgeAt or -1e9) < .4 or nowS - (R0.lastRoll or -1e9) < .4
			or (R0.detour ~= nil) or (R0.lastStuck and nowS - R0.lastStuck.t < 3);
		-- pressing into something (pillar, wall): never keep the old heading
		if not urgent then
			local hrpV = l.Character and l.Character:FindFirstChild("HumanoidRootPart");
			if hrpV then
				local v = hrpV.AssemblyLinearVelocity;
				if v.X * v.X + v.Z * v.Z < 9 then urgent = true; end;
			end;
		end;
		-- never smooth toward an edge: keeping the old heading is only allowed with solid floor 4 st ahead
		-- (it carried the character off the map once: "YOU SLIPPED")
		local function floorAhead(dx, dz)
			local hrp = l.Character and l.Character:FindFirstChild("HumanoidRootPart");
			if not hrp then return false; end;
			local rp = RaycastParams.new();
			rp.FilterType = Enum.RaycastFilterType.Exclude;
			rp.FilterDescendantsInstances = { l.Character };
			local o = hrp.Position + Vector3.new(dx * 4, 2, dz * 4);
			local hit = workspace:Raycast(o, Vector3.new(0, -12, 0), rp);
			return hit ~= nil and hit.Position.Y > hrp.Position.Y - 6;
		end;
		if sm and not urgent and nowS - sm.t < .5 then
			local dot = m * sm.x + G * sm.z;
			if dot < -0.34 and nowS - sm.setAt < .3 then
				if floorAhead(sm.x, sm.z) then m, G = sm.x, sm.z; end;
			elseif dot < .97 then
				local bx, bz = sm.x * .35 + m * .65, sm.z * .35 + G * .65;
				local bl = math.sqrt(bx * bx + bz * bz);
				if bl > .2 and floorAhead(bx / bl, bz / bl) then m, G = bx / bl, bz / bl; end;
			end;
		end;
		local turned = not sm or (m * sm.x + G * sm.z) < .5;
		R0.smoothDir = { x = m, z = G, t = nowS, setAt = (turned or not sm) and nowS or sm.setAt };
	end;
	run.lastDir = { m, G };
	if Q.background == true then
		-- no key presses in background mode: walk with Humanoid:Move
		inp.setMove(m, G);
		return;
	end;
	local Q = m * A + G * h;
	local e = m * k + G * T;
	tl("W", Q > .38);
	tl("S", Q < -0.38);
	tl("D", e > .38);
	tl("A", e < -0.38);
end;
local wQ, qQ, lQ = false, true, -1000000000.0;
local dQ;
local function fQ(m)
	if d() - lQ < 10 then
		if not m then
			notify("stats scan already ran in the last 10 s", "delve", 3);
		end;
		return;
	end;
	wQ, qQ = true, m;
end;
r.readStats = fQ;
local function zQ()
	wQ = false;
	-- manual stats: skip the scan entirely
	if Q.autoStats == false then
		return;
	end;
	local statT0 = not qQ and r.scanStart("Mining stats scan") or nil;
	lQ = d();
	r.statsFound = false;
	local ok, objects = pcall(getgc, true);
	local radius, reach;
	local ambiguous = false;
	if ok and type(objects) == "table" then
		for _, object in ipairs(objects) do
			if type(object) == "table" and type(rawget(object, "RuneFind")) == "number" then
				local candidateRadius = rawget(object, "Radius");
				local candidateReach = rawget(object, "Reach");
				if type(candidateRadius) == "number" and candidateRadius >= .1 and candidateRadius <= 10
					and type(candidateReach) == "number" and candidateReach >= .3 and candidateReach <= 20
				then
					if radius and (radius ~= candidateRadius or reach ~= candidateReach) then
						ambiguous = true;
						break;
					end;
					radius, reach = candidateRadius, candidateReach;
				end;
			end;
		end;
	end;
	if radius and not ambiguous then
		Q.radius, Q.reach = radius, reach;
		r.statsFound = true;
	end;
	if dQ then
		dQ();
	end;
	if r.statsFound and not qQ then
		if statT0 then r.scanEnd("Mining stats scan", statT0, string.format("Radius %.2f, reach %.2f.", Q.radius, Q.reach)); end;
	elseif not qQ then
		r.scanEnd("Mining stats scan", statT0, "No clear mining stats found; radius and reach kept.");
	end;
end;
local xQ = nil;
local WQ = "idle";
local KQ = l:GetMouse();
local oQ, FQ = nil, nil;
local jQ, RQ = nil, nil;
local CQ = nil;
local function DQ(m, G, Q)
	if CQ and CQ.step < 2 then
		local m, G = CQ.x - KQ.X, CQ.y - KQ.Y;
		if jQ and ((math.abs(m - jQ) <= 3 and math.abs(G - RQ) <= 3)) then
			oQ, FQ = m, G;
		end;
		jQ, RQ = m, G;
	end;
	local e, N;
	if oQ then
		e, N = m + oQ, G + FQ;
	else
		local inset = guiService:GetGuiInset();
		e, N = m + inset.X, G + inset.Y;
	end;
	local S, w;
	if CQ then
		S, w = CQ.fx, CQ.fy;
	end;
	if oQ then
		local m, G = KQ.X + oQ, KQ.Y + FQ;
		if not S or (CQ.step < 2 and math.abs(m - CQ.x) + math.abs(G - CQ.y) > 6) then
			S, w = m, G;
		end;
	end;
	local q = .5;
	if S and q > 0 then
		local m = CQ and math.min(Q - CQ.t, .1) or .016666666666667;
		local G = 1 - ((q * .9)) ^ ((m * 60));
		S, w = S + ((e - S)) * G, w + ((N - w)) * G;
		if math.abs(e - S) + math.abs(N - w) < 1 then
			S, w = e, N;
		end;
	else
		S, w = e, N;
	end;
	local l, d = math.floor(S + .5), math.floor(w + .5);
	local f = CQ and math.abs(l - CQ.x) + math.abs(d - CQ.y) or 99;
	if not CQ or f > 0 then
		inp.mouseMove(l, d);
	end;
	CQ = {
			x = l,
			y = d,
			fx = S,
			fy = w,
			step = f,
			t = Q,
		};
	r.mouseOffset = oQ and string.format("%d,%d", oQ, FQ) or "measuring";
end;
local function EQ(m, G)
	local r = cQ(m);
	local Q = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize;
	if not r or not Q or r.X < 0 or r.Y < 0 or r.X > Q.X or r.Y > Q.Y then
		CQ = nil;
		return;
	end;
	DQ(r.X, r.Y, G);
end;
local aQ = {
		eval = 0,
		poll = 0,
		sweep = 0,
		refresh = 0,
		dead = 0,
		tool = 0,
		haz = -1,
		ping = 0,
	};
local function iQ()
	if r.scanning then return true; end;
	-- in background mode nothing touches the mouse/keyboard, so an open menu doesn't need to pause the farm
	if Q.background == true then
		return false;
	end;
	return r.win and ((r.win.alive and r.win:IsVisible()));
end;
local function sQ()
	local m = l.Character;
	local G = m and m:FindFirstChild("HumanoidRootPart");
	return G and G.Position, m;
end;
local function OQ(m)
	if Q.autoEquip == false then
		return;
	end;
	if m - aQ.tool < .25 then
		return;
	end;
	aQ.tool = m;
	local G = nil;
	if WQ == "combat" and ((Q.combat and xQ)) then
		G = "weapon";
	elseif WQ == "mine" and ((Q.mine and L)) then
		G = "pickaxe";
	end;
	if not G or not inp.active() or iQ() then
		return;
	end;
	if m - ((r.toolPressAt or -1000000000.0)) < .8 then
		return;
	end;
	local e = l.Character;
	if not e then
		return;
	end;
	local N;
	if G == "weapon" then
		N = e:GetAttribute("WeaponDrawn");
	else
		N = e:GetAttribute("PickaxeOut");
	end;
	if N == true then
		r.toolTry = nil;
		return;
	end;
	if Q.background == true and Q.useLearned ~= false then
		local learned = inp.learned[G];
		if learned and learned[1] then
			-- background: replay the game's own equip remotes instead of pressing a key
			if inp.replay(G) then
				r.toolPressAt = m;
				r.toolPresses = ((r.toolPresses or 0)) + 1;
			end;
			return;
		end;
	end;
	local tk = G == "weapon" and mQ or Il;
	local last = r.toolTry;
	if last and last.key == tk and Q.background == true and not inp.focused() then
		-- the previous press changed nothing while tabbed out: send this key a different way
		local mode = inp.rotateKey(tk);
		if m - (r.toolNoteAt or -100) > 3 then
			r.toolNoteAt = m;
			notify(string.format("%s key had no effect, trying key method: %s", G, mode), "Delve");
		end;
	end;
	if QQ(tk, m) then
		r.toolPressAt = m;
		r.toolPresses = ((r.toolPresses or 0)) + 1;
		r.toolTry = { key = tk, t = m };
	end;
end;
local VQ = {
		seenAt = nil,
		check = 0,
		phase = "idle",
		t = 0,
		bx = 0,
		by = 0,
	};
r.replays = r.replays or 0;
local function yQ(m)
	if not m:IsA("GuiObject") or not m.Visible then return nil; end;
	local size = m.AbsoluteSize;
	if size.X < 1 or size.Y < 1 then return nil; end;
	return size.X, size.Y;
end;
local function bQ()
	local m = l:FindFirstChild("PlayerGui");
	local G = m and m:FindFirstChild("RunEnd");
	local verbs = G and G:FindFirstChild("Verbs");
	if not verbs then return nil; end;
	-- a scan is due: go back to the hub first (scan there, then start the next run from GO MINE)
	local okD, due = pcall(function() return r.scanDue and r.scanDue(); end);
	local hub = verbs:FindFirstChild("Hub");
	if okD and due and hub then
		if not r.hubForScan then
			r.hubForScan = d();
			if r.why then r.why("scan", "scan due: returning to the hub to scan before the next run"); end;
			notify("Scan due: returning to the hub first.", "Delve index");
		end;
		return hub;
	end;
	return verbs:FindFirstChild("Again");
end;
local function vQ()
	if VQ.phase == "down" then
		inp.mouseUp();
	end;
	VQ.phase = "idle";
end;
local function nQ(m)
	if not Q.autoReplay or r.f2Paused or not (Q.on or Q.autoStage or r.autoStart) then
		vQ();
		VQ.seenAt = nil;
		return false;
	end;
	if m - VQ.check >= .5 then
		VQ.check = m;
		if workspace:FindFirstChild("RunEndRoom") then
			VQ.seenAt = VQ.seenAt or m;
		else
			VQ.seenAt = nil;
			vQ();
		end;
	end;
	local sp = r.snapPending;
	if sp and d() - sp.at < 6 and not (sp.requested and type(isfile) == "function" and isfile("DelveWebhook/" .. sp.id .. ".png")) then
		return false;
	end;
	if not VQ.seenAt or m - VQ.seenAt < Q.replayDelay then
		return false;
	end;
	if not inp.active() or iQ() then
		vQ();
		return false;
	end;
	if VQ.phase == "idle" then
		if m - VQ.t < 3 then
			return false;
		end;
		local G = bQ();
		if not G then
			return false;
		end;
		if Q.background == true then
			-- no mouse in background mode: fire the button directly
			VQ.t = m;
			if inp.clickGui(G) then
				r.replays = r.replays + 1;
			end;
			return true;
		end;
		local r = G.AbsolutePosition;
		local Q, e = yQ(G);
		if not Q then return false; end;
		VQ.bx, VQ.by = r.X + Q / 2, r.Y + e / 2;
		VQ.phase, VQ.t = "move", m;
	end;
	if VQ.phase == "move" then
		DQ(VQ.bx, VQ.by, m);
		local G = math.abs(KQ.X - VQ.bx) <= 6 and math.abs(KQ.Y - VQ.by) <= 6;
		if G and ((CQ and CQ.step == 0)) then
			VQ.phase, VQ.t = "settle", m;
		elseif m - VQ.t > 2 then
			VQ.phase, VQ.t = "idle", m;
		end;
	elseif VQ.phase == "settle" then
		DQ(VQ.bx, VQ.by, m);
		if m - VQ.t >= .1 then
			inp.mouseDown();
			VQ.phase, VQ.t = "down", m;
		end;
	elseif VQ.phase == "down" then
		if m - VQ.t >= .08 then
			inp.mouseUp();
			r.replays = r.replays + 1;
			VQ.phase, VQ.t = "idle", m;
		end;
	end;
	return true;
end;
-- ===================================================================================
-- RELIC BRAIN
--   * finds the relic draft on screen (any GUI layout: looks for the tier words on cards)
--   * reads every card: tier, name, stat lines, set progress
--   * scores each card: tier + stat lines x category weights + set progress + what it learned
--   * waits for the card animation to settle, clicks, then VERIFIES the draft closed and
--     retries with another click method if not (mouse -> GUI signal -> VirtualInputManager)
--   * learns: relics you pick by hand are remembered (imitation), and every relic taken in a
--     run is credited with how good that run was compared to your usual runs
-- ===================================================================================
local MQ = { phase = "idle", t = 0, check = 0, bx = 0, by = 0 };
local relicAPI = (function()
	local VIMr;
	pcall(function() VIMr = game:GetService("VirtualInputManager"); end);
	local Http = game:GetService("HttpService");
	local TIER_VALUE = { BLESSING = 20, COMMON = 0, UNCOMMON = 10, RARE = 20, EPIC = 45, LEGENDARY = 80, MYTHIC = 150, EXOTIC = 160, DIVINE = 180, SECRET = 200 };
	local CATS = {
		{ "range", { "MINING RANGE", "MINE RANGE", "RADIUS", "REACH" } },
		{ "mining", { "MINE POWER", "MINING POWER", "MINING SPEED", "MINE SPEED", "MINING", "PICKAXE", " ORE", "ROCK" } },
		{ "control", { "FREEZE", "FROZEN", " ICE", "ICE ", "SLOW", "STUN", "KNOCKBACK", "FROST", "CHILL", "ROOT" } },
		{ "survival", { "DAMAGE TAKEN", "MAX HEALTH", "HEALTH", "MAX HP", " HP", "HEAL", "REGEN", "SHIELD", "ARMOR", "DEFENSE", "LIFESTEAL", "LIFE STEAL", "REVIVE", "INVULN", "BLOCK" } },
		{ "damage", { "DAMAGE", "DPS", "CRIT", "OVERKILL", "ATTACK", "WEAPON", "STRIKE", "BLEED", "BURN", "POISON", "EXECUTE", "CHAIN", "EXPLO" } },
		{ "mobility", { "MOVE SPEED", "MOVEMENT", "WALK SPEED", "ROLL", "DODGE", "DASH", "SPEED" } },
		{ "luck", { "LUCK", "RARITY", "DROP", "QUANTITY" } },
		{ "econ", { "CASH", "MONEY", "GOLD", "COIN", "SELL", "VALUE", " XP", "EXP" } },
	};
	local BUTTON_WORDS = { SELECT = true, PICK = true, CHOOSE = true, TAKE = true, CLAIM = true, EQUIP = true };

	local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")); end;
	local function txt(o)
		local ok, v = pcall(function() return o.ContentText; end);
		if ok and type(v) == "string" and v ~= "" then return v; end;
		return o.Text or "";
	end;
	local function shown(o)
		while o and o ~= game do
			if o:IsA("LayerCollector") then return o.Enabled ~= false; end;
			if o:IsA("GuiObject") and not o.Visible then return false; end;
			o = o.Parent;
		end;
		return false;
	end;
	local function relicRec(key)
		local rec = brain.relics[key];
		if type(rec) ~= "table" then
			rec = { n = 0, zsum = 0, picks = 0, user = 0, offered = 0 };
			brain.relics[key] = rec;
		end;
		return rec;
	end;

	-- clause -> signed value, category
	local function clauseValue(cl)
		local u = " " .. cl:upper() .. " ";
		if u:match("^%s*TAKEN%s*$") then return 0, nil; end;
		if u:find("MORE ELITES", 1, true) or u:find("CURSE", 1, true) then return -40, "risk"; end;
		local cat;
		for _, c in ipairs(CATS) do
			for _, kw in ipairs(c[2]) do
				if u:find(kw, 1, true) then cat = c[1]; break; end;
			end;
			if cat then break; end;
		end;
		local pct;
		for num in u:gmatch("([%d%.]+)%s*%%") do
			local v = tonumber(num);
			if v and (not pct or v > pct) then pct = v; end;
		end;
		local mult = tonumber(u:match("[X×]%s*([%d%.]+)"));
		local mag = pct or (mult and mult > 1 and (mult - 1) * 100) or 20;
		mag = math.min(150, math.max(5, mag));
		local aimsEnemy = u:find("ENEM", 1, true) or u:find("FOE", 1, true) or u:find(" MOB", 1, true) or u:find("BOSS", 1, true);
		local goodWhenLow = u:find("TAKEN", 1, true) or u:find("COOLDOWN", 1, true) or aimsEnemy;
		local neg = u:match("^%s*%-") ~= nil or u:find("LESS ", 1, true) or u:find("REDUC", 1, true) or u:find("LOWER", 1, true);
		local sign = 1;
		if neg and not goodWhenLow then sign = -1; end;
		if not neg and u:find("TAKEN", 1, true) and not aimsEnemy then sign = -1; end;
		if u:find("COLLAPSE", 1, true) then
			sign = (u:find("FASTER", 1, true) or (not neg and not u:find("SLOWER", 1, true))) and -1 or 1;
			cat = "survival";
		end;
		return sign * mag, cat;
	end;
	local function runMode()
		return (run.depth > 0 or run.isDelve) and "delve" or "waves";
	end;
	run.modeName = runMode;
	local function pairKey(a, b)
		if a > b then a, b = b, a; end;
		return a .. "||" .. b;
	end;
	local function catWeight(cat)
		if not cat then return .6; end;
		if cat == "risk" then return 1; end;
		local cm = brain.catMode[runMode()];
		local learned = 1;
		if Q.relicLearn ~= false then
			learned = (type(cm) == "table" and tonumber(cm[cat])) or tonumber(brain.cat[cat]) or 1;
		end;
		local total = run.combatT + run.mineT;
		local cf = total > 20 and run.combatT / total or .5;
		local ctx = 1;
		if cat == "damage" or cat == "survival" or cat == "control" or cat == "mobility" then
			ctx = .6 + .8 * cf;
		elseif cat == "mining" or cat == "range" then
			ctx = .6 + .8 * (1 - cf);
		elseif cat == "econ" then
			ctx = .7;
		end;
		if cat == "survival" then ctx = ctx * (1 + math.min(1, run.hits / 8)); end;
		return learned * ctx;
	end;

	-- ---------------------------------------------------------------- card discovery
	local hintName = nil;
	local function cardsIn(root)
		local found, seen = {}, {};
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080);
		for _, o in ipairs(root:GetDescendants()) do
			if o:IsA("TextLabel") or o:IsA("TextButton") then
				local t = trim(txt(o)):upper();
				if TIER_VALUE[t] and shown(o) then
					local card = o.Parent;
					local minH = math.max(120, vp.Y * .18);
					while card and card:IsA("GuiObject") and (card.AbsoluteSize.Y < minH or card.AbsoluteSize.X < 90) do
						card = card.Parent;
					end;
					local toast = false;
					if card and card:IsA("GuiObject") then
						for _, o2 in ipairs(card:GetDescendants()) do
							if (o2:IsA("TextLabel") or o2:IsA("TextButton")) and txt(o2):upper():find("1 IN %d") then
								toast = true;
								break;
							end;
						end;
					end;
					if card and card:IsA("GuiObject") and not toast and not seen[card] and card.AbsoluteSize.X < vp.X * .6 then
						seen[card] = true;
						found[#found + 1] = { root = card, tierLabel = o, tier = t };
					end;
				end;
			end;
		end;
		-- real drafts are 2+ cards of the same size side by side (filters out "Rare" loot toasts)
		local groups = {};
		for _, c in ipairs(found) do
			local s = c.root.AbsoluteSize;
			local key = math.floor(s.X / 12) .. "x" .. math.floor(s.Y / 12);
			groups[key] = groups[key] or {};
			table.insert(groups[key], c);
		end;
		local best;
		for _, gcards in pairs(groups) do
			if #gcards >= 2 and (not best or #gcards > #best) then best = gcards; end;
		end;
		if best then
			table.sort(best, function(x, y) return x.root.AbsolutePosition.X < y.root.AbsolutePosition.X; end);
		end;
		return best;
	end;
	local function findCards()
		local pg = l:FindFirstChild("PlayerGui");
		if not pg then return nil; end;
		local rdraft = pg:FindFirstChild("RelicDraft");
		if rdraft and rdraft:IsA("LayerCollector") and rdraft.Enabled ~= false then
			local panel = rdraft:FindFirstChild("Panel");
			local main = panel and panel:FindFirstChild("Main");
			local timer = rdraft:FindFirstChild("Timer", true);
			local timerOk = not timer or (shown(timer) and trim(txt(timer)) ~= "");
			if main and timerOk then
				local function tierOf(raw)
					local u = trim(raw or ""):upper();
					if TIER_VALUE[u] then return u; end;
					for _, w in ipairs({ "UNCOMMON", "COMMON", "LEGENDARY", "MYTHIC", "EXOTIC", "DIVINE", "SECRET", "EPIC", "RARE", "BLESSING" }) do
						if u:find(w, 1, true) then return w; end;
					end;
					return u ~= "" and u or "COMMON";
				end;
				local list = {};
				for _, cd in ipairs(main:GetChildren()) do
					if cd:IsA("GuiObject") and cd.Name:match("^Card%d+$") and shown(cd) then
						local tl, ti = cd:FindFirstChild("Title"), cd:FindFirstChild("Tier");
						if tl and tl:IsA("TextLabel") and trim(txt(tl)) ~= "" then
							list[#list + 1] = { root = cd, tierLabel = ti or tl, tier = tierOf(ti and txt(ti)) };
						end;
					end;
				end;
				if #list > 0 then
					table.sort(list, function(x, y) return x.root.AbsolutePosition.X < y.root.AbsolutePosition.X; end);
					hintName = "RelicDraft";
					return list;
				end;
			end;
		end;
		local tried = {};
		local function try(sg)
			if not sg or tried[sg] or not sg:IsA("LayerCollector") or sg.Enabled == false then return nil; end;
			tried[sg] = true;
			local cards = cardsIn(sg);
			if cards then hintName = sg.Name; end;
			return cards;
		end;
		local cards = try(pg:FindFirstChild("RelicDraft")) or (hintName and try(pg:FindFirstChild(hintName)));
		if cards then return cards; end;
		for _, sg in ipairs(pg:GetChildren()) do
			local n = sg.Name:upper();
			if n:find("RELIC") or n:find("DRAFT") or n:find("PICK") or n:find("CHOICE") or n:find("UPGRADE") or n:find("CARD") then
				cards = try(sg);
				if cards then return cards; end;
			end;
		end;
		return nil;
	end;
	local prompt = { label = nil, scanAt = -1e9 };
	local function promptVisible(now)
		local lbl = r.relicPromptLabel or prompt.label;
		if lbl and lbl.Parent then
			-- keep the label even while hidden: checking it is cheap, searching the screen is not
			prompt.label = lbl;
			return shown(lbl) and txt(lbl):upper():find("PICK A RELIC") ~= nil;
		end;
		if now - prompt.scanAt < 5 then return false; end;
		prompt.scanAt = now;
		prompt.label = nil;
		local pg = l:FindFirstChild("PlayerGui");
		if not pg then return false; end;
		for _, o in ipairs(pg:GetDescendants()) do
			if o:IsA("TextLabel") and txt(o):upper():find("PICK A RELIC") then
				prompt.label = o;
				return shown(o);
			end;
		end;
		return false;
	end;
	local fullScanAt = -1e9;
	local function findCardsSlow(now)
		if not promptVisible(now) then
			local pg = l:FindFirstChild("PlayerGui");
			local rd = pg and pg:FindFirstChild("RelicDraft");
			if not (rd and rd:IsA("LayerCollector") and rd.Enabled ~= false) then return nil; end;
		end;
		local cards = findCards();
		if cards or now - fullScanAt < 1.5 then return cards; end;
		fullScanAt = now;
		local pg = l:FindFirstChild("PlayerGui");
		if not pg then return nil; end;
		for _, sg in ipairs(pg:GetChildren()) do
			if sg:IsA("LayerCollector") and sg.Enabled ~= false then
				local c2 = cardsIn(sg);
				if c2 then hintName = sg.Name; return c2; end;
			end;
		end;
		return nil;
	end;

	local function parseCard(c)
		local root = c.root;
		local titleL, bonusL, statL, archL = root:FindFirstChild("Title"), root:FindFirstChild("Bonus"), root:FindFirstChild("Stat"), root:FindFirstChild("Archetype");
		if titleL and titleL:IsA("TextLabel") and (bonusL or statL) then
			c.name = trim(txt(titleL));
			c.desc = {};
			for _, L in ipairs({ bonusL, statL }) do
				-- hidden labels hold leftovers from other cards: skip them
				if L and L:IsA("TextLabel") and L.Visible and trim(txt(L)) ~= "" then c.desc[#c.desc + 1] = trim(txt(L)); end;
			end;
			c.setName, c.setP, c.setN = nil, nil, nil;
			if archL and archL.Visible then
				local at = trim(txt(archL)):upper();
				local sn, sp, sN = at:match("^(.-)%s*SET%s+(%d+)%s*/%s*(%d+)");
				if not sn then sn, sp, sN = at:match("^(.-)%s+(%d+)%s*/%s*(%d+)$"); end;
				if sn and trim(sn) ~= "" then c.setName, c.setP, c.setN = trim(sn), tonumber(sp), tonumber(sN); end;
			end;
			local note = root:FindFirstChild("Note");
			local nu = note and trim(txt(note)):upper() or "";
			c.taken = nu:find("TAKEN") ~= nil or nu:find("SOLD") ~= nil or nu:find("OWNED") ~= nil or nu:find("BOUGHT") ~= nil;
			c.price = nil;
			for _, o in ipairs(root:GetDescendants()) do
				if (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Visible then
					local pv = txt(o):match("%$%s*([%d,]+)");
					if pv then c.price = tonumber((pv:gsub(",", ""))); break; end;
				end;
			end;
			c.key = c.name:upper();
			c.button = root:FindFirstChild("Hit") or root:FindFirstChild("Action");
			return c;
		end;
		local labels = {};
		for _, o in ipairs(c.root:GetDescendants()) do
			if (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Visible then
				local t = txt(o);
				if t:match("%S") then
					labels[#labels + 1] = { o = o, t = trim(t), y = o.AbsolutePosition.Y, size = o.TextBounds.Y };
				end;
			end;
		end;
		table.sort(labels, function(x, y) return x.y < y.y; end);
		local nameL, nameSize, taken = nil, nil, false;
		local firstNumY = math.huge;
		for _, L in ipairs(labels) do
			if L.t:find("%d") then firstNumY = math.min(firstNumY, L.y); end;
		end;
		for _, L in ipairs(labels) do
			local u = L.t:upper();
			local on = L.o.Name:lower();
			if u == "TAKEN" or u == "OWNED" or u == "SOLD OUT" then taken = true; end;
			if L.o ~= c.tierLabel and not BUTTON_WORDS[u] then
				if on == "name" or on == "title" or on == "relicname" or on == "displayname" then
					nameL, nameSize = L, math.huge;
				elseif nameSize ~= math.huge and not u:find("%d") and #u <= 32 and L.y <= firstNumY
					and not u:find("SET%s+%d") and (not nameSize or L.size > nameSize) then
					nameL, nameSize = L, L.size;
				end;
			end;
		end;
		local desc = {};
		for _, L in ipairs(labels) do
			local u = L.t:upper();
			local sn, sp, sN = u:match("^(.-)%s*SET%s+(%d+)%s*/%s*(%d+)");
			if sn then
				c.setName, c.setP, c.setN = trim(sn), tonumber(sp), tonumber(sN);
			elseif L ~= nameL and L.o ~= c.tierLabel and not BUTTON_WORDS[u] then
				desc[#desc + 1] = L.t;
			end;
		end;
		c.name = nameL and nameL.t or (desc[1] or "?");
		c.desc = desc;
		c.taken = taken;
		c.key = trim(c.name):upper();
		if c.key == "" or c.key == "?" then c.key = trim(table.concat(desc, " ")):upper():sub(1, 48); end;
		-- what to click: the card's own button if it has one
		local btn;
		if c.root:IsA("GuiButton") then btn = c.root; end;
		if not btn then
			local action = c.root:FindFirstChild("Action", true);
			if action and action:IsA("GuiButton") then btn = action; end;
		end;
		btn = btn or c.root:FindFirstChildWhichIsA("GuiButton", true) or c.tierLabel:FindFirstAncestorWhichIsA("GuiButton");
		c.button = btn;
		return c;
	end;

	-- MECHANICS: anything the game shows that the brain hasn't met before (room types, card types,
	-- effects it can't classify, floor objectives, new screens). Each is remembered, and every run
	-- where it showed up feeds its score, so effects it doesn't understand still get judged by results.
	r.mechNorm = function(t)
		local u = trim(tostring(t or "")):upper();
		u = u:gsub("[%d][%d%.,]*", "#");
		u = u:gsub("%s+", " ");
		return u;
	end;
	r.mechSeen = function(kind, text, quiet)
		local norm = r.mechNorm(text);
		if #norm < 2 or #norm > 90 or not norm:match("%a") then return; end;
		local key = kind .. ":" .. norm;
		local m = brain.mech[key];
		local isNew = type(m) ~= "table";
		if isNew then
			m = { kind = kind, text = norm, first = os.time(), seen = 0, n = 0, zsum = 0 };
			brain.mech[key] = m;
		end;
		m.seen = (tonumber(m.seen) or 0) + 1;
		m.last, m.sample = os.time(), trim(tostring(text));
		m.depth = run.active and run.depth > 0 and run.depth or m.depth;
		if run.active then
			run.mechs = type(run.mechs) == "table" and run.mechs or {};
			run.mechs[key] = true;
			if isNew then
				run.newMechs = type(run.newMechs) == "table" and run.newMechs or {};
				run.newMechs[#run.newMechs + 1] = kind .. ": " .. m.sample;
			end;
		end;
		if isNew and not quiet then
			pcall(function()
				if type(appendfile) == "function" then
					appendfile("DelveMechanics.jsonl", game:GetService("HttpService"):JSONEncode({
						t = os.time(), kind = kind, text = m.sample, depth = run.depth,
					}) .. "\n");
				end;
			end);
			if Q.mechNotify ~= false and d() - (r.mechNoteAt or -1e9) > 3 then
				r.mechNoteAt = d();
				notify(string.format("New %s discovered: %s. I'll learn how it affects runs.", kind, m.sample), "Delve mechanics");
			end;
		end;
		markBrain();
		return m, isNew;
	end;
	-- learned value of a mechanic: average run z-score when it showed up (nil until seen in 2+ runs)
	r.mechZ = function(kind, text)
		local m = brain.mech[kind .. ":" .. r.mechNorm(text)];
		local n = type(m) == "table" and tonumber(m.n) or 0;
		if n < 2 then return nil, n; end;
		return math.max(-2, math.min(2, (tonumber(m.zsum) or 0) / n)), n;
	end;
	-- what matters most in a delve, in order:
	--   1. a second chance (revive / survive a fatal hit) when you don't have one yet: saves the run
	--   2. weapon power, mine power, swing / attack speed (the build)
	--   3. survivability and more time on the floor
	-- plus finishing sets already started (read from ACTIVE BUFFS), and everything learned from past runs.
	-- does this run need more mining? Sums the mining buffs you already have (ACTIVE BUFFS, e.g.
	-- "+90% MINE POWER - DEEP DELVER") and counts timer close calls since Worldheart.
	r.mineNeed = function()
		local have = 0;
		for _, u in ipairs(type(run.buffLines) == "table" and run.buffLines or {}) do
			if u:find("MINE", 1, true) or u:find("MINING", 1, true) or u:find("PICKAXE", 1, true) then
				local pct = tonumber(u:match("%+%s*([%d%.]+)%s*%%"));
				local mult = tonumber(u:match("[X×]%s*([%d%.]+)"));
				have = have + (pct or (mult and mult > 1 and (mult - 1) * 100) or 0);
			end;
		end;
		local calls = (run.dangerCount or 0) - (run.pathDanger or run.dangerCount or 0);
		if calls >= 1 then return true, string.format("%d timer close call%s since Worldheart", calls, calls > 1 and "s" or ""); end;
		if have < 100 then return true, string.format("only +%d%% mining buffs", have); end;
		return false, string.format("+%d%% mining already, no close calls", have);
	end;
	r.prio = {
		life = { "SECOND CHANCE", "SECOND LIFE", "EXTRA LIFE", "REVIVE", "RESURRECT", "CHEAT DEATH", "FATAL", "INSTEAD OF DYING",
			"WOULD DIE", "ON DEATH", "WHEN YOU DIE", "LAST STAND", "UNDYING", "PHOENIX", "SAVE THE RUN", "SAVES THE RUN", "SURVIVE A" },
		-- 2nd tier (after luck): mining power/range, weapon power/range, swing speed and area (AOE) hits
		power = { "WEAPON POWER", "MINE POWER", "MINING POWER", "SWING SPEED", "ATTACK SPEED", "MINE SPEED", "MINING SPEED",
			"STRIKE TWICE", "STRIKES TWICE", "SWINGS", "SWING",
			"MINING RANGE", "MINE RANGE", "MINING CIRCLE", "MINING RADIUS", "RADIUS", "REACH", "RANGE",
			"AOE", "AREA", "CLEAVE", "CHAIN", "SPLASH", "EXPLO", "SHOCKWAVE", "LIGHTNING", "NEARBY", "ALL MOBS", "EVERY MOB" },
		-- after Worldheart the path decides which half of the power tier comes first
		combat = { "WEAPON", "ATTACK", "STRIKE", "SWING", "CRIT", "DAMAGE TO", "ENEMY DAMAGE", "DPS", "CLEAVE", "CHAIN",
			"LIGHTNING", "BLEED", "BURN", "POISON", "EXECUTE", "OVERKILL", "ALL MOBS", "EVERY MOB", "KILL" },
		mine = { "MINE ", "MINING", "PICKAXE", " ORE", "ROCK" },
		time = { "ROWS OF TIME", "OF TIME", "EXTRA TIME", "MORE TIME", "TIMER", "SECONDS", "COLLAPSE", "LONGER" },
		has = function(u, list)
			for _, w in ipairs(list) do
				if u:find(w, 1, true) then return true; end;
			end;
			return false;
		end,
	};
	local function scoreCard(c)
		local parts = {};
		c.setBonus, c.completes = 0, false;
		if c.taken then return -1e6, { "taken" }, {}; end;
		local tierV = TIER_VALUE[c.tier] or 0;
		local total = tierV;
		parts[#parts + 1] = string.format("%s +%d", c.tier, tierV);
		local cats = {};
		local effects = {};
		local text = table.concat(c.desc, "\n"):gsub("%s+([%+%-]%d)", "\n%1");
		for cl in text:gmatch("[^\n]+") do
			local v, cat = clauseValue(cl);
			if not cat and Q.relicLearn ~= false then
				local mz, mn = r.mechZ("effect", cl);
				if mz then
					local adj = mz * 25 * (mn / (mn + 3));
					total = total + adj;
					parts[#parts + 1] = string.format("effect learned %+.0f", adj);
				end;
			end;
			local uc = " " .. cl:upper() .. " ";
			if v ~= 0 then
				local w = catWeight(cat);
				local pm, tag = 1, cat or "other";
				-- luck and drop quantity are top priority in delves (more and rarer drops)
				if cat == "luck" or uc:find(" LUCK", 1, true) or uc:find("QUANTITY", 1, true) then
					pm, tag = 1.8, "luck/drops";
				elseif run.worldPath and not uc:find("DAMAGE TAKEN", 1, true)
					and (cat == "range" or cat == "mining" or cat == "damage" or r.prio.has(uc, r.prio.power)) then
					-- Descend (the Hollow, more mobs): combat boosts right under luck, mining still good.
					-- Ascend (the Heavens, more rock): mining power/range first, combat still good.
					local isMine = cat == "mining" or r.prio.has(uc, r.prio.mine);
					local isCombat = not isMine and (cat == "damage" or r.prio.has(uc, r.prio.combat));
					local favour = (run.worldPath == "Descend" and isCombat) or (run.worldPath == "Ascend" and isMine);
					pm = favour and 1.75 or 1.45;
					tag = (isCombat and "combat" or "mining") .. (favour and " (" .. run.worldPath .. " path)" or "");
					if run.worldPath == "Descend" and isMine and v > 0 then
						-- Descend still needs ores mined to beat the timer. Mining relics move up when the run needs
						-- them (low mining buffs, or timer close calls since Worldheart), and a massive one (+60% or
						-- more) can beat the combat picks. Otherwise combat keeps going first to make the run faster.
						local need, why0 = r.mineNeed();
						local massive = v >= 60;
						pm = need and (massive and 1.9 or 1.7) or (massive and 1.6 or 1.35);
						tag = string.format("mining%s (%s)", massive and ", massive" or "", why0);
					end;
				elseif cat == "range" or r.prio.has(uc, r.prio.power) then
					pm, tag = 1.6, "power/range/aoe";
				elseif cat == "survival" or r.prio.has(uc, r.prio.time) then
					pm, tag = 1.35, "survival/time";
				end;
				total = total + v * w * pm;
				if cat then cats[cat] = true; end;
				effects[#effects + 1] = { cat = cat or "other", v = v, text = trim(cl) };
				parts[#parts + 1] = string.format("%s %+.0f", tag, v * w * pm);
			end;
			if r.prio.has(uc, r.prio.life) and not uc:find("ENEM", 1, true) then c.life = true; end;
		end;
		c.effects = effects;
		-- a luck relic with a manageable downside (walk speed, swing speed, mining speed...) is still worth it:
		-- half of that downside is forgiven. Dangerous downsides (damage taken, health, faster collapse,
		-- curses, elites) count in full.
		local luckUp = false;
		for _, ef in ipairs(effects) do
			if ef.cat == "luck" and ef.v > 0 then luckUp = true; break; end;
		end;
		if luckUp then
			local refund = 0;
			for _, ef in ipairs(effects) do
				if ef.v < 0 then
					local ut = tostring(ef.text):upper();
					local severe = ut:find("DAMAGE TAKEN", 1, true) or ut:find("HEALTH", 1, true) or ut:find(" HP", 1, true)
						or ut:find("COLLAPSE", 1, true) or ut:find("CURSE", 1, true) or ut:find("ELITE", 1, true) or ut:find("FATAL", 1, true);
					if not severe then refund = refund - ef.v * catWeight(ef.cat ~= "other" and ef.cat or nil) * .5; end;
				end;
			end;
			if refund > 0 then
				total = total + refund;
				parts[#parts + 1] = string.format("manageable downside %+.0f", refund);
			end;
		end;
		if c.life then
			-- 1st priority: a second chance, unless you already carry one
			local lb = (run.hasLife or run.hasLifeBuff) and 60 or 300;
			total = total + lb;
			cats.survival = true;
			parts[#parts + 1] = string.format("second chance %+d", lb);
		end;
		-- sets already in progress on the right side of the screen
		local prog = c.setName and type(run.buffSets) == "table" and run.buffSets[c.setName:upper()];
		if prog and prog.need and prog.need > 0 then
			local after = math.min(prog.need, (prog.have or 0) + 1);
			local sb2 = 20 + 50 * (after / prog.need);
			if after >= prog.need and (prog.have or 0) < prog.need then sb2 = sb2 + 80; c.completes = true; end;
			total = total + sb2;
			c.setBonus = sb2;
			parts[#parts + 1] = string.format("builds %s %d/%d %+.0f", c.setName, after, prog.need, sb2);
		elseif c.setN and c.setN > 0 and c.setP then
			local sb = 10 + 30 * (c.setP / c.setN);
			if c.setP == c.setN - 1 then sb = sb + 60; c.completes = true; end;
			local hist = brain.sets[tostring(c.setName)];
			if type(hist) == "number" then sb = sb + math.min(20, hist * 2); end;
			total = total + sb;
			c.setBonus = sb;
			parts[#parts + 1] = string.format("set %d/%d %+.0f", c.setP, c.setN, sb);
		end;
		local rec = brain.relics[c.key];
		if Q.relicLearn ~= false and type(rec) == "table" then
			local n = tonumber(rec.n) or 0;
			local zsum = tonumber(rec.zsum) or 0;
			-- prefer what it learned in THIS kind of run (delve vs waves) once there's enough of it
			local ms = type(rec.modes) == "table" and rec.modes[runMode()];
			if type(ms) == "table" and (tonumber(ms.n) or 0) >= 2 then
				n, zsum = tonumber(ms.n), tonumber(ms.zsum) or 0;
			end;
			if n > 0 then
				local conf = n / (n + 3);
				local z = math.max(-2, math.min(2, zsum / n));
				total = total + z * 30 * conf;
				parts[#parts + 1] = string.format("learned %+.0f (%d runs)", z * 30 * conf, n);
			end;
			local offered = tonumber(rec.offered) or 0;
			if offered >= 1 and (tonumber(rec.user) or 0) > 0 then
				local im = (tonumber(rec.user) or 0) / offered * 50;
				total = total + im;
				parts[#parts + 1] = string.format("you pick it %+.0f", im);
			end;
		end;
		-- synergy with relics already taken this run (learned from past runs with the same combo)
		if Q.relicLearn ~= false then
			local syn = 0;
			for _, owned in ipairs(run.relics) do
				local pr = brain.pairs[pairKey(c.key, owned.key)];
				if type(pr) == "table" and (tonumber(pr.n) or 0) > 0 then
					local pn = tonumber(pr.n);
					syn = syn + math.max(-2, math.min(2, (tonumber(pr.zsum) or 0) / pn)) * 15 * (pn / (pn + 2));
				end;
			end;
			if syn ~= 0 then
				total = total + syn;
				parts[#parts + 1] = string.format("combo %+.0f", syn);
			end;
			-- never-tried relics get a small curiosity bonus so the brain eventually tests them
			if type(rec) ~= "table" or (tonumber(rec.n) or 0) == 0 then
				total = total + 4;
			end;
		end;
		return total, parts, cats;
	end;
	-- CODEX: every relic ever seen is saved with what the brain understood it to do
	local function codexUpdate(c)
		local cx = brain.codex[c.key];
		local isNew = type(cx) ~= "table";
		if isNew then
			cx = { first = os.time(), seen = 0 };
			brain.codex[c.key] = cx;
		end;
		cx.name, cx.tier = c.name, c.tier;
		cx.seen = (tonumber(cx.seen) or 0) + 1;
		cx.desc = table.concat(c.desc or {}, " | ");
		cx.set, cx.setN = c.setName, c.setN;
		cx.effects = c.effects;
		local cl = {};
		for cat in pairs(c.cats or {}) do cl[#cl + 1] = cat; end;
		table.sort(cl);
		cx.cats = cl;
		cx.lastScore = math.floor((c.score or 0) + .5);
		cx.mode = runMode();
		if isNew and Q.mechNotify ~= false then
			notify(string.format("New relic learned: %s [%s] -> %s", tostring(c.name), tostring(c.tier),
				#cl > 0 and table.concat(cl, ", ") or "special effect"), "Delve codex");
		end;
		markBrain();
	end;

	-- ---------------------------------------------------------------- click helpers
	local function guiPoint(obj)
		local pos, size = obj.AbsolutePosition, obj.AbsoluteSize;
		local cx, cy = pos.X + size.X / 2, pos.Y + size.Y / 2;
		local inset = guiService:GetGuiInset();
		local sg = obj:FindFirstAncestorWhichIsA("ScreenGui");
		local ignore = false;
		if sg then
			local ok, v = pcall(function() return sg.IgnoreGuiInset; end);
			ignore = ok and v == true;
		end;
		local vx, vy = cx + (ignore and 0 or inset.X), cy + (ignore and 0 or inset.Y);
		-- mouse space (what the cursor mover expects) = viewport minus the top bar
		return vx - inset.X, vy - inset.Y, vx, vy;
	end;
	local function clickTarget(c)
		local b = c.button;
		if b and b.AbsoluteSize.X >= 20 and b.AbsoluteSize.Y >= 12 and shown(b) then return b; end;
		return c.root;
	end;

	-- ---------------------------------------------------------------- draft state machine
	local draft = nil;
	local function disconnectDraft()
		if draft and draft.conns then
			for _, cn in ipairs(draft.conns) do pcall(function() cn:Disconnect(); end); end;
			draft.conns = {};
		end;
	end;
	local function finishDraft()
		if not draft then return; end;
		disconnectDraft();
		local picked = draft.picked;
		if not picked and draft.clicks > 0 and d() - draft.ourClickAt < 1.5 then picked = draft.choice; end;
		for _, c in ipairs(draft.cards) do
			local rec = relicRec(c.key);
			rec.offered = (tonumber(rec.offered) or 0) + 1;
			rec.name = c.name;
		end;
		if picked and draft.trader and type(r.traderBought) == "table" then r.traderBought[picked.key] = true; end;
		if picked then
			local rec = relicRec(picked.key);
			rec.picks = (tonumber(rec.picks) or 0) + 1;
			if draft.userPicked then rec.user = (tonumber(rec.user) or 0) + 1; end;
			run.relics[#run.relics + 1] = { key = picked.key, cats = picked.cats or {} };
			if picked.life then run.hasLife = true; end;
			if picked.setName then
				brain.sets[picked.setName] = (tonumber(brain.sets[picked.setName]) or 0) + 1;
			end;
			r.cardPicks = (r.cardPicks or 0) + 1;
			if draft.userPicked and draft.choice and draft.choice ~= picked then
				notify(string.format("Noted: you picked %s over my choice %s. I'll weigh that next time.", picked.name, draft.choice.name), "Delve brain");
			end;
		end;
		-- (v5.40) saved with the next regular save (at most 20 s later), not with a full save right after every
		-- pick: a Prestige III run has 89 picks, each was a full brain write in the middle of play
		markBrain();
		draft = nil;
	end;
	local function sigOf(cards)
		local s = {};
		for _, c in ipairs(cards) do
			local tl, nl = c.root:FindFirstChild("Title"), c.root:FindFirstChild("Note");
			s[#s + 1] = c.tier .. ":" .. trim(txt(c.tierLabel)) .. ":" .. (tl and trim(txt(tl)) or "") .. ":"
				.. (nl and trim(txt(nl)) or "") .. ":" .. tostring(c.root);
		end;
		return table.concat(s, "|");
	end;
	local function posSig(cards)
		local s = {};
		for _, c in ipairs(cards) do
			local p = c.root.AbsolutePosition;
			s[#s + 1] = math.floor(p.X / 3) .. "," .. math.floor(p.Y / 3);
		end;
		return table.concat(s, "|");
	end;
	local function openDraft(cards, now)
		draft = { sig = sigOf(cards), cards = {}, openedAt = now, stableSince = now, pos = posSig(cards), attempts = 0, clicks = 0, conns = {}, ourClickAt = -1e9, lastSeen = now };
		local scored = {};
		for _, c in ipairs(cards) do
			parseCard(c);
			c.score, c.parts, c.cats = scoreCard(c);
			pcall(codexUpdate, c);
			draft.cards[#draft.cards + 1] = c;
			scored[#scored + 1] = c;
			-- watch for YOUR clicks so the brain can learn your preferences
			for _, b in ipairs({ c.button, c.root:IsA("GuiButton") and c.root or nil }) do
				if b then
					for _, sigName in ipairs({ "Activated", "MouseButton1Click" }) do
						local ok, cn = pcall(function()
							return b[sigName]:Connect(function()
								if not draft or draft.picked then return; end;
								draft.picked = c;
								draft.userPicked = d() - draft.ourClickAt > .7;
							end);
						end);
						if ok and cn then draft.conns[#draft.conns + 1] = cn; end;
					end;
				end;
			end;
		end;
		-- a really good relic beats set chasing: if another card is clearly better on its own,
		-- a set card loses its set bonus (half of it is kept when it would complete the set)
		local bestBase = -1e9;
		for _, c in ipairs(scored) do bestBase = math.max(bestBase, c.score - (c.setBonus or 0)); end;
		for _, c in ipairs(scored) do
			if (c.setBonus or 0) > 0 and bestBase - (c.score - c.setBonus) >= 35 then
				local keep = c.completes and .5 or 0;
				c.score = c.score - c.setBonus * (1 - keep);
				c.parts[#c.parts + 1] = "set bonus dropped: a much better relic is up";
			end;
		end;
		table.sort(scored, function(x, y) return x.score > y.score; end);
		local choice = scored[1];
		draft.explored = false;
		pcall(function()
			local sgM = cards[1].root:FindFirstAncestorWhichIsA("LayerCollector");
			local tm = sgM and sgM:FindFirstChild("Timer", true);
			if tm then
				-- "A TRADER IN THE DARK - LEAVING IN 5s" -> "A TRADER IN THE DARK"
				local room = trim(txt(tm)):upper():gsub("%s*%-%s*[^%-]*%d+%s*S%s*$", "");
				draft.room = room;
				r.mechSeen("room", room);
			end;
			for _, c in ipairs(scored) do
				r.mechSeen("card type", trim(txt(c.tierLabel)));
				for _, ef in ipairs(c.effects or {}) do
					if ef.cat == "other" then r.mechSeen("effect", ef.text); end;
				end;
			end;
		end);
		-- trader ("A TRADER IN THE DARK"): same window, cards cost cash and there is a WALK ON BY button
		local sg = cards[1].root:FindFirstAncestorWhichIsA("LayerCollector");
		local walk = sg and sg:FindFirstChild("WalkOn", true);
		local heading = sg and sg:FindFirstChild("OfferHeading", true);
		local timerL = sg and sg:FindFirstChild("Timer", true);
		draft.walkOn = walk;
		draft.trader = (walk and shown(walk)) or (heading and shown(heading) and txt(heading):upper():find("TRADER") ~= nil)
			or (timerL and txt(timerL):upper():find("TRADER") ~= nil) or false;
		-- "THE TUNNEL FORKS": SAFE PATH (slower collapse) vs CURSED PATH (+luck, more elites) for the next rooms
		local safeC, cursedC;
		for _, c in ipairs(scored) do
			local tu = (c.name .. " " .. tostring(c.tier)):upper();
			if tu:find("SAFE") then safeC = c; elseif tu:find("CURSE") then cursedC = c; end;
		end;
		draft.fork = safeC ~= nil and cursedC ~= nil;
		if draft.fork then
			local want = Q.forkPath or "Smart";
			local why = want;
			if want == "Smart" then
				local hum = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
				local hp = (hum and hum.MaxHealth > 0) and hum.Health / hum.MaxHealth or 1;
				local mins = math.max(1, (now - (run.startAt or now)) / 60);
				local learned = 0;
				for _, pc in ipairs({ { cursedC, 1 }, { safeC, -1 } }) do
					local rec = brain.relics[pc[1].key];
					local ms = type(rec) == "table" and type(rec.modes) == "table" and rec.modes.delve;
					if type(ms) == "table" and (tonumber(ms.n) or 0) >= 2 then
						learned = learned + pc[2] * math.max(-2, math.min(2, (tonumber(ms.zsum) or 0) / tonumber(ms.n)));
					end;
				end;
				local risky = hp < .7 or run.hits / mins > 3 or (run.dangerCount or 0) >= 2 or learned < -.5;
				want = risky and "Safe" or "Cursed";
				why = risky and string.format("HP %d%%, %d hits, %d close calls", math.floor(hp * 100), run.hits, run.dangerCount or 0)
					or "healthy, going for luck";
			end;
			choice = want == "Safe" and safeC or cursedC;
			draft.forkWhy = why;
		end;
		-- after Worldheart ("THE WORLD BREAKS OPEN"): ASCEND = the Heavens, mining path (denser rock, richer ore);
		-- DESCEND = the Hollow, combat path (more mobs, more elites). Your setting decides.
		local ascC, desC;
		for _, c in ipairs(scored) do
			local nu = tostring(c.name):upper();
			if nu == "DESCEND" or nu:find("^DESCEND") then desC = c; elseif nu == "ASCEND" or nu:find("^ASCEND") then ascC = c; end;
		end;
		local pathPick = Q.afterBossPath or "Descend";
		if ascC and desC then draft.fork = true; draft.forkWhy = draft.forkWhy or "the brain's choice"; end;
		if ascC and desC and pathPick ~= "Let the brain decide" then
			draft.fork = true;
			choice = pathPick == "Ascend" and ascC or desC;
			draft.forkWhy = "your setting: " .. pathPick;
		end;
		if ascC and desC and (choice == ascC or choice == desC) then
			local wp = choice == ascC and "Ascend" or "Descend";
			if run.worldPath ~= wp then
				run.worldPath, run.pathDanger = wp, run.dangerCount or 0;
				if r.why then r.why("relic", wp .. " path: relics now favour " .. (wp == "Descend" and "combat boosts" or "mining power/range")); end;
			end;
		end;
		-- a fork (Ascend/Descend, Safe/Cursed) always wins over the trader: the fork screen was once read as
		-- "A TRADER IN THE DARK" and the trader logic bought the highest score (ASCEND) over your Descend setting
		if draft.fork and draft.trader then
			draft.trader = false;
			if r.why then r.why("relic", "fork cards on a screen titled like a trader: treating it as the fork"); end;
		end;
		if draft.trader then
			r.traderBought = (type(r.traderBought) == "table" and now - (r.traderVisitAt or -1e9) < 30) and r.traderBought or {};
			r.traderVisitAt = now;
			choice = nil;
			if Q.traderBuy ~= false then
				local minScore = tonumber(Q.traderMinScore) or 5;
				for _, c in ipairs(scored) do
					if not c.taken and not r.traderBought[c.key] and c.score >= minScore then choice = c; break; end;
				end;
			end;
			draft.walk = choice == nil;
		elseif not draft.fork and Q.relicExplore ~= false and #scored >= 2 then
			-- LEARN THE INDEX: a relic it has never taken gets a real chance (half the time) when it isn't far
			-- behind, so every relic gets studied. Never instead of a second chance, a luck relic or a set
			-- completion. Otherwise, now and then, a close 2nd that's been tried fewer than 3 times.
			local best = scored[1];
			local protected = best.life or best.completes;
			for _, ef in ipairs(best.effects or {}) do
				if ef.cat == "luck" and ef.v > 0 then protected = true; end;
			end;
			local function timesTaken(c)
				local rec = brain.relics[c.key];
				return type(rec) == "table" and (tonumber(rec.n) or 0) or 0;
			end;
			local untried;
			if not protected then
				for i = 2, #scored do
					local c = scored[i];
					if not c.taken and c.score > -1e5 and c.score >= best.score - 80 and timesTaken(c) == 0 then untried = c; break; end;
				end;
			end;
			if untried and math.random() < .5 then
				choice = untried;
				draft.explored = "never taken before: trying it to learn what it does";
			elseif scored[2].score > -1e5 and scored[2].score >= best.score - 25 and timesTaken(scored[2]) < 3 and math.random() < .08 then
				choice = scored[2];
				draft.explored = "exploring a close 2nd";
			end;
		end;
		draft.choice = choice;
		local lines = {};
		for _, c in ipairs(scored) do
			lines[#lines + 1] = string.format("%s [%s] = %.0f  (%s)", c.name, c.tier, c.score, table.concat(c.parts, ", "));
		end;
		r.lastDraft = lines;
		if r.why then
			local head;
			if draft.fork then head = "fork: " .. (choice and choice.name or "?") .. " (" .. tostring(draft.forkWhy) .. ")";
			elseif draft.trader then head = choice and ("trader: buy " .. choice.name) or "trader: nothing worth buying, walk on by";
			else head = "pick " .. (choice and choice.name or "?") .. (draft.explored and (" (" .. tostring(draft.explored) .. ")") or " (highest score)"); end;
			r.why("relic", string.format("%s | %s", tostring(draft.room or "draft"), head));
			local roomU = tostring(draft.room or ""):upper();
			if (roomU:find("UNMAKER", 1, true) or roomU:find("SERAPH", 1, true)) and r.cycleKey then
				-- (v5.36) the Seraph (Ascend path) ends a cycle like the Unmaker: "THE SERAPH'S GRACE"
				r.unmakerDownKey = r.cycleKey();
				r.finalBoss = roomU:find("SERAPH", 1, true) and "Seraph" or "Unmaker";
				-- (v5.35) what the room after the Unmaker is made of, once per cycle
				if r.roomDump and r.roomDumpKey ~= r.unmakerDownKey then
					r.roomDumpKey = r.unmakerDownKey;
					task.delay(3, function() pcall(r.roomDump, "3 s after the " .. tostring(r.finalBoss) .. "'s reward", "DelveRoomDump.txt"); end);
				end;
			end;
			for _, ln in ipairs(lines) do r.why("relic", "   " .. ln); end;
		end;
		if Q.relicNotify ~= false and draft.fork and choice then
			notify(string.format("Fork: taking %s (%s)", choice.name, tostring(draft.forkWhy)), "Delve path");
		elseif Q.relicNotify ~= false and draft.trader then
			notify(choice and string.format("Trader: buying %s%s (%.0f)", choice.name,
				choice.price and (" for $" .. tostring(choice.price)) or "", choice.score) or "Trader: nothing worth buying, walking on by", "Delve trader");
		elseif Q.relicNotify ~= false and choice then
			notify(string.format("%s %s (%.0f)%s", Q.cardPick and "Picking" or "I'd pick", choice.name, choice.score,
				draft.explored and (" [" .. tostring(draft.explored) .. "]") or ""), "Delve relic");
		end;
	end;

	-- seconds left on the "PICK A RELIC - 4s" countdown (nil if not found)
	local function timerLeft()
		if not draft then return nil; end;
		local lbl = draft.timerLabel;
		if not (lbl and lbl.Parent) then
			draft.timerLabel = nil;
			if draft.timerSearched then return nil; end;
			draft.timerSearched = true;
			local first = draft.cards[1];
			local sg = first and first.root:FindFirstAncestorWhichIsA("LayerCollector");
			local pg = l:FindFirstChild("PlayerGui");
			for _, scope in ipairs({ sg, pg }) do
				if scope and not draft.timerLabel then
					for _, o in ipairs(scope:GetDescendants()) do
						if o:IsA("TextLabel") and txt(o):upper():find("PICK A RELIC") then
							draft.timerLabel = o;
							break;
						end;
					end;
				end;
			end;
			lbl = draft.timerLabel;
			if not lbl then return nil; end;
		end;
		return tonumber(txt(lbl):upper():match("(%d+)%s*S%s*$") or txt(lbl):match("(%d+)%s*[sS]"));
	end;
	local function relicTick(now)
		-- fast poll while a draft is up, slower otherwise
		local interval = draft and .05 or .15;
		if now - MQ.check < interval and MQ.phase == "idle" then
			return false;
		end;
		MQ.check = now;
		local cards = findCardsSlow(now);
		if not cards then
			if MQ.phase == "down" then inp.mouseUp(); end;
			MQ.phase = "idle";
			if draft and now - draft.lastSeen > .3 then finishDraft(); end;
			return false;
		end;
		local sig = sigOf(cards);
		if draft and draft.sig ~= sig then
			finishDraft();
		end;
		if not draft then
			openDraft(cards, now);
			if not r.relicDumped and r.dumpGui then
				r.relicDumped = true;
				local lc = cards[1].root:FindFirstAncestorWhichIsA("LayerCollector");
				task.spawn(function() pcall(r.dumpGui, lc, "relic"); end);
			end;
		end;
		draft.lastSeen = now;
		local ps = posSig(cards);
		if ps ~= draft.pos then draft.pos, draft.stableSince = ps, now; end;
		if not Q.cardPick or draft.picked or r.f2Paused then
			if MQ.phase == "down" then inp.mouseUp(); end;
			MQ.phase = "idle";
			return false;
		end;
		if draft.trader and not draft.walk and draft.attempts >= 6 and draft.choice then
			-- the buy isn't going through (probably can't afford it): skip it
			if type(r.traderBought) == "table" then r.traderBought[draft.choice.key] = true; end;
			draft.walk = true;
		end;
		if draft.trader and draft.walk then
			local wb = draft.walkOn;
			draft.walkTries = draft.walkTries or 0;
			if wb and wb.Parent and draft.walkTries < 8 and now - (draft.walkAt or -1e9) > .4 then
				draft.walkTries, draft.walkAt = draft.walkTries + 1, now;
				if r.fireAll then pcall(r.fireAll, wb); end;
				pcall(inp.clickGui, wb);
				if draft.walkTries >= 2 and VIMr then
					local _, _, vx, vy = guiPoint(wb);
					pcall(VIMr.SendMouseMoveEvent, VIMr, vx, vy, game);
					pcall(VIMr.SendMouseButtonEvent, VIMr, vx, vy, 0, true, game, 0);
					pcall(VIMr.SendMouseButtonEvent, VIMr, vx, vy, 0, false, game, 0);
				end;
			end;
			return false;
		end;
		-- always have something to click: best card, or any card that isn't already taken
		local choice = draft.choice;
		if not choice or choice.score < -1e5 then
			choice = nil;
			for _, c in ipairs(draft.cards) do
				if not c.taken then choice = c; break; end;
			end;
			choice = choice or draft.cards[1];
			draft.choice = choice;
		end;
		if not choice then return false; end;
		-- RelicDraft > Panel > Main > CardN { Hit (whole card), Action "TAKE" (shown once selected) }
		-- Pick instantly: click Hit, then TAKE as soon as it shows. Direct events need no focus;
		-- from the 3rd try on, a virtual mouse click is used too (also works while tabbed out).
		local card = choice.root;
		local hit = card:FindFirstChild("Hit") or choice.button or card;
		local action = card:FindFirstChild("Action");
		local retry = draft.attempts == 0 and 0 or .35;
		if now - draft.ourClickAt < retry then return false; end;
		if draft.attempts >= 14 then
			if not draft.gaveUp then
				draft.gaveUp = true;
				notify("Couldn't take the relic after 14 tries. Pick it yourself; I'll still learn from it.", "Delve relic");
			end;
			return false;
		end;
		draft.attempts = draft.attempts + 1;
		draft.ourClickAt, draft.clicks = now, draft.clicks + 1;
		local useVim = draft.attempts >= 3 and VIMr ~= nil;
		local useMouse = draft.attempts >= 6 and Q.background ~= true and inp.focused();
		local function press(obj)
			if not obj then return; end;
			if r.fireAll then pcall(r.fireAll, obj); end;
			pcall(inp.clickGui, obj);
			if useVim then
				local _, _, vx, vy = guiPoint(obj);
				pcall(VIMr.SendMouseMoveEvent, VIMr, vx, vy, game);
				pcall(VIMr.SendMouseButtonEvent, VIMr, vx, vy, 0, true, game, 0);
				pcall(VIMr.SendMouseButtonEvent, VIMr, vx, vy, 0, false, game, 0);
			end;
			if useMouse then
				local _, _, vx, vy = guiPoint(obj);
				inp.mouseMove(math.floor(vx + .5), math.floor(vy + .5));
				inp.mouseDown();
				inp.mouseUp();
			end;
		end;
		press(hit);
		draft.method = useMouse and "mouse" or (useVim and "virtual mouse" or "events");
		task.spawn(function()
			-- TAKE appears after the card is selected: press it the moment it does
			for _ = 1, 15 do
				if not draft or draft.picked then return; end;
				if action and action.Parent and action.Visible then break; end;
				task.wait(.02);
			end;
			if action and action.Parent and (action.Visible or draft.attempts >= 2) then
				press(action);
				if draft then draft.ourClickAt = d(); end;
			end;
		end);
		return false;
	end;

	-- ---------------------------------------------------------------- run tracking
	-- Sources, most accurate first:
	--   1. the "TRIP COMPLETE - DELVE 50M" results screen (depth, cash value, rocks, XP, materials)
	--   2. leaderstats (the player list shows "180 M" depth / "4 W" wave as a stat value)
	--   3. HUD text ("DEPTH 180 M", "WAVE 4 - ORE") as a fallback
	local hud = { scanAt = -1e9 };
	local function parseMoney(s)
		local str = tostring(s or ""):upper():gsub("[,%$%s%+]", "");
		local num, suf = str:match("^([%d%.]+)(%a*)");
		local v = tonumber(num);
		if not v then return nil; end;
		local mult = { K = 1e3, M = 1e6, B = 1e9, T = 1e12, QD = 1e15, QN = 1e18 };
		return v * (mult[suf] or 1);
	end;
	local function parseNum(s)
		local v = tostring(s or ""):gsub("[^%d%.%-]", "");
		return tonumber(v);
	end;
	local function leaderRead()
		local out = {};
		local ls = l:FindFirstChild("leaderstats");
		if not ls then return out; end;
		for _, v in ipairs(ls:GetChildren()) do
			if v:IsA("ValueBase") then
				local ok, val = pcall(function() return v.Value; end);
				if ok then
					local sv = trim(tostring(val)):upper():gsub(",", "");
					local n = v.Name:upper();
					local dm, wm = sv:match("^(%d+)%s*M$"), sv:match("^(%d+)%s*W$");
					if dm and not sv:find("%$") then
						out.depth = tonumber(dm);
					elseif wm then
						out.wave = tonumber(wm);
					elseif n:find("DEPTH") and tonumber(val) then
						out.depth = tonumber(val);
					elseif n:find("WAVE") and tonumber(val) then
						out.wave = tonumber(val);
					end;
					if n:find("CASH") or n:find("MONEY") or n:find("COIN") then
						out.cash = type(val) == "number" and val or parseMoney(val);
					end;
					if n:find("LEVEL") or n == "LVL" then out.level = tonumber(val) or parseNum(val); end;
				end;
			end;
		end;
		return out;
	end;
	local function cashNow() return leaderRead().cash; end;
	-- exact cash from the HUD ("$9,129,811,875"); the player list only shows "$9.13B"
	local cashLbl = { label = nil, scanAt = -1e9 };
	local function exactCash(now)
		local lbl = cashLbl.label;
		if not (lbl and lbl.Parent and txt(lbl):match("^%s*%$[%d,]+%s*$")) then
			if (now or d()) - cashLbl.scanAt < 3 then return nil; end;
			cashLbl.scanAt = now or d();
			cashLbl.label = nil;
			local pg = l:FindFirstChild("PlayerGui");
			local best;
			for _, o in ipairs(pg and pg:GetDescendants() or {}) do
				if o:IsA("TextLabel") then
					local t = txt(o);
					if t:match("^%s*%$[%d,]+%s*$") and t:find(",") then
						local v = parseNum(t);
						if v and (not best or v > best) then best, cashLbl.label = v, o; end;
					end;
				end;
			end;
			lbl = cashLbl.label;
			if not lbl then return nil; end;
		end;
		return parseNum(txt(lbl));
	end;
	-- results screen ------------------------------------------------------------
	local resLbl = { label = nil, scanAt = -1e9 };
	local RESULT_WORDS = { "TRIP COMPLETE", "RUN COMPLETE", "RUN OVER", "YOU DIED" };
	local function resultsTitle(now)
		local lbl = r.resultsLabel or resLbl.label;
		if lbl and lbl.Parent then
			resLbl.label = lbl;
			return shown(lbl) and lbl or nil;
		end;
		if now - resLbl.scanAt < 2 then return nil; end;
		resLbl.scanAt = now;
		resLbl.label = nil;
		local pg = l:FindFirstChild("PlayerGui");
		for _, o in ipairs(pg and pg:GetDescendants() or {}) do
			if o:IsA("TextLabel") then
				local u = txt(o):upper();
				for _, w in ipairs(RESULT_WORDS) do
					if u:find(w, 1, true) and shown(o) then
						resLbl.label = o;
						return o;
					end;
				end;
			end;
		end;
		return nil;
	end;
	-- the TRIP COMPLETE screen by its layout (DelveGuiDump_runend.txt): RunEnd > Results { Title, CashValue,
	-- Stats > Stat_rocks / Stat_xp / Stat_levels > Value, Count "+N MATERIALS" }
	local function readRunEnd()
		local pg = l:FindFirstChild("PlayerGui");
		local re = pg and pg:FindFirstChild("RunEnd");
		if not (re and re:IsA("LayerCollector") and re.Enabled ~= false) then return nil; end;
		local R = re:FindFirstChild("Results");
		if not (R and R:IsA("GuiObject") and R.Visible) then return nil; end;
		local function tv(o) return (o and (o:IsA("TextLabel") or o:IsA("TextButton"))) and trim(txt(o)) or ""; end;
		local title = tv(R:FindFirstChild("Title"));
		if title == "" then return nil; end;
		local st = R:FindFirstChild("Stats");
		local function stat(n)
			local f = st and st:FindFirstChild(n);
			return f and parseNum(tv(f:FindFirstChild("Value"))) or nil;
		end;
		local res = { title = title, endScreen = true };
		res.cashValue = parseMoney(tv(R:FindFirstChild("CashValue")));
		res.rocks, res.xp, res.level = stat("Stat_rocks"), stat("Stat_xp"), stat("Stat_levels");
		res.materials = parseNum((tv(R:FindFirstChild("Count")):match("([%d,]+)")) or "");
		local tu = title:upper():gsub(",", "");
		if tu:find("DIED", 1, true) then res.died = true; end;
		res.depth = tonumber(tu:match("(%d+)%s*M%s*$"));
		res.sig = table.concat({ title, tostring(res.cashValue), tostring(res.rocks), tostring(res.xp), tostring(res.level), tostring(res.materials) }, "|");
		return res;
	end;
	r.readRunEnd = readRunEnd;
	local function readResults(now)
		local title = resultsTitle(now);
		if not title then return nil; end;
		local gui = title:FindFirstAncestorWhichIsA("LayerCollector");
		if not gui then return nil; end;
		local labels = {};
		for _, o in ipairs(gui:GetDescendants()) do
			if (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Visible then
				local t = trim(txt(o)):upper();
				if t ~= "" then
					local p, sz = o.AbsolutePosition, o.AbsoluteSize;
					labels[#labels + 1] = { t = t, x = p.X, y = p.Y + sz.Y / 2, h = sz.Y };
				end;
			end;
		end;
		local function valueFor(key)
			for _, L in ipairs(labels) do
				local a = L.t:find(key, 1, true);
				if a then
					local inline = L.t:sub(a + #key):match("^%s*[:%-]?%s*([%+%-]?%$?[%d,%.]+%a*)");
					if inline then return inline; end;
					local best, bd;
					for _, M in ipairs(labels) do
						if M ~= L and M.t:find("%d") then
							local dy, dx = M.y - L.y, M.x - L.x;
							local dist;
							if math.abs(dy) < math.max(14, L.h * .6) and dx > 0 then
								dist = dx;
							elseif dy > 0 and dy < 150 and math.abs(dx) < 300 then
								dist = 2000 + dy;
							end;
							if dist and (not bd or dist < bd) then best, bd = M, dist; end;
						end;
					end;
					return best and best.t or nil;
				end;
			end;
			return nil;
		end;
		local tt = trim(txt(title)):upper():gsub(",", "");
		local res = { title = trim(txt(title)) };
		res.depth = tonumber(tt:match("(%d+)%s*M%s*$")) or tonumber(tt:match("DELVE%s*(%d+)"));
		res.wave = tonumber(tt:match("WAVE%s*(%d+)"));
		if tt:find("DELVE", 1, true) then res.mode = "delve"; end;
		-- the coloured "DELVE 50M" part can be its own label
		for _, L in ipairs(labels) do
			if not res.depth then
				local lt = L.t:gsub(",", "");
				local dv = lt:match("DELVE%s*(%d+)%s*M") or lt:match("^(%d+)%s*M$") or lt:match("DEPTH%s*(%d+)%s*M");
				if dv then res.depth, res.mode = tonumber(dv), "delve"; end;
			end;
			if not res.wave then
				local wv = L.t:match("WAVE%s*(%d+)");
				if wv then res.wave = tonumber(wv); end;
			end;
		end;
		res.died = tt:find("DIED", 1, true) ~= nil;
		res.cashValue = parseMoney(valueFor("CASH VALUE") or valueFor("CASH EARNED") or valueFor("EARNED"));
		res.rocks = parseNum(valueFor("ROCKS MINED") or valueFor("ORES MINED"));
		res.xp = parseNum(valueFor("XP GAINED") or valueFor("XP"));
		res.level = parseNum(valueFor("LEVEL"));
		res.materials = parseNum(valueFor("BROUGHT BACK") or valueFor("MATERIALS"));
		local sig = {};
		for _, L in ipairs(labels) do sig[#sig + 1] = L.t; end;
		res.sig = table.concat(sig, "|");
		return res;
	end;
	r.readResults = function() return readResults(d()); end;

	-- PRESTIGE ("THE DELVE - YOU BEGIN AGAIN" after the Unmaker): the depth starts over inside the same run.
	-- run.curDepth = the depth right now; run.depth = deepest in this cycle; run.prestigeTotal = metres of
	-- finished cycles, so the run's total progress is prestigeTotal + depth.
	local function noteDepth(v, now)
		if not v then return; end;
		if run.curDepth and run.depth - v > 2000 and v < 2000 then
			run.prestige = (run.prestige or 0) + 1;
			run.prestigeTotal = (run.prestigeTotal or 0) + run.depth;
			run.worldPath, run.pathDanger = nil, nil;
			if r.why then r.why("run", string.format("prestige %d after %d m: depth starts over (total %d m)", run.prestige, run.depth, run.prestigeTotal)); end;
			notify(string.format("Prestige %d! %d m done, starting over.", run.prestige, run.depth), "Delve run");
			run.depth = v;
		end;
		run.curDepth = v;
		if v > run.depth then run.depth = v; end;
		if v > (r.markDepth or -1) then
			r.markDepth = v;
			local hrpM = l.Character and l.Character:FindFirstChild("HumanoidRootPart");
			if hrpM then
				r.depthMarks = type(r.depthMarks) == "table" and r.depthMarks or {};
				table.insert(r.depthMarks, { x = hrpM.Position.X, z = hrpM.Position.Z, t = os.clock(), depth = v });
				while #r.depthMarks > 8 do table.remove(r.depthMarks, 1); end;
				-- the road always runs the same way across the map (depth 4,760 m at z -3,670, 9,060 m at
				-- z -7,080): learn that direction from the first mark of the run to the newest, keep it
				r.markAnchor = r.markAnchor or { x = hrpM.Position.X, z = hrpM.Position.Z };
				local ax, az = hrpM.Position.X - r.markAnchor.x, hrpM.Position.Z - r.markAnchor.z;
				local al = math.sqrt(ax * ax + az * az);
				if al >= 40 then
					ax, az = ax / al, az / al;
					local td = type(brain.tunnelDir) == "table" and brain.tunnelDir or nil;
					if td and tonumber(td.x) and tonumber(td.z) then
						local bx, bz = td.x * .8 + ax * .2, td.z * .8 + az * .2;
						local bl = math.sqrt(bx * bx + bz * bz);
						if bl > .1 then ax, az = bx / bl, bz / bl; end;
					end;
					brain.tunnelDir = { x = ax, z = az, n = ((td and tonumber(td.n)) or 0) + 1 };
					if (brain.tunnelDir.n % 10) == 1 then markBrain(); end;
				end;
			end;
		end;
	end;
	local function readHud(now)
		local ls = leaderRead();
		if ls.depth then noteDepth(ls.depth, now); end;
		-- boss intro card ("THE UNMAKER / THE END OF ALL THINGS"): remember the name as a boss
		local pgB = l:FindFirstChild("PlayerGui");
		local card = pgB and pgB:FindFirstChild("RiftBossCard");
		if card and card:IsA("LayerCollector") and card.Enabled ~= false then
			for _, o in ipairs(card:GetDescendants()) do
				if o:IsA("TextLabel") and o.Visible and trim(txt(o)):upper():find("^THE%s") then
					local nm = trim(txt(o)):upper();
					brain.bossNames = type(brain.bossNames) == "table" and brain.bossNames or {};
					if not brain.bossNames[nm] then
						brain.bossNames[nm] = true;
						markBrain();
						if r.why then r.why("boss", "boss card: " .. nm .. " (remembered as a boss)"); end;
					end;
					break;
				end;
			end;
		end;
		if ls.wave and ls.wave > run.wave then run.wave = ls.wave; end;
		if now - hud.scanAt > 10 then
			hud.scanAt = now;
			local pg = l:FindFirstChild("PlayerGui");
			if pg then
				hud.boss, hud.delve = nil, nil;
				local vpY = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 1080;
				if not (hud.timer and hud.timer.Parent and shown(hud.timer)) then hud.timer = nil; end;
				for _, o in ipairs(pg:GetDescendants()) do
					if o:IsA("TextLabel") then
						local u = trim(txt(o)):upper();
						-- the delve floor countdown ("0:30") sits at the top of the screen under DELVE
						if not hud.timer and u:match("^%d+:%d%d$") and o.AbsolutePosition.Y < vpY * .3 and shown(o)
							and not o:FindFirstAncestorWhichIsA("ScrollingFrame") then
							hud.timer = o;
						end;
						if u:find("^DEPTH%s*%d") then hud.depth = o; end;
						if u:find("WAVE%s*%d") then hud.wave = o; end;
						if u == "DELVE" then hud.delve = o; end;
						if u:find("BOSS") and #u <= 40 then hud.boss = o; end;
						-- boss fights show a CONTRIBUTION panel (Worldheart has no boss flag)
						if u == "CONTRIBUTION" then hud.contrib = o; end;
						if u == "ACTIVE BUFFS" then hud.buffs = o; end;
					end;
				end;
			end;
		end;
		if hud.depth and hud.depth.Parent then
			if not ls.depth then
				local v = tonumber((trim(txt(hud.depth)):upper():gsub(",", "")):match("^DEPTH%s*(%d+)"));
				noteDepth(v, now);
			end;
			local rom = trim(txt(hud.depth)):upper():match("PRESTIGE%s+([IVX]+)");
			local RN = { I = 1, II = 2, III = 3, IV = 4, V = 5, VI = 6, VII = 7, VIII = 8, IX = 9, X = 10 };
			if rom and RN[rom] and RN[rom] > (run.prestige or 0) then
				run.prestige = RN[rom];
				if r.why then r.why("run", "prestige " .. rom .. " (depth keeps counting)"); end;
			end;
		end;
		if hud.wave and hud.wave.Parent then
			local wt = txt(hud.wave):upper();
			local v = tonumber(wt:match("WAVE%s*(%d+)"));
			if not ls.wave and v and v > run.wave then run.wave = v; end;
			-- "WAVE 4 - ORE" -> stage "ORE"
			run.stage = trim(wt:match("WAVE%s*%d+%s*[%-:]%s*(.+)$") or "");
		end;
		if hud.delve and hud.delve.Parent and shown(hud.delve) then run.isDelve = true; end;
		-- ACTIVE BUFFS: "1/4 STORM" = a set in progress, other lines = effects you already have
		if hud.buffs and hud.buffs.Parent and now - (hud.buffsAt or -1e9) > 2 then
			hud.buffsAt = now;
			local sets, lines = {}, {};
			for _, o in ipairs(hud.buffs.Parent:GetDescendants()) do
				if o:IsA("TextLabel") and o ~= hud.buffs and o.Visible then
					local u = trim(txt(o)):upper();
					if u ~= "" then
						local have, need, nm = u:match("^(%d+)%s*/%s*(%d+)%s+(.+)$");
						if have then
							sets[trim(nm)] = { have = tonumber(have), need = tonumber(need) };
						else
							lines[#lines + 1] = u;
						end;
					end;
				end;
			end;
			run.buffSets, run.buffLines = sets, lines;
			-- only lines about range/radius/reach (counters like "BLOODRUSH 3/10" change all the time)
			local rl = {};
			for _, u in ipairs(lines) do
				if u:find("RANGE", 1, true) or u:find("RADIUS", 1, true) or u:find("REACH", 1, true) then rl[#rl + 1] = u; end;
			end;
			local bsig = table.concat(rl, "|");
			if run.buffSig and bsig ~= run.buffSig and r.readStats and CFG.autoStats ~= false then
				pcall(r.readStats, true);
				if r.why then r.why("mine", "buffs changed: re-reading mining range and radius from the game"); end;
			end;
			run.buffSig = bsig;
			local life = false;
			for _, u in ipairs(lines) do
				if r.prio and r.prio.has(" " .. u .. " ", r.prio.life) then life = true; end;
			end;
			run.hasLifeBuff = life;
		end;
		-- floor timer: under the danger time it stops chasing mobs (unless the floor needs them dead)
		run.timeLeft = nil;
		if hud.timer and hud.timer.Parent and shown(hud.timer) then
			local mm, ss = trim(txt(hud.timer)):match("^(%d+):(%d%d)$");
			if mm then
				local tl = tonumber(mm) * 60 + tonumber(ss);
				run.timeLeft, run.timeAt = tl, now;
				local dz = tonumber(Q.dangerTime) or 10;
				if tl <= dz and not run.inDanger then
					run.inDanger = true;
					run.dangerCount = (run.dangerCount or 0) + 1;
				elseif tl > dz + 5 then
					run.inDanger = false;
				end;
			end;
			-- floor objective: other short labels next to the timer ("SLAY THE GUARDIAN", "KILL 10"...)
			local box = hud.timer.Parent;
			local obj = {};
			for _, o in ipairs(box and box:GetChildren() or {}) do
				if o:IsA("TextLabel") and o ~= hud.timer and shown(o) then
					local u = trim(txt(o)):upper();
					-- "DEPTH 340 M - 1 MOB LEFT": keep the goal part after the dash
					if u:find("^DEPTH") then u = u:match("%-%s*(.+)$") or ""; end;
					if u ~= "DELVE" and u:match("%a") and #u <= 48 then obj[#obj + 1] = u; end;
				end;
			end;
			run.objective = table.concat(obj, " | ");
			if run.objective ~= "" and run.objective ~= run.lastObjective then
				run.lastObjective = run.objective;
				for _, ob in ipairs(obj) do pcall(r.mechSeen, "objective", ob); end;
			end;
			if not r.hudDumped and r.dumpGui then
				r.hudDumped = true;
				local lc = hud.timer:FindFirstAncestorWhichIsA("LayerCollector");
				task.spawn(function() pcall(r.dumpGui, lc, "hud"); end);
			end;
		end;
		run.bossHud = ((hud.boss and hud.boss.Parent and shown(hud.boss))
			or (hud.contrib and hud.contrib.Parent and shown(hud.contrib))) and true or false;
	end;
	task.spawn(function()
		local pg = l:WaitForChild("PlayerGui", 30);
		if not pg then return; end;
		local quiet = brain.mechBaseline == nil;
		brain.mechBaseline = true;
		for _, sg in ipairs(pg:GetChildren()) do
			if sg:IsA("LayerCollector") then pcall(r.mechSeen, "screen", sg.Name, true); end;
		end;
		local dumps = 0;
		pg.ChildAdded:Connect(function(sg)
			if not sg:IsA("LayerCollector") or sg.Name:find("Delve") or sg.Name:find("Wind") then return; end;
			local ok, m, isNew = pcall(r.mechSeen, "screen", sg.Name, quiet and not run.active);
			-- save the layout of a screen it has never seen, so its readers can be added
			if ok and isNew and dumps < 5 and r.dumpGui then
				dumps = dumps + 1;
				task.delay(1, function() pcall(r.dumpGui, sg, "new_" .. sg.Name:gsub("[^%w_]", "")); end);
			end;
		end);
	end);
	local function runStart(now)
		run.active, run.startAt = true, now;
		for _, a in pairs(brain.attacks or {}) do
			if type(a) == "table" then
				a.extra = (tonumber(a.extra) or 0) * .9;
				a.lead = (tonumber(a.lead) or 0) * .9;
			end;
		end;
		run.mechs, run.newMechs = {}, {};
		run.relics, run.depth, run.wave, run.died, run.hits = {}, 0, 0, false, 0;
		run.combatT, run.mineT = 0, 0;
		run.stage, run.bossHud, run.isDelve, run.mobHits = "", false, false, 0;
		run.timeLeft, run.inDanger, run.dangerCount, run.objective, run.rareSeen = nil, false, 0, "", {};
		run.curDepth, run.prestige, run.prestigeTotal, run.worldPath = nil, 0, 0, nil;
		r.depthMarks, r.markDepth, r.markAnchor = nil, nil, nil;
		run.buffSets, run.buffLines, run.hasLifeBuff, run.hasLife = {}, {}, false, false;
		run.cash0 = cashNow();
		run.cashExact0 = exactCash(now);
		run.level0 = leaderRead().level;
		run.id = l:GetAttribute("RunId");
		run.plateSeen = now;
	end;
	local function finalizeRun(snap, res, dur)
		-- the deepest of: results screen, player list, HUD (the results screen can show a checkpoint, not your depth)
		local depth = math.max((res and res.depth) or 0, snap.depth or 0);
		local wave = math.max(snap.wave, (res and res.wave) or 0);
		local mode = (res and res.mode) or ((depth > 0 or snap.isDelve) and "delve" or "waves");
		local died = snap.died or (res and res.died) or false;
		local cashExact1 = exactCash(d());
		local gain;
		if snap.cashExact0 and cashExact1 then
			gain = cashExact1 - snap.cashExact0;
		else
			local c1 = cashNow();
			gain = (snap.cash0 and c1) and (c1 - snap.cash0) or 0;
		end;
		local tripValue = res and res.cashValue or nil;
		local value = math.max(gain or 0, tripValue or 0);
		-- depth is the main goal in a delve: a new personal best gets extra credit
		local bestKey = mode .. "Best";
		local prevBest = tonumber(brain[bestKey]) or 0;
		if depth > prevBest then brain[bestKey] = depth; end;
		local score = depth + (depth > prevBest and prevBest > 0 and 50 or 0) + wave * 15 + (value > 1 and math.log10(value) * 8 or 0)
			+ math.min(40, ((res and res.rocks) or 0) * .05)
			- (died and 30 or 0) - snap.hits * .5 + math.min(dur, 900) / 30;
		-- compare a run against runs made with similar gear power, so upgrading gear
		-- doesn't make every relic from older runs look bad
		local pw = brain.player and tonumber(brain.player.power);
		local statKey = pw and pw > 0 and string.format("%s:p%d", mode, math.floor(math.log10(pw) * 4)) or mode;
		-- only real runs teach: a death, a results screen, or 2+ minutes. Quick exits and runs cut off by
		-- a disconnect are recorded but don't change what it has learned.
		local learnable = died or res ~= nil or dur >= 120;
		-- compare with your last 20 runs at similar gear power (not with every run ever)
		local st = brain.runs[statKey];
		if type(st) ~= "table" or type(st.recent) ~= "table" then st = { recent = {} }; brain.runs[statKey] = st; end;
		local recent = st.recent;
		local mean, var = 0, 0;
		for _, v in ipairs(recent) do mean = mean + v; end;
		mean = #recent > 0 and mean / #recent or 0;
		for _, v in ipairs(recent) do var = var + (v - mean) ^ 2; end;
		local std = #recent >= 3 and math.sqrt(var / (#recent - 1)) or 0;
		-- the score is mostly depth: differences under ~10% of a typical run aren't meaningful
		std = math.max(std, 50, math.abs(mean) * .1);
		local z = #recent >= 3 and (score - mean) / std or 0;
		if learnable then
			recent[#recent + 1] = score;
			while #recent > 20 do table.remove(recent, 1); end;
		end;
		local zc = learnable and math.max(-2.5, math.min(2.5, z)) or 0;
		if Q.relicLearn ~= false and learnable and zc ~= 0 then
			brain.catMode[mode] = type(brain.catMode[mode]) == "table" and brain.catMode[mode] or {};
			local cm = brain.catMode[mode];
			for idx, pick in ipairs(snap.relics) do
				local rec = relicRec(pick.key);
				rec.n = (tonumber(rec.n) or 0) + 1;
				rec.zsum = (tonumber(rec.zsum) or 0) + zc;
				rec.modes = type(rec.modes) == "table" and rec.modes or {};
				local ms = type(rec.modes[mode]) == "table" and rec.modes[mode] or { n = 0, zsum = 0 };
				ms.n, ms.zsum = (tonumber(ms.n) or 0) + 1, (tonumber(ms.zsum) or 0) + zc;
				rec.modes[mode] = ms;
				for cat in pairs(pick.cats) do
					brain.cat[cat] = math.max(.4, math.min(2.5, (tonumber(brain.cat[cat]) or 1) + .04 * zc));
					cm[cat] = math.max(.4, math.min(2.5, (tonumber(cm[cat]) or tonumber(brain.cat[cat]) or 1) + .06 * zc));
				end;
				for j = idx + 1, #snap.relics do
					local other = snap.relics[j];
					if other.key ~= pick.key then
						local pk = pairKey(pick.key, other.key);
						local pr = type(brain.pairs[pk]) == "table" and brain.pairs[pk] or { n = 0, zsum = 0 };
						pr.n, pr.zsum = (tonumber(pr.n) or 0) + 1, (tonumber(pr.zsum) or 0) + zc;
						brain.pairs[pk] = pr;
					end;
				end;
			end;
		end;
		-- category weights are relative: keep their average at 1 so they can't all drift to the cap
		local function normalize(t)
			local sum, n = 0, 0;
			for _, v in pairs(t) do if tonumber(v) then sum, n = sum + v, n + 1; end; end;
			if n < 2 or sum <= 0 then return; end;
			local avg = sum / n;
			for k, v in pairs(t) do if tonumber(v) then t[k] = math.max(.4, math.min(2.5, v / avg)); end; end;
		end;
		normalize(brain.cat);
		if type(brain.catMode[mode]) == "table" then normalize(brain.catMode[mode]); end;
		for key in pairs((learnable and type(snap.mechs) == "table") and snap.mechs or {}) do
			local m = brain.mech[key];
			if type(m) == "table" then
				m.n, m.zsum = (tonumber(m.n) or 0) + 1, (tonumber(m.zsum) or 0) + zc;
			end;
		end;
		-- full run history (one JSON line per run) so the brain keeps a long memory
		local names = {};
		for _, pick in ipairs(snap.relics) do
			local cx = brain.codex[pick.key];
			names[#names + 1] = type(cx) == "table" and cx.name or pick.key;
		end;
		local lv1 = leaderRead().level;
		local record = {
			t = os.time(), mode = mode, score = math.floor(score * 10 + .5) / 10, z = math.floor(zc * 100 + .5) / 100,
			depth = depth, maxDepth = math.max(depth, snap.depth), wave = wave, cash = gain, tripValue = tripValue,
			rocks = res and res.rocks, xp = res and res.xp, materials = res and res.materials,
			level = (res and res.level) or lv1, levelUp = (snap.level0 and lv1) and (lv1 - snap.level0) or nil,
			died = died, hits = snap.hits, seconds = math.floor(dur), relics = names,
			title = res and res.title, source = res and "results screen" or "live tracking",
			power = brain.player and brain.player.power, luck = brain.player and brain.player.luck,
			combatPct = (snap.combatT + snap.mineT) > 0 and math.floor(snap.combatT / (snap.combatT + snap.mineT) * 100 + .5) or nil,
		};
		record.rareDrops, record.closeCalls, record.newMechanics = snap.rare, snap.close, snap.newMechs;
		record.learned = learnable;
		record.prestige = snap.prestige;
		pcall(function()
			local line = Http:JSONEncode(record) .. "\n";
			if type(appendfile) == "function" and type(isfile) == "function" and isfile("DelveRuns.jsonl") then
				appendfile("DelveRuns.jsonl", line);
			elseif type(writefile) == "function" then
				local old = "";
				if type(isfile) == "function" and isfile("DelveRuns.jsonl") and type(readfile) == "function" then old = readfile("DelveRuns.jsonl"); end;
				writefile("DelveRuns.jsonl", old .. line);
			end;
		end);
		brain.runCount = (tonumber(brain.runCount) or 0) + 1;
		markBrain();
		saveBrain(true);
		if r.sendRunWebhook then
			local info = record;
			info.relicCount = #names;
			-- the results screen is up right now: post (and screenshot) immediately
			task.delay(res and 0 or (tonumber(Q.webhookDelay) or 1.5), function() pcall(r.sendRunWebhook, info); end);
		end;
		notify(string.format("Run scored %.0f (%s, %dm, %+.2f vs your average). Learned from %d relic pick%s.",
			score, mode, math.floor(depth), zc, #snap.relics, #snap.relics == 1 and "" or "s"), "Delve brain");
	end;
	-- ask the screenshot helper for a picture of the end screen right away (before Auto Replay starts the next run)
	r.helperAlive = function()
		local alive = false;
		pcall(function()
			if type(isfile) == "function" and isfile("DelveWebhook/helper_alive.txt") then
				local t = tonumber((readfile("DelveWebhook/helper_alive.txt") or ""):match("%d+"));
				alive = t ~= nil and math.abs(os.time() - t) < 20;
			end;
		end);
		return alive;
	end;
	r.requestSnap = function()
		local sp = r.snapPending;
		if not sp or sp.requested then return; end;
		sp.requested = true;
		pcall(function()
			writefile("DelveWebhook/job_" .. sp.id .. ".json", game:GetService("HttpService"):JSONEncode({ snap = sp.id .. ".png" }));
		end);
		r.lastSnap = sp.id .. ".png";
	end;
	local function runFinish(now)
		if not run.active then return; end;
		run.active = false;
		r.snapPending, r.lastSnap = nil, nil;
		if CFG.webhookOn == true and type(writefile) == "function" and r.helperAlive() then
			r.snapPending = { at = d(), id = "snap_" .. tostring(os.time()) .. "_" .. tostring(math.random(100, 999)) };
		end;
		local dur = now - run.startAt;
		readHud(now);
		local snap = {
			relics = run.relics, depth = (run.prestigeTotal or 0) + run.depth, wave = run.wave, died = run.died, hits = run.hits,
			prestige = run.prestige,
			cash0 = run.cash0, cashExact0 = run.cashExact0, level0 = run.level0, isDelve = run.isDelve,
			combatT = run.combatT, mineT = run.mineT, rare = run.rareSeen, close = run.dangerCount,
			mechs = run.mechs, newMechs = run.newMechs,
		};
		if dur < 20 then return; end;
		task.spawn(function()
			-- wait for the results screen, then until its numbers stop counting up
			local t0 = d();
			local res, prev;
			-- prefer the TRIP COMPLETE screen (it has rocks, XP, level, materials); the "YOU DIED TO" overlay
			-- only has a title, so it's used only if the end screen never shows
			local endRes, otherRes;
			while d() - t0 < 8 do
				local re = readRunEnd();
				if re then
					-- the end screen is up: picture now, then wait until its numbers stop counting up
					pcall(r.requestSnap);
					if endRes and endRes.sig == re.sig then endRes = re; break; end;
					endRes = re;
					task.wait(.4);
				else
					otherRes = readResults(d()) or otherRes;
					if d() - t0 >= 4 then pcall(r.requestSnap); end;
					task.wait(.25);
				end;
			end;
			res = endRes or otherRes;
			pcall(r.requestSnap);
			-- save what the end screen looks like once, so its reader can be fixed if it misses fields
			if not r.runEndDumped and r.dumpGui then
				local pg = l:FindFirstChild("PlayerGui");
				local re = pg and pg:FindFirstChild("RunEnd");
				if re then r.runEndDumped = true; pcall(r.dumpGui, re, "runend"); end;
			end;
			local ok, err = pcall(finalizeRun, snap, res, dur);
			if r.curveRefresh then task.delay(.5, r.curveRefresh); end;
			if not ok then notify("Run finish error: " .. tostring(err), "Delve brain"); end;
		end);
	end;
	local runCheckAt = -1e9;
	local function runTick(now)
		if now - runCheckAt < .5 then return; end;
		runCheckAt = now;
		local endRoom = workspace:FindFirstChild("RunEndRoom");
		local plate = workspace:FindFirstChild("StrataPlate");
		local id = l:GetAttribute("RunId");
		if run.active then
			if plate then
				run.plateSeen = now;
			end;
			if endRoom or resultsTitle(now) or (not plate and now - (run.plateSeen or now) > 4) then
				runFinish(now);
			elseif id ~= nil and run.id ~= nil and id ~= run.id then
				runFinish(now);
				runStart(now);
			else
				readHud(now);
			end;
		elseif plate and not endRoom and not resultsTitle(now) then
			runStart(now);
		end;
	end;

	local function report()
		local list = {};
		for key, rec in pairs(brain.relics) do
			if type(rec) == "table" then
				local n = tonumber(rec.n) or 0;
				local v = n > 0 and (tonumber(rec.zsum) or 0) / n or 0;
				list[#list + 1] = { name = rec.name or key, v = v, n = n, user = tonumber(rec.user) or 0, offered = tonumber(rec.offered) or 0 };
			end;
		end;
		table.sort(list, function(x, y) return x.v * x.n / (x.n + 3) > y.v * y.n / (y.n + 3); end);
		local out = {};
		for k = 1, math.min(8, #list) do
			local e = list[k];
			out[#out + 1] = string.format("%s %+.2f (%d runs, you %d/%d)", e.name, e.v, e.n, e.user, e.offered);
		end;
		local cats = {};
		for cat, w in pairs(brain.cat) do cats[#cats + 1] = string.format("%s x%.2f", cat, tonumber(w) or 1); end;
		return (#out > 0 and table.concat(out, "\n") or "No relics learned yet.") .. "\nCategory weights: " .. (#cats > 0 and table.concat(cats, ", ") or "default");
	end;

	return {
		tick = relicTick,
		runTick = runTick,
		report = report,
		finish = function() pcall(disconnectDraft); end,
		hasDraft = function() return draft ~= nil; end,
	};
end)();
local function LQ(m)
	return relicAPI.tick(m);
end;
local function uQ(now, force)
	local character = l.Character;
	local tool = character and character:FindFirstChildOfClass("Tool");
	if character ~= r.rangeCharacter or tool ~= r.rangeTool then
		r.rangeCharacter, r.rangeTool = character, tool;
		r.range, r.rangeSeenAt, r.rangeCheckedAt = nil, nil, nil;
	end;
	if not Q.autoCombatStats or not character or character:GetAttribute("WeaponDrawn") == false then
		r.range, r.rangeSeenAt, r.rangeCheckedAt = nil, nil, nil;
		return;
	end;
	if not force and r.rangeCheckedAt and now - r.rangeCheckedAt < .25 then return; end;
	r.rangeCheckedAt = now;

	-- Use the same attack-cone geometry the existing combat loop reads.
	local cone = workspace:FindFirstChild("WeaponCone");
	local detected;
	if cone then
		for _, part in ipairs(cone:GetChildren()) do
			if part:IsA("BasePart") and part.Size.X < .3 and part.Size.Z > 1 then
				detected = math.max(detected or 0, part.Size.Z);
			end;
		end;
	end;
	if detected then
		r.range, r.rangeSeenAt = detected, now;
	elseif r.rangeSeenAt and now - r.rangeSeenAt > 4 then
		r.range, r.rangeSeenAt = nil, nil;
	end;
end;
local function YQ()
	local manual = tonumber(Q.fightDist) or 8;
	-- live range from the attack cone, else the range learned for the sword you hold
	local rg = r.range or r.swordLearnedRange;
	local out = manual;
	if Q.autoCombatStats and rg then
		out = math.min(rg * .7, manual);
	end;
	-- learned live: where hits really land (bigger with range relics), minus a shrink when swings miss
	if r.liveHitMax == nil and type(brain.swordHit) == "table" and brain.player then
		r.liveHitMax = tonumber(brain.swordHit[tostring(brain.player.sword or "?")]);
	end;
	if r.liveHitMax and r.liveHitMax > 20 then r.liveHitMax = nil; end;
	if r.liveHitMax then out = math.max(out, math.min(manual, r.liveHitMax * .9)); end;
	return math.max(2, out - (tonumber(r.orbitShrink) or 0));
end;
local function pQ(m, G)
	if not a or #i < 3 then
		return true;
	end;
	local r, Q = g(a, m, G);
	for m, G in ipairs({
		{ -0.15, -0.15 },
		{ .15, -0.15 },
		{ -0.15, .15 },
		{ .15, .15 },
	}) do
		if not V[math.floor(((r + G[1])) + .5) * 4096 + math.floor(((Q + G[2])) + .5)] then
			return false;
		end;
	end;
	return true;
end;
r.walkable = pQ;
local function centerFarmAnchor(position)
	-- A visible chest can be used even before it unlocks.
	local saved = r.centerFarmChest;
	if saved and pQ(saved.x, saved.z) then return saved.x, saved.z; end;
	local chest, nearest;
	for _, candidate in pairs(r.chestScanPlate == E and ql or {}) do
		local distance = (candidate.x - position.X)^2 + (candidate.z - position.Z)^2;
		if (not nearest or distance < nearest) and pQ(candidate.x, candidate.z) then
			chest, nearest = candidate, distance;
		end;
	end;
	if chest then
		r.centerFarmChest = chest;
		return chest.x, chest.z;
	end;

	-- Snap the midpoint of the floor bounds to a real tile, even on irregular floors.
	if #i == 0 then return nil; end;
	if r.centerFarmTiles ~= i then
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge;
		for _, tile in ipairs(i) do
			minX, maxX = math.min(minX, tile.wx), math.max(maxX, tile.wx);
			minZ, maxZ = math.min(minZ, tile.wz), math.max(maxZ, tile.wz);
		end;
		local midX, midZ = (minX + maxX) / 2, (minZ + maxZ) / 2;
		local center, nearestTile;
		for _, tile in ipairs(i) do
			local distance = (tile.wx - midX)^2 + (tile.wz - midZ)^2;
			if not nearestTile or distance < nearestTile then
				center, nearestTile = tile, distance;
			end;
		end;
		r.centerFarmTiles, r.centerFarmTile = i, center;
	end;
	return r.centerFarmTile.wx, r.centerFarmTile.wz;
end;
local function HQ(m, G)
	if a and #i >= 3 then
		local G, r = g(a, m.X, m.Z);
		if not V[math.floor(G + .5) * 4096 + math.floor(r + .5)] then
			return 0;
		end;
	end;
	local r = 0;
	if not pQ(m.X + G[1] * 2.5, m.Z + G[2] * 2.5) then
		r = r + 1;
	end;
	if not pQ(m.X + G[1] * 5, m.Z + G[2] * 5) then
		r = r + 1;
	end;
	return r;
end;
local function tQ()
	local m = .7071;
	return {
		{ A, h },
		{ -A, -h },
		{ k, T },
		{ -k, -T },
		{ ((A + k)) * m, ((h + T)) * m },
		{ ((A - k)) * m, ((h - T)) * m },
		{ ((-A + k)) * m, ((-h + T)) * m },
		{ ((-A - k)) * m, ((-h - T)) * m },
	};
end;
local function PQ(m, G)
	local r = 0;
	for Q, e in ipairs(Fl) do
		local N = ul(e, m, G, e.pm or Yl);
		if N then
			r = ((r + N)) + 1;
			local Q = ul(e, m, G, Vl);
			if Q then
				r = r + ((Q + 1)) * 6;
			end;
		end;
	end;
	return r;
end;
local JQ;
local function IQ(m)
	if not inp.active() or m - ((r.lastRoll or -1000000000.0)) < yl then
		return;
	end;
	local G = sQ();
	if not G then
		return;
	end;
	for r, Q in pairs(Cl) do
		if not Q.rolled and (Q.hitAt and (Q.hitAt > m and (Q.hitAt - m < yl and ul(Q.zone, G.X, G.Z, Vl)))) then
			return;
		end;
	end;
	for Q, e in pairs(el) do
		-- in a boss fight, don't spend the roll on small mobs' swings: the boss's attacks are the ones that kill
		if e.owned and (e.strikeAt and (e.rolledFor ~= e.strikeAt and m - e.strikeAt < .15))
			and not (r.bossFight and tostring(e.name) ~= r.bossFight)
			-- the strike already hit you: rolling now only wastes the roll
			and not (r.lastHitAt and m - r.lastHitAt < .3) then
			e.rolledFor = e.strikeAt;
			for Q, N in ipairs(Fl) do
				if ul(N, G.X, G.Z, Vl) then
					if eQ(m) then
						r.lastRoll = m;
						f(string.format("strike roll vs %s", tostring(e.name)));
					end;
					return;
				end;
			end;
		end;
	end;
	-- roll BEFORE the strike: once a mob's windup length is learned, schedule the roll from the windup start
	if Q.windupLearn ~= false and r.windups then
		local lead = bl + (r.pingLead or 0);
		for _, mob in pairs(el) do
			local dur = mob.owned and mob.phase == "windup" and mob.windupAt and mob.x and tonumber(r.windups[mob.name]) or nil;
			-- (the boss-fight condition used to sit at the end of the line above, which turned dur into
			-- true/false instead of the windup time and crashed "windupAt + dur")
			if dur and r.bossFight and tostring(mob.name) ~= r.bossFight then dur = nil; end;
			if dur and mob.rolledForW ~= mob.windupAt then
				local hitAt = mob.windupAt + dur;
				if m >= hitAt - lead and m <= hitAt + .12 then
					local dx, dz = mob.x - G.X, mob.z - G.Z;
					local reach = math.max(vl, (CFG.dodgeLearn ~= false and tonumber(brain.mobReach[tostring(mob.name)])) or 0) + Vl;
					if dx * dx + dz * dz <= reach * reach then
						if eQ(m) then
							mob.rolledForW = mob.windupAt;
							r.lastRoll = m;
							f(string.format("windup roll vs %s (%.2fs windup)", tostring(mob.name), dur));
						end;
						return;
					end;
				end;
			end;
		end;
	end;
end;
-- ATTACK ROLLS: when nothing is about to hit you, spend the roll going INTO the target.
-- On or Off (the old "Auto"/"Always" count as On). The roll distance is learned from real rolls.
local function attackRoll(m)
	local G = sQ();
	-- measure how far a roll actually goes
	local rf = r.rollFrom;
	-- measured 0.3 s after the roll (later than that it also counted walking, so it maxed out at 20 st)
	if rf and G and m - rf.t >= .3 then
		r.rollFrom = nil;
		local dist = math.sqrt((G.X - rf.x) ^ 2 + (G.Z - rf.z) ^ 2);
		if dist > 1 and dist < 40 then
			brain.rollDist = math.max(2, math.min(12, (tonumber(brain.rollDist) or dist) * .8 + dist * .2));
		end;
	end;
	-- boss fights: rolling through the boss deals damage, so roll into it while it's quiet: no attack zone
	-- within 18 st (25 st on a 1-HP run), nothing timed or winding up, no boss attack predicted for 2 s.
	-- Otherwise keep the roll for defence (and cancel a queued attack roll).
	local inBoss = r.bossFight ~= nil;
	if inBoss then
		local quiet = CFG.bossRolls ~= false and G ~= nil and next(Cl) == nil;
		if quiet then
			local qr = r.fragile and 25 or 18;
			for _, z in ipairs(Fl) do
				local zr = qr + math.max(z.h1 or 0, z.h2 or 0);
				if (z.x - G.X) ^ 2 + (z.z - G.Z) ^ 2 < zr * zr then quiet = false; break; end;
			end;
		end;
		if not quiet then
			if r.offRollAt then r.offRollAt, r.forceDir = nil, nil; f("attack roll cancelled: boss attack nearby"); end;
			return;
		end;
	end;
	-- just got hit: more hits are likely, so keep the roll for defence (cancel a queued attack roll too)
	if r.lastHitAt and m - r.lastHitAt < 1 then
		if r.offRollAt then r.offRollAt, r.forceDir = nil, nil; f("attack roll cancelled: just got hit"); end;
		return;
	end;
	-- phase 2: direction is set, roll now, unless something dangerous started in the meantime
	if r.offRollAt and m >= r.offRollAt then
		r.offRollAt = nil;
		local danger = next(Cl) ~= nil;
		if not danger then
			for _, mob in pairs(el) do
				if mob.owned and mob.phase == "windup" then danger = true; break; end;
			end;
		end;
		local pr0 = dangerMem.predict;
		if pr0 and pr0.at - m < (inBoss and 2 or 1.2) and pr0.at - m > -.5 then danger = true; end;
		if danger then
			r.forceDir = nil;
			f("attack roll cancelled: an attack is coming");
			return;
		end;
		if inp.active() and m - (r.lastRoll or -1e9) >= yl and eQ(m) then
			r.lastRoll = m;
			r.attackRolls = (r.attackRolls or 0) + 1;
			if G then r.rollFrom = { x = G.X, z = G.Z, t = m }; end;
			f(string.format("attack roll (%s)", tostring(r.offRollWhy)));
		end;
		return;
	end;
	local mode = CFG.attackRoll or "On";
	if mode == "Off" or WQ ~= "combat" or not G or not inp.active() then return; end;
	if CFG.autoRoll == false or m - (r.lastRoll or -1e9) < yl + .35 or r.offRollAt then return; end;
	-- a boss attack is predicted soon: keep the roll for it
	local pr = dangerMem.predict;
	if pr and pr.at - m < (inBoss and 2 or 1.2) and pr.at - m > -.5 then return; end;
	-- keep the roll for dodging while an attack is coming
	if next(Cl) then return; end;
	for _, mob in pairs(el) do
		if mob.owned and mob.phase == "windup" then return; end;
	end;
	local best, bd;
	for _, mob in ipairs(ol()) do
		local dd = (mob.x - G.X) ^ 2 + (mob.z - G.Z) ^ 2;
		if not bd or dd < bd then best, bd = mob, dd; end;
	end;
	-- in a boss fight, roll at the current target (the boss or its pylon), not just the nearest mob
	if inBoss and xQ and el[xQ] and el[xQ].x then
		best = el[xQ];
		bd = (best.x - G.X) ^ 2 + (best.z - G.Z) ^ 2;
	end;
	if not best then return; end;
	local dist = math.sqrt(bd);
	local rd = tonumber(brain.rollDist) or 6;
	-- only mobs a roll can actually reach (about 12 st at most), not ones across the room
	if dist > math.min(12, rd + 4) then return; end;
	-- without a roll perk ("Always"), only use it to close the gap
	local dx, dz = best.x - G.X, best.z - G.Z;
	if dist < 2.5 and not inBoss then dx, dz = -dz, dx; end; -- on top of a mob: roll around it (a boss: straight through)
	local len = math.sqrt(dx * dx + dz * dz);
	if len < .01 then return; end;
	dx, dz = dx / len, dz / len;
	-- never roll off the map or into a hazard
	local ex, ez = G.X + dx * rd, G.Z + dz * rd;
	if r.navOpenAt then
		local okO, open = pcall(r.navOpenAt, ex, ez);
		if okO and (tonumber(open) or 99) < 2 then return; end;
	end;
	for _, zone in ipairs(Fl) do
		if ul(zone, ex, ez, Vl) then return; end;
	end;
	r.forceDir = { x = dx, z = dz, untilT = m + .3 };
	r.offRollAt = m + .06;
	r.offRollWhy = string.format("%s, %.1f st%s", tostring(best.name), dist, inBoss and ", through the boss" or "");
end;
-- move before a predicted boss attack lands
local function prePosition(m)
	local pr = dangerMem.predict;
	if not pr or not pr.info or pr.at - m > .9 or pr.at - m < -.3 or pr.done then return; end;
	local G = sQ();
	local boss = dangerMem.boss(G);
	if not G or not boss or not boss.x then return; end;
	local dx, dz = boss.x - G.X, boss.z - G.Z;
	local dist = math.sqrt(dx * dx + dz * dz);
	if dist < .1 then return; end;
	local info = pr.info;
	local a = brain.attacks[pr.sig];
	local holeOk = info.hole and not (type(a) == "table" and a.noHole);
	if holeOk and dist > info.hole * .6 and dist < (info.r or 0) + 4 then
		-- ring attack coming: get into the small safe circle by the boss
		r.forceDir = { x = dx / dist, z = dz / dist, untilT = m + .35 };
		pr.done = true;
		f(string.format("pre-move into safe ring (%s)", tostring(pr.sig)));
	elseif not info.hole and info.onBoss and (info.r or 0) >= 4 and dist < (info.r or 0) + 1.5 then
		-- big circle on the boss coming: step out before it shows
		r.forceDir = { x = -dx / dist, z = -dz / dist, untilT = m + .35 };
		pr.done = true;
		f(string.format("pre-move out of %s (r %.1f)", tostring(pr.sig), info.r or 0));
	end;
end;
local function mh(m)
	NQ(m);
	IQ(m);
	-- (v5.4) pattern-based pre-moves are paused: with the old lumped attack data they forced 591
	-- meaningless "step out" moves. They come back once the new attack fingerprints prove reliable.
	pcall(attackRoll, m);
	-- a queued escape roll: direction was set last frame, roll now if still useful
	local er = r.escRoll;
	if er and m >= er.at then
		r.escRoll = nil;
		if m - er.at < .15 and inp.active() and m - (r.lastRoll or -1e9) >= yl and eQ(m) then
			if er.w then er.w.rolled = true; end;
			r.lastRoll = m;
			r.lastRollSig = er.sig;
			r.lastRollHitIn = er.hitIn;
			f(string.format("escape roll (walking out needed %.2fs, %s left)", er.walkT, er.left and string.format("%.2fs", er.left) or "?"));
		end;
	end;
	if not next(Cl) then
		JQ = nil;
		return;
	end;
	local G = sQ();
	if not G then
		return;
	end;
	local Q, e = 0, 0;
	if JQ and m - JQ.t > .001 then
		Q, e = ((G.X - JQ.x)) / ((m - JQ.t)), ((G.Z - JQ.z)) / ((m - JQ.t));
	end;
	if not JQ or m - JQ.t >= .05 then
		JQ = { x = G.X, z = G.Z, t = m };
	end;
	-- boss attacks land a bit earlier than their telegraph suggests (the killing Worldheart hit came
	-- 90 ms before the roll): roll a little earlier in boss fights
	local N = bl + (r.pingLead or 0) + (r.bossFight and .08 or 0);
	for S, w in pairs(Cl) do
		if not w.rolled then
			local S = (w.hitAt and m >= w.hitAt - N - (w.zone and w.zone.sl or 0)) or (not w.hitAt and w.p >= .9);
			if S and ((not w.hitAt or m <= w.hitAt + .1)) then
				local N = w.hitAt and math.max(w.hitAt - m, 0) or 0;
				local justHit = r.lastHitAt and m - r.lastHitAt < .3 and N < .05;
				if not justHit and ul(w.zone, G.X + Q * N, G.Z + e * N, Vl) and (inp.active() and m - ((r.lastRoll or -1000000000.0)) >= yl) then
					-- (v5.30) the i-frames end 0.35 s into the roll: if the planned attacks hit where this roll lands
					-- after that (the Warden's shards after its charge), turn first and roll a frame later
					local turn;
					if r.plan and r.plan.hooked and CFG.planFeed ~= false and not r.escRoll then
						local okT, tx, tz = pcall(r.plan.rollDir, G, run.lastDir);
						if okT and tx then turn = { tx, tz }; end;
					end;
					if turn then
						w.rolled = true;
						r.forceDir = { x = turn[1], z = turn[2], untilT = m + .25 };
						SQ(turn[1], turn[2]);
						r.escRoll = { at = m + .03, w = w, sig = w.zone and w.zone.sig, hitIn = N, walkT = 0, left = N };
						f(string.format("roll turned: its landing spot gets hit after the i-frames (zone %.1f,%.1f, hitIn=%.2f)", w.zone.x, w.zone.z, N));
					elseif eQ(m) then
						w.rolled = true;
						r.lastRoll = m;
						r.lastRollSig = w.zone and w.zone.sig;
						r.lastRollHitIn = w.hitAt and (w.hitAt - m) or nil;
						f(string.format("roll zone=%.1f,%.1f hitIn=%.2f", w.zone.x, w.zone.z, ((w.hitAt or m)) - m));
					end;
				end;
			end;
		end;
	end;
	-- WALK OR ROLL: inside an attack zone, can walking get you out before it lands? If not, roll out
	-- (only when the roll lands on safe ground). Before this it walked 9-15 studs with 0.4-0.7 s left and got hit.
	if not r.escRoll and inp.active() and m - (r.lastRoll or -1e9) >= yl and not (r.lastHitAt and m - r.lastHitAt < .3) then
		local hum = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
		local ws = math.max(4, hum and hum.WalkSpeed or 16);
		for _, w in pairs(Cl) do
			if not w.rolled and w.zone then
				local depth, ox, oz = ul(w.zone, G.X, G.Z, Vl);
				local et = r.escTarget;
				if depth and ox and et and m - et.t < .4 then
					local ddx, ddz = et.x - G.X, et.z - G.Z;
					local dl = math.sqrt(ddx * ddx + ddz * ddz);
					if dl > 1 then ox, oz = ddx / dl, ddz / dl; end;
				end;
				if depth and ox then
					local walkT = depth / ws;
					local left = w.hitAt and (w.hitAt - m) or nil;
					-- one-hit runs (Glass Soul: max health 1) leave no room for a close call: roll sooner
					local glass = hum and hum.MaxHealth <= 5;
					local late = (left and left > 0 and walkT > left - (glass and .25 or .05))
						or (not w.hitAt and (tonumber(w.p) or 0) >= (glass and .45 or .6) and walkT > (glass and .2 or .35));
					if late then
						local rd = math.min(12, tonumber(brain.rollDist) or 6);
						local ex, ez = G.X + ox * rd, G.Z + oz * rd;
						local safe = true;
						for _, z2 in ipairs(Fl) do
							if not z2.plan and ul(z2, ex, ez, Vl) then safe = false; break; end;
						end;
						-- planned attacks: the landing spot has to be clear once the i-frames are over
						if safe and r.plan and r.plan.hooked and CFG.planFeed ~= false then
							local sv = r.plan.srv();
							if r.plan.hitAt(ex, ez, sv + .35, sv + 1.1) then safe = false; end;
						end;
						if safe and r.navOpenAt then
							local okO, open = pcall(r.navOpenAt, ex, ez);
							if okO and (tonumber(open) or 99) < 1 then safe = false; end;
						end;
						if safe then
							-- point the character out of the zone now, roll next frame
							r.forceDir = { x = ox, z = oz, untilT = m + .25 };
							SQ(ox, oz);
							r.escRoll = { at = m + .03, w = w, sig = w.zone.sig, hitIn = left, walkT = walkT, left = left };
							break;
						end;
					end;
				end;
			end;
		end;
	end;
end;
local Gh = {
		3,
		6,
		9,
		12,
		16,
		20,
		25,
		32,
		40,
		50,
	};
local rh = 16;
local Qh = nil;
local function eh(m, G, r)
	for m, Q in ipairs(m) do
		if ul(Q, G, r, Vl + .5) then
			return true;
		end;
	end;
	return false;
end;
-- ===================================================================================
-- NAV: pathfinding over the real floor tiles
--   * openness  = how many studs a tile is from the edge of the map (corners/walls are low)
--   * escape    = Dijkstra from your tile to the nearest tile outside every attack zone,
--                 paying extra for tiles inside zones, near edges, under rocks or recently stuck.
--   This replaces the old fixed 25-stud ring search that found nothing when a boss parked a
--   huge AOE in a corner (so the character stood still, rolled once and died).
-- ===================================================================================
local nav = { tiles = nil, map = nil, open = nil, cell = 4, blocked = {} };
nav.N8 = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } };
local function navBuild()
	if nav.tiles == i and nav.map then return true; end;
	if nav.tiles == i and not nav.map then return false; end;
	-- the tile list gets refreshed all the time; only a different floor (other size or position) is a new map.
	-- Rebuilding every refresh wiped the blocked pillars, so it walked into the same pillar again and again.
	-- the tile list is refreshed all the time and shrinks as the floor collapses. Rebuild the map at most
	-- once a second, and only forget blocked pillars when it's a different floor (run id + depth).
	local fkey = tostring(l:GetAttribute("RunId")) .. "|" .. tostring(run.prestige or 0) .. "|" .. tostring(run.curDepth or run.depth);
	if nav.map and fkey == nav.fkey and d() - (nav.builtAt or 0) < 1 then
		nav.tiles = i;
		return true;
	end;
	local newFloor = fkey ~= nav.fkey;
	nav.fkey, nav.builtAt = fkey, d();
	nav.tiles, nav.map, nav.open = i, nil, nil;
	if newFloor then
		nav.blocked = {};
		nav.needScan = true;
	end;
	if #i < 3 then return false; end;
	local map = {};
	for _, t in ipairs(i) do map[t.cx * 4096 + t.cz] = t; end;
	local cs;
	for _, t in ipairs(i) do
		local nb = map[(t.cx + 1) * 4096 + t.cz] or map[t.cx * 4096 + t.cz + 1];
		if nb then
			cs = math.sqrt((nb.wx - t.wx) ^ 2 + (nb.wz - t.wz) ^ 2);
			break;
		end;
	end;
	nav.cell = (cs and cs > .1) and cs or 4;
	local open, queue, head = {}, {}, 1;
	for key, t in pairs(map) do
		local edge = false;
		for _, dl in ipairs(nav.N8) do
			if not map[(t.cx + dl[1]) * 4096 + t.cz + dl[2]] then edge = true; break; end;
		end;
		if edge then open[key] = 0; queue[#queue + 1] = t; end;
	end;
	while head <= #queue do
		local t = queue[head];
		head = head + 1;
		local base = open[t.cx * 4096 + t.cz];
		for _, dl in ipairs(nav.N8) do
			local k2 = (t.cx + dl[1]) * 4096 + t.cz + dl[2];
			if map[k2] and open[k2] == nil then
				open[k2] = base + 1;
				queue[#queue + 1] = map[k2];
			end;
		end;
	end;
	nav.map, nav.open = map, open;
	-- new floor: find the pillars on it once
	if nav.needScan then
		nav.needScan = false;
		task.defer(function() pcall(nav.scanPillars); end);
	end;
	return true;
end;
local function navCellAt(x, z)
	if not a or #i < 3 then return nil; end;
	local cx, cz = g(a, x, z);
	return math.floor(cx + .5), math.floor(cz + .5);
end;
-- studs from the map edge at a world point (99 when the floor is unknown, 0 when off the floor)
local function navOpenAt(x, z)
	if not navBuild() then return 99; end;
	local cx, cz = navCellAt(x, z);
	if not cx then return 99; end;
	local v = nav.open[cx * 4096 + cz];
	if v == nil then return 0; end;
	return (v + .5) * nav.cell;
end;
r.navOpenAt = navOpenAt;
local function navBlock(x, z, now, secs)
	local cx, cz = navCellAt(x, z);
	if cx then nav.blocked[cx * 4096 + cz] = now + (secs or 2); end;
end;
-- tiny binary heap for Dijkstra
function nav.push(h, cost, key)
	local n = #h + 1;
	h[n] = { cost, key };
	while n > 1 do
		local p = math.floor(n / 2);
		if h[p][1] <= h[n][1] then break; end;
		h[p], h[n] = h[n], h[p];
		n = p;
	end;
end;
function nav.pop(h)
	local top = h[1];
	if not top then return nil; end;
	local last = h[#h];
	h[#h] = nil;
	if #h > 0 then
		h[1] = last;
		local n = 1;
		while true do
			local l2, r2, s = n * 2, n * 2 + 1, n;
			if h[l2] and h[l2][1] < h[s][1] then s = l2; end;
			if h[r2] and h[r2][1] < h[s][1] then s = r2; end;
			if s == n then break; end;
			h[s], h[n] = h[n], h[s];
			n = s;
		end;
	end;
	return top[1], top[2];
end;
-- PILLARS: tall solid parts standing on the floor. Their tiles are blocked for the whole floor,
-- so walking (to ores, chests, mobs) routes around them instead of pushing into them.
function nav.floorY()
	local ch = l.Character;
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart");
	local hum = ch and ch:FindFirstChildOfClass("Humanoid");
	if not hrp then return nil, nil; end;
	return hrp.Position.Y - (hum and hum.HipHeight or 2) - hrp.Size.Y / 2, hrp;
end;
function nav.isObstacle(part, floorY)
	if not part:IsA("BasePart") or not part.CanCollide or part.Transparency >= .95 then return false; end;
	local sz, pos = part.Size, part.Position;
	local foot = math.max(sz.X, sz.Z);
	if foot < .8 or foot > 14 then return false; end;
	if pos.Y + sz.Y / 2 < floorY + 5.5 or pos.Y - sz.Y / 2 > floorY + 2.5 then return false; end;
	local a = part.Parent;
	for _ = 1, 4 do
		if not a or a == workspace then break; end;
		if a:FindFirstChildOfClass("Humanoid") then return false; end;
		local n = a.Name:upper();
		if n:find("CHEST", 1, true) or n:find("ORE", 1, true) or n:find("ROCK", 1, true) or n:find("DROP", 1, true) or n:find("LOOT", 1, true) then
			return false;
		end;
		a = a.Parent;
	end;
	return true;
end;
function nav.blockPart(part, untilT)
	local pos, sz = part.Position, part.Size;
	local h = math.max(sz.X, sz.Z) / 2 + 1 + nav.cell * .25;
	local n = 0;
	for key, t in pairs(nav.map or {}) do
		if math.abs(t.wx - pos.X) < h and math.abs(t.wz - pos.Z) < h then
			nav.blocked[key] = math.max(nav.blocked[key] or 0, untilT);
			n = n + 1;
		end;
	end;
	return n;
end;
function nav.scanPillars()
	if not navBuild() then return 0; end;
	local floorY, hrp = nav.floorY();
	if not floorY then return 0; end;
	local minx, maxx, minz, maxz = math.huge, -math.huge, math.huge, -math.huge;
	for _, t in pairs(nav.map) do
		minx, maxx = math.min(minx, t.wx), math.max(maxx, t.wx);
		minz, maxz = math.min(minz, t.wz), math.max(maxz, t.wz);
	end;
	if minx == math.huge then return 0; end;
	local op = OverlapParams.new();
	op.FilterType = Enum.RaycastFilterType.Exclude;
	op.FilterDescendantsInstances = { l.Character };
	local parts = workspace:GetPartBoundsInBox(CFrame.new((minx + maxx) / 2, floorY + 6, (minz + maxz) / 2),
		Vector3.new(maxx - minx + 8, 10, maxz - minz + 8), op);
	local found = 0;
	for _, part in ipairs(parts) do
		if nav.isObstacle(part, floorY) and nav.blockPart(part, math.huge) > 0 then found = found + 1; end;
	end;
	if found > 0 and r.why then r.why("move", string.format("floor mapped: %d pillars/obstacles blocked off", found)); end;
	return found;
end;
-- right where it got stuck
function nav.blockNear(x, z, untilT)
	local floorY = nav.floorY();
	if not floorY or not navBuild() then return 0; end;
	local op = OverlapParams.new();
	op.FilterType = Enum.RaycastFilterType.Exclude;
	op.FilterDescendantsInstances = { l.Character };
	local found = 0;
	for _, part in ipairs(workspace:GetPartBoundsInRadius(Vector3.new(x, floorY + 3, z), 3.5, op)) do
		if nav.isObstacle(part, floorY) and nav.blockPart(part, untilT) > 0 then found = found + 1; end;
	end;
	return found;
end;
-- shortest walk over the floor tiles from A to B, going around tiles marked blocked (pillars, walls)
local function navRoute(px, pz, gx, gz, now)
	if not navBuild() then return nil; end;
	local map, open = nav.map, nav.open;
	local scx, scz = navCellAt(px, pz);
	local gcx, gcz = navCellAt(gx, gz);
	if not (scx and gcx) then return nil; end;
	local startKey, goalKey = scx * 4096 + scz, gcx * 4096 + gcz;
	if not map[goalKey] then
		-- goal off the tile map: aim for the tile nearest to it
		local best, bd;
		for key, t in pairs(map) do
			local dd = (t.wx - gx) ^ 2 + (t.wz - gz) ^ 2;
			if not bd or dd < bd then best, bd = key, dd; end;
		end;
		goalKey = best;
	end;
	if not goalKey or not map[startKey] then return nil; end;
	local dist, prev, heap, seen = { [startKey] = 0 }, {}, {}, 0;
	nav.push(heap, 0, startKey);
	while true do
		local c, key = nav.pop(heap);
		if not key then break; end;
		seen = seen + 1;
		if key == goalKey or seen > 4000 then break; end;
		if c <= (dist[key] or math.huge) then
			local t = map[key];
			for _, dl in ipairs(nav.N8) do
				local k2 = (t.cx + dl[1]) * 4096 + t.cz + dl[2];
				local blocked = (nav.blocked[k2] or 0) > now;
				if map[k2] and not blocked then
					local step = (dl[1] ~= 0 and dl[2] ~= 0) and 1.42 or 1;
					if (open[k2] or 0) == 0 then step = step + 3; end;
					local nc = c + step;
					if nc < (dist[k2] or math.huge) then
						dist[k2], prev[k2] = nc, key;
						nav.push(heap, nc, k2);
					end;
				end;
			end;
		end;
	end;
	if not prev[goalKey] then return nil; end;
	local path, key = {}, goalKey;
	while key and key ~= startKey do
		local t = map[key];
		table.insert(path, 1, { x = t.wx, z = t.wz });
		key = prev[key];
	end;
	return path;
end;
r.navRoute = navRoute;
-- ROUTE TO A TARGET AROUND HAZARDS: over the floor tiles, skipping tiles inside attack zones, ending on the
-- first tile within `reach` of the target. ignoreFloor = also allow lingering ground hazards (burn strips),
-- used only when there's no fully safe way (so it doesn't freeze). Cached 0.5 s per target.
r.routeCache = {};
r.lavaOk = function()
	local hum = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
	return hum ~= nil and hum.MaxHealth > 5 and hum.Health / hum.MaxHealth >= .6;
end;
r.routeTo = function(mob, G, reach, ignoreFloor)
	if not (mob and mob.x and G) or not navBuild() then return nil; end;
	local now = d();
	local key = tostring(mob.addr) .. (ignoreFloor and ":f" or "");
	local c = r.routeCache[key];
	if c and now - c.t < .5 then return c.path; end;
	local map = nav.map;
	local function bad(t)
		if (nav.blocked[t.cx * 4096 + t.cz] or 0) > now then return true; end;
		for _, z in ipairs(Fl) do
			local sg = tostring(z.sig or "");
			local lingering = z.floor or sg:find("Burn", 1, true);
			if sg:sub(1, 11) ~= "projectile:" and not (ignoreFloor and lingering) and ul(z, t.wx, t.wz, .5) then return true; end;
		end;
		return false;
	end;
	local scx, scz = navCellAt(G.X, G.Z);
	local startKey = scx and (scx * 4096 + scz);
	if not (startKey and map[startKey]) then r.routeCache[key] = { t = now }; return nil; end;
	local dist, prev, heap, seen, goal = { [startKey] = 0 }, {}, {}, 0, nil;
	local badMemo = {};
	nav.push(heap, 0, startKey);
	while true do
		local cst, k = nav.pop(heap);
		if not k then break; end;
		seen = seen + 1;
		if seen > 5000 then break; end;
		local t = map[k];
		if (t.wx - mob.x) ^ 2 + (t.wz - mob.z) ^ 2 <= reach * reach then goal = k; break; end;
		if cst <= (dist[k] or math.huge) then
			for _, dl in ipairs(nav.N8) do
				local k2 = (t.cx + dl[1]) * 4096 + t.cz + dl[2];
				local t2 = map[k2];
				if t2 then
					if badMemo[k2] == nil then badMemo[k2] = bad(t2); end;
					if not badMemo[k2] then
						local nc = cst + ((dl[1] ~= 0 and dl[2] ~= 0) and 1.42 or 1);
						if nc < (dist[k2] or math.huge) then
							dist[k2], prev[k2] = nc, k;
							nav.push(heap, nc, k2);
						end;
					end;
				end;
			end;
		end;
	end;
	local path;
	if goal then
		path = {};
		local k = goal;
		while k and k ~= startKey do
			local t = map[k];
			table.insert(path, 1, { x = t.wx, z = t.wz });
			k = prev[k];
		end;
	end;
	r.routeCacheN = (r.routeCacheN or 0) + 1;
	if r.routeCacheN > 300 then r.routeCache, r.routeCacheN = {}, 0; end;
	r.routeCache[key] = { t = now, path = path };
	return path;
end;
-- ===================================================================================
-- ROOMS (v5.30). Delve is one straight shaft: its rows run along -Z (Shared/Grid.toWorld for the shaft
-- plate), chambers follow each other along those rows (Shared/Delve startOf/depthOf/bounds, a gate every
-- 5th chamber), and every floor tile is named Tile_<row>_<col> at exactly that row's spot, so the row of
-- any position is read straight off the tiles. The chamber you're in comes from the game's SessionSync
-- event, or from the depth label when it is exactly a chamber's last row x 10 m (4,760 m = chamber 30,
-- the Pale Warden; 9,060 m = 50, the Worldheart; 17,520 m = 90, the Unmaker). Forward = that chamber's
-- exit row (where the ChamberWall stands); once you're there, the next chamber's exit.
-- ===================================================================================
do
	local RM = { s = {}, sAt = -1e9 };
	r.room = RM;
	local CELL = 8;
	-- a copy of Shared/Delve's layout maths with the exported Config values (used if require() fails)
	local function port()
		local D = {};
		local function bossDepth(c)
			if c == 50 then return 22; end;
			if c > 50 and (c - 50) % 40 == 0 then return 22; end;
			if c == 30 then return 20; end;
			return nil;
		end;
		function D.depthOf(c)
			c = math.max(math.floor(c), 1);
			if c % 5 == 0 then return bossDepth(c) or 8; end;
			return math.min(5 + (c - 1), 24);
		end;
		local st = { 1 };
		function D.startOf(c)
			c = math.max(math.floor(c), 1);
			for n = #st, c - 1 do st[n + 1] = st[n] + D.depthOf(n); end;
			return st[c];
		end;
		function D.bounds(c)
			local a = D.startOf(c);
			return a, a + D.depthOf(c) - 1;
		end;
		function D.metresAt(c)
			local _, b = D.bounds(math.max(math.floor(c), 1));
			return b * 10;
		end;
		return D;
	end;
	local okD, Dv = pcall(function()
		local st = game:GetService("ReplicatedStorage"):FindFirstChild("Strata");
		local sh = st and st:FindFirstChild("Shared");
		local dm = sh and sh:FindFirstChild("Delve");
		return dm and require(dm) or nil;
	end);
	if okD and type(Dv) == "table" and type(Dv.bounds) == "function" and type(Dv.metresAt) == "function" then
		RM.D, RM.dsrc = Dv, "the game's Delve module";
	else
		RM.D, RM.dsrc = port(), "built-in copy of the layout";
	end;
	pcall(function()
		local st = game:GetService("ReplicatedStorage"):FindFirstChild("Strata");
		local cm = st and st:FindFirstChild("Config");
		local cfg = cm and require(cm);
		CELL = tonumber(cfg and cfg.Grid and cfg.Grid.CellSize) or CELL;
	end);
	-- (v5.39) gates: every 5th chamber that isn't a boss room (30 Pale Warden, 50 Worldheart, 90 Unmaker, ...)
	function RM.isGate(c)
		c = tonumber(c);
		if not c or c < 5 or c % 5 ~= 0 then return false; end;
		if c == 30 or c == 50 or (c > 50 and (c - 50) % 40 == 0) then return false; end;
		return true;
	end;
	function RM.inGate()
		if not run.isDelve then return false; end;
		return RM.isGate(RM.s.chamber) and d() - RM.sAt < 120;
	end;
	function RM.onSession(p)
		if type(p) ~= "table" then return; end;
		if p.active then
			local before;
			pcall(function() before = RM.front(); end);
			for k, v in pairs(p) do RM.s[k] = v; end;
			RM.sAt = d();
			local sp = tonumber(p.collapseSpeed) or 0;
			-- (v5.39) in a gate a change in the mobs left is logged too
			local sig = tostring(p.chamber) .. "|" .. string.format("%.2f", sp) .. "|" .. tostring(p.collapseFrom)
				.. (RM.isGate(p.chamber) and ("|" .. tostring(RM.s.mobsLeft)) or "");
			local fr;
			pcall(function() fr = RM.front(); end);
			local jump = before and fr and p.collapseX and math.abs(fr - before) > 3;
			if p.chamber ~= nil and (sig ~= RM.lastSig or jump) then
				RM.lastSig, RM.lastChamber = sig, p.chamber;
				local extra = "";
				pcall(function()
					local srv = (r.plan and r.plan.srv) and r.plan.srv() or workspace:GetServerTimeNow();
					local cf = tonumber(p.collapseFrom);
					if cf and cf > srv + .2 then extra = extra .. string.format(", starts in %.1f s", cf - srv); end;
					local hrp = l.Character and l.Character:FindFirstChild("HumanoidRootPart");
					local oz = RM.originZ();
					if hrp and oz and fr then
						local row = (oz - hrp.Position.Z) / CELL + 1;
						local secs = sp > 0 and (row - .5 - fr) / sp or nil;
						extra = extra .. string.format("; you at row %.0f, %.0f rows ahead of it%s", row, row - fr, secs and string.format(" (%.0f s)", secs) or "");
					end;
					local ce = tonumber(p.chamberEnds);
					if ce then extra = extra .. string.format("; chamber clock %.0f s", ce - srv); end;
					if RM.s.mobsLeft ~= nil then extra = extra .. "; mobs left " .. tostring(RM.s.mobsLeft); end;
				end);
				f(string.format("session: chamber %s%s%s%s", tostring(p.chamber),
					p.collapseX and string.format(", collapse front at row %.1f (+%.2f rows/s)", fr or tonumber(p.collapseX) or 0, sp) or "",
					jump and string.format(" [front moved %.1f rows from where it was expected]", fr - before) or "", extra));
			end;
		else
			RM.s, RM.lastChamber, RM.lastSig = {}, nil, nil;
		end;
	end;
	-- the plate's row-1 Z, averaged over a few tiles; nil if the tiles don't agree (not a shaft plate)
	function RM.originZ()
		local sp = workspace:FindFirstChild("StrataPlate");
		local gr = sp and sp:FindFirstChild("Ground");
		if not gr then RM.og = nil; return nil; end;
		local c = RM.og;
		if c and c.g == gr and c.z then return c.z; end;
		local sum, n, lo, hi = 0, 0, math.huge, -math.huge;
		for _, t in ipairs(gr:GetChildren()) do
			local row = tonumber((t.Name:match("^Tile_(%-?%d+)_")));
			if row and t:IsA("BasePart") then
				local oz = t.Position.Z + (row - 1) * CELL;
				sum, n = sum + oz, n + 1;
				lo, hi = math.min(lo, oz), math.max(hi, oz);
				if n >= 24 then break; end;
			end;
		end;
		if n < 3 or hi - lo > 1 then return nil; end;
		RM.og = { g = gr, z = sum / n };
		return RM.og.z;
	end;
	function RM.chamberFromDepth(m)
		m = tonumber(m);
		if not m or m <= 0 then return nil; end;
		RM.mc = RM.mc or {};
		local hit = RM.mc[m];
		if hit == nil then
			hit = false;
			for c = 1, 800 do
				local okM, mt = pcall(RM.D.metresAt, c);
				if not okM or type(mt) ~= "number" then break; end;
				if mt == m then hit = c; break; end;
				if mt > m then break; end;
			end;
			RM.mc[m] = hit;
		end;
		return hit or nil;
	end;
	-- chamber, where it came from, your row, the chamber's rows; nil + reason when it's uncertain
	function RM.current(pz)
		if not run.isDelve then return nil, "not in a Delve"; end;
		local oz = RM.originZ();
		if not oz then return nil, "no shaft floor tiles to read rows from"; end;
		local myRow = (oz - pz) / CELL + 1;
		local c, src;
		local sc = tonumber(RM.s.chamber);
		if sc and sc >= 1 then c, src = sc, "session sync"; end;
		if not c then
			c = RM.chamberFromDepth(run.curDepth);
			src = c and "depth label" or nil;
		end;
		if not c then return nil, "chamber unknown (depth " .. tostring(run.curDepth) .. " m isn't a chamber's end)"; end;
		local okB, a, b = pcall(RM.D.bounds, c);
		if not okB or type(a) ~= "number" then return nil, "no rows for chamber " .. tostring(c); end;
		if myRow < a - 4 or myRow > b + 4 then
			return nil, string.format("chamber %d (%s) is rows %d-%d but you're at row %.0f", c, src, a, b, myRow);
		end;
		return c, src, myRow, a, b, oz;
	end;
	function RM.goal(px, pz)
		local c, src, myRow, a, b, oz = RM.current(pz);
		if not c then return nil, src; end;
		local goalRow, why = b, "exit";
		if myRow >= b - .5 then
			local okN, _, b2 = pcall(RM.D.bounds, c + 1);
			if okN and type(b2) == "number" then goalRow, why = b2, "next chamber's exit"; end;
		end;
		return oz - (goalRow - 1) * CELL, goalRow, c, src, myRow, why;
	end;
	-- (v5.39) GATE WATCH: 13 of 34 runs on 2026-11-14 caved in at a gate, 10 of them at chambers 55 and 65. The gate's clock ran
	-- out with the bot 15-20 rows short of the gate's end, and nothing was logged in the last 10-20 s. While in a
	-- gate: a line when what it sees or does changes (at most every 3 s), and a room dump (DelveRoomDump_gate.txt)
	-- when the gate's clock is nearly out, once per run. Nothing here changes what it does.
	function RM.gateNote(G, S, m)
		if not RM.inGate() then return; end;
		local s0 = RM.s;
		local srv = (r.plan and r.plan.srv) and r.plan.srv() or workspace:GetServerTimeNow();
		local clock = tonumber(s0.chamberEnds) and (tonumber(s0.chamberEnds) - srv) or nil;
		if clock and clock < 4 and clock > -3 and r.roomDump then
			local dk = tostring(r.cycleKey and r.cycleKey() or "") .. "|" .. tostring(s0.chamber);
			if RM.gateDumped ~= dk then
				RM.gateDumped = dk;
				task.spawn(function()
					pcall(r.roomDump, string.format("gate %s clock %.1f s, %s mobs left (game), %d seen, last step: %s", tostring(s0.chamber), clock,
						tostring(s0.mobsLeft or "?"), #S, tostring(r.lhBranch)), "DelveRoomDump_gate.txt");
				end);
			end;
		end;
		if not r.why then return; end;
		local key = tostring(s0.chamber) .. "|" .. tostring(s0.mobsLeft) .. "|" .. tostring(#S) .. "|" .. tostring(WQ) .. "|" .. tostring(r.lhBranch);
		if m - (RM.gateAt or -1e9) < 3 or (key == RM.gateKey and m - (RM.gateAt or -1e9) < 8) then return; end;
		RM.gateKey, RM.gateAt = key, m;
		local oz = RM.originZ();
		local row = oz and ((oz - G.Z) / CELL + 1) or nil;
		local fr, spd = RM.front();
		local okF, fx, _, _, _, gp, fsrc = pcall(r.forwardInfo, G.X, G.Z);
		r.why("gate", string.format("gate %s: %s mobs left (game), %d seen; clock %s; %s; you at row %s; doing: %s, %s%s",
			tostring(s0.chamber), tostring(s0.mobsLeft or "?"), #S, clock and string.format("%.0f s", clock) or "?",
			(fr and row) and string.format("collapse %.0f rows behind (+%.2f/s)", row - fr, spd or 0) or "collapse ?",
			row and string.format("%.0f", row) or "?", tostring(WQ), tostring(r.lhBranch or "?"),
			(okF and fx) and string.format("; forward goal: %s, %.0f st", tostring(fsrc), tonumber(gp) or 0) or "; no forward goal"));
	end;
	-- the collapse front in rows, on the game's clock (PlateRenderer._collapseStep)
	function RM.front()
		local s0 = RM.s;
		local x0 = tonumber(s0.collapseX);
		if not x0 then return nil; end;
		local spd = tonumber(s0.collapseSpeed) or 0;
		local t0 = math.max(tonumber(s0.collapseAt) or 0, tonumber(s0.collapseFrom) or 0);
		local now = r.plan and r.plan.srv() or os.clock();
		return x0 + spd * math.max(now - t0, 0), spd;
	end;
	-- seconds until the floor at world Z falls (rows below the front fall); nil without SessionSync data
	function RM.secondsUntilFalls(z)
		local fr, spd = RM.front();
		local oz = RM.originZ();
		if not (fr and oz) then return nil; end;
		if not spd or spd <= 0 then return math.huge; end;
		local row = (oz - z) / CELL + 1;
		return (row - .5 - fr) / spd;
	end;
	-- Settings button: one line per signal, so a test can see what picked the destination
	function RM.report()
		local hrp = l.Character and l.Character:FindFirstChild("HumanoidRootPart");
		if not hrp then notify("No character yet.", "Delve"); return; end;
		local px, pz = hrp.Position.X, hrp.Position.Z;
		local c, src, myRow, a, b = RM.current(pz);
		local okF, fx, fz, gx, gz, gp, fsrc = pcall(r.forwardInfo, px, pz);
		local fr, spd = RM.front();
		local Pq = r.plan;
		local lines = {
			c and string.format("chamber %d (%s), rows %d-%d, you at row %.1f", c, src, a, b, myRow) or ("chamber: uncertain, " .. tostring(src)),
			(okF and fx) and string.format("forward goal: %s, %.0f st (heading %.2f, %.2f)", tostring(fsrc), gp or 0, fx, fz) or "forward goal: none (no signal: it keeps mining)",
			fr and string.format("collapse front at row %.1f (%.2f rows/s)%s", fr, spd, myRow and string.format(", %.1f rows behind you", myRow - fr) or "") or "collapse front: no SessionSync data yet",
			Pq and string.format("attack plans: feed %s, %d planned, %d shots, %d plans so far, %d server dodges", Pq.hooked and "on" or "off", #Pq.hz, #Pq.shots, Pq.plans, Pq.dodged or 0) or "attack plans: module missing",
			"layout from " .. tostring(RM.dsrc),
		};
		for _, ln in ipairs(lines) do if r.why then r.why("move", "[check] " .. ln); end; end;
		notify(table.concat(lines, "\n"), "Delve forward check");
	end;
end;
-- FORWARD (up the tunnel). Two signals, both about where you've been, never about the shape of the map:
--   1. away from the tiles that collapsed in the last 20 s (the collapse is always behind you)
--   2. the way the depth has been going up: from an earlier depth mark to the newest (gates)
-- v5.28 used the middle of all loaded tiles, which lies behind you when old segments are still loaded,
-- and sent it running back into the cave-in. No signal = no push (it just keeps mining).
r.forwardInfoRaw = function(px, pz)
	local haveMap = navBuild() and nav.map ~= nil;
	-- 0. (v5.30) the chamber layout: a safe tile at the current chamber's exit row (never past it), only when
	--    the chamber and your row agree. Otherwise the signals below (collapse, depth marks, learned direction).
	if haveMap then
		local okR, gzR, rowR, cR, srcR, myRow, why = pcall(function() return r.room.goal(px, pz); end);
		if okR and gzR then
			local fzR = gzR < pz and -1 or 1;
			local best, bs;
			for _, t in pairs(nav.map) do
				if (t.wz - gzR) * fzR <= 2 and not eh(Fl, t.wx, t.wz) then
					local sc = math.abs(t.wz - gzR) * 3 + math.abs(t.wx - px) * .5;
					if not bs or sc < bs then best, bs = t, sc; end;
				end;
			end;
			if best then
				-- (v5.33) signed: past the last floor tile the goal tile is behind you, and it used to walk back to it
				return 0, fzR, best.wx, best.wz, (best.wz - pz) * fzR,
					string.format("chamber %d %s, row %d (%s; you're at row %.0f)", cR, why, rowR, srcR, myRow);
			end;
		end;
	end;
	local now = os.clock();
	local fx, fz, src;
	local gx, gz, gn = 0, 0, 0;
	if type(r.gone) == "table" then
		for _, e in ipairs(r.gone) do
			if now - e.t < 20 then gx, gz, gn = gx + e.x, gz + e.z, gn + 1; end;
		end;
	end;
	if gn >= 3 then
		local dx, dz = px - gx / gn, pz - gz / gn;
		local dl = math.sqrt(dx * dx + dz * dz);
		if dl >= 4 then fx, fz, src = dx / dl, dz / dl, "away from the collapse"; end;
	end;
	local mk = r.depthMarks;
	if not fx and type(mk) == "table" and #mk >= 2 then
		local newest = mk[#mk];
		if now - newest.t < 240 then
			for k = #mk - 1, 1, -1 do
				local c = mk[k];
				local dx, dz = newest.x - c.x, newest.z - c.z;
				local dl = math.sqrt(dx * dx + dz * dz);
				if dl >= 8 then fx, fz, src = dx / dl, dz / dl, "the way the depth goes up"; break; end;
			end;
		end;
	end;
	if not fx then
		local td = type(brain.tunnelDir) == "table" and brain.tunnelDir or nil;
		if td and tonumber(td.x) and tonumber(td.z) and (tonumber(td.n) or 0) >= 3 then
			fx, fz, src = td.x, td.z, "the road's learned direction";
		end;
	end;
	if not fx then return nil; end;
	-- (v5.33) no floor map (tiles not loaded, or a room that isn't built from shaft tiles): a point 30 st that
	-- way; the walk checks the floor at every step. Before, no map meant no forward signal at all.
	if not haveMap then return fx, fz, px + fx * 30, pz + fz * 30, 30, src .. ", no floor map"; end;
	-- farthest safe tile that way, staying in the corridor (not a side pocket)
	local best, bp;
	for _, t in pairs(nav.map) do
		local ox, oz = t.wx - px, t.wz - pz;
		local pr = ox * fx + oz * fz;
		local side = math.abs(ox * fz - oz * fx);
		if side < 40 and (not bp or pr > bp) and not eh(Fl, t.wx, t.wz) then best, bp = t, pr; end;
	end;
	return fx, fz, best and best.wx, best and best.wz, bp, src;
end;
r.forwardInfo = function(px, pz)
	local fc = r.fwdCache;
	local nowC = os.clock();
	if fc and nowC - fc.t < .4 and (fc.px - px) ^ 2 + (fc.pz - pz) ^ 2 < 9 then
		return fc[1], fc[2], fc[3], fc[4], fc[5], fc[6];
	end;
	local a1, a2, a3, a4, a5, a6 = r.forwardInfoRaw(px, pz);
	r.fwdCache = { a1, a2, a3, a4, a5, a6, t = nowC, px = px, pz = pz };
	return a1, a2, a3, a4, a5, a6;
end;
r.steerDir = function(pos, tx, tz)
	local now = d();
	local dx, dz = tx - pos.X, tz - pos.Z;
	r.steerGoal = { x = tx, z = tz, t = now };
	local len = math.sqrt(dx * dx + dz * dz);
	if len < 1.5 or not navBuild() then return dx, dz; end;
	local hit = false;
	local step = nav.cell * .5;
	for k = step, len, step do
		local cx, cz = navCellAt(pos.X + dx / len * k, pos.Z + dz / len * k);
		if cx and ((nav.blocked[cx * 4096 + cz] or 0) > now or (nav.map and not nav.map[cx * 4096 + cz])) then hit = true; break; end;
	end;
	if not hit then r.steerPath = nil; return dx, dz; end;
	local sp = r.steerPath;
	if not sp or math.abs(sp.tx - tx) > 1 or math.abs(sp.tz - tz) > 1 or now - sp.at > 1.5 then
		sp = { tx = tx, tz = tz, at = now, path = navRoute(pos.X, pos.Z, tx, tz, now), i = 1 };
		r.steerPath = sp;
	end;
	if not sp.path then return dx, dz; end;
	local wp = sp.path[sp.i];
	while wp and (wp.x - pos.X) ^ 2 + (wp.z - pos.Z) ^ 2 < 2.25 do
		sp.i = sp.i + 1;
		wp = sp.path[sp.i];
	end;
	if not wp then return dx, dz; end;
	return wp.x - pos.X, wp.z - pos.Z;
end;
local function navEscape(px, pz, zones, now)
	if CFG.smartEscape == false or not navBuild() then return nil; end;
	local map, open, cell = nav.map, nav.open, nav.cell;
	local scx, scz = navCellAt(px, pz);
	if not scx then return nil; end;
	local startKey = scx * 4096 + scz;
	if not map[startKey] then
		local bestD;
		for key, t in pairs(map) do
			local dd = (t.wx - px) ^ 2 + (t.wz - pz) ^ 2;
			if not bestD or dd < bestD then startKey, bestD = key, dd; end;
		end;
		if not bestD then return nil; end;
	end;
	-- only zones that can matter
	local near = {};
	for _, z in ipairs(zones) do
		local reach = math.max(z.h1, z.h2) + 70;
		if not z.plan and (z.x - px) ^ 2 + (z.z - pz) ^ 2 < reach * reach then near[#near + 1] = z; end;
	end;
	-- (v5.30) planned attacks are checked at the time you'd reach each tile (walk speed), and the tile you
	-- stop on has to stay clear for 2.2 s after you get there. Arriving after a slab lands is fine; being
	-- there when it lands is not. (v5.33: was 1.2 s. The Worldheart's donut was announced 3 s ahead, the spot
	-- it stood on counted as safe until 1.2 s before it landed, and walking out of a ring that size took
	-- longer than that: escape picked 0.02 s before the hit, dead.)
	local Pq = r.plan;
	local usePlan = Pq ~= nil and Pq.hooked == true and CFG.planFeed ~= false and (#Pq.hz + #Pq.shots) > 0;
	local srv0 = usePlan and Pq.srv() or 0;
	local humW = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
	local wsp = math.max(6, humW and humW.WalkSpeed or 16);
	local distS, pdMemo = {}, {};
	local function planDanger(key, studs, stay)
		if not usePlan then return 0; end;
		local ta = srv0 + studs / wsp + .05;
		local mk = key * 64 + (math.floor(ta * 4) % 32) * 2 + (stay and 1 or 0);
		local v = pdMemo[mk];
		if v == nil then
			local t = map[key];
			v = Pq.hitAt(t.wx, t.wz, ta - .15, ta + (stay and 2.2 or .25)) and 4 or 0;
			pdMemo[mk] = v;
		end;
		return v;
	end;
	-- rocks block movement: tiles under ores are expensive
	local rockCells = {};
	for _, rock in pairs(D) do
		if rock.cx and rock.cz then
			for ox = -0.5, .5, 1 do
				for oz = -0.5, .5, 1 do
					rockCells[math.floor(rock.cx + ox + .5) * 4096 + math.floor(rock.cz + oz + .5)] = true;
				end;
			end;
		end;
	end;
	local margin = Vl + .5 + cell * .35;
	local dangerCache = {};
	local humE = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
	local lavaCost = (humE and humE.MaxHealth <= 5) and 200 or 20;
	local function danger(key)
		local v = dangerCache[key];
		if v == nil then
			v = 0;
			local t = map[key];
			for _, z in ipairs(near) do
				local depth = ul(z, t.wx, t.wz, margin);
				if depth then
					-- burning floor (the orange lava tiles) ticks damage the whole time you're on it
					local lava = z.floor or tostring(z.sig or ""):find("Burn", 1, true);
					v = v + depth + 1 + (lava and lavaCost or 0);
				end;
			end;
			dangerCache[key] = v;
		end;
		return v;
	end;
	local edgeSafe = tonumber(CFG.edgeSafe) or 6;
	local cornerOn = CFG.cornerAvoid ~= false;
	local dist, prev, heap = { [startKey] = 0 }, {}, {};
	distS[startKey] = 0;
	nav.push(heap, 0, startKey);
	local best, bestScore, fallback, fallbackScore = nil, nil, nil, nil;
	local pops = 0;
	while true do
		local c, key = nav.pop(heap);
		if not c then break; end;
		pops = pops + 1;
		if pops > 2500 then break; end;
		if c <= (dist[key] or math.huge) + 1e-6 then
			if bestScore and c > bestScore then break; end;
			local t = map[key];
			local dg = danger(key) + planDanger(key, distS[key] or 0, true);
			local studsOpen = ((open[key] or 0) + .5) * cell;
			local edgeCost = cornerOn and math.max(0, edgeSafe - studsOpen) * 2.5 or 0;
			if dg == 0 and not rockCells[key] then
				local score = c + edgeCost;
				if not bestScore or score < bestScore then best, bestScore = key, score; end;
			end;
			local fs = dg * 12 + c * .25 + edgeCost;
			if not fallbackScore or fs < fallbackScore then fallback, fallbackScore = key, fs; end;
			for _, dl in ipairs(nav.N8) do
				local nx, nz = t.cx + dl[1], t.cz + dl[2];
				local k2 = nx * 4096 + nz;
				if map[k2] then
					local diag = dl[1] ~= 0 and dl[2] ~= 0;
					-- no corner cutting over the void
					if not diag or (map[(t.cx + dl[1]) * 4096 + t.cz] and map[t.cx * 4096 + t.cz + dl[2]]) then
						local blockedUntil = nav.blocked[k2];
						if not (blockedUntil and blockedUntil > now) then
							local step = (diag and 1.4142 or 1) * cell;
							local dS = (distS[key] or 0) + step;
							local cost = c + step + (danger(k2) + planDanger(k2, dS)) * cell * 3 + (rockCells[k2] and cell * 3 or 0);
							if cost < (dist[k2] or math.huge) then
								dist[k2], prev[k2] = cost, key;
								distS[k2] = dS;
								nav.push(heap, cost, k2);
							end;
						end;
					end;
				end;
			end;
		end;
	end;
	local goal = best or fallback;
	if not goal then return nil; end;
	local path = {};
	local k = goal;
	while k do
		table.insert(path, 1, k);
		k = prev[k];
	end;
	local startDanger = danger(startKey);
	-- walk straight to the farthest path tile we can reach without crossing the void or deeper danger
	local function lineClear(t)
		local dx, dz = t.wx - px, t.wz - pz;
		local len = math.sqrt(dx * dx + dz * dz);
		local steps = math.max(1, math.ceil(len / (cell * .5)));
		for s = 1, steps do
			local f2 = s / steps;
			local sx, sz = px + dx * f2, pz + dz * f2;
			if not pQ(sx, sz) then return false; end;
			if usePlan then
				local ta = srv0 + (len * f2) / wsp + .05;
				if Pq.hitAt(sx, sz, ta - .15, ta + .2) then return false; end;
			end;
			local scx2, scz2 = navCellAt(sx, sz);
			local k2 = scx2 and (scx2 * 4096 + scz2);
			if k2 and map[k2] and (danger(k2) > startDanger + .01 or rockCells[k2]) then return false; end;
		end;
		return true;
	end;
	local wp = map[path[math.min(#path, 2)]];
	for j = math.min(#path, 14), 2, -1 do
		local t = map[path[j]];
		if lineClear(t) then wp = t; break; end;
	end;
	local gt = map[goal];
	r.escInfo = { t = d(), safe = best ~= nil, len = #path, plan = usePlan };
	return { x = wp.wx, z = wp.wz, gx = gt.wx, gz = gt.wz, t = now, safe = best ~= nil, len = #path };
end;
-- OPEN GROUND (maps without a tile floor, like the Arena): look at points around you every 4 studs
-- (36 st radius), keep the ones that are real floor (a short ray down hits ground, not a wall), outside every
-- attack zone, and not hemmed in by walls; take the one that's quickest to reach and keeps you off the edges.
r.floorCache, r.floorCacheN = {}, 0;
local function openGround(px, pz, now)
	local hrp = l.Character and l.Character:FindFirstChild("HumanoidRootPart");
	if not hrp then return nil; end;
	local y = hrp.Position.Y;
	local rp = RaycastParams.new();
	rp.FilterType = Enum.RaycastFilterType.Exclude;
	rp.FilterDescendantsInstances = { l.Character };
	local function floorAt(x, z)
		local key = math.floor(x / 2) * 100000 + math.floor(z / 2);
		local c = r.floorCache[key];
		if c ~= nil then return c; end;
		local hit = workspace:Raycast(Vector3.new(x, y + 6, z), Vector3.new(0, -14, 0), rp);
		local ok = hit ~= nil and hit.Position.Y < y - .5 and hit.Position.Y > y - 7;
		r.floorCacheN = r.floorCacheN + 1;
		if r.floorCacheN > 6000 then r.floorCache, r.floorCacheN = {}, 0; end;
		r.floorCache[key] = ok;
		return ok;
	end;
	-- keep the open spot picked a moment ago while it's still safe
	local et0 = r.escTarget;
	if et0 and not et0.flank and not et0.covered and now - et0.t < 1.5 and not eh(Fl, et0.x, et0.z)
		and (et0.x - px) ^ 2 + (et0.z - pz) ^ 2 < 36 * 36 then
		return { x = et0.x, z = et0.z, t = et0.t, gx = et0.x, gz = et0.z };
	end;
	local Pq = r.plan;
	local usePlan = Pq ~= nil and Pq.hooked == true and CFG.planFeed ~= false and (#Pq.hz + #Pq.shots) > 0;
	local srv0 = usePlan and Pq.srv() or 0;
	local humW = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
	local wsp = math.max(6, humW and humW.WalkSpeed or 16);
	local function blockedAt(x, z, ta, stay)
		for _, zz in ipairs(Fl) do
			if not zz.plan and ul(zz, x, z, Vl + .5) then return true; end;
		end;
		return usePlan and Pq.hitAt(x, z, ta - .15, ta + stay) ~= nil;
	end;
	local best, bestScore, leastBad, leastScore;
	for gx = -36, 36, 4 do
		for gz = -36, 36, 4 do
			local dist = math.sqrt(gx * gx + gz * gz);
			if dist <= 36 and dist >= 3 then
				local cx, cz = px + gx, pz + gz;
				if floorAt(cx, cz) then
					local hits = 0;
					for _, z in ipairs(Fl) do
						if not z.plan and ul(z, cx, cz, Vl + .5) then hits = hits + 1; end;
					end;
					if usePlan and Pq.hitAt(cx, cz, srv0 + dist / wsp - .1, srv0 + dist / wsp + 2.2) then hits = hits + 1; end;
					-- walls/void around it (corners score worst)
					local edge = 0;
					for _, dv in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { .7, .7 }, { -.7, .7 }, { .7, -.7 }, { -.7, -.7 } }) do
						if not floorAt(cx + dv[1] * 6, cz + dv[2] * 6) then edge = edge + 1; end;
					end;
					-- attack zones crossed on the way there
					local cross = 0;
					for k = 1, 3 do
						local f2 = k / 4;
						if blockedAt(px + gx * f2, pz + gz * f2, srv0 + dist * f2 / wsp, .2) then cross = cross + 1; end;
					end;
					local score = dist + edge * 6 + cross * 8;
					if hits == 0 then
						if not bestScore or score < bestScore then best, bestScore = { cx, cz }, score; end;
					else
						-- whole-map attacks: remember the spot covered by the fewest zones
						local s2 = score + hits * 25;
						if not leastScore or s2 < leastScore then leastBad, leastScore = { cx, cz }, s2; end;
					end;
				end;
			end;
		end;
	end;
	local pick = best or leastBad;
	if not pick then return nil; end;
	r.escTarget = { x = pick[1], z = pick[2], t = now, covered = best == nil };
	return { x = pick[1], z = pick[2], t = now, gx = pick[1], gz = pick[2] };
end;
-- FLANK: in a fight, the best way out of an attack is often past the enemy, behind or beside it, where
-- the attack isn't and your weapon still reaches. Before, it backed out to the far side of the zone and
-- stood waiting for the attack to end, out of range. Candidates are behind the target (the side away
-- from the attack) and 45/90 degrees around it, at about 80% of weapon reach; the closest safe one wins.
local function flankSpot(px, pz, now)
	if WQ ~= "combat" or not xQ then return nil; end;
	local t = el[xQ];
	if not (t and t.x) then return nil; end;
	local tdx, tdz = t.x - px, t.z - pz;
	local tdist = math.sqrt(tdx * tdx + tdz * tdz);
	if tdist > 20 then return nil; end;
	-- keep the flank spot picked a moment ago while it's still safe and still next to the enemy
	local et0 = r.escTarget;
	if et0 and et0.flank and now - et0.t < 1.5 and not eh(Fl, et0.x, et0.z) and (et0.x - t.x) ^ 2 + (et0.z - t.z) ^ 2 < 144 then
		return { x = et0.x, z = et0.z, t = et0.t, gx = et0.x, gz = et0.z };
	end;
	-- the attack we're standing in (or about to be): its centre tells which side of the enemy is dangerous
	local zc;
	for _, z in ipairs(Fl) do
		if ul(z, px, pz, Vl + .5) then zc = z; break; end;
	end;
	if not zc then return nil; end;
	local ax, az = t.x - zc.x, t.z - zc.z;
	local al = math.sqrt(ax * ax + az * az);
	if al < .5 then ax, az, al = tdx, tdz, math.max(tdist, .1); end; -- zone centred on the enemy: go through to the far side
	ax, az = ax / al, az / al;
	local reach = math.max(3, math.min(10, YQ() * .8));
	local hrp = l.Character and l.Character:FindFirstChild("HumanoidRootPart");
	local best, bd;
	for _, ang in ipairs({ 0, .785, -.785, 1.571, -1.571 }) do
		local ca, sa = math.cos(ang), math.sin(ang);
		local dx, dz = ax * ca - az * sa, ax * sa + az * ca;
		local cx, cz = t.x + dx * reach, t.z + dz * reach;
		if not eh(Fl, cx, cz) then
			local floorOk;
			if nav.map then
				floorOk = navOpenAt(cx, cz) >= 1;
			elseif hrp then
				local rp = RaycastParams.new();
				rp.FilterType = Enum.RaycastFilterType.Exclude;
				rp.FilterDescendantsInstances = { l.Character };
				local hit = workspace:Raycast(Vector3.new(cx, hrp.Position.Y + 6, cz), Vector3.new(0, -14, 0), rp);
				floorOk = hit ~= nil and hit.Position.Y < hrp.Position.Y - .5 and hit.Position.Y > hrp.Position.Y - 7;
			end;
			if floorOk then
				local dd = math.sqrt((cx - px) ^ 2 + (cz - pz) ^ 2);
				if dd <= 16 and (not bd or dd < bd) then best, bd = { cx, cz }, dd; end;
			end;
		end;
	end;
	if not best then return nil; end;
	r.escTarget = { x = best[1], z = best[2], t = now, flank = true };
	if r.why and now - (r.flankNoteAt or 0) > 6 then
		r.flankNoteAt = now;
		r.why("combat", string.format("dodging past %s to stay in reach (%.0f st move)", tostring(t.name), bd));
	end;
	return { x = best[1], z = best[2], t = now, gx = best[1], gz = best[2] };
end;
local function Nh(m, G, r)
	-- stick with the chosen spot (it was re-chosen 4 times a second, so the character zig-zagged)
	if Qh and (r - Qh.t < 1.2 and not eh(Fl, Qh.gx or Qh.x, Qh.gz or Qh.z)) then
		if not Qh.gx or (Qh.x - m) ^ 2 + (Qh.z - G) ^ 2 > (nav.cell * .6) ^ 2 then
			return Qh;
		end;
	end;
	-- fighting: try to get out past the enemy (keeps hitting it) before backing off
	if CFG.flankDodge ~= false then
		local okF, fs = pcall(flankSpot, m, G, r);
		if okF and fs then
			Qh = fs;
			return Qh;
		end;
	end;
	local esc = navEscape(m, G, Fl, r);
	if esc then
		Qh = esc;
		return Qh;
	end;
	-- no tile map here (Arena), or the tile planner found nothing: scan the real floor for open ground
	do
		local okO, og = pcall(openGround, m, G, r); -- (r is the time inside Nh)
		if okO and og then
			Qh = og;
			return Qh;
		end;
	end;
	local Q = {};
	for r, e in ipairs(Fl) do
		local N = math.max(e.h1, e.h2) + 30;
		if ((e.x - m)) ^ 2 + ((e.z - G)) ^ 2 < N * N then
			Q[#Q + 1] = e;
		end;
	end;
	local e = {};
	for r, N in ipairs(Gh) do
		for r = 0, rh - 1, 1 do
			local S = (((r / rh)) * math.pi) * 2;
			local w, q = m + math.cos(S) * N, G + math.sin(S) * N;
			if pQ(w, q) and not eh(Q, w, q) then
				e[#e + 1] = { x = w, z = q, d = N };
			end;
		end;
		if #e >= 12 then
			break;
		end;
	end;
	local N, S = nil, nil;
	for r, e in ipairs(e) do
		local w = 0;
		local q = math.max(1, math.floor(e.d / 1.5));
		for r = 1, q - 1, 1 do
			local N = r / q;
			if eh(Q, m + ((e.x - m)) * N, G + ((e.z - G)) * N) then
				w = w + 1;
			end;
		end;
		local l = e.d + w * 5;
		if not S or l < S then
			N, S = e, l;
		end;
	end;
	Qh = N and { x = N.x, z = N.z, t = r } or nil;
	return Qh;
end;
local Sh, wh = 1, 0;
local function qh(m, G, e, N)
	local S = Kl(G, N);
	local w = YQ();
	local q, l = m.X - S.X, m.Z - S.Z;
	local d = math.sqrt(q * q + l * l);
	if d < .001 then
		q, l, d = k, T, 1;
	end;
	local z, c = ((-l / d)) * Sh, ((q / d)) * Sh;
	local x = {};
	for m, r in ipairs(e) do
		if r ~= G then
			x[#x + 1] = Kl(r, N);
		end;
	end;
	local function W(m, G)
		local r = 0;
		for Q, e in ipairs(x) do
			if ((e.X - m)) ^ 2 + ((e.Z - G)) ^ 2 < 12.25 then
				r = r + 1;
			end;
		end;
		return r;
	end;
	local K = Q.dodge;
	if K and eh(Fl, m.X, m.Z) then
		local G = Nh(m.X, m.Z, N);
		if G then
			if not r.dodging then
				f(string.format("escape to open ground (combat) %.1f studs away, zones=%d", math.sqrt(((G.x - m.X)) ^ 2 + ((G.z - m.Z)) ^ 2), #Fl));
			end;
			r.dodging, r.lastDodgeAt = true, N; -- (d is a distance in here; N is the time)
			SQ(G.x - m.X, G.z - m.Z);
			return;
		end;
	end;
	local o = tQ();
	local F = K and PQ(m.X, m.Z) or 0;
	local j = nil;
	local R = F > 0 and 0 or 1;
	-- corner avoidance: being near the map edge is penalised (much more while attacks are on the floor),
	-- so the orbit swings to the open side of a boss instead of getting pinned in a corner
	local cornerW = 0;
	if CFG.cornerAvoid ~= false then
		cornerW = (#Fl > 0) and 3 or .6;
	end;
	local edgeSafe = tonumber(CFG.edgeSafe) or 6;
	local function edgePen(x, z)
		if cornerW == 0 then return 0; end;
		return math.max(0, edgeSafe - navOpenAt(x, z)) * cornerW;
	end;
	local C = ((((F * 24 + (math.abs(d - w) * .8) * R)) + .4)) + W(m.X, m.Z) * 1.5 + edgePen(m.X, m.Z);
	for G, r in ipairs(o) do
		local Q, e = m.X + r[1] * 2.5, m.Z + r[2] * 2.5;
		local N, q = m.X + r[1] * 5, m.Z + r[2] * 5;
		local l = K and ((PQ(Q, e) + PQ(N, q)) + PQ(m.X + r[1] * 7.5, m.Z + r[2] * 7.5)) or 0;
		local d = math.sqrt(((N - S.X)) ^ 2 + ((q - S.Z)) ^ 2);
		local f = ((((((l * 8 + HQ(m, r) * 40)) + (math.abs(d - w) * .8) * R)) - (((r[1] * z + r[2] * c)) * 1.2) * R)) + W(N, q) * 1.5 + edgePen(N, q);
		if f < C then
			j, C = r, f;
		end;
	end;
	-- already at the right distance with nothing to dodge: stand and swing (no wasted orbiting)
	if j and F == 0 and #Fl == 0 and math.abs(d - w) < 1.2 then
		j = nil;
	end;
	if j and ((j[1] * z + j[2] * c < -0.3 and N - wh > 1.5)) then
		Sh = -Sh;
		wh = N;
	end;
	if F > 0 and not r.dodging then
		f(string.format("dodge start (combat) zones=%d danger=%.1f dir=%s", #Fl, F, j and string.format("%.2f,%.2f", j[1], j[2]) or "stay"));
	end;
	r.dodging = F > 0;
	if j then
		SQ(j[1], j[2]);
	else
		SQ(nil);
	end;
end;
-- ===================================================================================
-- TARGET PRIORITY ("Smart"): ores first, fight when it matters
--   fight when: boss stage / boss on the field, the stage is a mob stage, no ores left,
--   a mob is inside the learned threat radius (it's hitting you anyway), or you're swarmed.
--   at low HP it stops chasing normal mobs and keeps mining/dodging instead.
--   The threat radius is learned: mobs hitting you while you mine push it out, quiet mining pulls it in.
-- ===================================================================================
-- BOSS STUDY (live): measures how fast the boss actually loses HP while you hit it, compared with
-- your normal damage on other mobs. If the boss is tanky and there are other things on the field
-- (Worldheart + Heart Pylons), it goes for those first, and learns which of them make the boss
-- vulnerable: a kill that makes boss damage jump is remembered for that boss in every later run.
local bossStudy = { at = -1e9, notes = {} };
function bossStudy.rateOf(hist)
	local h1, h2 = hist[1], hist[#hist];
	if not (h1 and h2) or h2.t - h1.t < 1.5 then return nil; end;
	local on = 0;
	for _, h in ipairs(hist) do if h.on then on = on + 1; end; end;
	if on < #hist * .5 then return nil; end;
	return math.max(0, (h1.hp - h2.hp) / (h2.t - h1.t));
end;
function bossStudy.tick(list, pos, now)
	if now - bossStudy.at < .4 or not pos then return; end;
	bossStudy.at = now;
	brain.bossAdds = type(brain.bossAdds) == "table" and brain.bossAdds or {};
	local boss, near = nil, {};
	for _, mob in ipairs(list) do
		local mx = tonumber(mob.max) or 0;
		if mob.boss and (not boss or mx > (tonumber(boss.max) or 0)) then boss = mob; end;
	end;
	if not boss and run.bossNow then
		for _, mob in ipairs(list) do
			if not boss or (tonumber(mob.max) or 0) > (tonumber(boss.max) or 0) then boss = mob; end;
		end;
	end;
	-- your normal damage rate: HP lost per second by whatever non-boss mob you're hitting
	local tg = bossStudy.tgt;
	for _, mob in ipairs(list) do
		if mob.addr == xQ and mob ~= boss and tonumber(mob.hp) then
			if not tg or tg.addr ~= mob.addr then
				-- new target: its "no hits yet" clock starts now (it used to carry over from the last target,
				-- so almost every target switch was logged as "hits not landing")
				tg = { addr = mob.addr, hist = {} };
				bossStudy.tgt = tg;
				r.noHitSince = now;
			end;
			local dd = math.sqrt((mob.x - pos.X) ^ 2 + (mob.z - pos.Z) ^ 2);
			tg.hist[#tg.hist + 1] = { t = now, hp = tonumber(mob.hp), on = dd <= (tonumber(CFG.fightDist) or 8) + 4 };
			while #tg.hist > 0 and now - tg.hist[1].t > 4 do table.remove(tg.hist, 1); end;
			local rt = bossStudy.rateOf(tg.hist);
			if rt and rt > 0 then brain.dmgRate = (tonumber(brain.dmgRate) or rt) * .9 + rt * .1; end;
			-- LIVE SWORD RANGE: the farthest distance your hits really land at (relics/gear change it)
			local n2 = #tg.hist;
			local prevH = n2 >= 2 and tg.hist[n2 - 1] or nil;
			-- damage from procs/flames/lightning can land anywhere: only count hits within believable sword reach
			local plausible = math.min(20, ((r.range or r.swordLearnedRange or tonumber(CFG.fightDist) or 8)) * 1.5);
			if prevH and tg.hist[n2].hp < prevH.hp - .5 and dd <= plausible then
				r.liveHitMax = math.min(20, math.max((tonumber(r.liveHitMax) or dd) * .995, dd));
				r.noHitSince = now;
				r.orbitShrink = math.max(0, (tonumber(r.orbitShrink) or 0) - .1);
				brain.swordHit = type(brain.swordHit) == "table" and brain.swordHit or {};
				brain.swordHit[tostring(brain.player and brain.player.sword or "?")] = r.liveHitMax;
			elseif WQ == "combat" and dd <= (tonumber(CFG.fightDist) or 8) + 2 and now - (r.noHitSince or now) > 2.5 then
				-- swinging but nothing lands: get closer
				r.orbitShrink = math.min(2.5, (tonumber(r.orbitShrink) or 0) + .5);
				r.noHitSince = now;
				if r.why then r.why("combat", string.format("hits not landing at %.1f st: moving %.1f st closer", dd, r.orbitShrink)); end;
			end;
		end;
	end;
	if not boss then bossStudy.cur = nil; r.bossFight = nil; return; end;
	r.bossFight = tostring(boss.name);
	local cur = bossStudy.cur;
	if not cur or cur.addr ~= boss.addr then
		cur = { addr = boss.addr, name = tostring(boss.name), hist = {}, adds = {} };
		bossStudy.cur = cur;
	end;
	local bd = math.sqrt((boss.x - pos.X) ^ 2 + (boss.z - pos.Z) ^ 2);
	if tonumber(boss.hp) then
		cur.hist[#cur.hist + 1] = { t = now, hp = tonumber(boss.hp), on = xQ == boss.addr and bd <= (tonumber(CFG.fightDist) or 8) + 6 };
		while #cur.hist > 0 and now - cur.hist[1].t > 4 do table.remove(cur.hist, 1); end;
	end;
	local rate = bossStudy.rateOf(cur.hist);
	if rate then cur.rate = rate; end;
	-- tanky? (you do under 30% of your normal damage to it)
	local normal = tonumber(brain.dmgRate);
	cur.shielded = rate ~= nil and normal ~= nil and normal > 0 and rate < normal * .3;
	-- the other things on the field, and which of them just died
	local alive = {};
	cur.still = cur.still or {};
	local stillNow = {};
	for _, mob in ipairs(list) do
		if mob ~= boss and (mob.x - boss.x) ^ 2 + (mob.z - boss.z) ^ 2 < 10000 then
			alive[mob.addr] = tostring(mob.name);
			-- standing still for 3 s while a boss is up = probably a boss mechanic (pylon, totem, crystal)
			local st = cur.still[mob.addr];
			if not st or (mob.x - st.x) ^ 2 + (mob.z - st.z) ^ 2 > .25 then
				st = { x = mob.x, z = mob.z, since = now };
			end;
			stillNow[mob.addr] = st;
			if now - st.since >= 3 and not st.flagged then
				st.flagged = true;
				if r.why then r.why("boss", string.format("%s hasn't moved for 3 s next to %s: treating it as a boss mechanic, attacking it first", tostring(mob.name), cur.name)); end;
				if not bossStudy.notes[cur.name .. ":still:" .. tostring(mob.name)] then
					bossStudy.notes[cur.name .. ":still:" .. tostring(mob.name)] = true;
					notify(string.format("%s isn't moving: likely part of %s's mechanic. Destroying it first.", tostring(mob.name), cur.name), "Delve boss");
				end;
			end;
		end;
	end;
	cur.still = stillNow;
	for addr, name in pairs(cur.adds) do
		if not alive[addr] and not cur.pending then
			cur.pending = { name = name, at = now, before = cur.rate or 0 };
			cur.hist, cur.rate = {}, nil;
		end;
	end;
	cur.adds = alive;
	-- 4 s after an add died: did the boss start taking more damage?
	local pend = cur.pending;
	if pend and now - pend.at > 6 then
		cur.pending = nil;
		local after = cur.rate;
		if after then
			local book = type(brain.bossAdds[cur.name]) == "table" and brain.bossAdds[cur.name] or {};
			local rec = type(book[pend.name]) == "table" and book[pend.name] or { score = 0, n = 0 };
			rec.n = (tonumber(rec.n) or 0) + 1;
			local helped = after > (pend.before or 0) * 1.8 + 1;
			rec.score = math.max(-2, math.min(5, (tonumber(rec.score) or 0) + (helped and 1 or -.5)));
			book[pend.name] = rec;
			brain.bossAdds[cur.name] = book;
			markBrain();
			if helped and not bossStudy.notes[cur.name .. pend.name] then
				bossStudy.notes[cur.name .. pend.name] = true;
				notify(string.format("%s takes more damage after %s dies. Killing those first from now on.", cur.name, pend.name), "Delve boss");
				if r.why then r.why("boss", string.format("%s damage went %.0f/s -> %.0f/s after %s died: learned, kill it first", cur.name, pend.before or 0, after, pend.name)); end;
			end;
		end;
	end;
	if cur.shielded and next(alive) and not bossStudy.notes[cur.name .. ":shield"] then
		bossStudy.notes[cur.name .. ":shield"] = true;
		notify(string.format("%s is barely taking damage. Trying the other targets on the field first.", cur.name), "Delve boss");
		if r.why then r.why("boss", string.format("%s takes %.0f/s vs your normal %.0f/s: shielded, switching to adds", cur.name, rate or 0, normal or 0)); end;
	end;
end;
-- how much closer (in studs) a mob should count when picking a target
-- is the straight walk to this mob free of attack zones, burning floor and void? (cached 0.3 s per mob)
-- 5 of 6 Worldheart deaths came seconds after crossing the arena to a pylon 33-100 studs away.
function bossStudy.pathSafe(mob)
	bossStudy.safeCache = bossStudy.safeCache or {};
	local now = d();
	local c = bossStudy.safeCache[mob.addr];
	if c and now - c.t < .3 then return c.ok, c.why; end;
	local pos = sQ();
	local ok, why = true, nil;
	if pos and mob.x then
		local dx, dz = mob.x - pos.X, mob.z - pos.Z;
		local len = math.sqrt(dx * dx + dz * dz);
		local steps = math.min(40, math.floor(len / 2));
		for k = 1, steps do
			local f = k / (steps + 1);
			local x, z = pos.X + dx * f, pos.Z + dz * f;
			if r.navOpenAt then
				local okO, open = pcall(r.navOpenAt, x, z);
				if okO and (tonumber(open) or 99) < 1 then ok, why = false, "path leaves the floor"; break; end;
			end;
			for _, zone in ipairs(Fl) do
				if ul(zone, x, z, Vl) then
					ok, why = false, zone.floor and "burning floor on the way" or "attack zones on the way";
					break;
				end;
			end;
			if not ok then break; end;
		end;
	end;
	bossStudy.safeN = (bossStudy.safeN or 0) + 1;
	if bossStudy.safeN > 300 then bossStudy.safeCache, bossStudy.safeN = {}, 0; end;
	bossStudy.safeCache[mob.addr] = { t = now, ok = ok, why = why };
	return ok, why;
end;
function bossStudy.bias(mob)
	local cur = bossStudy.cur;
	if not cur or mob.addr == cur.addr then return 0; end;
	-- (v5.39) a gate has guardians and their pack, not boss mechanics: the "boss mechanic" priority made it run
	-- 80-270 st across the gate between far targets while the gate's clock ran out. In a gate the nearest mob comes first.
	if r.room and r.room.inGate and r.room.inGate() then return 0; end;
	local b = bossStudy.biasRaw(mob, cur);
	if b > 0 and (tonumber(mob.d) or 0) > 12 then
		-- go for it if there's a way around the hazards (straight lines across the arena always crossed a burn strip)
		local G = sQ();
		local reach = math.max(4, YQ());
		local okA, pA = pcall(r.routeTo, mob, G, reach);
		local path = okA and pA or nil;
		if not path and r.lavaOk() then
			local okB2, pB = pcall(r.routeTo, mob, G, reach, true);
			path = okB2 and pB or nil;
		end;
		if not path then
			bossStudy.noteAt = bossStudy.noteAt or {};
			if r.why and d() - (bossStudy.noteAt[mob.addr] or 0) > 10 then
				if (bossStudy.noteN or 0) > 300 then bossStudy.noteAt, bossStudy.noteN = {}, 0; end;
				bossStudy.noteN = (bossStudy.noteN or 0) + 1;
				bossStudy.noteAt[mob.addr] = d();
				r.why("boss", string.format("%s is %.0f st away and there's no way around the hazards yet: fighting what's near", tostring(mob.name), tonumber(mob.d) or 0));
			end;
			return 0;
		end;
	end;
	return b;
end;
function bossStudy.biasRaw(mob, cur)
	local book = type(brain.bossAdds) == "table" and brain.bossAdds[cur.name];
	local rec = type(book) == "table" and book[tostring(mob.name)];
	if type(rec) == "table" and (tonumber(rec.score) or 0) >= 1 then return 60; end;
	if type(rec) == "table" and (tonumber(rec.score) or 0) <= -1 then return 0; end;
	local st = cur.still and cur.still[mob.addr];
	-- give it up after 25 s (some still things can't be destroyed)
	if st and st.flagged and d() - st.since < 25 then return 45; end;
	if cur.shielded then return 30; end;
	return 0;
end;
local function wantFight(list, pos, now)
	local pr = CFG.mobPriority or "Smart";
	r.collapseHurry, r.collapseFwd = nil, nil;
	if pr == "Always fight" or not CFG.mine then
		r.fightWhy = "always";
		return true;
	end;
	local stage = (tostring(run.stage or "") .. " " .. tostring(run.objective or "")):upper();
	local boss = run.bossHud or stage:find("BOSS") ~= nil or stage:find("GUARDIAN") ~= nil;
	local minMax, maxMax = math.huge, 0;
	for _, mob in ipairs(list) do
		-- a mob that killed you before and is named on the death screen ("THE WORLDHEART") is a boss,
		-- unless it was an elite
		-- re-checked every 5 s: a boss card can name the boss after the mob first showed up
		if not mob.boss and d() - (mob.knownChecked or -1e9) > 5 then
			mob.knownChecked = d();
			local nm = tostring(mob.name or ""):upper():gsub("%s", "");
			local names = {};
			for killer in pairs(type(brain.deaths) == "table" and brain.deaths or {}) do names[#names + 1] = killer; end;
			for bn in pairs(type(brain.bossNames) == "table" and brain.bossNames or {}) do names[#names + 1] = bn; end;
			for _, killer in ipairs(names) do
				local k = tostring(killer):upper();
				-- named bosses only ("THE WORLDHEART"); a normal mob that killed you once (POWDER GUNNER) isn't one
				if k:find("^THE%s") then
					k = k:gsub("^THE%s+", ""):gsub("%s", "");
					if #k >= 4 and nm ~= "" and (nm == k or nm:find(k, 1, true) or k:find(nm, 1, true)) then mob.boss = true; end;
				end;
			end;
		end;
		if mob.boss then boss = true; end;
		local mx = tonumber(mob.max) or 0;
		if mx > 0 then minMax, maxMax = math.min(minMax, mx), math.max(maxMax, mx); end;
	end;
	-- only real bosses (the game's boss flag, the HUD or the stage name) count as a boss. A mob with 5x the
	-- health of the others is still worth fighting, but it's not a boss: calling it one switched sets, marked
	-- normal floors (340 m, 880 m) as boss floors and blocked early dodges against everything else.
	run.bossNow = boss;
	-- (v5.36) the collapse / chamber clock first: it decides how much fighting is affordable
	local dz0 = tonumber(CFG.dangerTime) or 10;
	local csec, chow = math.huge, "timer";
	do
		local tlx = tonumber(run.timeLeft);
		if tlx and now - (tonumber(run.timeAt) or -1e9) < 2 then csec = tlx; end;
		if run.isDelve and r.collapseState then
			local okC, sc, how = pcall(r.collapseState, pos);
			if okC and sc and sc < csec then csec, chow = sc, how; end;
		end;
	end;
	local hurry = run.isDelve and csec <= dz0; -- (waves: the clock is the session timer, nothing is "behind")
	if hurry then
		r.collapseHurry = csec;
		local okF, fx, fz = pcall(r.forwardInfo, pos.X, pos.Z);
		if okF and fx then r.collapseFwd = { fx, fz }; end;
	end;
	-- (v5.37) bosses and gate guardians are always fought: the way on only opens once they're dead, and a shooter
	-- that stays back would never come to you. Near the collapse the ones ahead of you are picked first.
	if boss then r.fightWhy = "boss"; return true; end;
	-- (the "big mob" rule comes after the timer check: a 42,840 m run caved in chasing big mobs 25-45 st
	-- away with 5 s left on the timer)
	if stage:find("MOB") or stage:find("ENEM") or stage:find("FIGHT") or stage:find("HORDE") or stage:find("SLAY") or stage:find("KILL")
		or stage:find("ELITE") or stage:find("DEFEAT") or stage:find("CLEAR") then
		r.fightWhy = "mob stage";
		return true;
	end;
	-- a mob right on top of you: kill it first (it would keep hitting you and block mining), then back to mining
	do
		local closest = math.huge;
		for _, mob in ipairs(list) do
			local dd = math.sqrt((mob.x - pos.X) ^ 2 + (mob.z - pos.Z) ^ 2);
			if dd < closest then closest = dd; end;
		end;
		local tooClose = math.max(5, math.min(9, (tonumber(CFG.fightDist) or 8)));
		-- (v5.36) close to the collapse only a mob right on top of you is fought; at 6 s or less none
		if hurry then tooClose = csec <= 6 and 0 or 3; end;
		if tooClose > 0 and closest <= tooClose then
			r.fightWhy = string.format("too close (%.1f st): clear it, then mine", closest);
			return true;
		end;
	end;
	-- delve floor timer in the danger zone: ignore mobs, every second goes to ores / getting down
	local tl = tonumber(run.timeLeft);
	if tl and tl <= dz0 and now - (tonumber(run.timeAt) or -1e9) < 2 then
		r.fightWhy = nil;
		r.danger, r.dangerWhy = true, string.format("timer %ss", tostring(tl));
		return false;
	end;
	-- (v5.34) the collapse front itself (it caught runs with the clock still showing 8-9 s)
	if run.isDelve and r.collapseState then
		local okC, sc, how = pcall(r.collapseState, pos);
		if okC and sc and sc <= dz0 then
			r.fightWhy = nil;
			r.danger, r.dangerWhy = true, string.format("%s %.0fs", how == "timer" and "timer" or "collapse", sc);
			return false;
		end;
	end;
	r.danger, r.dangerWhy = false, nil;
	if #list >= 2 and maxMax > 0 and maxMax >= minMax * 5 then r.fightWhy = "big mob"; return true; end;
	if next(D) == nil then r.fightWhy = "no ores"; return true; end;
	local nearest = math.huge;
	for _, mob in ipairs(list) do
		local dd = math.sqrt((mob.x - pos.X) ^ 2 + (mob.z - pos.Z) ^ 2);
		if dd < nearest then nearest = dd; end;
	end;
	local mode = run.modeName and run.modeName() or "waves";
	local threat = tonumber(brain.threat[mode]) or 8;
	if pr == "Ores first" then threat = math.min(threat, 4); end;
	-- keep fighting a mob we already engaged until it backs off a bit (no flip-flopping)
	if WQ == "combat" then threat = threat + 4; end;
	local character = l.Character;
	local hum = character and character:FindFirstChildOfClass("Humanoid");
	local hpPct = (hum and hum.MaxHealth > 0) and hum.Health / hum.MaxHealth * 100 or 100;
	if hpPct < (tonumber(CFG.lowHpPct) or 35) then
		threat = math.min(threat, 4);
	end;
	if nearest <= threat then r.fightWhy = string.format("threat %.0f st", nearest); return true; end;
	if pr == "Smart" and #list >= (tonumber(CFG.crowdSize) or 5) and hpPct >= (tonumber(CFG.lowHpPct) or 35) then
		r.fightWhy = "swarmed";
		return true;
	end;
	r.fightWhy = nil;
	return false;
end;
-- DANGER MAP (Settings > "Show what it sees"): draws, live, what the dodge logic detects:
-- red = attack zones, orange = burning floor, yellow = attacks timed to hit you soon, green = where it's heading.
-- The marks are local, can't be touched or hit by rays, and sit in a folder, so detection never sees them.
r.viewPool = {};
r.dangerView = function(now)
	if now - (r.viewAt or 0) < .15 then return; end;
	r.viewAt = now;
	local folder = r.viewFolder;
	if CFG.dangerView ~= true then
		if folder then pcall(function() folder:Destroy(); end); r.viewFolder, r.viewPool = nil, {}; end;
		return;
	end;
	local hrp = l.Character and l.Character:FindFirstChild("HumanoidRootPart");
	if not hrp then return; end;
	if not (folder and folder.Parent) then
		folder = Instance.new("Folder");
		folder.Name = "DelveDangerView";
		folder.Parent = workspace;
		r.viewFolder, r.viewPool = folder, {};
	end;
	local y = hrp.Position.Y - 2.8;
	local function mark(k)
		local pt = r.viewPool[k];
		if not pt then
			pt = Instance.new("Part");
			pt.Anchored, pt.CanCollide, pt.CanTouch, pt.CanQuery, pt.CastShadow = true, false, false, false, false;
			pt.Material, pt.Transparency = Enum.Material.Neon, .72;
			pt.Parent = folder;
			r.viewPool[k] = pt;
		end;
		return pt;
	end;
	local timed = {};
	for _, w in pairs(Cl) do if w.zone then timed[w.zone] = true; end; end;
	local n = 0;
	for _, z in ipairs(Fl) do
		if n >= 90 then break; end;
		if (z.x - hrp.Position.X) ^ 2 + (z.z - hrp.Position.Z) ^ 2 < 90 * 90 and not z.safeHole then
			n = n + 1;
			local pt = mark(n);
			pt.Color = timed[z] and Color3.fromRGB(255, 220, 60) or ((z.floor or tostring(z.sig or ""):find("Burn", 1, true)) and Color3.fromRGB(255, 140, 40) or Color3.fromRGB(255, 50, 50));
			if z.circle then
				local dmt = math.max(.5, (z.h1 or 1) * 2);
				pt.Shape = Enum.PartType.Cylinder;
				pt.Size = Vector3.new(.15, dmt, dmt);
				pt.CFrame = CFrame.new(z.x, y, z.z) * CFrame.Angles(0, 0, math.rad(90));
			else
				pt.Shape = Enum.PartType.Block;
				pt.Size = Vector3.new(math.max(.5, (z.h1 or 1) * 2), .15, math.max(.5, (z.h2 or 1) * 2));
				pt.CFrame = CFrame.fromMatrix(Vector3.new(z.x, y, z.z), Vector3.new(z.ax or 1, 0, z.az or 0), Vector3.new(0, 1, 0));
			end;
			pt.Transparency = .72;
		end;
	end;
	-- where it's heading to get safe
	local et = r.escTarget;
	local goal = (et and now - et.t < 1) and et or (Qh and now - (Qh.t or 0) < 1 and Qh) or nil;
	n = n + 1;
	local gp = mark(n);
	if goal then
		gp.Shape, gp.Color, gp.Transparency = Enum.PartType.Cylinder, Color3.fromRGB(70, 230, 110), .35;
		gp.Size = Vector3.new(.3, 3, 3);
		gp.CFrame = CFrame.new(goal.x, y + .1, goal.z) * CFrame.Angles(0, 0, math.rad(90));
	else
		gp.Transparency = 1;
	end;
	for k = n + 1, #r.viewPool do r.viewPool[k].Transparency = 1; end;
end;
-- ===================================================================================
-- (v5.33) AFTER THE UNMAKER + STALL WATCHDOG
--   On 2026-11-13 it killed the Unmaker, took the Tithe relic and then stood still for 48 minutes at
--   17,760 m without one log line: the portal note is only written once per session (the second portal
--   was silent), and with no portal, no floor map or no forward goal it just stopped. Now:
--   * portalFind: the nearest portal (tag, model name or sign), aimed at its core ("Deep")
--   * portalWalk: says where it's going every 8 s, walks through the ring if standing in it does
--     nothing, gives up on a portal it can't get closer to (the walk up the road takes over)
--   * floorHeading: a heading close to the one wanted with floor under the next 3 and 6 studs
--   * stallTick: farming in a Delve, out of combat, not moved 4 studs and no ore/mob change for 25 s:
--     logs what it was doing (DelveReasoning.txt + DelveStall.txt), skips the ores right there for 30 s
--     and walks on for 6 s; still stuck after 3 minutes, one Discord alert (with the disconnect ping on)
-- ===================================================================================
do
	local CS = game:GetService("CollectionService");
	-- the portal's core (the dark disc in the ring) when it has one, else its pivot / position
	local function corePos(o)
		local deep = o:FindFirstChild("Deep");
		if deep and deep:IsA("BasePart") then return deep.Position; end;
		if o:IsA("BasePart") then return o.Position; end;
		if o:IsA("Model") then return o:GetPivot().Position; end;
		return nil;
	end;
	r.portalFind = function(G, wantShop)
		local tag = wantShop and "VesperInGate" or "PrestigePortal";
		local now = d();
		local best;
		local function consider(o, how)
			if not (o and o.Parent) then return; end;
			-- (v5.39) the shop's ring (Plates...VesperGate) carries the PrestigePortal tag too, 28 st from the real one:
			-- never take it (or Vesper standing next to it) when heading for Prestige
			if not wantShop and tostring(o.Name):find("Vesper", 1, true) then return; end;
			local bad = r.portalBad and r.portalBad[o];
			if bad and now < bad then return; end;
			local okC, pos = pcall(corePos, o);
			if not (okC and pos) then return; end;
			local dd = (pos.X - G.X) ^ 2 + (pos.Z - G.Z) ^ 2;
			if dd < 640000 and (not best or dd < best.dd) then
				local axis;
				pcall(function() if o:IsA("Model") then axis = o:GetPivot().RightVector; end; end);
				best = { inst = o, pos = pos, how = how, dd = dd, axis = axis };
			end;
		end;
		-- (v5.39) the shop: its own ring first (VesperGate, tagged PrestigePortal). The VesperInGate tag is Vesper
		-- standing next to it, and walking into Vesper doesn't take you through.
		local ring;
		if wantShop then
			pcall(function()
				for _, o in ipairs(CS:GetTagged("PrestigePortal")) do
					if o.Name == "VesperGate" then consider(o, "the shop's ring (VesperGate)"); end;
				end;
			end);
			for o, nm in pairs(r.portalModels or {}) do
				if nm == "VesperGate" and o.Parent and o:FindFirstChild("Deep") then consider(o, "a model named VesperGate"); end;
			end;
			ring = best;
		end;
		if not ring then
			pcall(function()
				for _, o in ipairs(CS:GetTagged(tag)) do consider(o, tag .. " tag"); end;
			end);
			for o, nm in pairs(r.portalModels or {}) do
				if nm == tag and o.Parent and o:FindFirstChild("Deep") then consider(o, "a model named " .. nm); end;
			end;
		end;
		-- the sign over it: the main signal for the rare shop (garbled label) when its ring isn't found, a fallback for prestige
		local bb = r.portalSigns and (wantShop and r.portalSigns.mystery or r.portalSigns.prestige);
		if bb and bb.Parent and ((wantShop and not ring) or not best) then
			local sp;
			pcall(function()
				local holder = bb.Adornee or bb.Parent;
				if holder:IsA("Attachment") then sp = holder.WorldPosition;
				elseif holder:IsA("BasePart") then sp = holder.Position;
				else
					local part = holder:FindFirstChildWhichIsA("BasePart", true) or holder:FindFirstAncestorWhichIsA("BasePart");
					sp = part and part.Position;
				end;
			end);
			local bad = r.portalBad and r.portalBad[bb];
			if sp and not (bad and now < bad) then
				local dd = (sp.X - G.X) ^ 2 + (sp.Z - G.Z) ^ 2;
				if dd < 62500 then best = { inst = bb, pos = sp, how = "sign text", dd = dd }; end;
			end;
		end;
		if not best then return nil; end;
		best.dist = math.sqrt(best.dd);
		return best;
	end;
	local function ignorePortal(inst, m)
		r.portalBad = r.portalBad or setmetatable({}, { __mode = "k" });
		r.portalBad[inst] = m + 60;
		r.portalState = nil;
	end;
	r.portalWalk = function(G, m, tg, wantShop)
		local name = wantShop and "rare shop" or "prestige";
		local st = r.portalState;
		if not st or st.inst ~= tg.inst then
			st = { inst = tg.inst, best = tg.dist, bestAt = m };
			r.portalState = st;
		end;
		-- (v5.37) back after a pause (a fight, F2): the "getting closer" clocks start over
		if st.lastAt and m - st.lastAt > 3 then st.best, st.bestAt, st.nearAt = tg.dist, m, nil; end;
		st.lastAt = m;
		if tg.dist < st.best - 3 then st.best, st.bestAt = tg.dist, m; end;
		if m - (r.portalNoteAt or -1e9) > 8 then
			r.portalNoteAt = m;
			if r.why then r.why("move", string.format("walking into the %s portal: %.0f st away (found by %s)", name, tg.dist, tg.how)); end;
			if not st.told then
				st.told = true;
				notify("Taking the " .. name .. " portal.", "Delve run");
			end;
			if not r.portalDumped and type(writefile) == "function" then
				r.portalDumped = true;
				pcall(function()
					local root = tg.inst:IsA("Model") and tg.inst or tg.inst:FindFirstAncestorWhichIsA("Model") or tg.inst;
					local lines = { "Delve portal " .. os.date("%Y-%m-%d %H:%M:%S"), root.ClassName .. " " .. root:GetFullName() };
					for _, d0 in ipairs(root:GetDescendants()) do
						if #lines > 120 then break; end;
						if d0:IsA("BasePart") or d0:IsA("TextLabel") then
							lines[#lines + 1] = string.format("  %s '%s'%s", d0.ClassName, d0.Name, d0:IsA("TextLabel") and (" text=\"" .. d0.Text .. "\"") or "");
						end;
					end;
					writefile("DelveGuiDump_portals.txt", table.concat(lines, "\n"));
				end);
			end;
		end;
		-- not 3 st closer in 25 s: leave it for a minute (the walk up the road takes over)
		if m - st.bestAt > 25 then
			ignorePortal(tg.inst, m);
			if r.why then r.why("move", string.format("not getting closer to the %s portal (%.0f st away for 25 s): leaving it for a minute", name, tg.dist)); end;
			if r.roomDump and m - (r.portalDumpAt or -1e9) > 60 then
				r.portalDumpAt = m;
				task.spawn(function() pcall(r.roomDump, "portal walk: not getting closer", "DelveRoomDump_portal.txt"); end);
			end;
			return false;
		end;
		local tx, tz = tg.pos.X, tg.pos.Z;
		if tg.dist <= 4.5 or (st.nearAt and tg.dist <= 9) then
			-- in the ring and nothing happened: walk through it along its axis, the other side every 3 s
			st.nearAt = st.nearAt or m;
			local held = m - st.nearAt;
			if held > 15 then
				ignorePortal(tg.inst, m);
				if r.why then r.why("move", string.format("the %s portal didn't take me in after 15 s at it: leaving it for a minute", name)); end;
				if r.roomDump and m - (r.portalDumpAt or -1e9) > 60 then
					r.portalDumpAt = m;
					task.spawn(function() pcall(r.roomDump, "portal walk: at the portal, nothing happened", "DelveRoomDump_portal.txt"); end);
				end;
				return false;
			end;
			if held > 1.5 then
				local ax, az = 0, 0;
				if tg.axis then ax, az = tg.axis.X, tg.axis.Z; end;
				local al = math.sqrt(ax * ax + az * az);
				if al < .3 and st.fromX then
					ax, az = tx - st.fromX, tz - st.fromZ;
					al = math.sqrt(ax * ax + az * az);
				end;
				if al > .1 then
					local side = (math.floor((held - 1.5) / 3) % 2 == 0) and 1 or -1;
					tx, tz = tg.pos.X + ax / al * 7 * side, tg.pos.Z + az / al * 7 * side;
					if side ~= st.side then
						st.side = side;
						if r.why then r.why("move", "at the portal and nothing happened: walking through the ring"); end;
					end;
				end;
			end;
		else
			st.nearAt, st.side = nil, nil;
			st.fromX, st.fromZ = G.X, G.Z;
		end;
		-- around pillars and attacks; after 8 s without getting closer, straight at it
		local wp;
		if m - st.bestAt <= 8 then
			local okRt, path = pcall(r.routeTo, { addr = "portal" .. name, x = tx, z = tz }, G, 2);
			if okRt and path then
				for _, p0 in ipairs(path) do
					if (p0.x - G.X) ^ 2 + (p0.z - G.Z) ^ 2 > 4 then wp = p0; break; end;
				end;
			end;
		end;
		if wp then
			SQ(wp.x - G.X, wp.z - G.Z);
		else
			local okS, sx, sz = pcall(r.steerDir, G, tx, tz);
			if okS and sx then SQ(sx, sz); else SQ(tx - G.X, tz - G.Z); end;
		end;
		return true;
	end;
	-- a heading close to (dx, dz) with floor under the next 3 and 6 studs and no attack 4 studs ahead
	r.floorHeading = function(G, dx, dz)
		local len = math.sqrt(dx * dx + dz * dz);
		if len < .01 then return nil; end;
		dx, dz = dx / len, dz / len;
		local hrp = l.Character and l.Character:FindFirstChild("HumanoidRootPart");
		if not hrp then return nil; end;
		local y0 = hrp.Position.Y;
		local rp = RaycastParams.new();
		rp.FilterType = Enum.RaycastFilterType.Exclude;
		rp.FilterDescendantsInstances = { l.Character };
		local function floorAt(x, z)
			local hit = workspace:Raycast(Vector3.new(x, y0 + 3, z), Vector3.new(0, -14, 0), rp);
			return hit ~= nil and hit.Position.Y > y0 - 7 and hit.Position.Y < y0 + 1.5;
		end;
		for pass = 1, 2 do
			for _, deg in ipairs({ 0, 25, -25, 50, -50, 75, -75 }) do
				local a = math.rad(deg);
				local ca, sa = math.cos(a), math.sin(a);
				local hx, hz = dx * ca - dz * sa, dx * sa + dz * ca;
				if floorAt(G.X + hx * 3, G.Z + hz * 3) and floorAt(G.X + hx * 6, G.Z + hz * 6)
					and (pass == 2 or not eh(Fl, G.X + hx * 4, G.Z + hz * 4)) then
					return hx, hz;
				end;
			end;
		end;
		return nil;
	end;
	r.stallReport = function(G, S, m, secs)
		local parts = {};
		local function add(x) parts[#parts + 1] = x; end;
		add("last step: " .. tostring(r.lhBranch or "?"));
		add(L and "an ore in reach" or "no ore in reach");
		add(u and string.format("ore to walk to %.0f st away", math.sqrt((u.X - G.X) ^ 2 + (u.Z - G.Z) ^ 2)) or "no ore to walk to");
		add(string.format("%d ores known, %d mobs, %d attack zones", tonumber(r.rockCount) or 0, #S, #Fl));
		add(string.format("%d floor tiles, floor map %s", #i, nav.map and "yes" or "no"));
		local okF, fx, fz, gx, gz, gp, fsrc = pcall(r.forwardInfo, G.X, G.Z);
		add(okF and (fx and string.format("forward goal: %s, %.0f st", tostring(fsrc), tonumber(gp) or 0) or "forward goal: none") or ("forward check error: " .. tostring(fx)));
		local okR, c, src = pcall(function() return r.room.current(G.Z); end);
		add(okR and (c and string.format("chamber %s (%s)", tostring(c), tostring(src)) or ("chamber: " .. tostring(src))) or "chamber check failed");
		local okP, tg = pcall(r.portalFind, G, false);
		add(okP and (tg and string.format("prestige portal %.0f st away (%s)", tg.dist, tg.how) or "no prestige portal found") or ("portal check error: " .. tostring(tg)));
		add(string.format("depth %s m", tostring(run.curDepth or run.depth)));
		local line = string.format("standing still for %d s (%s). Skipping the ores here and moving on.", secs, table.concat(parts, "; "));
		if r.why then r.why("move", line); end;
		if type(writefile) ~= "function" then return; end;
		pcall(function()
			local out = { "Delve stall " .. os.date("%Y-%m-%d %H:%M:%S") .. " (v5.33)", line,
				string.format("position %.1f, %.1f, %.1f; mode %s; farm %s, walk %s, mine %s", G.X, G.Y, G.Z, tostring(WQ), tostring(Q.on), tostring(Q.walk), tostring(Q.mine)) };
			local function put(x) out[#out + 1] = x; end;
			put(string.format("objective '%s', timer %s, depth %s (deepest %s), prestige %s", tostring(run.objective or ""), tostring(run.timeLeft), tostring(run.curDepth), tostring(run.depth), tostring(run.prestige)));
			pcall(function()
				local rp = RaycastParams.new();
				rp.FilterType = Enum.RaycastFilterType.Exclude;
				rp.FilterDescendantsInstances = { l.Character };
				local hit = workspace:Raycast(G + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), rp);
				put("standing on: " .. (hit and (hit.Instance:GetFullName() .. string.format(" (y %.1f)", hit.Position.Y)) or "nothing within 14 st"));
			end);
			pcall(function()
				local sp = workspace:FindFirstChild("StrataPlate");
				local gr = sp and sp:FindFirstChild("Ground");
				local lo, hi, n = math.huge, -math.huge, 0;
				for _, t in ipairs(gr and gr:GetChildren() or {}) do
					local row = tonumber((t.Name:match("^Tile_(%-?%d+)_")));
					if row then n, lo, hi = n + 1, math.min(lo, row), math.max(hi, row); end;
				end;
				put(string.format("shaft tiles: %d (rows %s to %s)", n, n > 0 and tostring(lo) or "-", n > 0 and tostring(hi) or "-"));
			end);
			pcall(function()
				local kv = {};
				for k, v in pairs(r.room and r.room.s or {}) do kv[#kv + 1] = tostring(k) .. "=" .. tostring(v); end;
				table.sort(kv);
				put("session: " .. (#kv > 0 and table.concat(kv, ", ") or "none (inactive)"));
			end);
			for _, tag in ipairs({ "PrestigePortal", "VesperInGate" }) do
				pcall(function()
					for _, o in ipairs(CS:GetTagged(tag)) do
						local okC, pp = pcall(corePos, o);
						local bad = r.portalBad and r.portalBad[o];
						put(string.format("tag %s: %s at %s, %.0f st away%s", tag, o:GetFullName(),
							(okC and pp) and string.format("%.0f, %.0f, %.0f", pp.X, pp.Y, pp.Z) or "?",
							(okC and pp) and math.sqrt((pp.X - G.X) ^ 2 + (pp.Z - G.Z) ^ 2) or -1,
							(bad and m < bad) and " (ignored for now)" or ""));
					end;
				end);
			end;
			for o, nm in pairs(r.portalModels or {}) do
				pcall(function() put(string.format("model %s: %s", nm, o:GetFullName())); end);
			end;
			for k, bb in pairs(r.portalSigns or {}) do
				pcall(function() put(string.format("sign %s: %s", tostring(k), bb:GetFullName())); end);
			end;
			pcall(function()
				local names = {};
				for _, c0 in ipairs(workspace:GetChildren()) do
					if #names >= 80 then break; end;
					names[#names + 1] = c0.Name .. "(" .. c0.ClassName .. ")";
				end;
				put("workspace: " .. table.concat(names, ", "));
				local pl = workspace:FindFirstChild("Plates");
				if pl then
					local pn = {};
					for _, c0 in ipairs(pl:GetChildren()) do
						if #pn >= 40 then break; end;
						local okV, pv = pcall(function() return c0:IsA("Model") and c0:GetPivot().Position or (c0:IsA("BasePart") and c0.Position) or nil; end);
						pn[#pn + 1] = c0.Name .. ((okV and pv) and string.format(" at %.0f, %.0f", pv.X, pv.Z) or "");
					end;
					put("Plates: " .. table.concat(pn, ", "));
				end;
			end);
			put("recent log:");
			local wl = r.whyLines or {};
			for k = math.max(1, #wl - 15), #wl do put("  " .. tostring(wl[k])); end;
			writefile("DelveStall.txt", table.concat(out, "\n"));
		end);
	end;
	-- (v5.34) how close the collapse is: seconds until the front reaches where you stand (SessionSync, the
	-- same maths the game draws it with) and the chamber clock (HUD; at 0:00 you're caved in), the lower one
	r.collapseState = function(G)
		local sf, st;
		pcall(function() sf = r.room and r.room.secondsUntilFalls(G.Z); end);
		if sf then sf = math.max(sf, 0); end;
		local tl = tonumber(run.timeLeft);
		if tl and d() - (tonumber(run.timeAt) or -1e9) < 2 then st = tl; end;
		local sc = math.min(sf or math.huge, st or math.huge);
		local how = (sf and sf <= (st or math.huge)) and "collapse" or "timer";
		return sc, how, sf, st;
	end;
	-- one Delve cycle (a run, and each prestige inside it)
	r.cycleKey = function()
		return tostring(run.id) .. "|" .. tostring(run.cash0) .. "|" .. tostring(run.prestige or 0);
	end;
	-- a chest the collapse reaches before you've walked there and opened it, or (with under 12 s left) any
	-- chest that isn't ahead and within 25 st: a reason to skip it, else nil. A 96 st walk back to a chest
	-- with the timer at 8 s ended a 13,140 m run.
	r.chestTooLate = function(G, c)
		if not run.isDelve then return nil; end;
		local dist = math.sqrt((c.x - G.X) ^ 2 + (c.z - G.Z) ^ 2);
		local hum = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
		local spd = math.max(8, hum and hum.WalkSpeed or 16);
		local need = dist / spd + 3;
		local atChest;
		pcall(function() atChest = r.room and r.room.secondsUntilFalls(c.z); end);
		if atChest and atChest < need + 3 then
			return string.format("the collapse gets there in %.0f s, walking there and opening it takes %.0f s", math.max(atChest, 0), need);
		end;
		local sc, how = r.collapseState(G);
		if sc < 12 then
			local okF, fx, fz = pcall(r.forwardInfo, G.X, G.Z);
			local ahead = okF and fx and ((c.x - G.X) * fx + (c.z - G.Z) * fz) > -2;
			if not ahead or dist > 25 then
				return string.format("%s %.0f s away, no detours", how == "timer" and "the chamber clock runs out" or "the collapse is", sc);
			end;
		end;
		return nil;
	end;
	-- (v5.35) ROOM DUMP: what the room after the Unmaker is made of: the floor around you (a ray down every
	-- 8 st out to 64 in 8 directions), both portals with their facing and solid / trigger parts, and every
	-- part within 200 st (shaft tiles only counted, attack effects skipped). Written 3 s after the Unmaker's
	-- Tithe (DelveRoomDump.txt, once per cycle) and when a portal walk fails (DelveRoomDump_portal.txt, at
	-- most once a minute). Read-only; it pauses a frame every 4,000 objects so the game doesn't hitch.
	r.roomDump = function(why, file)
		if type(writefile) ~= "function" then return; end;
		local char = l.Character;
		local hrp = char and char:FindFirstChild("HumanoidRootPart");
		if not hrp then return; end;
		local hum = char:FindFirstChildOfClass("Humanoid");
		local p0 = hrp.Position;
		local RANGE = 200;
		local out = {};
		local function put(x) out[#out + 1] = x; end;
		local function v3(v) return string.format("%.1f, %.1f, %.1f", v.X, v.Y, v.Z); end;
		local function flat(a) return math.sqrt((a.X - p0.X) ^ 2 + (a.Z - p0.Z) ^ 2); end;
		put(string.format("Delve room dump %s (v5.35): %s", os.date("%Y-%m-%d %H:%M:%S"), tostring(why)));
		put(string.format("you at %s, walk speed %s, depth %s m, prestige %s, last step: %s", v3(p0), tostring(hum and hum.WalkSpeed),
			tostring(run.curDepth), tostring(run.prestige), tostring(r.lhBranch)));
		pcall(function()
			local okF, fx, fz, gx, gz, gp, fsrc = pcall(r.forwardInfo, p0.X, p0.Z);
			put("forward goal: " .. ((okF and fx) and string.format("%s, %.0f st", tostring(fsrc), tonumber(gp) or 0) or "none"));
			local okP, tg = pcall(r.portalFind, p0, false);
			put("portal the bot picks: " .. ((okP and tg) and string.format("%.0f st away (%s), aiming at %s", tg.dist, tg.how, v3(tg.pos)) or "none"));
		end);
		local rp = RaycastParams.new();
		rp.FilterType = Enum.RaycastFilterType.Exclude;
		rp.FilterDescendantsInstances = { char };
		put("");
		put("FLOOR (distance:part@height; none = no floor there)");
		for _, dv in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { .71, .71 }, { -.71, .71 }, { .71, -.71 }, { -.71, -.71 } }) do
			local row = {};
			for dist = 0, 64, 8 do
				local hit = workspace:Raycast(Vector3.new(p0.X + dv[1] * dist, p0.Y + 6, p0.Z + dv[2] * dist), Vector3.new(0, -30, 0), rp);
				row[#row + 1] = hit and string.format("%d:%s@%.1f", dist, hit.Instance.Name, hit.Position.Y) or (tostring(dist) .. ":none");
			end;
			put(string.format("  toward %5.2f, %5.2f   %s", dv[1], dv[2], table.concat(row, "  ")));
		end;
		put("");
		put("PORTALS");
		for _, tag in ipairs({ "PrestigePortal", "VesperInGate" }) do
			pcall(function()
				for _, o in ipairs(CS:GetTagged(tag)) do
					local okC, pos = pcall(corePos, o);
					if not okC then pos = nil; end;
					put(string.format("  %s: %s %s, core at %s, %.0f st away", tag, o.ClassName, o:GetFullName(), pos and v3(pos) or "?", pos and flat(pos) or -1));
					local at = {};
					for k, v in pairs(o:GetAttributes()) do at[#at + 1] = tostring(k) .. "=" .. tostring(v); end;
					if #at > 0 then put("    attributes: " .. table.concat(at, ", ")); end;
					if o:IsA("Model") then
						local cf = o:GetPivot();
						put("    pivot " .. v3(cf.Position) .. ", facing " .. v3(cf.LookVector) .. ", ring axis " .. v3(cf.RightVector));
					end;
					for _, c in ipairs(o:GetDescendants()) do
						if c:IsA("BasePart") and (c.Name == "Deep" or c.Name == "Core" or c.CanCollide or (c.CanTouch and c.Transparency >= 1)) then
							put(string.format("    part %s at %s, size %s, collide=%s, touch=%s, transparency %.2f", c.Name, v3(c.Position), v3(c.Size),
								tostring(c.CanCollide), tostring(c.CanTouch), c.Transparency));
						end;
					end;
				end;
			end);
		end;
		local skipF = {};
		for _, nm in ipairs({ "Hazards", "MobTelegraphs" }) do
			local f0 = workspace:FindFirstChild(nm);
			if f0 then skipF[#skipF + 1] = f0; end;
		end;
		local tiles, lo, hi = 0, math.huge, -math.huge;
		local near = {};
		local okScan, scanErr = pcall(function()
		for k, o in ipairs(workspace:GetDescendants()) do
			if k % 4000 == 0 then task.wait(); end;
			if o:IsA("BasePart") and o.Parent and not o:IsDescendantOf(char) then
				local skipIt = false;
				for _, f0 in ipairs(skipF) do if o:IsDescendantOf(f0) then skipIt = true; break; end; end;
				if not skipIt then
					local row = tonumber((o.Name:match("^Tile_(%-?%d+)_")));
					if row then
						tiles, lo, hi = tiles + 1, math.min(lo, row), math.max(hi, row);
					else
						local dd = flat(o.Position);
						if dd <= RANGE and o.Size.Magnitude > .5 then
							local tags = CS:GetTags(o);
							near[#near + 1] = { dd, string.format("  %.0f st  %s (%s) at %s, size %s, collide=%s, transparency %.2f%s", dd, o:GetFullName(), o.ClassName,
								v3(o.Position), v3(o.Size), tostring(o.CanCollide), o.Transparency, #tags > 0 and (", tags " .. table.concat(tags, "/")) or "") };
						end;
					end;
				end;
			end;
		end;
		end);
		if not okScan then put("(part scan stopped early: " .. tostring(scanErr) .. ")"); end;
		table.sort(near, function(a, b) return a[1] < b[1]; end);
		put("");
		put(string.format("SHAFT TILES: %d loaded (rows %s to %s)", tiles, tiles > 0 and tostring(lo) or "-", tiles > 0 and tostring(hi) or "-"));
		put(string.format("PARTS within %d st: %d (nearest first, up to 1500)", RANGE, #near));
		for k = 1, math.min(#near, 1500) do put(near[k][2]); end;
		put("");
		local names = {};
		for _, c0 in ipairs(workspace:GetChildren()) do names[#names + 1] = c0.Name .. " (" .. c0.ClassName .. ")"; end;
		put("WORKSPACE: " .. table.concat(names, ", "));
		local plates = workspace:FindFirstChild("Plates");
		if plates then
			for _, c0 in ipairs(plates:GetChildren()) do
				local okV, pv = pcall(function() return (c0:IsA("Model") and c0:GetPivot().Position) or (c0:IsA("BasePart") and c0.Position) or nil; end);
				put(string.format("  Plates/%s at %s", c0.Name, (okV and pv) and v3(pv) or "?"));
			end;
		end;
		writefile(file, table.concat(out, "\n"));
		if r.why then r.why("move", string.format("room dump written to %s (%d lines): %s", file, #out, tostring(why))); end;
	end;
	r.stallTick = function(G, S, m)
		local hum0 = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
		local on = Q.on and run.isDelve and run.active and not r.scanning and hum0 ~= nil and hum0.Health > 0 and WQ ~= "combat" and not r.f2Paused;
		local sr = r.stallRef;
		local rc = tonumber(r.rockCount) or 0;
		if not on or not sr or (G.X - sr.x) ^ 2 + (G.Z - sr.z) ^ 2 > 16 or rc ~= sr.rocks or #S ~= sr.mobs then
			r.stallRef = { x = G.X, z = G.Z, t = m, rocks = rc, mobs = #S, since = m };
			return;
		end;
		if m - sr.t < 25 then return; end;
		sr.t = m;
		local secs = math.floor(m - sr.since);
		r.stallKick = { untilT = m + 6 };
		-- the ores right here are skipped for 30 s (one that never breaks kept it in place)
		for _, rock in pairs(D) do
			if rock.wx and rock.wz and (rock.wx - G.X) ^ 2 + (rock.wz - G.Z) ^ 2 < 144 then rock.skipUntil = m + 30; end;
		end;
		pcall(r.stallReport, G, S, m, secs);
		if secs >= 180 and not sr.pinged and CFG.pingDisconnect ~= false and r.postEmbed then
			sr.pinged = true;
			pcall(r.postEmbed, {
				title = "Delve: stuck",
				description = string.format("Standing still for %d min at depth %s m (last step: %s). It keeps trying to move on; details in DelveStall.txt.",
					math.floor(secs / 60), tostring(run.curDepth or run.depth), tostring(r.lhBranch or "?")),
				color = 15105570,
			}, "alert");
		end;
	end;
end;
local function lh(m)
	pcall(r.dangerView, m);
	local G = sQ();
	if not G then
		WQ, L, u, xQ = "idle", nil, nil, nil;
		Pl();
		return;
	end;
	-- (v5.36) F2: you have control. Nothing moves the character (the portal walk and the mob search ignored
	-- the pause before); keys it held are let go once, yours are never touched.
	if r.f2Paused then
		WQ, L, u, xQ = "idle", nil, nil, nil;
		r.lhBranch = "paused (F2)";
		if MQ.phase == "down" then pcall(inp.mouseUp); end;
		MQ.phase = "idle";
		Pl();
		return;
	end;
	B();
	local e = inp.active();
	local N = false;
	for m, G in pairs(Hl) do
		N = N or G;
	end;
	if inp.moveVec then
		N = true;
	end;
	if N then
		local Q = r.stuckRef;
		if not Q or ((G.X - Q.x)) ^ 2 + ((G.Z - Q.z)) ^ 2 > .25 then
			r.stuckRef = { x = G.X, z = G.Z, t = m };
		elseif m - Q.t > (r.dodging and .6 or 1.2) then
			-- stuck on a rock / wall: remember the blocked tile so the pathfinder routes around it
			local dir = run.lastDir;
			if dir then
				-- stuck at the same spot again: block longer and wider
				local near = r.lastStuck and (r.lastStuck.x - G.X) ^ 2 + (r.lastStuck.z - G.Z) ^ 2 < 9 and m - r.lastStuck.t < 15;
				r.stuckStreak = near and (r.stuckStreak or 0) + 1 or 1;
				r.lastStuck = { x = G.X, z = G.Z, t = m };
				local secs = math.min(30, 8 * r.stuckStreak);
				local ax, az = G.X + dir[1] * nav.cell * .8, G.Z + dir[2] * nav.cell * .8;
				-- find the actual thing in the way (pillar) and block all of it for the rest of the floor
				local okN, nObs = pcall(nav.blockNear, G.X + dir[1] * 2, G.Z + dir[2] * 2, math.huge);
				if not (okN and (nObs or 0) > 0) then navBlock(ax, az, m, secs); end;
				if r.stuckStreak >= 2 and not (okN and (nObs or 0) > 0) then
					-- also the tiles beside it: the obstacle is wider than one tile
					navBlock(ax - dir[2] * nav.cell, az + dir[1] * nav.cell, m, secs);
					navBlock(ax + dir[2] * nav.cell, az - dir[1] * nav.cell, m, secs);
				end;
				-- route to where it was actually going (chest / ore), not just "a bit ahead"
				local sg = r.steerGoal;
				local goal = (sg and m - sg.t < 2) and { x = sg.x, z = sg.z } or { x = G.X + dir[1] * 18, z = G.Z + dir[2] * 18 };
				r.steerPath = nil;
				if r.stuckStreak >= 3 then
					-- the same spot keeps stopping it: back off at an angle and drop the current rock as a target
					r.forceDir = { x = -dir[1] - dir[2], z = -dir[2] + dir[1], untilT = m + .7 };
					L, u = nil, nil;
					if r.why then r.why("move", string.format("stuck %d times here: backing off and picking another target", r.stuckStreak)); end;
				end;
				local okR, path = pcall(navRoute, G.X, G.Z, goal.x, goal.z, m);
				if okR and path and #path >= 2 then
					r.detour = { path = path, i = 1, untilT = m + 4 };
					f(string.format("stuck (x%d): detour of %d tiles around the obstacle", r.stuckStreak, #path));
					if r.why then r.why("move", string.format("stuck on an obstacle (x%d), walking around it", r.stuckStreak)); end;
				else
					-- no tile route: back off and sidestep
					r.forceDir = { x = -dir[2] - dir[1] * .5, z = dir[1] - dir[2] * .5, untilT = m + .5 };
				end;
			end;
			Qh = nil;
			Pl();
			r.stuckRef = nil;
			r.unsticks = ((r.unsticks or 0)) + 1;
		end;
	else
		r.stuckRef = nil;
	end;
	local S = ol();
	pcall(bossStudy.tick, S, G, m);
	-- black box: a small sample every 0.25 s, last 5 s kept, written out only when you die
	if m - (r.boxAt or 0) >= .25 then
		r.boxAt = m;
		r.box = r.box or {};
		local hum = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
		local inZ = {};
		for _, z in ipairs(Fl) do
			if z.sig and ul(z, G.X, G.Z, 0) then inZ[#inZ + 1] = z.sig; if #inZ >= 4 then break; end; end;
		end;
		local tgt;
		for _, mob in ipairs(S) do if mob.addr == xQ then tgt = mob; break; end; end;
		table.insert(r.box, {
			t = math.floor(m * 100) / 100, hp = hum and math.floor(hum.Health) or nil, mode = WQ,
			x = math.floor(G.X), z = math.floor(G.Z), zones = #Fl, inZones = inZ,
			target = tgt and tostring(tgt.name) or nil, dist = tgt and tgt.d and math.floor(tgt.d * 10) / 10 or nil,
			rollReady = m - (r.lastRoll or -1e9) >= yl, why = r.fightWhy, timer = run.timeLeft, stuck = r.stuckStreak,
			planned = r.plan and #r.plan.hz or nil,
			planHitIn = (function()
				local Pq = r.plan;
				if not (Pq and Pq.hooked) then return nil; end;
				local sv = Pq.srv();
				local t = Pq.hitAt(G.X, G.Z, sv, sv + 1.2);
				return t and math.floor((t - sv) * 100) / 100 or nil;
			end)(),
		});
		while #r.box > 20 do table.remove(r.box, 1); end;
	end;
	-- the "move closer" adjustment wears off when not fighting
	if WQ ~= "combat" and (tonumber(r.orbitShrink) or 0) > 0 then
		r.orbitShrink = math.max(0, r.orbitShrink - .01);
	end;
	r.mobCount = #S;
	-- (v5.39) gate watch: a log line while in a gate (it doesn't change what it does)
	if r.room and r.room.gateNote then pcall(r.room.gateNote, G, S, m); end;
	if #S > 0 and Q.combat and wantFight(S, G, m) then
		WQ = "combat";
	elseif Q.mine then
		WQ = "mine";
	else
		WQ = "idle";
	end;
	xQ = nil;
	local w, q = nil, nil;
	for m, Q in ipairs(S) do
		local e = math.sqrt(((Q.x - G.X)) ^ 2 + ((Q.z - G.Z)) ^ 2);
		Q.d = e;
		local okB, bias = pcall(bossStudy.bias, Q);
		if okB and bias then e = e - bias; end;
		-- mobs that have killed you 3+ times (e.g. Elite Powder Gunner, 13 one-shots) are taken out first,
		-- if they're within 45 studs: up to 30 studs "closer" in the target choice
		r.deathBias = r.deathBias or {};
		local nmKey = tostring(Q.name);
		local db0 = r.deathBias[nmKey];
		if db0 == nil then
			local nm = nmKey:upper():gsub("%s", "");
			local cnt = 0;
			for killer, n in pairs(type(brain.deaths) == "table" and brain.deaths or {}) do
				local k = tostring(killer):upper():gsub("^ELITE%s+", ""):gsub("^THE%s+", ""):gsub("%s", "");
				if #k >= 4 and (k == nm or nm:find(k, 1, true) or k:find(nm, 1, true)) then cnt = cnt + (tonumber(n) or 0); end;
			end;
			db0 = cnt >= 3 and math.min(30, cnt * 3) or 0;
			r.deathBias[nmKey] = db0;
		end;
		if db0 > 0 and (Q.d or 99) < 45 then e = e - db0; end;
		-- (v5.36) close to the collapse: mobs behind you (toward it) go last
		if r.collapseHurry and r.collapseFwd and ((Q.x - G.X) * r.collapseFwd[1] + (Q.z - G.Z) * r.collapseFwd[2]) < -6 then e = e + 40; end;
		-- ranged mobs (seen shooting 3+ times, or learned reach 12+ st) go first, only when necessary:
		-- it fired in the last 8 s, or you're inside its reach. A quiet shooter far away isn't chased.
		if CFG.rangedFirst ~= false then
			local shots = type(brain.ranged) == "table" and tonumber(brain.ranged[nmKey]) or 0;
			local reach0 = tonumber(brain.mobReach[nmKey]) or 0;
			if (shots >= 3 or reach0 >= 12) and (Q.d or 99) < 40 then
				local firedAt = r.rangedSeen and r.rangedSeen[nmKey];
				if (firedAt and d() - firedAt < 8) or (Q.d or 99) <= reach0 + 4 then
					e = e - 25;
					r.rangedNote = r.rangedNote or {};
					if r.why and d() - (r.rangedNote[nmKey] or 0) > 60 then
						r.rangedNote[nmKey] = d();
						r.why("combat", string.format("%s hits from range (%.0f st away): taking it out first", nmKey, Q.d or 0));
					end;
				end;
			end;
		end;
		if r.keepTarget == Q.addr then
			-- (v5.39) in a gate it stays on its target unless another mob is 12+ st closer (it switched every 2 s)
			e = e - ((r.room and r.room.inGate and r.room.inGate()) and 12 or 4);
		end;
		if not q or e < q then
			w, q = Q, e;
		end;
	end;
	if WQ == "combat" and ((Q.combat and w)) then
		xQ = w.addr;
		r.keepTarget = w.addr;
	else
		r.keepTarget = nil;
	end;
	do
		local tname = WQ == "combat" and w and tostring(w.name) or "-";
		local reason = WQ == "combat" and tostring(r.fightWhy or "fight")
			or (r.danger and string.format("%s: ignoring mobs", tostring(r.dangerWhy or ("timer " .. tostring(run.timeLeft) .. "s"))) or (#S > 0 and "mobs not a threat, ores first" or "no mobs"));
		local key = WQ .. "|" .. tname .. "|" .. reason;
		if key ~= r.whyKey and m - (r.whyAt or 0) > 1.5 then
			r.whyKey, r.whyAt = key, m;
			local extra = "";
			if WQ == "combat" and w then
				local okB, bias = pcall(bossStudy.bias, w);
				extra = string.format(", %.1f st away", tonumber(w.d) or 0) .. ((okB and (bias or 0) > 0) and ", priority target (boss mechanic)" or "")
					.. (w.boss and ", boss" or "");
			end;
			if r.why then r.why("combat", string.format("%s %s: %s%s, %d mobs up", WQ, tname ~= "-" and tname or "", reason, extra, #S)); end;
		end;
	end;
	if WQ == "mine" then
		if y(m) then
			Ql(G, m);
		else
			L, u = nil, nil;
		end;
	else
		L, u = nil, nil;
		if y(m) then
			a = n({});
		end;
	end;
	r.mode, r.walkTo, r.aimAt = WQ, u ~= nil, L ~= nil;
	-- (v5.33) what it's doing (for the stall report) and the stall watchdog; while it kicks in (6 s), no ore
	-- targets so the walk up the road takes over
	r.lhBranch = WQ == "combat" and "fighting" or WQ;
	pcall(r.stallTick, G, S, m);
	if r.stallKick and m < r.stallKick.untilT and WQ ~= "combat" then
		L, u = nil, nil;
		r.walkTo, r.aimAt = false, false;
	end;
	if not e or iQ() then
		r.lhBranch = "paused (scan or no input)";
		Pl();
		return;
	end;
	if Q.dodge or Q.autoRoll then
		-- the per-frame hazard scan in r.step already refreshed Fl this frame
		if aQ.haz ~= m then
			Xl(G, m);
		end;
	elseif #Fl > 0 or next(Cl) then
		Fl, Cl = {}, {};
	end;
	if WQ == "combat" then uQ(m); end;
	-- PORTALS AFTER THE UNMAKER: two rings you walk into. Left is labelled "PRESTIGE I/II/..." (keep going
	-- deeper); right has a garbled label and leads to "THE $!?#$#*", a shop for very rare items (it never buys).
	-- (v5.33) Found by its tag (PrestigePortal / VesperInGate), a model with that name, or its sign; the nearest
	-- one wins and it walks to the portal's core, as soon as no mob is within 25 studs. It says where it's going
	-- every 8 s, walks through the ring if standing in it does nothing, and leaves a portal it can't get closer
	-- to for a minute. One status line per cycle once it's past the Unmaker's room.
	if not r.portalWatch then
		r.portalWatch, r.portalSigns, r.portalModels = true, {}, setmetatable({}, { __mode = "k" });
		local function checkSign(bb)
			if not (bb and bb.Parent) then return; end;
			for _, o in ipairs(bb:GetDescendants()) do
				if o:IsA("TextLabel") and o.Text ~= "" then
					local tu = o.Text:upper();
					local junk = select(2, tu:gsub("[#&%*%^%$@!%%]", ""));
					if tu:find("PRESTIGE", 1, true) then r.portalSigns.prestige = bb;
					elseif junk >= 3 and #tu <= 16 then r.portalSigns.mystery = bb; end;
				end;
			end;
		end;
		local function checkModel(o)
			if o.Name == "PrestigePortal" or o.Name == "VesperInGate" or o.Name == "VesperGate" then r.portalModels[o] = o.Name; end;
		end;
		pcall(function()
			workspace.DescendantAdded:Connect(function(o)
				if o:IsA("BillboardGui") then task.delay(.5, function() pcall(checkSign, o); end);
				elseif o:IsA("Model") then pcall(checkModel, o); end;
			end);
		end);
		task.spawn(function()
			pcall(function()
				for _, o in ipairs(workspace:GetDescendants()) do
					if o:IsA("BillboardGui") then checkSign(o); elseif o:IsA("Model") then checkModel(o); end;
				end;
			end);
		end);
	end;
	do
		local pick = CFG.afterUnmaker or "Prestige portal";
		local wantShop = pick == "?????" or tostring(pick):find("shop", 1, true) ~= nil;
		if r.unmakerDownKey ~= nil and r.cycleKey and r.unmakerDownKey == r.cycleKey() then
			local key = r.unmakerDownKey;
			if r.pastBossKey ~= key then
				r.pastBossKey = key;
				local okT, tg0 = pcall(r.portalFind, G, wantShop);
				local okF, fx0, fz0, gx0, gz0, gp0, fsrc0 = pcall(r.forwardInfo, G.X, G.Z);
				if r.why then
					r.why("move", string.format("past the %s (depth %s m): %s; forward goal %s; after it: %s", tostring(r.finalBoss or "Unmaker"), tostring(run.curDepth),
						(okT and tg0) and string.format("%s portal %.0f st away (%s)", wantShop and "shop" or "prestige", tg0.dist, tg0.how) or "no portal in sight yet",
						(okF and fx0) and string.format("%s, %.0f st", tostring(fsrc0), tonumber(gp0) or 0) or "none", tostring(pick)));
				end;
			end;
		end;
		if CFG.on and pick ~= "Neither" and pick ~= "Don't enter" then
			local okP, tg = pcall(r.portalFind, G, wantShop);
			if okP and tg then
				local nearest = math.huge;
				for _, mob in ipairs(S) do nearest = math.min(nearest, tonumber(mob.d) or math.huge); end;
				if nearest > 25 then
					local okW, walked = pcall(r.portalWalk, G, m, tg, wantShop);
					if okW and walked then
						r.lhBranch = "walking into the portal";
						return;
					end;
				end;
			end;
		end;
	end;
	-- FIND ALL THE MOBS: the HUD says "N MOBS LEFT"; far mobs (pylons at the top of a boss room) aren't
	-- loaded until you get close, so when it sees fewer than N it moves up the room, away from where it came
	-- in, along a safe route, until all of them are in sight. A mob right next to you is still fought first.
	local floorId = tostring(run.prestige or 0) .. "|" .. tostring(run.curDepth or run.depth);
	if floorId ~= r.exploreDepth then
		r.exploreDepth, r.floorEntry, r.exploreGoal = floorId, { x = G.X, z = G.Z }, nil;
	end;
	do
		local need = tonumber(tostring(run.objective or ""):match("(%d+)%s*MOBS?%s*LEFT"));
		local nearest = math.huge;
		for _, mob in ipairs(S) do nearest = math.min(nearest, tonumber(mob.d) or math.huge); end;
		if CFG.on and CFG.exploreForMobs ~= false and need and #S < need and nearest > 8 and not eh(Fl, G.X, G.Z) and nav.map and r.floorEntry then
			local goal = r.exploreGoal;
			if not goal or (goal.x - G.X) ^ 2 + (goal.z - G.Z) ^ 2 < 16 or m - goal.t > 6 then
				-- the floor tile farthest from where we came in (and from here, once there), not in an attack
				local fromX, fromZ = r.floorEntry.x, r.floorEntry.z;
				if goal and (goal.x - G.X) ^ 2 + (goal.z - G.Z) ^ 2 < 16 then fromX, fromZ = G.X, G.Z; end;
				local best, bd;
				for _, t in pairs(nav.map) do
					local dd = (t.wx - fromX) ^ 2 + (t.wz - fromZ) ^ 2;
					if (not bd or dd > bd) and not eh(Fl, t.wx, t.wz) then best, bd = t, dd; end;
				end;
				goal = best and { x = best.wx, z = best.wz, t = m } or nil;
				r.exploreGoal = goal;
				if goal and r.why then
					r.why("move", string.format("see %d of %d mobs left: moving up the room to find the rest", #S, need));
				end;
			end;
			if goal then
				local okRt, path = pcall(r.routeTo, { addr = "explore", x = goal.x, z = goal.z }, G, 3);
				local wp;
				if okRt and path then
					for _, p0 in ipairs(path) do
						if (p0.x - G.X) ^ 2 + (p0.z - G.Z) ^ 2 > 4 then wp = p0; break; end;
					end;
				end;
				if wp then SQ(wp.x - G.X, wp.z - G.Z); else SQ(goal.x - G.X, goal.z - G.Z); end;
				r.lhBranch = "looking for the mobs left";
				return;
			end;
		end;
	end;
	-- LOW HP + BOSS: two Worldheart deaths came from charging it with 16 and 27 HP left. Below the low-HP
	-- setting, keep out of the boss's reach and only fight what comes to you until health is back.
	if WQ == "combat" and w and r.bossFight and tostring(w.name) == r.bossFight then
		local hum0 = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
		local hpPct0 = (hum0 and hum0.MaxHealth > 0) and hum0.Health / hum0.MaxHealth * 100 or 100;
		if hpPct0 < (tonumber(CFG.lowHpPct) or 35) then
			local keep = math.max(14, (tonumber(brain.mobReach[tostring(w.name)]) or 0) + 6);
			local dxb, dzb = w.x - G.X, w.z - G.Z;
			local db = math.sqrt(dxb * dxb + dzb * dzb);
			if r.why and m - (r.lowHpNoteAt or 0) > 8 then
				r.lowHpNoteAt = m;
				r.why("combat", string.format("low HP (%d%%): keeping %d st from %s instead of closing in", math.floor(hpPct0), keep, tostring(w.name)));
			end;
			if not eh(Fl, G.X, G.Z) then
				if db < keep and db > .1 then SQ(-dxb / db, -dzb / db); else SQ(nil); end;
				return;
			end;
		end;
	end;
	-- far target (e.g. a pylon across burn strips): walk the route around the hazards instead of a straight line.
	-- No safe route for 4 s: allow crossing lingering ground hazards rather than standing still.
	if WQ == "combat" and Q.chase and w and Q.dodge and not eh(Fl, G.X, G.Z) then
		local reach = math.max(4, YQ());
		if (tonumber(w.d) or 0) > reach + 2 then
			local okRt, path = pcall(r.routeTo, w, G, reach);
			if not okRt then path = nil; end;
			if path then
				r.noRouteSince = nil;
			else
				r.noRouteSince = r.noRouteSince or m;
				if m - r.noRouteSince > 4 and r.lavaOk() then
					local okRt2, p2 = pcall(r.routeTo, w, G, reach, true);
					path = okRt2 and p2 or nil;
				end;
			end;
			if path and #path > 0 then
				local wp;
				for _, p0 in ipairs(path) do
					if (p0.x - G.X) ^ 2 + (p0.z - G.Z) ^ 2 > 4 then wp = p0; break; end;
				end;
				if wp then
					if r.why and (r.routeNoteTo ~= w.addr or m - (r.routeNoteAt or 0) > 10) then
						r.routeNoteTo, r.routeNoteAt = w.addr, m;
						r.why("combat", string.format("routing to %s around hazards (%d tiles, %.0f st away)", tostring(w.name), #path, tonumber(w.d) or 0));
					end;
					SQ(wp.x - G.X, wp.z - G.Z);
					return;
				end;
			end;
		end;
	end;
	-- standing in an attack zone, or the next steps toward the target are in one: get safe first, don't chase
	local chaseUnsafe = false;
	if WQ == "combat" and Q.dodge and w and #Fl > 0 then
		if eh(Fl, G.X, G.Z) then
			chaseUnsafe = true;
		else
			local tdx, tdz = w.x - G.X, w.z - G.Z;
			local tl2 = math.sqrt(tdx * tdx + tdz * tdz);
			if tl2 > .1 then
				local ax, az = G.X + tdx / tl2 * 3, G.Z + tdz / tl2 * 3;
				-- ground attacks only: a projectile lane ahead is gone in a moment and the dodge handles a
				-- shot that's about to hit; treating lanes as walls kept it 40-60 st from the Pale Warden
				local groundZ = {};
				for _, z in ipairs(Fl) do
					if tostring(z.sig or ""):sub(1, 11) ~= "projectile:" then groundZ[#groundZ + 1] = z; end;
				end;
				if eh(groundZ, ax, az) then
					chaseUnsafe = true;
					-- an attack zone sits between us and the target. Standing still here and stepping in again
					-- once it moved made it jitter back and forth (W/S) and burn the timer, so it walks AROUND the
					-- zone toward the target instead: the first safe heading 30-90 degrees off the straight line,
					-- keeping the same side for 1.5 s so it doesn't flip. Only if every heading is blocked, it holds.
					local ux, uz = tdx / tl2, tdz / tl2;
					if tl2 <= math.max(4, YQ()) + .5 then
						-- already in weapon reach: stay out of the zone and keep hitting
						SQ(nil);
						return;
					end;
					local side = r.holdSide and m - r.holdSide.t < 1.5 and r.holdSide.addr == w.addr and r.holdSide.s or nil;
					local pickX, pickZ, pickS;
					for _, deg in ipairs({ 30, 50, 70, 90 }) do
						for _, sg in ipairs(side and { side } or { 1, -1 }) do
							local a = math.rad(deg) * sg;
							local ca, sa = math.cos(a), math.sin(a);
							local dx, dz = ux * ca - uz * sa, ux * sa + uz * ca;
							local ok3 = not eh(groundZ, G.X + dx * 3, G.Z + dz * 3) and not eh(groundZ, G.X + dx * 6, G.Z + dz * 6);
							if ok3 and nav.map then ok3 = navOpenAt(G.X + dx * 3, G.Z + dz * 3) >= 1; end;
							if ok3 then pickX, pickZ, pickS = dx, dz, sg; break; end;
						end;
						if pickX then break; end;
					end;
					if pickX then
						if not (r.holdSide and r.holdSide.addr == w.addr and r.holdSide.s == pickS and m - r.holdSide.t < 1.5) then
							r.holdSide = { s = pickS, t = m, addr = w.addr };
						end;
						if r.why and m - (r.holdNoteAt or 0) > 5 then
							r.holdNoteAt = m;
							r.why("combat", string.format("attack zone between me and %s: going around it", tostring(w.name)));
						end;
						SQ(pickX, pickZ);
						return;
					end;
					if r.why and m - (r.holdNoteAt or 0) > 5 then
						r.holdNoteAt = m;
						r.why("combat", string.format("not chasing %s: attack zone between us, no way around, holding outside", tostring(w.name)));
					end;
					SQ(nil);
					return;
				end;
			end;
		end;
	end;
	if WQ == "combat" and w and r.lastDodgeAt and m - r.lastDodgeAt < .6 and not eh(Fl, G.X, G.Z) then
		if Qh and (Qh.x - G.X) ^ 2 + (Qh.z - G.Z) ^ 2 > 2.25 then SQ(Qh.x - G.X, Qh.z - G.Z); else SQ(nil); end;
		return;
	end;
	if WQ == "combat" and ((Q.combat and ((Q.chase and w)))) and not chaseUnsafe then
		qh(G, w, S, m);
		return;
	end;
	if Q.dodge and (#Fl > 0 and eh(Fl, G.X, G.Z)) then
		local Q = Nh(G.X, G.Z, m);
		if Q then
			if not r.dodging then
				f(string.format("escape to open ground %.1f studs away, zones=%d", math.sqrt(((Q.x - G.X)) ^ 2 + ((Q.z - G.Z)) ^ 2), #Fl));
			end;
			r.dodging, r.lastDodgeAt = true, d();
			SQ(Q.x - G.X, Q.z - G.Z);
			r.lhBranch = "dodging";
			return;
		end;
	end;
	if Q.dodge and #Fl > 0 then
		local m, Q, e = 0, 0, false;
		for r, N in ipairs(Fl) do
			local S, w, q = ul(N, G.X, G.Z, N.pm or Yl);
			if S then
				e = true;
				m, Q = m + w * S, Q + q * S;
			end;
		end;
		if e then
			local e = math.sqrt(m * m + Q * Q);
			if e < .001 then
				m, Q, e = k, T, 1;
			end;
			local N, S = nil, nil;
			for r, w in ipairs(tQ()) do
				local q = (PQ(G.X + w[1] * 2.5, G.Z + w[2] * 2.5) + PQ(G.X + w[1] * 5, G.Z + w[2] * 5)) + PQ(G.X + w[1] * 7.5, G.Z + w[2] * 7.5);
				local l = ((q * 8 + HQ(G, w) * 40)) - ((((w[1] * m + w[2] * Q)) / e)) * 2;
				if CFG.cornerAvoid ~= false then
					l = l + math.max(0, (tonumber(CFG.edgeSafe) or 6) - navOpenAt(G.X + w[1] * 5, G.Z + w[2] * 5)) * 2;
				end;
				if not S or l < S then
					N, S = w, l;
				end;
			end;
			if not r.dodging then
				f(string.format("dodge start (out of combat) zones=%d dir=%.2f,%.2f", #Fl, N[1], N[2]));
			end;
			SQ(N[1], N[2]);
			r.dodging, r.lastDodgeAt = true, d();
			return;
		end;
	end;
	r.dodging = false;
	if WQ == "mine" and Q.centerFarm and E then
		local anchorX, anchorZ = centerFarmAnchor(G);
		if anchorX then
			r.chestWalk = false;
			local dx, dz = anchorX - G.X, anchorZ - G.Z;
			local atAnchor = dx * dx + dz * dz <= 1.25^2;
			local strays = (r.posCount or 0) > 0;
			local cleanup = Q.centerCleanup ~= false;
			if r.strayTrip and (not strays or not cleanup) then
				r.strayTrip = false;
			end;
			if L and (atAnchor or r.strayTrip) then
				-- something is in reach from here: stand still and mine it
				SQ(nil);
				return;
			end;
			if not L and cleanup and strays and u and (r.strayTrip or (atAnchor and r.noAimSince and m - r.noAimSince > .8)) then
				-- ores the anchor can't reach (edge of the arena / off screen): walk to them, then head back
				r.strayTrip = true;
				SQ(u.X - G.X, u.Z - G.Z);
				return;
			end;
			if atAnchor then
				SQ(nil);
			else
				L = nil;
				r.progressAt = m;
				SQ(dx, dz);
			end;
			return;
		end;
	end;
	if Q.chests and WQ ~= "combat" then
		local m = cl(G);
		if m then
			local Q, e = m.x - G.X, m.z - G.Z;
			-- (v5.34) not a chest the collapse gets to first, and no detours with under 12 s left
			local tooLate;
			if Q * Q + e * e > 1 then
				local okT, why = pcall(r.chestTooLate, G, m);
				if okT and why then
					tooLate = true;
					local ck0 = math.floor(m.x) .. "_" .. math.floor(m.z);
					if r.why and r.chestSkipFor ~= ck0 then
						r.chestSkipFor = ck0;
						r.why("move", string.format("skipping a chest %.0f st away: %s", math.sqrt(Q * Q + e * e), why));
					end;
				end;
			end;
			if Q * Q + e * e > 1 and not tooLate then
				local ck = math.floor(m.x) .. "_" .. math.floor(m.z);
				if r.why and ck ~= r.chestNoteFor then
					r.chestNoteFor = ck;
					r.why("move", string.format("walking to a chest %.0f st away", math.sqrt(Q * Q + e * e)));
				end;
				r.chestWalk = true;
				r.lhBranch = "walking to a chest";
				-- around attack zones and burn strips when possible, otherwise the pillar-aware straight route
				local okR, cpath = pcall(r.routeTo, { addr = "chest" .. math.floor(m.x) .. "_" .. math.floor(m.z), x = m.x, z = m.z }, G, 1.5);
				local cwp;
				if okR and cpath then
					for _, p0 in ipairs(cpath) do
						if (p0.x - G.X) ^ 2 + (p0.z - G.Z) ^ 2 > 4 then cwp = p0; break; end;
					end;
				end;
				if cwp then
					SQ(cwp.x - G.X, cwp.z - G.Z);
				else
					local okS, sx, sz = pcall(r.steerDir, G, m.x, m.z);
					if okS and sx then SQ(sx, sz); else SQ(Q, e); end;
				end;
				return;
			end;
		end;
	end;
	r.chestWalk = false;
	-- KEEP MOVING FORWARD (Delve, v5.31): all the time, not only when the floor timer runs low. Ores ahead
	-- come first (Ql); with nothing to walk to it heads for the chamber's exit. A missed ore behind is still
	-- mined if it can get there and mine it before that spot falls (collapse front from SessionSync, else
	-- the floor timer, else nothing is collapsing). An ore in reach is mined unless the floor under you
	-- falls first.
	-- (v5.33) With no floor map it walks the forward direction with a floor check every step; past the
	-- Unmaker (or while the stall watchdog kicks) it keeps going past the last floor tile, floor checked; and
	-- with no forward signal at all it says why (every 10 s) instead of standing there silently.
	do
		if CFG.pushForward ~= false and run.isDelve and WQ ~= "combat" and Q.on then
			local kick = r.stallKick and m < r.stallKick.untilT;
			-- (v5.34) past the Unmaker = its Tithe was taken in this cycle (the depth label keeps counting after
			-- a prestige, so "deeper than 17,520 m" stayed true for the whole next cycle)
			local pastBoss = r.unmakerDownKey ~= nil and r.cycleKey and r.unmakerDownKey == r.cycleKey();
			local okF, fx, fz, gx, gz, gp, fsrc = pcall(r.forwardInfo, G.X, G.Z);
			if okF and fx then
				local humS = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
				local spd = math.max(8, humS and humS.WalkSpeed or 16);
				local tlF = tonumber(run.timeLeft);
				local function timeLeftAt(z)
					local okC, sec = pcall(function() return r.room and r.room.secondsUntilFalls(z); end);
					if okC and sec then return sec, "the collapse"; end;
					if tlF then return tlF, "the floor timer"; end;
					return math.huge, "nothing collapsing";
				end;
				local reason, stuckBack;
				if u and ((u.X - G.X) * fx + (u.Z - G.Z) * fz) < -4 then
					local need = math.sqrt((u.X - G.X) ^ 2 + (u.Z - G.Z) ^ 2) / spd + 1.5;
					local left, how = timeLeftAt(u.Z);
					if need >= left - 3 then
						reason = string.format("ore behind needs %.1fs, %s leaves %.1fs", need, how, left);
						stuckBack = true;
					end;
				elseif not u and L then
					local left, how = timeLeftAt(G.Z);
					if left < 3 then
						reason = string.format("%s reaches this spot in %.1fs", how, left);
						stuckBack = true;
					end;
				elseif not u then
					reason = "nothing left to walk to";
				end;
				if kick and not reason then reason = "standing still too long, moving on"; end;
				if reason then
					local key = reason:sub(1, 14);
					if r.why and (m - (r.fwdNoteAt or 0) > 5 or r.fwdNoteKey ~= key) then
						r.fwdNoteAt, r.fwdNoteKey = m, key;
						r.why("move", string.format("walking up the road (%s, %.0f st): %s", tostring(fsrc), gp or 0, reason));
					end;
					if gx and (gp or 0) > 3 then
						local wp;
						if nav.map then
							local okRt, path = pcall(r.routeTo, { addr = "forward", x = gx, z = gz }, G, 3);
							if okRt and path then
								for _, p0 in ipairs(path) do
									if (p0.x - G.X) ^ 2 + (p0.z - G.Z) ^ 2 > 4 then wp = p0; break; end;
								end;
							end;
						end;
						if wp then
							SQ(wp.x - G.X, wp.z - G.Z);
						else
							-- no route (or no floor map): straight that way, but only onto floor
							local okH, hx, hz = pcall(r.floorHeading, G, gx - G.X, gz - G.Z);
							if okH and hx then SQ(hx, hz); elseif nav.map then SQ(gx - G.X, gz - G.Z); else SQ(nil); end;
						end;
						r.lhBranch = "walking up the road";
						return;
					elseif stuckBack then
						-- already at the exit: don't walk back into the collapse for it
						SQ(nil);
						r.lhBranch = "holding at the exit (collapse behind)";
						return;
					elseif (kick or pastBoss) and not u and not L then
						-- at the last floor tile with nothing to do (the room after the Unmaker isn't built from
						-- shaft tiles): keep going that way, floor checked every step
						local okH, hx, hz = pcall(r.floorHeading, G, fx, fz);
						if okH and hx then
							if r.why and m - (r.pastFloorNoteAt or 0) > 8 then
								r.pastFloorNoteAt = m;
								r.why("move", "at the last floor tile with nothing to do: walking on that way (floor checked every step)");
							end;
							SQ(hx, hz);
							r.lhBranch = "walking past the last floor tile";
							return;
						end;
					end;
				end;
			elseif (not u and not L) or kick then
				-- no forward signal at all: walk the road's learned direction if there is one, and say why
				local why = okF and "no direction signal" or ("forward check error: " .. tostring(fx));
				pcall(function()
					local c, src = r.room.current(G.Z);
					if not c then why = why .. "; " .. tostring(src); end;
				end);
				local td = type(brain.tunnelDir) == "table" and brain.tunnelDir or nil;
				local hx, hz;
				if td and tonumber(td.x) and tonumber(td.z) then
					local okH, h1, h2 = pcall(r.floorHeading, G, td.x, td.z);
					if okH then hx, hz = h1, h2; end;
				end;
				if r.why and m - (r.noFwdNoteAt or 0) > 10 then
					r.noFwdNoteAt = m;
					r.why("move", string.format("nothing to walk to and no forward goal (%s)%s", why, hx and ": walking the road's learned direction" or ""));
				end;
				if hx then
					SQ(hx, hz);
					r.lhBranch = "walking the road's learned direction";
					return;
				end;
			end;
		end;
	end;
	if WQ == "mine" and ((Q.walk and u)) then
		local okS, sx, sz = pcall(r.steerDir, G, u.X, u.Z);
		if okS and sx then SQ(sx, sz); else SQ(u.X - G.X, u.Z - G.Z); end;
		r.lhBranch = "walking to an ore";
		return;
	end;
	if WQ ~= "combat" then r.lhBranch = L and "mining an ore in reach" or "nothing to do"; end;
	SQ(nil);
end;
-- ===================================================================================
-- DISCORD WEBHOOK: "Run Complete" post when a run ends
--   With delve_webhook_helper.ps1 running on your PC, the post includes a screenshot of your
--   screen (Roblox can't capture the screen itself, so the script drops a job file in the
--   executor's workspace\DelveWebhook folder and the helper screenshots + uploads it).
--   Without the helper it still posts the run stats as text.
-- ===================================================================================
-- Discord message body. A mention only pings when it's in the message text (not inside the embed),
-- and allowed_mentions limits it to that one user.
r.discordPayload = function(embed, kind)
	local payload = { username = "Delve Brain", embeds = { embed } };
	local id = tostring(CFG.pingUserId or ""):match("^%s*(%d%d%d%d%d+)%s*$");
	local want = (kind == "run" and CFG.pingRuns ~= false) or (kind == "drop" and CFG.pingDrops ~= false) or kind == "test"
		or (kind == "alert" and CFG.pingDisconnect ~= false) or (kind == "vesper" and CFG.vesperPause ~= false);
	if id and want then
		payload.content = "<@" .. id .. ">";
		payload.allowed_mentions = { users = { id } };
	else
		payload.allowed_mentions = { parse = {} };
	end;
	return payload;
end;
r.sendRunWebhook = function(info, isTest)
	if not isTest and CFG.webhookOn ~= true then return false; end;
	local url = tostring(CFG.webhookUrl or "");
	url = url:gsub("^%s+", ""):gsub("%s+$", "");
	if not url:match("^https://[%w%.]*discord[%w]*%.com/api/webhooks/%d+/[%w%-_]+") then
		if isTest then notify("Paste a Discord webhook URL first (https://discord.com/api/webhooks/...).", "Delve webhook"); end;
		return false;
	end;
	local Hs = game:GetService("HttpService");
	info = info or {};
	local function money(v)
		v = tonumber(v) or 0;
		local sign = v < 0 and "-" or "";
		v = math.abs(v);
		for _, u in ipairs({ { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
			if v >= u[1] then return string.format("%s$%.2f%s", sign, v / u[1], u[2]); end;
		end;
		return string.format("%s$%.0f", sign, v);
	end;
	local secs = tonumber(info.seconds) or 0;
	local relicText = type(info.relics) == "table" and table.concat(info.relics, ", ") or "";
	if relicText == "" then relicText = "none"; end;
	if #relicText > 1000 then relicText = relicText:sub(1, 997) .. "..."; end;
	local function num(v)
		v = tonumber(v);
		if not v then return "?"; end;
		local s2 = tostring(math.floor(v + .5));
		local out = s2:reverse():gsub("(%d%d%d)", "%1,"):reverse();
		return (out:gsub("^,", ""):gsub("^%-,", "-"));
	end;
	local known = 0;
	for _ in pairs(brain.codex) do known = known + 1; end;
	local depthText = tostring(math.floor(tonumber(info.depth) or 0)) .. " m";
	if tonumber(info.maxDepth) and tonumber(info.maxDepth) > (tonumber(info.depth) or 0) then
		depthText = depthText .. string.format(" (max %d m)", info.maxDepth);
	end;
	local fields = {};
	local function add(name, value, inline)
		fields[#fields + 1] = { name = name, value = tostring(value), inline = inline ~= false };
	end;
	if info.mode == "delve" then add("Depth", depthText); else add("Wave", tostring(info.wave or 0)); end;
	add("Trip cash value", info.tripValue and money(info.tripValue) or "?");
	add("Cash change", money(info.cash));
	add("Rocks mined", num(info.rocks));
	add("XP gained", info.xp and ("+" .. num(info.xp)) or "?");
	add("Materials", info.materials and ("+" .. num(info.materials)) or "?");
	add("Level", tostring(info.level or "?") .. ((tonumber(info.levelUp) or 0) > 0 and string.format(" (+%d)", info.levelUp) or ""));
	add("Time", string.format("%dm %02ds", math.floor(secs / 60), secs % 60));
	add("Outcome", (info.died and "Died" or "Survived") .. string.format(", %d hits", tonumber(info.hits) or 0));
	add("Run score", string.format("%.1f (%+.2f vs avg)", tonumber(info.score) or 0, tonumber(info.z) or 0));
	add("Fighting", info.combatPct and (tostring(info.combatPct) .. "% of the time") or "?");
	if info.closeCalls then add("Timer close calls", tostring(info.closeCalls)); end;
	if (tonumber(info.prestige) or 0) > 0 then add("Prestige", tostring(info.prestige) .. " (depth counts every cycle)"); end;
	if type(info.newMechanics) == "table" and #info.newMechanics > 0 then
		add("New mechanics found", table.concat(info.newMechanics, "\n"):sub(1, 1000), false);
	end;
	if type(info.rareDrops) == "table" and next(info.rareDrops) then
		local rl = {};
		for nm, n in pairs(info.rareDrops) do rl[#rl + 1] = string.format("%s x%d", nm, n); end;
		table.sort(rl);
		add("Rare drops", table.concat(rl, ", "):sub(1, 1000), false);
	end;
	add("Brain", string.format("%d runs, %d relics known", tonumber(brain.runCount) or 0, known));
	if type(brain.player) == "table" and brain.player.power then
		add("Gear", string.format("power %s, luck %s, dmg %s", tostring(brain.player.power), tostring(brain.player.luck or "?"), tostring(brain.player.damage or "?")));
	end;
	if type(brain.lifetime) == "table" and next(brain.lifetime) then
		local lines = {};
		for _, k2 in ipairs({ "CASH EARNED", "BEST RUN", "DEEPEST DELVE", "RUNS", "ROCKS BROKEN", "MATERIALS MINED",
			"MOBS KILLED", "BIG BOSSES SLAIN", "CHESTS OPENED", "RUNES FOUND", "TIME MINING", "INDEX" }) do
			local v2 = brain.lifetime[k2];
			if v2 then lines[#lines + 1] = k2:sub(1, 1) .. k2:sub(2):lower() .. ": " .. tostring(v2); end;
		end;
		if #lines > 0 then add("Lifetime", table.concat(lines, "\n"), false); end;
	end;
	if type(brain.player) == "table" and brain.player.pickaxe then
		add("Loadout", string.format("%s (%s)\n%s (%s)", tostring(brain.player.pickaxe), tostring(brain.player.pickPower or "?"),
			tostring(brain.player.sword or "?"), tostring(brain.player.swordPower or "?")), true);
	end;
	add("Relics taken (" .. tostring(type(info.relics) == "table" and #info.relics or 0) .. ")", relicText, false);
	local title = isTest and "Webhook test" or "Run Complete";
	if not isTest and info.mode == "delve" then
		title = string.format("Run Complete - Delve %dm", math.floor(tonumber(info.depth) or 0));
	elseif not isTest and (tonumber(info.wave) or 0) > 0 then
		title = string.format("Run Complete - Wave %d", info.wave);
	end;
	local embed = {
		title = title,
		description = info.title and ("> " .. tostring(info.title)) or nil,
		color = isTest and 3447003 or (info.died and 15158332 or 3066993),
		fields = fields,
		footer = { text = "Delve v3 brain | " .. tostring(l.Name) .. " | " .. tostring(info.source or "live tracking") },
	};
	pcall(function() embed.timestamp = DateTime.now():ToIsoDate(); end);
	-- is the screenshot helper running? (it refreshes this file every few seconds)
	local helperAlive = false;
	pcall(function()
		if type(isfile) == "function" and isfile("DelveWebhook/helper_alive.txt") then
			local t = tonumber((readfile("DelveWebhook/helper_alive.txt") or ""):match("%d+"));
			helperAlive = t ~= nil and math.abs(os.time() - t) < 20;
		end;
	end);
	if helperAlive and type(writefile) == "function" then
		embed.image = { url = "attachment://run.png" };
		local job = { url = url, payload = r.discordPayload(embed, isTest and "test" or "run"), image = (not isTest) and r.lastSnap or nil };
		r.lastSnap = nil;
		local ok = pcall(function()
			writefile(string.format("DelveWebhook/job_%d_%d.json", os.time(), math.random(1000, 9999)), Hs:JSONEncode(job));
		end);
		if ok then
			if isTest then notify("Sent to the screenshot helper. Check Discord in a few seconds.", "Delve webhook"); end;
			return true;
		end;
	end;
	local req = (type(request) == "function" and request) or (type(http_request) == "function" and http_request)
		or (type(syn) == "table" and syn.request) or (type(http) == "table" and http.request);
	if not req then
		notify("This executor has no request() function, and the screenshot helper isn't running.", "Delve webhook");
		return false;
	end;
	embed.footer.text = embed.footer.text .. " | start delve_webhook_helper.ps1 for screenshots";
	local ok, res = pcall(req, {
		Url = url,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = Hs:JSONEncode(r.discordPayload(embed, isTest and "test" or "run")),
	});
	local code = ok and type(res) == "table" and tonumber(res.StatusCode) or nil;
	if isTest then
		notify(code and code < 300 and "Webhook OK (text only: screenshot helper not running)." or ("Webhook failed: " .. tostring(code or res)), "Delve webhook");
	end;
	return code ~= nil and code < 300;
end;
pcall(function()
	if type(makefolder) == "function" and (type(isfolder) ~= "function" or not isfolder("DelveWebhook")) then
		makefolder("DelveWebhook");
	end;
end);
-- generic Discord post (used by rare-drop alerts); screenshot attached when the helper is running
r.postEmbed = function(embed, kind)
	kind = kind or "drop";
	local url = tostring(CFG.webhookUrl or ""):gsub("^%s+", ""):gsub("%s+$", "");
	if CFG.webhookOn ~= true or not url:match("^https://[%w%.]*discord[%w]*%.com/api/webhooks/%d+/[%w%-_]+") then return false; end;
	local Hs = game:GetService("HttpService");
	pcall(function() embed.timestamp = DateTime.now():ToIsoDate(); end);
	local helperAlive = false;
	pcall(function()
		if type(isfile) == "function" and isfile("DelveWebhook/helper_alive.txt") then
			local t = tonumber((readfile("DelveWebhook/helper_alive.txt") or ""):match("%d+"));
			helperAlive = t ~= nil and math.abs(os.time() - t) < 20;
		end;
	end);
	if helperAlive and type(writefile) == "function" then
		embed.image = { url = "attachment://run.png" };
		local ok = pcall(function()
			writefile(string.format("DelveWebhook/job_%d_%d.json", os.time(), math.random(1000, 9999)),
				Hs:JSONEncode({ url = url, payload = r.discordPayload(embed, kind), retry = kind == "alert" or nil }));
		end);
		if ok then return true; end;
		embed.image = nil;
	end;
	local req = (type(request) == "function" and request) or (type(http_request) == "function" and http_request)
		or (type(syn) == "table" and syn.request) or (type(http) == "table" and http.request);
	if not req then return false; end;
	local ok, res = pcall(req, {
		Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" },
		Body = Hs:JSONEncode(r.discordPayload(embed, kind)),
	});
	return ok and type(res) == "table" and (tonumber(res.StatusCode) or 999) < 300;
end;
-- (v5.39) VESPER'S SHOP: the "?????" portal after the Unmaker (Plates...VesperGate) takes you to workspace.VesperSanctum,
-- far from the delve. When you arrive there: a Discord ping and everything paused like F2 (press F2 to carry on).
-- Checked once a second (a distance or two); the bot never buys, sells or talks to Vesper.
task.spawn(function()
	local inside, since, notified, awaySince = false, nil, false, nil;
	local box = { at = -1e9 };
	while not r.stopped do
		task.wait(1);
		pcall(function()
			if CFG.vesperPause == false then inside, since, notified = false, nil, false; return; end;
			local sanctum = workspace:FindFirstChild("VesperSanctum");
			local hrp = l.Character and l.Character:FindFirstChild("HumanoidRootPart");
			local here = false;
			if sanctum and hrp then
				local pos = hrp.Position;
				local gate = sanctum:FindFirstChild("ReturnGate");
				local okA, anchor = pcall(function()
					if gate and gate:IsA("Model") then return gate:GetPivot().Position; end;
					if gate and gate:IsA("BasePart") then return gate.Position; end;
					return sanctum:GetPivot().Position;
				end);
				if okA and anchor and (pos - anchor).Magnitude < (inside and 900 or 600) then here = true; end;
				if not here then
					-- the sanctum's outline (read every 30 s; ignored if it's huge)
					if box.model ~= sanctum or os.clock() - box.at > 30 then
						box.model, box.at = sanctum, os.clock();
						local okB, cf, size = pcall(function() return sanctum:GetBoundingBox(); end);
						box.cf, box.size = okB and cf or nil, okB and size or nil;
					end;
					if box.cf and box.size and box.size.X < 2500 and box.size.Z < 2500 then
						local lp = box.cf:PointToObjectSpace(pos);
						here = math.abs(lp.X) <= box.size.X / 2 + 25 and math.abs(lp.Z) <= box.size.Z / 2 + 25 and math.abs(lp.Y) <= box.size.Y / 2 + 80;
					end;
				end;
			end;
			inside = here;
			if not here then
				-- gone for 5 s (not a blink while the character reloads): the next visit pings again
				since = nil;
				awaySince = awaySince or os.clock();
				if os.clock() - awaySince >= 5 then notified = false; end;
				return;
			end;
			awaySince = nil;
			since = since or os.clock();
			-- right away; the pause waits for the window (the F2 code) for up to 15 s after the script loads
			if notified or not (r.f2Pause or os.clock() - since >= 15) then return; end;
			notified = true;
			local paused = r.f2Pause and r.f2Pause() or false;
			notify("At Vesper's shop: everything is paused (like F2). Press F2 to start farming again.", "Delve");
			if r.why then
				r.why("run", string.format("arrived at Vesper's shop%s; Discord ping sent (realm %s)",
					paused and ": everything paused like F2" or " (already paused)", tostring(r.room and r.room.s and r.room.s.realm)));
			end;
			pcall(r.postEmbed, {
				title = "At Vesper's shop",
				description = "You went through the ????? portal and arrived at Vesper's shop. Everything is paused (like F2), so you have control. Press F2 to start farming again.",
				color = 10181046,
			}, "vesper");
		end);
	end;
end);
-- DISCONNECT ALERT: Roblox's "Disconnected" / kick prompt pings you on Discord (with the helper running it
-- keeps retrying until the internet is back). A heartbeat file lets the helper ping you too if Roblox
-- closes, crashes or freezes while the bot was on.
task.spawn(function()
	local Hs = game:GetService("HttpService");
	local GS = game:GetService("GuiService");
	local alerted = false;
	-- (v5.38) AUTO-REJOIN: after a disconnect while farming it joins a new Delve server inside the same Roblox, so
	-- Volt (which only connects to a Roblox it launched) stays connected and the script loads again: the autoexec
	-- does that, and a queued loader covers the case where the autoexec doesn't run after a teleport. Never after a
	-- kick or ban, or when the account joined from another device (rejoining would throw that session out). A rejoin
	-- that worked is counted when the script loads again; after 5 in an hour it stops and pings you.
	local REJOIN_FILE = "DelveRejoins.json";
	local function rejoinState()
		local okR, data = pcall(function()
			if type(isfile) == "function" and isfile(REJOIN_FILE) then return Hs:JSONDecode(readfile(REJOIN_FILE)); end;
			return nil;
		end);
		local st = (okR and type(data) == "table") and data or {};
		st.times = type(st.times) == "table" and st.times or {};
		return st;
	end;
	local function saveRejoinState(st)
		pcall(function() if type(writefile) == "function" then writefile(REJOIN_FILE, Hs:JSONEncode(st)); end; end);
	end;
	local function recentRejoins(st, now)
		local keep = {};
		for _, t0 in ipairs(st.times) do
			if now - (tonumber(t0) or 0) < 3600 then keep[#keep + 1] = t0; end;
		end;
		st.times = keep;
		return #keep;
	end;
	-- back after a rejoin: count it and say so (no ping)
	pcall(function()
		local st = rejoinState();
		local now = os.time();
		if type(st.pending) == "table" and now - (tonumber(st.pending.at) or 0) < 1800 then
			recentRejoins(st, now);
			st.times[#st.times + 1] = now;
			local why0 = tostring(st.pending.msg or "");
			st.pending = nil;
			saveRejoinState(st);
			if r.why then r.why("run", string.format("back in Delve after a disconnect (rejoin %d in the last hour): %s", #st.times, why0)); end;
			pcall(r.postEmbed, {
				title = "Back in Delve",
				description = string.format("Rejoined by itself after a disconnect (%s). Farming carries on. Rejoins in the last hour: %d of 5.",
					why0 ~= "" and why0 or "no message", #st.times),
				color = 3066993,
			}, "rejoin");
		elseif st.pending then
			st.pending = nil;
			saveRejoinState(st);
		end;
	end);
	-- messages that must not be answered with a rejoin
	local function rejoinBlockedBy(mu)
		local rules = {
			{ "ANOTHER DEVICE", "your account joined from another device" }, { "DIFFERENT DEVICE", "your account joined from another device" },
			{ "SAME ACCOUNT", "your account joined from another device" }, { "BANNED", "a ban" }, { "EXPLOIT", "the game flagged the client" },
			{ "UNEXPECTED CLIENT", "the game flagged the client" }, { "KICK", "you were kicked" },
		};
		for _, rule in ipairs(rules) do
			if mu:find(rule[1], 1, true) and not (rule[1] == "KICK" and mu:find("IDLE", 1, true)) then return rule[2]; end;
		end;
		return nil;
	end;
	local function startRejoin(msg)
		task.spawn(function()
			local TS = game:GetService("TeleportService");
			local failMsg;
			pcall(function()
				TS.TeleportInitFailed:Connect(function(_, result, em)
					failMsg = tostring(result) .. (em ~= nil and (": " .. tostring(em)) or "");
				end);
			end);
			local st = rejoinState();
			st.pending = { at = os.time(), msg = msg };
			saveRejoinState(st);
			-- if the autoexec doesn't run after the teleport, this loads the script 35 s after arriving (only if
			-- nothing else did by then)
			pcall(function()
				local q = (type(queue_on_teleport) == "function" and queue_on_teleport) or (type(queueonteleport) == "function" and queueonteleport) or nil;
				if q then
					q([[task.spawn(function() local arrived = os.time(); task.wait(35); local env = (type(getgenv) == "function" and getgenv()) or _G; if (tonumber(env.DelveLoadedAt) or 0) < arrived then loadstring(game:HttpGet("https://raw.githubusercontent.com/pokemoncombi145-sys/delve/main/delve_v3.lua"))(); end; end)]]);
				end;
			end);
			local waits = { 5, 15, 30, 60 };
			local started = os.time();
			for attempt = 1, 200 do
				task.wait(attempt <= #waits and waits[attempt] or 120);
				if os.time() - started > 3 * 3600 then break; end;
				failMsg = nil;
				pcall(function() if r.why then r.why("run", string.format("rejoining Delve (try %d)", attempt)); end; end);
				-- Delve's start place (the hub): the farm starts the stage from there, as after any join
				local target = (tostring(game.GameId) == "10766181632") and 132273490031319 or game.PlaceId;
				pcall(function() TS:Teleport(target, l); end);
				-- a teleport that works ends this script here (the new server loads it again); otherwise try again
				task.wait(20);
				if failMsg then pcall(function() if r.why then r.why("run", "rejoin try failed: " .. failMsg); end; end); end;
			end;
			pcall(r.postEmbed, { title = "Delve: auto-rejoin gave up", description = "Couldn't get back in for 3 hours.", color = 15158332 }, "alert");
		end);
	end;
	local function alert(msg)
		if alerted or r.stopped then return; end;
		-- you left / closed the game yourself (or a normal teleport): not a disconnect, no ping
		local mu = tostring(msg or ""):upper();
		if mu:find("CLIENTINITIATED", 1, true) or mu:find("CLIENT INITIATED", 1, true) or mu:find("LEFT THE GAME", 1, true) then return; end;
		alerted = true;
		msg = tostring(msg or ""):gsub("^%s+", ""):gsub("%s+$", "");
		-- (v5.38) rejoin by itself? only while farming, when the message allows it, and at most 5 rejoins an hour
		local rejoin, notWhy = false, nil;
		if CFG.autoRejoin == false then
			notWhy = "\"Rejoin after a disconnect\" is off";
		elseif not (CFG.on or r.autoStart) then
			-- (v5.38.1) say so: a test with the farm paused looked like nothing happened
			notWhy = "Auto Farm is off or paused with F2, so you have control";
		else
			notWhy = rejoinBlockedBy(mu);
			if not notWhy then
				local st = rejoinState();
				if recentRejoins(st, os.time()) >= 5 then notWhy = "it already rejoined 5 times in the last hour"; else rejoin = true; end;
			end;
		end;
		local tail = rejoin and " (rejoining by itself)" or (notWhy and (" (not rejoining: " .. notWhy .. ")") or "");
		pcall(function() if r.why then r.why("run", "disconnected: " .. msg .. tail); end; end);
		pcall(function() notify("Disconnected: " .. msg .. (rejoin and " Rejoining by itself..." or (notWhy and (" Not rejoining: " .. notWhy .. ".") or "")), "Delve"); end);
		local depth = (type(run) == "table" and run.depth) or 0;
		pcall(r.postEmbed, {
			title = "Disconnected from Delve",
			description = (msg ~= "" and msg or "Roblox showed a disconnect prompt.") .. string.format("\nDepth when it happened: %s m", tostring(depth))
				.. (rejoin and "\nRejoining by itself in 5 s." or (notWhy and ("\nNot rejoining: " .. notWhy .. ".") or "")),
			color = 15158332,
		}, "alert");
		if rejoin then startRejoin(msg); end;
	end;
	pcall(function()
		GS.ErrorMessageChanged:Connect(function()
			local okM, m = pcall(function() return GS:GetErrorMessage(); end);
			if okM and type(m) == "string" and m ~= "" then alert(m); end;
		end);
	end);
	pcall(function()
		local ov = game:GetService("CoreGui"):WaitForChild("RobloxPromptGui", 60):WaitForChild("promptOverlay", 60);
		ov.ChildAdded:Connect(function(c)
			if c.Name ~= "ErrorPrompt" then return; end;
			task.wait(1);
			local m = "";
			pcall(function()
				for _, o in ipairs(c:GetDescendants()) do
					if o:IsA("TextLabel") and o.Text:find("Error Code", 1, true) then m = o.Text; end;
				end;
			end);
			alert(m ~= "" and m or "Disconnected");
		end);
	end);
	-- heartbeat for the helper (only while webhooks are set up)
	while true do
		if r.stopped then break; end;
		pcall(function()
			local url = tostring(CFG.webhookUrl or ""):gsub("^%s+", ""):gsub("%s+$", "");
			if CFG.webhookOn == true and CFG.pingDisconnect ~= false and type(writefile) == "function"
				and url:match("^https://[%w%.]*discord[%w]*%.com/api/webhooks/%d+/[%w%-_]+") then
				local depth = (type(run) == "table" and run.depth) or 0;
				writefile("DelveWebhook/game_alive.json", Hs:JSONEncode({
					t = os.time(), farming = (CFG.on or r.autoStart) and true or false, alerted = alerted, url = url,
					payload = r.discordPayload({
						title = "Delve stopped",
						description = string.format("The script stopped reporting: Roblox closed, crashed or froze. Last depth %s m. Auto-rejoin can't start Roblox again: press Launch in Volt.", tostring(depth)),
						color = 15158332,
					}, "alert"),
				}));
			end;
		end);
		task.wait(10);
	end;
end);
-- ===================================================================================
-- INDEX + EQUIPMENT KNOWLEDGE
--   * on launch: opens the T menu, reads every Index entry (name, zone, "1 in N", found or not)
--     straight from the GUI (entries scrolled out of view are still readable, no scrolling needed)
--   * selects each FOUND entry it hasn't studied yet to read which rocks drop it and how often
--     (Field Stone 1 in 1.4, Copper Vein 1 in 33...). Already-studied entries are skipped next time.
--     Studying happens outside a run; during a run only the quick read is done.
--   * reads Equipment stats (luck, power, damage, health, selected item stats). Never clicks
--     anything in Equipment, so it can't equip or sell by accident.
--   * learns from drop pop-ups as you play; rare drops / new index entries go to Discord
--   * uses the drop tables to rate rocks: rocks that drop rare or still-missing ores get mined first
-- ===================================================================================
local indexAPI = (function()
	-- ===============================================================================
	-- INDEX / EQUIPMENT / STATS: one careful scan, then it stops.
	--   * runs once per launch (outside a run), or when you press "Scan" in the Brain tab
	--   * Index: scrolls the grid top to bottom, clicks every found item, waits for its details,
	--     scrolls the details list to the end and saves every source (mob/rock, zone, odds).
	--     Items already studied are skipped next launch.
	--   * Stats: scrolls both panels (Your Stats + Lifetime) to the end, reading row by row.
	--   * Equipment: read only, never clicks.
	--   * Writes the real menu layout to DelveGuiDump_*.txt so the readers can be tuned.
	--   After the scan nothing here touches the GUI again: drops are caught only from text that
	--   newly appears during a run (no repeated whole-screen searches -> no frame drops).
	-- ===============================================================================
	brain.index = type(brain.index) == "table" and brain.index or {};
	brain.sources = type(brain.sources) == "table" and brain.sources or {};
	brain.player = type(brain.player) == "table" and brain.player or {};
	brain.you = type(brain.you) == "table" and brain.you or {};
	brain.lifetime = type(brain.lifetime) == "table" and brain.lifetime or {};
	brain.gear = type(brain.gear) == "table" and brain.gear or {};
	if (tonumber(brain.cleanV) or 0) == 2 then
		-- v3.9 put a hidden template row (FIELD STONE, GRASSLANDS, 1 in 1.4) first in every item's sources.
		-- Remove it (except for STONE, which really drops from Field Stone) and keep everything else,
		-- so items that were already studied are not clicked again.
		brain.cleanV = 3;
		brain.sources = {};
		for key, rec in pairs(brain.index) do
			if type(rec) == "table" and type(rec.sources) == "table" then
				local first = rec.sources[1];
				if key ~= "STONE" and type(first) == "table" and tostring(first.name):upper() == "FIELD STONE"
					and tonumber(first.odds) == 1.4 then
					table.remove(rec.sources, 1);
				end;
				if rec.studied then rec.sv = 3; end;
				for _, sv in ipairs(rec.sources) do
					if type(sv) == "table" and sv.name then
						local sk = tostring(sv.name):upper() .. (sv.zone and (" | " .. tostring(sv.zone):upper()) or "");
						local srec = type(brain.sources[sk]) == "table" and brain.sources[sk] or { name = sv.name, zone = sv.zone, drops = {} };
						srec.drops[key] = sv.odds;
						brain.sources[sk] = srec;
					end;
				end;
			end;
		end;
	end;
	if (tonumber(brain.cleanV) or 0) < 2 then
		-- v3.6 read the Stats panels badly and logged index-screen labels as drops: start those fresh
		brain.cleanV = 2;
		brain.lifetime, brain.index, brain.rocks = {}, {}, nil;
	end;
	-- FORSAKEN / ETERNAL are above Mythic (e.g. "[FORSAKEN] Player found an Ascension Stone! (1 in 1,750,000)")
	local TIERS = { COMMON = 1, UNCOMMON = 2, RARE = 3, EPIC = 4, LEGENDARY = 5, MYTHIC = 6, EXOTIC = 6, DIVINE = 7, SECRET = 7, FORSAKEN = 8, ETERNAL = 9 };
	local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")); end;
	local function txt(o)
		local ok, v = pcall(function() return o.ContentText; end);
		if ok and type(v) == "string" and v ~= "" then return v; end;
		return o.Text or "";
	end;
	local function shown(o)
		while o and o ~= game do
			if o:IsA("LayerCollector") then return o.Enabled ~= false; end;
			if o:IsA("GuiObject") and not o.Visible then return false; end;
			o = o.Parent;
		end;
		return false;
	end;
	local function oddsIn(t)
		local n = tostring(t or ""):upper():match("1%s+IN%s+([%d,%.]+)");
		return n and tonumber((n:gsub(",", ""))) or nil;
	end;
	local function numOf(t)
		local v = tostring(t or ""):gsub("[^%d%.]", "");
		return tonumber(v);
	end;
	local function pgui() return l:FindFirstChild("PlayerGui"); end;
	local function isText(o) return o:IsA("TextLabel") or o:IsA("TextButton"); end;
	local function labelsIn(root)
		local out = {};
		for _, o in ipairs(root:GetDescendants()) do
			if isText(o) and o.Visible then
				local raw = trim(txt(o));
				if raw ~= "" then
					local p, sz = o.AbsolutePosition, o.AbsoluteSize;
					out[#out + 1] = { o = o, raw = raw, t = raw:upper(), x = p.X, y = p.Y + sz.Y / 2, w = sz.X, h = sz.Y };
				end;
			end;
		end;
		return out;
	end;
	local function joined(root)
		local ls = labelsIn(root);
		table.sort(ls, function(a2, b2)
			if math.abs(a2.y - b2.y) > 6 then return a2.y < b2.y; end;
			return a2.x < b2.x;
		end);
		local parts = {};
		for _, L in ipairs(ls) do parts[#parts + 1] = L.raw; end;
		return table.concat(parts, " "), ls;
	end;
	local function sizedAncestor(o, minX, minY)
		local a2 = o.Parent;
		while a2 and a2:IsA("GuiObject") do
			local s2 = a2.AbsoluteSize;
			if s2.X >= minX and s2.Y >= minY then return a2; end;
			a2 = a2.Parent;
		end;
		return nil;
	end;
	local function waitFor(fn, secs)
		local t0 = d();
		while d() - t0 < secs do
			local v = fn();
			if v then return v; end;
			task.wait(.1);
		end;
		return nil;
	end;
	-- ---------------------------------------------------------------- windows
	local function findWindow(title)
		local pg = pgui();
		if not pg then return nil; end;
		for _, o in ipairs(pg:GetDescendants()) do
			if o:IsA("TextLabel") and trim(txt(o)):upper() == title and shown(o) and not o:FindFirstAncestorWhichIsA("GuiButton") then
				local win = sizedAncestor(o, 500, 300);
				if win and o.AbsolutePosition.Y < win.AbsolutePosition.Y + 90 then return win; end;
			end;
		end;
		return nil;
	end;
	-- the tab bar ("Backpack Equipment Index Stats Races"): any of its words on screen means the menu is open
	local function tabLabels(name)
		local pg = pgui();
		local out = {};
		for _, o in ipairs(pg and pg:GetDescendants() or {}) do
			if isText(o) and trim(txt(o)):upper() == name and shown(o) then out[#out + 1] = o; end;
		end;
		-- the tab is the one lowest on screen (window titles sit at the top)
		table.sort(out, function(a2, b2) return a2.AbsolutePosition.Y > b2.AbsolutePosition.Y; end);
		return out;
	end;
	local VIMx;
	pcall(function() VIMx = game:GetService("VirtualInputManager"); end);
	local function centerOf(obj)
		local pos, size = obj.AbsolutePosition, obj.AbsoluteSize;
		local cx, cy = pos.X + size.X / 2, pos.Y + size.Y / 2;
		local inset = guiService:GetGuiInset();
		local sg = obj:FindFirstAncestorWhichIsA("ScreenGui");
		local ignore = false;
		if sg then
			local ok, v = pcall(function() return sg.IgnoreGuiInset; end);
			ignore = ok and v == true;
		end;
		-- viewport coordinates (VirtualInputManager / screen in fullscreen)
		return cx + (ignore and 0 or inset.X), cy + (ignore and 0 or inset.Y), cx, cy;
	end;
	-- fire every way a game can listen for a click on this object
	local function fireAll(obj)
		local fired = false;
		local vx, vy, cx, cy = centerOf(obj);
		for _, sigName in ipairs({ "MouseButton1Down", "MouseButton1Up", "MouseButton1Click", "Activated" }) do
			local okS, sig = pcall(function() return obj[sigName]; end);
			if okS and sig then
				if type(getconnections) == "function" then
					for _, c in ipairs(getconnections(sig)) do
						if type(c.Function) == "function" then
							task.spawn(c.Function, cx, cy);
							fired = true;
						elseif type(c.Fire) == "function" then
							pcall(c.Fire, c, cx, cy);
							fired = true;
						end;
					end;
				elseif type(firesignal) == "function" and pcall(firesignal, sig) then
					fired = true;
				end;
			end;
		end;
		if type(getconnections) == "function" then
			for _, ev in ipairs({ "InputBegan", "InputEnded" }) do
				local okI, sig = pcall(function() return obj[ev]; end);
				if okI and sig then
					local fake = {
						UserInputType = Enum.UserInputType.MouseButton1,
						UserInputState = ev == "InputBegan" and Enum.UserInputState.Begin or Enum.UserInputState.End,
						Position = Vector3.new(cx, cy, 0),
						Delta = Vector3.zero,
						KeyCode = Enum.KeyCode.Unknown,
					};
					for _, c in ipairs(getconnections(sig)) do
						if type(c.Function) == "function" then
							task.spawn(c.Function, fake, false);
							fired = true;
						end;
					end;
				end;
			end;
		end;
		return fired, vx, vy;
	end;
	r.fireAll = fireAll;
	-- click with increasingly "real" methods until check() says it worked
	local function clickVerified(obj, check, label, abort)
		if not obj then return false; end;
		-- abort(): checked before every attempt and while waiting (e.g. it became unsafe, or a deadline passed)
		local aborted = false;
		local function stop()
			if abort and abort() then aborted = true; end;
			return aborted;
		end;
		local function waitOk(secs)
			local v = waitFor(function()
				if stop() then return "abort"; end;
				return check();
			end, secs);
			return v ~= nil and v ~= "abort";
		end;
		local targets = {};
		local btn = obj:IsA("GuiButton") and obj or obj:FindFirstAncestorWhichIsA("GuiButton");
		if btn then targets[#targets + 1] = btn; end;
		if obj.Parent and obj.Parent:IsA("GuiObject") and obj.Parent ~= btn then targets[#targets + 1] = obj.Parent; end;
		targets[#targets + 1] = obj;
		for _, t2 in ipairs(targets) do
			if stop() then return false, "aborted"; end;
			fireAll(t2);
			if waitOk(1.2) then return true, "events"; end;
			if aborted then return false, "aborted"; end;
		end;
		local vx, vy = centerOf(btn or obj);
		local focusedNow = inp.focused();
		if VIMx then
			if stop() then return false, "aborted"; end;
			pcall(VIMx.SendMouseMoveEvent, VIMx, vx, vy, game);
			task.wait(.05);
			pcall(VIMx.SendMouseButtonEvent, VIMx, vx, vy, 0, true, game, 0);
			task.wait(.06);
			pcall(VIMx.SendMouseButtonEvent, VIMx, vx, vy, 0, false, game, 0);
			if waitOk(1.2) then return true, "virtual mouse"; end;
			if aborted then return false, "aborted"; end;
		end;
		if focusedNow and Q.background ~= true then
			if stop() then return false, "aborted"; end;
			-- real mouse: fullscreen, so viewport coordinates are screen coordinates
			inp.mouseMove(math.floor(vx + .5), math.floor(vy + .5));
			task.wait(.15);
			inp.mouseDown();
			task.wait(.07);
			inp.mouseUp();
			if waitOk(1.5) then return true, "mouse"; end;
			if aborted then return false, "aborted"; end;
		end;
		notify("Couldn't click " .. tostring(label or obj.Name) .. ". Layout saved to DelveGuiDump_menu.txt.", "Delve index");
		return false;
	end;
	local function menuOpen()
		return #tabLabels("RACES") > 0 or #tabLabels("BACKPACK") > 0;
	end;
	local function pressT()
		if Q.background == true or inp.focused() then
			inp.key(84, true);
			task.wait(.06);
			inp.key(84, false);
			return true;
		end;
		-- tabbed out: send T straight to the game (never to whatever window you're using)
		local ok = false;
		if VIMx then
			ok = pcall(VIMx.SendKeyEvent, VIMx, true, Enum.KeyCode.T, false, game);
			task.wait(.06);
			pcall(VIMx.SendKeyEvent, VIMx, false, Enum.KeyCode.T, false, game);
		end;
		return ok;
	end;
	-- click a bottom tab and wait until that window's title is showing
	local function openTab(name, abort)
		if findWindow(name) then return findWindow(name); end;
		local tab = tabLabels(name)[1];
		if not tab then return nil; end;
		local ok = clickVerified(tab, function() return findWindow(name); end, name .. " tab", abort);
		return ok and findWindow(name) or nil;
	end;
	local function scrollers(win)
		local list = {};
		for _, o in ipairs(win:GetDescendants()) do
			if o:IsA("ScrollingFrame") and o.Visible then list[#list + 1] = o; end;
		end;
		return list;
	end;
	-- step a ScrollingFrame from the top to the very bottom, calling onStep at every position
	local function scrollThrough(sf, onStep, pause)
		pause = pause or .3;
		local function maxY() return math.max(0, sf.AbsoluteCanvasSize.Y - sf.AbsoluteWindowSize.Y); end;
		sf.CanvasPosition = Vector2.new(sf.CanvasPosition.X, 0);
		task.wait(pause);
		pcall(onStep);
		local step = math.max(30, sf.AbsoluteWindowSize.Y * .5);
		for _ = 1, 400 do
			local before = sf.CanvasPosition.Y;
			if before >= maxY() - 1 then break; end;
			sf.CanvasPosition = Vector2.new(sf.CanvasPosition.X, math.min(maxY(), before + step));
			task.wait(pause);
			pcall(onStep);
			if sf.CanvasPosition.Y <= before + .5 then break; end;
		end;
	end;
	-- ---------------------------------------------------------------- layout dump (for tuning)
	local function dump(win, tag)
		if type(writefile) ~= "function" or not win then return; end;
		local lines = { "Delve GUI dump: " .. tag .. "  " .. os.date("!%Y-%m-%d %H:%M:%S") };
		local rowsSeen = {};
		local function walk(o, depth)
			if #lines > 12000 then return; end;
			if not (o:IsA("GuiObject") or o:IsA("LayerCollector") or o:IsA("Folder")) then return; end;
			if o.Name == "Row" or o.Name == "Tile" then
				local key = tostring(o.Parent) .. o.Name;
				rowsSeen[key] = (rowsSeen[key] or 0) + 1;
				if rowsSeen[key] > 3 then return; end;
			end;
			local info = string.rep("  ", depth) .. o.ClassName .. " '" .. o.Name .. "'";
			if o:IsA("GuiObject") then
				local p, sz = o.AbsolutePosition, o.AbsoluteSize;
				info = info .. string.format(" pos=%d,%d size=%d,%d%s", p.X, p.Y, sz.X, sz.Y, o.Visible and "" or " HIDDEN");
			end;
			if isText(o) then info = info .. " text=\"" .. trim(txt(o)):gsub("\n", "\\n") .. "\""; end;
			if o:IsA("ScrollingFrame") then
				info = info .. string.format(" canvas=%d window=%d", o.AbsoluteCanvasSize.Y, o.AbsoluteWindowSize.Y);
			end;
			lines[#lines + 1] = info;
			if o:IsA("ViewportFrame") then return; end;
			for _, c in ipairs(o:GetChildren()) do walk(c, depth + 1); end;
		end;
		walk(win, 0);
		pcall(writefile, "DelveGuiDump_" .. tag .. ".txt", table.concat(lines, "\n"));
	end;
	r.dumpGui = dump;
	-- ---------------------------------------------------------------- index
	local function biggestScroller(win, exclude)
		local best, bn;
		for _, sf in ipairs(scrollers(win)) do
			if sf ~= exclude then
				local n = 0;
				for _, o in ipairs(sf:GetDescendants()) do if o:IsA("GuiButton") then n = n + 1; end; end;
				if not bn or n > bn then best, bn = sf, n; end;
			end;
		end;
		return best;
	end;
	local function readTotals(win, grid)
		-- "177 /277 FOUND 63%": may be split over several labels, so read whole rows
		local fallback;
		local checked = {};
		for _, L in ipairs(labelsIn(win)) do
			local row = L.o.Parent;
			if row and not checked[row] and row ~= grid and not row:IsDescendantOf(grid) then
				checked[row] = true;
				local text = joined(row):upper();
				local a2, b2 = text:match("(%d+)%s*/%s*(%d+)");
				if a2 then
					if text:find("FOUND") then
						brain.indexTotals = { found = tonumber(a2), total = tonumber(b2) };
						return;
					elseif tonumber(b2) >= 100 then
						fallback = fallback or { found = tonumber(a2), total = tonumber(b2) };
					end;
				end;
			end;
		end;
		if fallback then brain.indexTotals = fallback; end;
	end;
	local function collectTiles(grid, tiles, order)
		local items = {};
		for _, c in ipairs(grid:GetDescendants()) do
			if c:IsA("GuiObject") and c.Visible and (c.Name == "Header" or c.Name == "Tile") and c.Parent and c.Parent.Visible
				and not (c.Parent.Name == "Templates" or (c.Parent.Parent and c.Parent.Parent.Name == "Templates")) then
				items[#items + 1] = c;
			end;
		end;
		table.sort(items, function(a2, b2)
			local pa, pb = a2.AbsolutePosition, b2.AbsolutePosition;
			if math.abs(pa.Y - pb.Y) > 4 then return pa.Y < pb.Y; end;
			return pa.X < pb.X;
		end);
		local zone, zoneTally;
		for _, c in ipairs(items) do
			if c.Name == "Header" then
				local t1, t2 = c:FindFirstChild("Title"), c:FindFirstChild("Tally");
				zone = t1 and trim(txt(t1)) or zone;
				zoneTally = t2 and trim(txt(t2)) or nil;
				if zone and zoneTally then
					local fa, fb = zoneTally:match("(%d+)%s*/%s*(%d+)");
					brain.zones = type(brain.zones) == "table" and brain.zones or {};
					brain.zones[zone] = { found = tonumber(fa), total = tonumber(fb) };
				end;
			elseif not tiles[c] then
				local nameL, countL = c:FindFirstChild("ItemName"), c:FindFirstChild("Count");
				local hit = c:FindFirstChild("Hit") or c:FindFirstChildWhichIsA("GuiButton");
				local name = nameL and trim(txt(nameL)) or nil;
				local odds = countL and oddsIn(txt(countL)) or oddsIn((joined(c)));
				if name or odds then
					tiles[c] = {
						button = hit or c, tile = c, name = (name and name ~= "") and name or "???", odds = odds, zone = zone,
						found = name ~= nil and name ~= "" and not name:find("%?"),
					};
					order[#order + 1] = c;
				end;
			end;
		end;
	end;
	local function detailHasName(win, grid, name)
		local want = tostring(name):upper();
		for _, L in ipairs(labelsIn(win)) do
			if not L.o:IsDescendantOf(grid) and L.t == want then return L; end;
		end;
		return nil;
	end;
	local function readDetail(win, grid, entry)
		local header = detailHasName(win, grid, entry.name);
		if not header then return false; end;
		local key = tostring(entry.name):upper();
		local rec = type(brain.index[key]) == "table" and brain.index[key] or {};
		-- Description > Info { Title, RarityLine "COMMON ORE", TierLine "1 IN 2", FigureLine "MINED 9,631 TIMES",
		--   Flavour, Attributes, Stat (composition %), Sources (ScrollingFrame) > Row { Source, Area, Odds } }
		local info = header.o.Parent;
		local function field(n)
			local f = info and info:FindFirstChild(n);
			return f and f:IsA("TextLabel") and trim(txt(f)) or nil;
		end;
		rec.tier = field("RarityLine") or rec.tier;
		local fig = field("FigureLine");
		if fig then
			rec.figure = fig;
			rec.mined = numOf(fig:upper():match("([%d,]+)")) or rec.mined;
		end;
		local flavour = field("Flavour");
		if flavour and flavour ~= "" then rec.flavour = flavour; end;
		-- extra lines (attributes / composition) when the game shows them
		local extra = {};
		for _, f in ipairs(info and info:GetChildren() or {}) do
			if f:IsA("Frame") and f.Visible and (f.Name == "Attributes" or f.Name == "Stat") then
				local text = joined(f);
				if text ~= "" then extra[#extra + 1] = text; end;
			end;
		end;
		if #extra > 0 then rec.extra = extra; end;
		local list = info and info:FindFirstChild("Sources");
		if not (list and list:IsA("ScrollingFrame")) then
			for _, sf in ipairs(scrollers(win)) do
				if sf ~= grid and not sf:IsDescendantOf(grid) then list = sf; break; end;
			end;
		end;
		local sources, seen = {}, {};
		local function readRows()
			if not list then return; end;
			for _, row in ipairs(list:GetChildren()) do
				-- skip the hidden "SourceRow" template (that was the bogus FIELD STONE in every item)
				if row:IsA("GuiObject") and row.Visible and row.Name ~= "SourceRow" then
					local srcL, areaL, oddsL = row:FindFirstChild("Source"), row:FindFirstChild("Area"), row:FindFirstChild("Odds");
					local name = srcL and trim(txt(srcL));
					local oddsText = oddsL and trim(txt(oddsL)) or "";
					if not name then
						local text, ls = joined(row);
						for _, L in ipairs(ls) do
							if L.t:match("%a") and not L.t:find("1%s+IN") then name = L.raw; break; end;
						end;
						oddsText = text;
					end;
					local odds = oddsIn(oddsText);
					local hi = tonumber((tostring(oddsText):upper():match("%-%s*1%s+IN%s+([%d,%.]+)") or ""):gsub(",", ""));
					if name and name ~= "" and odds and not seen[name:upper() .. (areaL and txt(areaL) or "")] then
						seen[name:upper() .. (areaL and txt(areaL) or "")] = true;
						sources[#sources + 1] = { name = name, zone = areaL and trim(txt(areaL)) or nil, odds = odds, oddsBest = hi, oddsText = oddsText };
					end;
				end;
			end;
		end;
		if list then scrollThrough(list, readRows, .25); end;
		rec.name, rec.odds, rec.zone, rec.found = entry.name, entry.odds or oddsIn(field("TierLine")), entry.zone or rec.zone, true;
		rec.sources, rec.studied, rec.sv = sources, os.time(), 3;
		brain.index[key] = rec;
		for _, sv in ipairs(sources) do
			local sk = sv.name:upper() .. (sv.zone and (" | " .. sv.zone:upper()) or "");
			local srec = type(brain.sources[sk]) == "table" and brain.sources[sk] or { name = sv.name, zone = sv.zone, drops = {} };
			srec.drops = type(srec.drops) == "table" and srec.drops or {};
			srec.drops[key] = sv.odds;
			brain.sources[sk] = srec;
		end;
		return true;
	end;
	local menuDumped = false;
	local function dumpMenu()
		if menuDumped then return; end;
		local tab = tabLabels("RACES")[1] or tabLabels("BACKPACK")[1];
		local lc = tab and tab:FindFirstAncestorWhichIsA("LayerCollector");
		if lc then
			menuDumped = true;
			dump(lc, "menu");
		end;
	end;
	local function scanIndex(win, study)
		local grid = biggestScroller(win);
		if not grid then return 0, 0; end;
		dump(win, "index");
		readTotals(win, grid);
		local tiles, order = {}, {};
		collectTiles(grid, tiles, order);
		local expected = brain.indexTotals and tonumber(brain.indexTotals.found) or 1;
		if #order < expected then
			-- some tiles only load while scrolling: go through the whole list
			scrollThrough(grid, function() collectTiles(grid, tiles, order); end, .3);
		end;
		for _, b in ipairs(order) do
			local e = tiles[b];
			local key = e.found and e.name:upper() or string.format("??? %s 1 IN %s", tostring(e.zone or "?"), tostring(e.odds));
			local rec = type(brain.index[key]) == "table" and brain.index[key] or {};
			rec.name, rec.odds, rec.zone = e.name, e.odds, e.zone or rec.zone;
			rec.found = e.found or rec.found == true;
			brain.index[key] = rec;
		end;
		local studied, skipped = 0, 0;
		for _, b2 in ipairs(order) do
			local e2 = tiles[b2];
			local r2 = e2.found and brain.index[e2.name:upper()];
			if type(r2) == "table" and r2.studied and r2.sv == 3 then skipped = skipped + 1; end;
		end;
		r.indexSkipped = skipped;
		if study then
			for _, b in ipairs(order) do
				local e = tiles[b];
				local rec = brain.index[e.found and e.name:upper() or ""];
				if e.found and not (type(rec) == "table" and rec.studied and rec.sv == 3) then
					if run.active or relicAPI.hasDraft() or not findWindow("INDEX") then break; end;
					-- bring the item into view, click it, give the details time to load
					local offset = e.tile.AbsolutePosition.Y - grid.AbsolutePosition.Y + grid.CanvasPosition.Y;
					grid.CanvasPosition = Vector2.new(grid.CanvasPosition.X, math.max(0, offset - 40));
					task.wait(.25);
					local shownNow = clickVerified(e.button, function() return detailHasName(win, grid, e.name); end, e.name);
					if shownNow then
						task.wait(.35);
						if studied == 0 then
							local hdr = detailHasName(win, grid, e.name);
							local pnl = hdr and sizedAncestor(hdr.o, 250, 300);
							if pnl then dump(pnl, "index_detail"); end;
						end;
						if readDetail(win, grid, e) then studied = studied + 1; end;
					end;
				end;
			end;
			grid.CanvasPosition = Vector2.new(grid.CanvasPosition.X, 0);
		end;
		brain.indexScannedAt = os.time();
		return #order, studied;
	end;
	-- ---------------------------------------------------------------- stats (row by row)
	local function scanStats(win)
		dump(win, "stats");
		local count = 0;
		for _, sf in ipairs(scrollers(win)) do
			-- which panel: nearest header label above this list ("YOUR STATS" / "LIFETIME")
			local panelName, pd;
			for _, L in ipairs(labelsIn(win)) do
				if not L.o:IsDescendantOf(sf) then
					local dy = sf.AbsolutePosition.Y - L.y;
					local overlap = L.x >= sf.AbsolutePosition.X - 20 and L.x <= sf.AbsolutePosition.X + sf.AbsoluteSize.X;
					if overlap and dy > 0 and dy < 80 and L.t:match("%a") and (not pd or dy < pd) then panelName, pd = L.t, dy; end;
				end;
			end;
			local target;
			if panelName then
				target = panelName:find("LIFE") and brain.lifetime or brain.you;
			else
				-- no header found: the right-hand panel is Lifetime
				target = (sf.AbsolutePosition.X > win.AbsolutePosition.X + win.AbsoluteSize.X / 2) and brain.lifetime or brain.you;
			end;
			local section = nil;
			scrollThrough(sf, function()
				local rows = {};
				for _, o in ipairs(sf:GetDescendants()) do
					if isText(o) and o.Visible and trim(txt(o)) ~= "" then
						local row = o.Parent;
						rows[row] = rows[row] or {};
						table.insert(rows[row], o);
					end;
				end;
				local ordered = {};
				for row, ls in pairs(rows) do ordered[#ordered + 1] = { row = row, ls = ls, y = ls[1].AbsolutePosition.Y }; end;
				table.sort(ordered, function(a2, b2) return a2.y < b2.y; end);
				for _, it in ipairs(ordered) do
					table.sort(it.ls, function(a2, b2) return a2.AbsolutePosition.X < b2.AbsolutePosition.X; end);
					if #it.ls == 1 then
						section = trim(txt(it.ls[1])):upper();
					elseif #it.ls >= 2 then
						local k2 = trim(txt(it.ls[1])):upper();
						local v2 = trim(txt(it.ls[#it.ls]));
						if k2 ~= "" and v2 ~= "" then
							if target[k2] ~= nil and section and target[k2] ~= v2 and not target[section .. " " .. k2] then
								k2 = section .. " " .. k2;
							end;
							if target[k2] == nil then count = count + 1; end;
							target[k2] = v2;
						end;
					end;
				end;
			end, .3);
		end;
		brain.statsAt = os.time();
		-- feed what matters into the rest of the script
		local you, p = brain.you, brain.player;
		p.pickaxe, p.sword = you["PICKAXE"] or p.pickaxe, you["SWORD"] or p.sword;
		p.pickPower = numOf(you["PICKAXE POWER"]) or p.pickPower;
		p.swordPower = numOf(you["SWORD POWER"]) or p.swordPower;
		p.power = numOf(you["MINE POWER"]) or p.power;
		p.weaponPower = numOf(you["WEAPON POWER"]) or p.weaponPower;
		p.attackSpeed = numOf(you["ATTACK SPEED"]) or p.attackSpeed;
		p.mineSpeed = numOf(you["MINE SPEED"]) or p.mineSpeed;
		p.walkSpeed = numOf(you["WALK SPEED"]) or p.walkSpeed;
		p.miningRange = numOf(you["MINING RANGE"]) or p.miningRange;
		p.maxHealth = numOf(you["MAX HEALTH"]) or p.maxHealth;
		p.level = numOf(you["LEVEL"]) or p.level;
		-- the Stats tab states the mining range directly: use it if the memory scan found nothing
		if p.miningRange and p.miningRange > 0 and not r.statsFound then
			Q.radius = p.miningRange;
			if r.sync then r.sync(); end;
		end;
		return count;
	end;
	-- ---------------------------------------------------------------- equipment (read only)
	local function scanEquipment(win)
		dump(win, "equipment");
		local labels = labelsIn(win);
		local function above(key)
			for _, L in ipairs(labels) do
				if L.t == key then
					local best, bd;
					for _, M in ipairs(labels) do
						if M ~= L and M.t:find("%d") then
							local dy, dx = L.y - M.y, math.abs((M.x + M.w / 2) - (L.x + L.w / 2));
							if dx < 120 and dy > 0 and dy < 45 and (not bd or dy < bd) then best, bd = M, dy; end;
						end;
					end;
					if best then return numOf(best.t); end;
				end;
			end;
			return nil;
		end;
		local p = brain.player;
		p.luck = above("LUCK") or p.luck;
		p.health = above("HEALTH") or p.health;
		p.damage = above("DAMAGE") or p.damage;
		p.t = os.time();
	end;
	-- ---------------------------------------------------------------- the scan
	local busy, done = false, false;
	local function scan(reason)
		if busy then return; end;
		busy = true;
		r.scanning = true;
		r.scanT0 = r.scanStart("Index, Stats and Equipment scan");
		if r.win and r.win.Close then pcall(r.win.Close); end;
		task.wait(.3);
		local summary = {};
		local ok, err = pcall(function()
			local opened = false;
			if not menuOpen() then
				if not pressT() then
					summary.waiting = true;
					return;
				end;
				opened = true;
				if not waitFor(menuOpen, 2) then
					-- backup: click the backpack button on the hotbar (the slot labelled T)
					local pg = pgui();
					for _, o in ipairs(pg and pg:GetDescendants() or {}) do
						if isText(o) and trim(txt(o)):upper() == "T" and shown(o) and not menuOpen() then
							local slot = o:FindFirstAncestorWhichIsA("GuiButton") or o.Parent;
							if slot then clickVerified(slot, menuOpen, "backpack button"); end;
						end;
					end;
				end;
				if not waitFor(menuOpen, 2) then summary.noMenu = true; return; end;
			end;
			task.wait(.5);
			dumpMenu();
			local win = openTab("INDEX");
			if win then
				task.wait(.6);
				summary.entries, summary.studied = scanIndex(win, not run.active);
			else
				summary.failed = (summary.failed or "") .. " Index";
			end;
			win = openTab("STATS");
			if win then
				task.wait(.6);
				summary.stats = scanStats(win);
			else
				summary.failed = (summary.failed or "") .. " Stats";
			end;
			win = openTab("EQUIPMENT");
			if win then
				task.wait(.6);
				scanEquipment(win);
			else
				summary.failed = (summary.failed or "") .. " Equipment";
			end;
			if opened then
				pressT();
				task.wait(.5);
				if menuOpen() then pressT(); end;
			end;
		end);
		r.scanning = false;
		busy = false;
		markBrain();
		saveBrain(true);
		if not ok then
			notify("Scan error: " .. tostring(err), "Delve index");
			return;
		end;
		if summary.waiting then return; end; -- Roblox not focused yet: try again later
		done = true;
		brain.runsAtScan = tonumber(brain.runCount) or 0;
		local t = brain.indexTotals;
		r.scanEnd("Index, Stats and Equipment scan", r.scanT0, string.format("%sIndex %s, %d items read, %d new studied, %d already known (skipped). %d stats read.%s",
			reason and ("(" .. reason .. ") ") or "", t and (t.found .. "/" .. t.total) or "?",
			summary.entries or 0, summary.studied or 0, r.indexSkipped or 0, summary.stats or 0,
			summary.failed and (" Couldn't open:" .. summary.failed .. ".") or ""));
	end;
	-- ---------------------------------------------------------------- gear memory (cheap, no GUI)
	local gear = {};
	local function gearTick()
		local character = l.Character;
		local tool = character and character:FindFirstChildOfClass("Tool");
		if not tool then return; end;
		local name = tool.Name;
		local kind = character:GetAttribute("PickaxeOut") == true and "pickaxe" or (character:GetAttribute("WeaponDrawn") == true and "sword") or nil;
		if not kind then return; end;
		local g = type(brain.gear[name]) == "table" and brain.gear[name] or { kind = kind };
		brain.gear[name] = g;
		if gear[kind] ~= name then
			local prev = gear[kind];
			gear[kind] = name;
			if prev then
				if kind == "pickaxe" then
					if g.radius and g.reach then
						Q.radius, Q.reach = g.radius, g.reach;
						if r.sync then r.sync(); end;
					end;
					if r.readStats then task.delay(1, function() pcall(r.readStats, true); end); end;
				end;
				notify(string.format("%s changed to %s%s", kind == "pickaxe" and "Pickaxe" or "Sword", name,
					(g.radius or g.coneRange) and " (stats known)" or " (learning it)"), "Delve gear");
			end;
		end;
		if kind == "pickaxe" and r.statsFound then g.radius, g.reach = Q.radius, Q.reach; end;
		if kind == "sword" then
			if r.range then g.coneRange = r.range; end;
			r.swordLearnedRange = g.coneRange;
		end;
	end;
	-- ---------------------------------------------------------------- drops (only during runs)
	local function rarityRank(odds)
		local list = {};
		for _, rec in pairs(brain.index) do
			local od = type(rec) == "table" and tonumber(rec.odds);
			if od then list[#list + 1] = od; end;
		end;
		if not odds or #list == 0 then return nil, #list; end;
		local rank = 1;
		for _, v in ipairs(list) do if v > odds then rank = rank + 1; end; end;
		return rank, #list;
	end;
	local lastPost, dropSeen = -1e9, setmetatable({}, { __mode = "k" });
	local function onDrop(name, odds, tier, count, fromChat)
		local key = name:upper();
		local rec = brain.index[key];
		local isNew = brain.indexScannedAt ~= nil and (type(rec) ~= "table" or rec.found ~= true);
		rec = type(rec) == "table" and rec or { name = name };
		rec.found, rec.odds = true, odds or rec.odds;
		rec.drops = (tonumber(rec.drops) or 0) + 1;
		rec.lastDrop = os.time();
		brain.index[key] = rec;
		markBrain();
		local tierRank = TIERS[tostring(tier or ""):upper()] or 0;
		local rank, total = rarityRank(odds);
		local topPct = tonumber(CFG.rareTopPct) or 3;
		local inTop = rank and total >= 20 and topPct > 0 and rank <= math.max(1, math.ceil(total * topPct / 100));
		-- only Mythic tier or higher is announced (with a screenshot when the helper runs);
		-- drops with no tier shown (e.g. from chat) count when they're 1 in 100,000 or rarer
		local rare = tierRank >= TIERS.MYTHIC or (tierRank == 0 and (odds or 0) >= (tonumber(CFG.rareDropOdds) or 100000));
		if not rare then return; end;
		pcall(function()
			if type(appendfile) == "function" then
				appendfile("DelveDrops.jsonl", game:GetService("HttpService"):JSONEncode({
					t = os.time(), name = name, odds = odds, tier = tier, count = count, new = isNew, depth = run.depth,
				}) .. "\n");
			end;
		end);
		run.rareSeen = type(run.rareSeen) == "table" and run.rareSeen or {};
		local already = run.rareSeen[name];
		run.rareSeen[name] = (already or 0) + 1;
		if already and not isNew then return; end;
		notify(string.format("%s %s (1 in %s)%s", isNew and "NEW INDEX ENTRY:" or "Rare drop:", name, tostring(odds or "?"), tier and (" [" .. tier .. "]") or ""), "Delve drop");
		if CFG.dropWebhook ~= false and d() - lastPost > 3 then
			lastPost = d();
			local where = {};
			if type(rec.sources) == "table" then
				for k = 1, math.min(3, #rec.sources) do
					local sv = rec.sources[k];
					where[#where + 1] = string.format("%s (%s) 1 in %s", sv.name, tostring(sv.zone or "?"), tostring(sv.odds));
				end;
			end;
			local fields = {
				{ name = "Odds", value = odds and ("1 in " .. tostring(odds)) or "?", inline = true },
				{ name = "Rarity", value = tostring(tier or rec.tier or "?"), inline = true },
				{ name = "Amount", value = count and ("x" .. count) or "x1", inline = true },
				{ name = "Rarity rank", value = rank and string.format("#%d of %d", rank, total) or "?", inline = true },
				{ name = "Depth", value = run.depth > 0 and (run.depth .. " m") or "?", inline = true },
				{ name = "Index", value = brain.indexTotals and (brain.indexTotals.found .. "/" .. brain.indexTotals.total) or "?", inline = true },
			};
			if #where > 0 then fields[#fields + 1] = { name = "Drops from", value = table.concat(where, "\n"), inline = false }; end;
			if fromChat then fields[#fields + 1] = { name = "Seen in", value = "Roblox chat", inline = true }; end;
			task.spawn(r.postEmbed, {
				title = (isNew and "NEW INDEX ENTRY: " or "Rare drop: ") .. name,
				color = tierRank >= 8 and 15548997 or (isNew and 16766720 or (tierRank >= 5 and 15844367 or 10181046)),
				fields = fields,
				footer = { text = "Delve v3 brain | " .. tostring(l.Name) },
			});
		end;
	end;
	-- a newly appeared label: is it a drop pop-up? (pop-ups have a tier word and "1 in N")
	local function checkToast(lbl)
		if not (lbl.Parent and run.active and not r.scanning) then return; end;
		local odds = oddsIn(txt(lbl));
		if not odds or lbl:FindFirstAncestorWhichIsA("ScrollingFrame") or not shown(lbl) then return; end;
		local box = lbl.Parent;
		while box and box.Parent and box.Parent:IsA("GuiObject") and box.Parent.AbsoluteSize.Y <= 140 and box.Parent.AbsoluteSize.X <= 520 do
			box = box.Parent;
		end;
		if not box or not box:IsA("GuiObject") or box.AbsoluteSize.X > 520 or box.AbsoluteSize.Y > 140 then return; end;
		local name, tier, count;
		for _, M in ipairs(labelsIn(box)) do
			if not oddsIn(M.t) then
				if TIERS[M.t] then
					tier = M.raw;
				elseif M.t:match("%a") and not name then
					count = M.t:match("[X×]%s*(%d+)%s*$");
					name = trim(M.raw:gsub("%s*[xX×]%s*%d+%s*$", ""));
				end;
			end;
		end;
		if not tier or not name or name == "" then return; end; -- no tier word = not a drop pop-up
		if dropSeen[box] == name then return; end;
		dropSeen[box] = name;
		onDrop(name, odds, tier, tonumber(count));
	end;
	-- labels that appear are queued and handled in small batches (cheap, no screen-wide searches)
	local queue = {};
	local addConn, chatConn;
	local function onChat(text)
		if not run.active then return; end;
		local plain = tostring(text or ""):gsub("<[^>]->", "");
		local up = plain:upper();
		local oddsStr = up:match("1%s+OUT%s+OF%s+([%d,]+)") or up:match("1%s+IN%s+([%d,]+)") or up:match("1/([%d,]+)");
		local odds = oddsStr and tonumber((oddsStr:gsub(",", "")));
		if not odds then return; end;
		if not (up:find(tostring(l.Name):upper(), 1, true) or up:find(tostring(l.DisplayName):upper(), 1, true)) then return; end;
		local item = plain:match("[Ff]ound%s+(.-)%s*[%(%[]") or plain:match("[Gg]ot%s+(.-)%s*[%(%[]")
			or plain:match("[Oo]btained%s+(.-)%s*[%(%[]") or plain:match("[Mm]ined%s+(.-)%s*[%(%[]");
		item = trim(item and item:gsub("^[Aa]n?%s+", "") or plain:sub(1, 60));
		-- "the Broadside Blunderbuss in a chest!" -> "Broadside Blunderbuss" (one name per item, so repeats are counted)
		item = item:gsub("^[Tt]he%s+", ""):gsub("%s+in%s+a%s+chest", ""):gsub("%s+off%s+a%s+mob", ""):gsub("[!%.]+$", "");
		item = trim(item);
		local tier;
		for t2 in pairs(TIERS) do
			if up:find("%f[%a]" .. t2 .. "%f[%A]") then tier = t2; end;
		end;
		pcall(onDrop, item, odds, tier, nil, true);
	end;
	local function hook()
		local pg = pgui();
		if not pg then return false; end;
		addConn = pg.DescendantAdded:Connect(function(o)
			if o:IsA("TextLabel") and #queue < 400 then queue[#queue + 1] = o; end;
		end);
		pcall(function()
			chatConn = game:GetService("TextChatService").MessageReceived:Connect(function(msg)
				pcall(onChat, msg and msg.Text);
			end);
		end);
		if not chatConn then
			pcall(function()
				local ev = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents");
				ev = ev and ev:FindFirstChild("OnMessageDoneFiltering");
				if ev then
					chatConn = ev.OnClientEvent:Connect(function(data) pcall(onChat, type(data) == "table" and data.Message); end);
				end;
			end);
		end;
		return true;
	end;
	r.stopIndex = function()
		if addConn then pcall(function() addConn:Disconnect(); end); addConn = nil; end;
		if chatConn then pcall(function() chatConn:Disconnect(); end); chatConn = nil; end;
	end;
	-- ---------------------------------------------------------------- AUTO FARM (stage launcher)
	-- Hub: GO MINE! -> window "GO MINE" with a horizontal list of stage cards (GRASSLANDS ... THE ABYSS)
	-- and the DELVE panel on the right. Pick the card (scrolling the list left/right to it), then
	-- CLICK TO DESCEND; for Delve, click the Delve panel.
	local launch = { at = -1e9, fails = 0, findAt = -1e9 };
	local function goMineButton()
		local lb = launch.label;
		if lb and lb.Parent and shown(lb) then return lb; end;
		local now = d();
		if now - launch.findAt < 8 then return nil; end;
		launch.findAt, launch.label = now, nil;
		local pg = pgui();
		for _, o in ipairs(pg and pg:GetDescendants() or {}) do
			if isText(o) and trim(txt(o)):upper() == "GO MINE!" and shown(o) then
				launch.label = o;
				return o;
			end;
		end;
		return nil;
	end;
	local function labelIn(root, text, exact)
		for _, o in ipairs(root:GetDescendants()) do
			if isText(o) and shown(o) then
				local u = trim(txt(o)):upper();
				if (exact and u == text) or (not exact and u:find(text, 1, true)) then return o; end;
			end;
		end;
		return nil;
	end;
	local function bestButton(root)
		if not root then return nil; end;
		local best, area = nil, 0;
		local all = root:GetDescendants();
		all[#all + 1] = root;
		for _, o in ipairs(all) do
			if o:IsA("GuiButton") and shown(o) then
				local a = o.AbsoluteSize.X * o.AbsoluteSize.Y;
				if a > area then best, area = o, a; end;
			end;
		end;
		return best;
	end;
	local function stageWanted()
		local other = trim(tostring(CFG.stageOther or ""));
		return (other ~= "" and other or tostring(CFG.stage or "Delve")):upper();
	end;
	local function inRun()
		return run.active or workspace:FindFirstChild("StrataPlate") ~= nil or workspace:FindFirstChild("RunEndRoom") ~= nil;
	end;
	local function launchStage()
		if launch.busy then return; end;
		launch.busy, r.launching = true, true;
		local ok, err = pcall(function()
			local want = stageWanted();
			local function started()
				return workspace:FindFirstChild("StrataPlate") ~= nil or run.active or not findWindow("GO MINE");
			end;
			local win = findWindow("GO MINE");
			if not win then
				local btn = goMineButton();
				if not btn then return; end;
				clickVerified(btn, function() return findWindow("GO MINE"); end, "GO MINE!");
				win = waitFor(function() return findWindow("GO MINE"); end, 2);
			end;
			if not win then launch.fails = launch.fails + 1; return; end;
			if not r.goMineDumped then r.goMineDumped = true; pcall(dump, win, "gomine"); end;
			task.wait(.4);
			if want == "DELVE" then
				local tag = labelIn(win, "ENDLESS DESCENT", true) or labelIn(win, "YOUR DEEPEST", true);
				local panel = tag and (sizedAncestor(tag, 200, 250) or tag.Parent);
				if not panel then
					launch.fails = launch.fails + 1;
					notify("Couldn't find the Delve panel in GO MINE. Layout saved to DelveGuiDump_gomine.txt.", "Auto farm");
					return;
				end;
				notify("Starting Delve.", "Auto farm");
				if clickVerified(bestButton(panel) or panel, started, "Delve panel") then launch.fails = 0; else launch.fails = launch.fails + 1; end;
				return;
			end;
			-- the stage list scrolls sideways
			local list;
			for _, sf in ipairs(scrollers(win)) do
				if sf.AbsoluteCanvasSize.X > sf.AbsoluteSize.X + 4 then list = sf; break; end;
			end;
			local function findCard()
				for _, o in ipairs((list or win):GetDescendants()) do
					if isText(o) and trim(txt(o)):upper() == want then
						local card = o.Parent;
						while card and card.Parent and card.Parent ~= list and card:IsA("GuiObject")
							and not (card.AbsoluteSize.X >= 120 and card.AbsoluteSize.Y >= 90) do
							card = card.Parent;
						end;
						return card;
					end;
				end;
				return nil;
			end;
			local card = findCard();
			if list then
				local maxX = math.max(0, list.AbsoluteCanvasSize.X - list.AbsoluteSize.X);
				local stepX = math.max(80, list.AbsoluteSize.X * .6);
				local x = 0;
				while not card and x <= maxX + stepX do
					list.CanvasPosition = Vector2.new(math.min(x, maxX), list.CanvasPosition.Y);
					task.wait(.3);
					card = findCard();
					x = x + stepX;
				end;
				if card then
					local rel = card.AbsolutePosition.X - list.AbsolutePosition.X + list.CanvasPosition.X;
					local target = math.clamp(rel - (list.AbsoluteSize.X - card.AbsoluteSize.X) / 2, 0, maxX);
					list.CanvasPosition = Vector2.new(target, list.CanvasPosition.Y);
					task.wait(.35);
				end;
			end;
			if not card then
				launch.fails = launch.fails + 1;
				notify("Couldn't find the stage '" .. want .. "' in GO MINE. Check the name in the Farm tab.", "Auto farm");
				return;
			end;
			local function selected()
				if labelIn(card, "SELECTED", true) then return true; end;
				for _, o in ipairs(win:GetDescendants()) do
					if isText(o) and shown(o) and not (list and o:IsDescendantOf(list)) and trim(txt(o)):upper() == want then return true; end;
				end;
				return false;
			end;
			if not selected() then clickVerified(bestButton(card) or card, selected, want .. " card"); end;
			if not selected() then launch.fails = launch.fails + 1; return; end;
			task.wait(.3);
			local lock = labelIn(win, "TO ENTER", false);
			if lock then
				launch.lockedUntil = d() + 300;
				notify(string.format("%s is locked (%s). Trying again in 5 minutes.", want, trim(txt(lock))), "Auto farm");
				return;
			end;
			local go = labelIn(win, "CLICK TO DESCEND", true);
			if not go then launch.fails = launch.fails + 1; return; end;
			local area = sizedAncestor(go, 300, 200) or go.Parent;
			notify("Starting " .. want .. ".", "Auto farm");
			if clickVerified(bestButton(area) or go, started, "Click to descend") then launch.fails = 0; else launch.fails = launch.fails + 1; end;
		end);
		if not ok then notify("Auto farm error: " .. tostring(err), "Auto farm"); end;
		if workspace:FindFirstChild("StrataPlate") or run.active or not findWindow("GO MINE") then
			-- the farm turns itself on once the run has loaded
			if not CFG.on then r.autoStart = true; end;
		end;
		launch.busy, r.launching = false, false;
	end;
	r.launchStage = function() launch.at, launch.fails, launch.lockedUntil = d(), 0, nil; task.spawn(launchStage); end;
	local tickAt, queueAt, startedAt = -1e9, -1e9, nil;
	local function tick(now)
		-- process newly appeared labels: drop pop-ups, and hand relic / results labels to the run tracker
		if now - queueAt > .3 and #queue > 0 then
			queueAt = now;
			local batch = queue;
			queue = {};
			for _, o in ipairs(batch) do
				if o.Parent then
					local u = txt(o):upper();
					if u:find("PICK A RELIC", 1, true) then r.relicPromptLabel = o; end;
					if u:find("TRIP COMPLETE", 1, true) or u:find("RUN COMPLETE", 1, true) then r.resultsLabel = o; end;
					if u:find("1%s+IN%s+%d") then pcall(checkToast, o); end;
				end;
			end;
		end;
		if now - tickAt < 1 then return; end;
		tickAt = now;
		if not startedAt and brain.indexScannedAt then
			-- a new session (joined, rejoined after a disconnect, or the script re-run): the scan count starts over
			brain.runsAtScan = tonumber(brain.runCount) or 0;
		end;
		startedAt = startedAt or now;
		if not addConn then hook(); end;
		pcall(gearTick);
		-- one scan per launch, outside a run, once Roblox is focused; then it's done
		-- scan every N finished runs (mine or delve), between runs; the very first time as soon as possible
		local every = math.max(1, math.floor(tonumber(CFG.scanEveryRuns) or 10));
		local runsSince = (tonumber(brain.runCount) or 0) - (tonumber(brain.runsAtScan) or 0);
		local due = brain.indexScannedAt == nil or runsSince >= every;
		if r.hubForScan and inRun() and now - r.hubForScan > 30 then r.hubForScan = nil; end;
		if due and not busy and not r.launching and not r.f2Paused and CFG.autoIndexScan ~= false and now - startedAt > 10
			and not run.active and not relicAPI.hasDraft() and now - (r.scanTryAt or 0) > 10
			and not workspace:FindFirstChild("RunEndRoom") then
			r.scanTryAt = now;
			task.spawn(scan, brain.indexScannedAt == nil and "first scan" or string.format("after %d runs", runsSince));
		end;
		-- in the hub with Auto Farm on: open GO MINE and start the chosen stage
		-- after a scan trip to the hub, the next run starts from here even with Auto Farm off (scan first,
		-- unless it keeps failing for 90 s)
		local scanTrip = r.hubForScan and not r.f2Paused and (not (CFG.autoIndexScan ~= false and due) or now - r.hubForScan > 90);
		if (CFG.autoStage == true or scanTrip) and not r.f2Paused and not busy and not launch.busy and now - startedAt > 10 and not inRun()
			and not (CFG.autoStage == true and r.hubForScan and not scanTrip)
			and not relicAPI.hasDraft() and now - launch.at > math.min(60, 8 + launch.fails * 6)
			and now > (launch.lockedUntil or 0) and goMineButton() then
			launch.at = now;
			task.spawn(launchStage);
		end;
	end;
	local function report()
		local found, total, studied = 0, 0, 0;
		for _, rec in pairs(brain.index) do
			if type(rec) == "table" then
				total = total + 1;
				if rec.found then found = found + 1; end;
				if rec.studied then studied = studied + 1; end;
			end;
		end;
		local nsrc = 0;
		for _ in pairs(brain.sources) do nsrc = nsrc + 1; end;
		local p = brain.player;
		local life = 0;
		for _ in pairs(brain.lifetime) do life = life + 1; end;
		return string.format("Index: %d items, %d found, %d studied, %d sources (mobs/rocks).\nYou: %s (%s power), %s (%s power), mine power %s, mining range %s, luck %s\nLifetime stats: %d",
			total, found, studied, nsrc, tostring(p.pickaxe or "?"), tostring(p.pickPower or "?"), tostring(p.sword or "?"),
			tostring(p.swordPower or "?"), tostring(p.power or "?"), tostring(p.miningRange or "?"), tostring(p.luck or "?"), life);
	end;
	r.scanDue = function()
		if CFG.autoIndexScan == false then return false; end;
		local every = math.max(1, math.floor(tonumber(CFG.scanEveryRuns) or 10));
		return brain.indexScannedAt == nil or (tonumber(brain.runCount) or 0) - (tonumber(brain.runsAtScan) or 0) >= every;
	end;
	return { tick = tick, scan = function(reason) done = false; scan(reason); end, report = report };
end)();
-- ===================================================================================
-- DODGE BRAIN: learns from every hit you take
--   * hit while standing in a telegraphed zone  -> widen the safety margin (and roll earlier if
--     the roll was already pressed, i.e. it was too late)
--   * hit by a mob's swing from farther than expected -> remember that mob's real reach
--   * a roll with no hit afterwards -> slowly relax the margin again
-- ===================================================================================
local brainTick = (function()
	local hs = { hum = nil, conn = nil, hp = nil, rollSeen = nil, lastT = nil, saveAt = 0 };
	local function learnFromHit(loss, now)
		run.hits = run.hits + 1;
		if CFG.dodgeLearn == false then return; end;
		local pos = sQ();
		if not pos then return; end;
		-- (v5.30) lead-time record: the plan that covered this spot, how long before the hit it arrived, and
		-- when the escape and the roll started
		pcall(function()
			local Pq = r.plan;
			if not (Pq and Pq.hooked) then return; end;
			local sv = Pq.srv();
			local _, e = Pq.hitAt(pos.X, pos.Z, sv - .35, sv + .05);
			local esc, lr = r.escInfo, r.lastRoll;
			local nearD;
			for _, sh in ipairs(Pq.shots) do
				local sx, sz = Pq.shotPos(sh, sv - .1);
				if sx then
					local dd0 = math.sqrt((sx - pos.X) ^ 2 + (sz - pos.Z) ^ 2);
					if not nearD or dd0 < nearD then nearD = dd0; end;
				end;
			end;
			local tail = string.format("escape picked %s, roll %s, nearest planned shot %s",
				esc and string.format("%.2fs before", now - esc.t) or "never", lr and string.format("%.2fs before", now - lr) or "never",
				nearD and string.format("%.1f st", nearD) or "none");
			if e then
				f(string.format("hit -%.0f by plan #%s %s %s: cue came %.2fs before it landed, %s", loss, tostring(e.id), tostring(e.mob),
					tostring(e.what), (e.hitAt or e.spawnAt or sv) - (e.recv or sv), tail));
			else
				f(string.format("hit -%.0f: no planned attack covered this spot (%d planned, %d shots): touch or untracked, %s", loss, #Pq.hz, #Pq.shots, tail));
			end;
			local humC = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
			local dead = humC ~= nil and humC.Health <= 0;
			if dead or r.bossFight or (#Pq.hz + #Pq.shots) > 0 then
				Pq.requestCapture(dead and "death" or "hit", loss);
			end;
		end);
		local dd = brain.dodge;
		dd.hits = (tonumber(dd.hits) or 0) + 1;
		local inZone = false;
		local rolledRecently = now - (r.lastRoll or -1e9) < .7;
		local sigs, seenSig = {}, {};
		for _, z in ipairs(Fl) do
			if not z.mob and ul(z, pos.X, pos.Z, Vl + 1) then
				inZone = true;
				if z.sig and not seenSig[z.sig] then
					seenSig[z.sig] = true;
					sigs[#sigs + 1] = z.sig;
					-- this attack type got you: keep more distance from it and roll earlier next time
					local a = type(brain.attacks[z.sig]) == "table" and brain.attacks[z.sig] or { hits = 0, deaths = 0, extra = 0, lead = 0 };
					a.hits = (tonumber(a.hits) or 0) + 1;
					a.extra = math.min(3, (tonumber(a.extra) or 0) + (rolledRecently and .08 or .25));
					-- PERFECT DODGE timing: the roll's invincibility (i-frames) has to cover the moment it lands
					local since = now - (r.lastRoll or -1e9);
					local iw = tonumber(brain.dodge.iframe) or .35;
					if since < .7 then
						if since > iw then
							a.lead = math.max(-.15, (tonumber(a.lead) or 0) - .03); -- rolled too early: roll later
							a.early = (tonumber(a.early) or 0) + 1;
						else
							a.lead = math.min(.3, (tonumber(a.lead) or 0) + .02); -- still hit inside the roll: roll earlier
							a.late = (tonumber(a.late) or 0) + 1;
							-- and the i-frames are shorter than believed
							brain.dodge.iframe = math.max(.15, iw * .9 + since * .1);
						end;
					elseif now - (r.lastRoll or -1e9) >= yl and z.seenAt and now - z.seenAt >= .25 then
						-- the roll was ready and the attack was visible in time, but it didn't roll: roll earlier.
						-- (No warning or roll on cooldown = not a timing problem, so timing is left alone.)
						a.lead = math.min(.3, (tonumber(a.lead) or 0) + .03);
						a.missed = (tonumber(a.missed) or 0) + 1;
					end;
					if z.hole and math.sqrt((pos.X - z.x) ^ 2 + (pos.Z - z.z) ^ 2) < z.hole then
						-- hit while standing in the "safe" inner circle: it isn't safe for this attack
						a.holeHits = (tonumber(a.holeHits) or 0) + 1;
						if a.holeHits >= 2 then a.noHole = true; end;
					end;
					a.last = os.time();
					brain.attacks[z.sig] = a;
					z.sx, z.sl, z.noHole = a.extra, a.lead, a.noHole or nil;
				end;
			end;
		end;
		if inZone then
			dd.extra = math.min(2.5, (tonumber(dd.extra) or 0) + (rolledRecently and .05 or .15));
			if rolledRecently then
				dd.leadAdj = math.min(.2, (tonumber(dd.leadAdj) or 0) + .01);
			end;
		end;
		local best, bd;
		for _, mob in pairs(el) do
			if mob.owned and mob.x and mob.name and mob.strikeAt and now - mob.strikeAt < .6 then
				local dist = math.sqrt((mob.x - pos.X) ^ 2 + (mob.z - pos.Z) ^ 2);
				if (not bd or dist < bd) then best, bd = mob, dist; end;
			end;
		end;
		if best and WQ == "mine" then
			-- a mob hit us while we were mining: start fighting mobs from farther away
			local mode = run.modeName and run.modeName() or "waves";
			brain.threat[mode] = math.min(18, (tonumber(brain.threat[mode]) or 8) + .5);
			run.mobHits = (run.mobHits or 0) + 1;
			hs.lastMobHit = now;
		end;
		-- no strike seen and no zone: if a mob is close (15 st), it's most likely that mob (e.g. an elite's slam).
		-- Its reach is only raised after 2 such hits, so one stray projectile can't inflate it.
		local nearMob, nearD;
		if not inZone and not best then
			for _, mob in pairs(el) do
				if mob.owned and mob.x and mob.name and not mob.dead then
					local dist = math.sqrt((mob.x - pos.X) ^ 2 + (mob.z - pos.Z) ^ 2);
					if dist < 15 and (not nearD or dist < nearD) then nearMob, nearD = mob, dist; end;
				end;
			end;
			if nearMob then
				brain.reachObs = type(brain.reachObs) == "table" and brain.reachObs or {};
				local key = tostring(nearMob.name);
				local ob = type(brain.reachObs[key]) == "table" and brain.reachObs[key] or { n = 0, max = 0 };
				ob.n, ob.max = (tonumber(ob.n) or 0) + 1, math.max(tonumber(ob.max) or 0, nearD);
				brain.reachObs[key] = ob;
				if ob.n >= 2 and nearD > vl then
					local cur = tonumber(brain.mobReach[key]) or vl;
					brain.mobReach[key] = math.min(14, math.max(cur, nearD + .75));
					f(string.format("learned reach %s -> %.1f (unseen strike, %d hits)", key, brain.mobReach[key], ob.n));
				end;
			end;
		end;
		-- nothing explains this damage and no mob is near: it's the floor (lava strips etc.)
		-- (v5.37) ...unless it was a planned attack (the Worldheart's donut was put on the floor slabs under it),
		-- a fall into the collapse (health at 0 or below), the health reset in a run's first seconds (Seg_1, the
		-- first slab of every run, had 34 "hits") or the hub (SnowMound)
		local floorBlame = not inZone and not best and not nearMob;
		if floorBlame then
			local humF = l.Character and l.Character:FindFirstChildOfClass("Humanoid");
			if not run.active or now - (tonumber(run.startAt) or -1e9) < 12 or (humF and humF.Health <= 0) then
				floorBlame = false;
			else
				pcall(function()
					local Pq = r.plan;
					if Pq and Pq.hooked and CFG.planFeed ~= false then
						local sv = Pq.srv();
						if Pq.hitAt(pos.X, pos.Z, sv - .8, sv + .1) ~= nil then floorBlame = false; end;
					end;
				end);
			end;
		end;
		if floorBlame then
			local seenF = {};
			for _, part in ipairs(dangerMem.partsNear(pos, 0, true)) do
				local sig = dangerMem.sigOf(part);
				if sig and not seenF[sig] then
					seenF[sig] = true;
					local fr = type(brain.floorHaz[sig]) == "table" and brain.floorHaz[sig] or { hits = 0, safe = 0 };
					fr.hits = (tonumber(fr.hits) or 0) + 1;
					fr.last = os.time();
					brain.floorHaz[sig] = fr;
					sigs[#sigs + 1] = "floor:" .. sig;
					if fr.hits == 2 then notify("Learned a dangerous floor: " .. sig:match("^[^|]*") .. ". Avoiding it from now on.", "Delve danger"); end;
				end;
			end;
			pcall(navBlock, pos.X, pos.Z, now, 20);
			dangerMem.refreshAt = -1e9;
		end;
		hs.lastHitSigs, hs.lastHitAt, hs.lastHitMob = sigs, now, (best and best.name) or (nearMob and nearMob.name) or nil;
		if best and bd and bd > vl and bd < 16 then
			local key = tostring(best.name);
			local cur = tonumber(brain.mobReach[key]) or vl;
			brain.mobReach[key] = math.min(16, math.max(cur, bd + .75));
			f(string.format("learned reach %s -> %.1f", key, brain.mobReach[key]));
		end;
		markBrain();
		if r.sync then r.sync(); end;
		f(string.format("hit -%.0f inZone=%s rolled=%s margin+%.2f", loss, tostring(inZone), tostring(rolledRecently), dd.extra));
	end;
	-- a death teaches much more than a hit: whatever hit you last gets a big push
	r.learnDeath = function()
		if CFG.dodgeLearn == false then return; end;
		local now = d();
		-- read who killed you a moment later, and blame that boss's last attack too
		task.delay(1, function()
			pcall(function()
				local function tx(o) return (tostring(o.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")); end;
				local pg = l:FindFirstChild("PlayerGui");
				for _, o in ipairs(pg and pg:GetDescendants() or {}) do
					if o:IsA("TextLabel") and o.Visible and tx(o):upper() == "YOU DIED TO" then
						local best, by;
						for _, s2 in ipairs(o.Parent:GetDescendants()) do
							if s2:IsA("TextLabel") and s2 ~= o and s2.Visible and s2.AbsolutePosition.Y > o.AbsolutePosition.Y
								and tx(s2):match("%a") and not tx(s2):upper():find("DEPTH") and not tx(s2):find("%$")
								and (not by or s2.AbsolutePosition.Y < by) then
								best, by = s2, s2.AbsolutePosition.Y;
							end;
						end;
						local killer = best and tx(best):upper() or nil;
						if killer then
							brain.deaths = type(brain.deaths) == "table" and brain.deaths or {};
							brain.deaths[killer] = (tonumber(brain.deaths[killer]) or 0) + 1;
							r.deathBias = {};
							run.killer = killer;
							local live = dangerMem.live;
							if live and live.sig and now - live.at < 6 and type(brain.attacks[live.sig]) == "table" then
								local a = brain.attacks[live.sig];
								a.extra = math.min(4, (tonumber(a.extra) or 0) + .3);
								a.lead = math.min(.35, (tonumber(a.lead) or 0) + .03);
							end;
							markBrain();
							notify(string.format("Killed by %s (%d time%s). Its attacks get more room next time.", killer,
								brain.deaths[killer], brain.deaths[killer] == 1 and "" or "s"), "Delve danger");
						end;
						break;
					end;
				end;
			end);
		end);
		if not hs.lastHitAt or now - hs.lastHitAt > 4 then return; end;
		local what = {};
		for _, sig in ipairs(hs.lastHitSigs or {}) do
			local fsig = sig:match("^floor:(.+)$");
			if fsig and type(brain.floorHaz[fsig]) == "table" then
				local fr = brain.floorHaz[fsig];
				fr.hits = math.max(2, (tonumber(fr.hits) or 0) + 2);
				fr.deaths = (tonumber(fr.deaths) or 0) + 1;
				what[#what + 1] = "floor " .. fsig:match("^[^|]*");
			elseif type(brain.attacks[sig]) == "table" then
				local a = brain.attacks[sig];
				a.deaths = (tonumber(a.deaths) or 0) + 1;
				a.extra = math.min(4, (tonumber(a.extra) or 0) + .5);
				a.lead = math.min(.35, (tonumber(a.lead) or 0) + .05);
				what[#what + 1] = sig:gsub("^%a+:", "");
			end;
		end;
		if hs.lastHitMob then
			local key = tostring(hs.lastHitMob);
			brain.mobReach[key] = math.min(16, (tonumber(brain.mobReach[key]) or vl) + 1);
			what[#what + 1] = key;
		end;
		local dd = brain.dodge;
		dd.extra = math.min(2.5, (tonumber(dd.extra) or 0) + .1);
		markBrain();
		saveBrain(true);
		-- write the black box (last 5 s) so every death can be explained afterwards
		local box = r.box or {};
		task.delay(1.2, function()
			pcall(function()
				if type(appendfile) ~= "function" then return; end;
				appendfile("DelveDeaths.jsonl", game:GetService("HttpService"):JSONEncode({
					t = os.time(), depth = run.depth, killer = run.killer, lastHit = hs.lastHitSigs, lastMob = hs.lastHitMob,
					boss = r.bossFight, samples = box,
				}) .. "\n");
			end);
		end);
		notify("Died to " .. (#what > 0 and table.concat(what, ", ") or "something unseen")
			.. ". Next time: more distance from it and earlier rolls.", "Delve danger");
	end;
	r.stopBrain = function()
		if hs.conn then pcall(function() hs.conn:Disconnect(); end); hs.conn = nil; end;
		if hs.dconn then pcall(function() hs.dconn:Disconnect(); end); hs.dconn = nil; end;
	end;
	return function(now)
		local dt = hs.lastT and math.min(.25, now - hs.lastT) or 0;
		hs.lastT = now;
		if run.active then
			if WQ == "combat" then run.combatT = run.combatT + dt; elseif WQ == "mine" then run.mineT = run.mineT + dt; end;
			-- a minute of mining without mob hits: allow mobs a bit closer before stopping to fight
			if WQ == "mine" and CFG.on then
				hs.quietMine = (hs.quietMine or 0) + dt;
				if hs.lastMobHit and now - hs.lastMobHit < 60 then hs.quietMine = 0; end;
				if hs.quietMine >= 60 then
					hs.quietMine = 0;
					local mode = run.modeName and run.modeName() or "waves";
					brain.threat[mode] = math.max(5, (tonumber(brain.threat[mode]) or 8) - .25);
					markBrain();
				end;
			end;
		end;
		local character = l.Character;
		local hum = character and character:FindFirstChildOfClass("Humanoid");
		if hum ~= hs.hum then
			r.stopBrain();
			hs.hum, hs.hp = hum, hum and hum.Health;
			if hum then
				hs.conn = hum.HealthChanged:Connect(function(hp)
					local old = hs.hp or hp;
					hs.hp = hp;
					if hp < old - .5 then r.lastHitAt = d(); end;
					if hp < old - .5 and CFG.on then
						pcall(learnFromHit, old - hp, d());
					end;
				end);
				hs.dconn = hum.Died:Connect(function()
					run.died = true;
					pcall(r.learnDeath);
				end);
			end;
		end;
		-- a roll that wasn't followed by a hit = successful dodge: relax the margin a little
		local lr = r.lastRoll;
		if lr and lr ~= hs.rollSeen and now - lr > 1 then
			hs.rollSeen = lr;
			if run.hits == (hs.hitsAtRoll or run.hits) then
				local a = r.lastRollSig and brain.attacks[r.lastRollSig];
				if type(a) == "table" then
					a.extra = math.max(0, (tonumber(a.extra) or 0) - .03);
					a.lead = (tonumber(a.lead) or 0) * .97; -- a clean dodge eases the timing back too
					a.perfect = (tonumber(a.perfect) or 0) + 1;
				end;
				-- a clean roll through an attack that landed mid-roll: the i-frames last at least about that long.
				-- Moves slowly (it may also have just missed), instead of ratcheting to the cap.
				local hitIn = r.lastRollHitIn;
				local iw0 = tonumber(brain.dodge.iframe) or .35;
				if hitIn and hitIn > 0 and hitIn < .8 and hitIn + .05 > iw0 then
					brain.dodge.iframe = math.min(.6, iw0 * .95 + (hitIn + .05) * .05);
				end;
				r.lastRollHitIn = nil;
				local dd = brain.dodge;
				dd.dodges = (tonumber(dd.dodges) or 0) + 1;
				dd.extra = math.max(0, (tonumber(dd.extra) or 0) - .02);
				if r.sync then r.sync(); end;
				markBrain();
			end;
		end;
		if lr and lr ~= hs.rollMark then hs.rollMark, hs.hitsAtRoll = lr, run.hits; end;
		if run.active then
			local pos = sQ();
			pcall(dangerMem.refresh, pos, now);
			if pos and now - (hs.floorCheckAt or 0) > 1 and next(brain.floorHaz) then
				hs.floorCheckAt = now;
				if not hs.lastHitAt or now - hs.lastHitAt > 2.5 then
					for _, part in ipairs(dangerMem.partsNear(pos, 0, true)) do
						local sig = dangerMem.sigOf(part);
						local fr = sig and brain.floorHaz[sig];
						if type(fr) == "table" then fr.safe = (tonumber(fr.safe) or 0) + 1; end;
					end;
				end;
			end;
		end;
		pcall(relicAPI.runTick, now);
		pcall(indexAPI.tick, now);
		-- settings autosave (cheap: only writes when something changed)
		if now - (hs.setAt or 0) > 2 then
			hs.setAt = now;
			pcall(r.saveSettings);
		end;
		-- farm was on last session: start it once Delve is loaded
		if r.autoStart and now - (hs.autoAt or 0) > 1 then
			hs.autoAt = now;
			if not farmBlocker() then
				r.autoStart = false;
				N(true);
				if r.farmToggle then pcall(function() r.farmToggle:Set(true); end); end;
				notify("Farm auto-started (it was on when you left).", "Delve");
			end;
		end;
		if now - hs.saveAt > 20 then
			hs.saveAt = now;
			saveBrain(false);
		end;
	end;
end)();
-- main frame step (kept in r.step so the connection below can pcall it)
r.step = function()
		local m = d();
		pcall(brainTick, m);
		local blockedInput = missingInput and Q.background ~= true;
		if blockedInput or iQ() then
			if not blockedInput then
				Pl();
				inp.clearAim();
				NQ(m, true);
				vQ();
				if MQ.phase == "down" then inp.mouseUp(); end;
				MQ.phase = "idle";
				pcall(LQ, m);
			end;
			if wQ and not blockedInput then zQ(); end;
			if dQ and m - aQ.poll >= .1 then aQ.poll = m; dQ(); end;
			return;
		end;
		if wQ then
			zQ();
			return;
		end;
		if Q.autoStats ~= false and not r.statsFound and ((((r.rockCount or 0)) > 0 and m - lQ > 20)) then
			fQ(true);
		end;
		if m - aQ.poll >= .1 then
			aQ.poll = m;
			if ((Q.on and true or false)) ~= r.farmOn then
				N(Q.on);
			end;
			if dQ then
				dQ();
			end;
		end;
		-- network ping (one way) so rolls are sent early enough to land before the hit
		if m - aQ.ping >= .5 then
			aQ.ping = m;
			local okPing, ping = pcall(l.GetNetworkPing, l);
			r.pingLead = (Q.pingComp ~= false and okPing and type(ping) == "number") and math.min(ping, .25) or 0;
		end;
		local G = Q.combat or Q.chests or (Q.on and Q.centerFarm);
		if G then
			if m - aQ.sweep >= .5 then
				aQ.sweep, aQ.refresh = m, m;
				zl(m);
			elseif m - aQ.refresh >= .016 then
				aQ.refresh = m;
				xl(m);
			end;
			if xQ and ((el[xQ] and m - aQ.dead >= .25)) then
				aQ.dead = m;
				Wl(xQ, el[xQ], m);
			end;
		elseif next(el) then
			el = {};
		end;
		-- scan attack telegraphs every frame (the slow eval loop below is too late for fast attacks)
		if Q.dodge or Q.autoRoll then
			if inp.active() then
				local hazardPos = sQ();
				if hazardPos then
					aQ.haz = m;
					Xl(hazardPos, m);
				end;
			end;
		end;
		if m - aQ.eval >= ((((#Fl > 0 or next(Cl))) and .033 or .1)) then
			aQ.eval = m;
			lh(m);
		end;
		if Q.autoRoll and not iQ() then
			mh(m);
		else
			NQ(m);
		end;
		OQ(m);
		local e = nQ(m) or LQ(m);
		if not e and m - ((aQ.aim or 0)) >= .016666666666667 then
			aQ.aim = m;
			local G = nil;
			if inp.active() and not iQ() then
				local r = xQ and el[xQ];
				if r and ((WQ == "combat" and Q.combat)) then
					G = Kl(r, m);
				elseif WQ == "mine" and ((Q.mine and ((L and a)))) then
					if L.ore then
						local ore = L.ore;
						if ore and ore:IsDescendantOf(workspace) then
							local part = orePart(ore);
							G = part and part.Position;
						end;
					else
						G = Z(a, L.ax, L.az);
					end;
				end;
			end;
			if G then
				if inp.silent() and inp.setAim(G) then
					-- silent aim: the game reads our target instead of the cursor, the real mouse stays put
					CQ = nil;
				else
					inp.clearAim();
					EQ(G, m);
				end;
			else
				CQ = nil;
				inp.clearAim();
			end;
		end;
	end;
local dh = false;
do
	local connection;
	local handlingIdle = false;
	r.connectAntiAfk = function()
		connection = l.Idled:Connect(function()
			if dh or not Q.antiAfk or handlingIdle then return; end;
			local camera = workspace.CurrentCamera;
			if not camera then return; end;

			handlingIdle = true;
			local ok, err = pcall(function()
				local virtualUser = game:GetService("VirtualUser");
				local cameraFrame = camera.CFrame;
				virtualUser:Button2Down(Vector2.zero, cameraFrame);
				task.wait(1);
				virtualUser:Button2Up(Vector2.zero, cameraFrame);
			end);
			handlingIdle = false;
			if ok then
				notify("Idle input sent.", "Delve Anti-AFK");
			else
				notify(tostring(err), "Delve Anti-AFK error");
			end;
		end);
	end;
	r.disconnectAntiAfk = function()
		if connection then
			connection:Disconnect();
			connection = nil;
		end;
	end;
end;
r.stop = function()
		if dh then
			return;
		end;
		dh = true;
		r.stopped = true; -- (v5.38) a stopped or replaced copy no longer alerts, rejoins or writes the heartbeat
		r.disconnectAntiAfk();
		pcall(function()
			for _, c in ipairs(type(r.planConns) == "table" and r.planConns or {}) do c:Disconnect(); end;
			r.planConns = {};
		end);
		pcall(function() if r.f2Conn then r.f2Conn:Disconnect(); r.f2Conn = nil; end; end);
		pcall(function() r.stopBrain(); end);
		pcall(function() r.stopIndex(); end);
		pcall(function() relicAPI.finish(); end);
		pcall(saveBrain, true);
		uiNotify = nil;
		pcall(function()
			r.conn:Disconnect();
		end);
		pcall(function()
			r.conn2:Disconnect();
		end);
		pcall(inp.stop);
		pcall(Pl);
		pcall(vQ);
		if MQ.phase == "down" then
			pcall(inp.mouseUp);
		end;
		pcall(NQ, 0, true);
		if r.win and r.win.alive then
			r.win:Unload();
		end;
		notify("Stopped.", "Delve");
	end;

-- apply settings that are cached in upvalues (and resolve keybinds); safe to call any time
do
	local specialKeys = { Space = 32, Shift = 16, LShift = 160, RShift = 161, Ctrl = 17, Alt = 18, Tab = 9 };
	local function keyCode(name, fallback)
		if type(name) ~= "string" or #name == 0 then
			return fallback;
		end;
		if specialKeys[name] then
			return specialKeys[name];
		end;
		if #name == 1 then
			return string.byte(name:upper());
		end;
		return fallback;
	end;
	local function slotCode(n, fallback)
		n = math.floor(tonumber(n) or fallback);
		if n < 1 or n > 9 then
			n = fallback;
		end;
		return 48 + n;
	end;
	r.sync = function()
		dl = tonumber(Q.chestRange) or 120;
		Yl = tonumber(Q.keepAway) or 7;
		Vl = (tonumber(Q.hitMargin) or 1.5) + ((Q.dodgeLearn ~= false and tonumber(brain.dodge.extra)) or 0);
		vl = tonumber(Q.meleeReach) or 5.5;
		bl = (tonumber(Q.rollLead) or .2) + ((Q.dodgeLearn ~= false and tonumber(brain.dodge.leadAdj)) or 0);
		yl = tonumber(Q.rollCooldown) or 1.05;
		Jl = keyCode(Q.rollKey, 81);
		Il = slotCode(Q.pickSlot, 1);
		mQ = slotCode(Q.weaponSlot, 2);
	end;
	r.sync();
end;

(function()
	-- Settings shared by the controls and the runtime
	local STAGES = { "Delve", "Grasslands", "Sun Flats", "Frostbite", "Mycelia", "Pirates Cove", "Infernia", "The Abyss" };
	local spec = {
		{
			name = "Farm",
			main = true,
			items = {
				{ k = "stage", t = "combo", text = "Stage", items = STAGES },
				{ k = "stageOther", t = "input", text = "Other stage (overrides the list)", placeholder = "Type a stage name, e.g. THE ABYSS" },
				{ k = "autoReplay", t = "toggle", text = "Play again when a run ends" },
				{ k = "replayDelay", t = "slider", text = "Play again after", min = .5, max = 10, step = .5, suffix = " s" },
				{ k = "autoStartFarm", t = "toggle", text = "Turn the farm back on after a restart" },
				{ k = "autoRejoin", t = "toggle", text = "Rejoin after a disconnect" },
			},
		},
		{
			name = "Mining",
			icon = "pickaxe",
			items = {
				{ k = "mine", t = "feat", text = "Mine rocks" },
				{ k = "walk", t = "feat", text = "Walk to rocks" },
				{ k = "chests", t = "feat", text = "Collect chests" },
				{ k = "centerFarm", t = "toggle", text = "Mine from the chest / arena center" },
				{ k = "centerCleanup", t = "toggle", text = "Center: walk to ores out of reach" },
				{ k = "mineRange", t = "slider", text = "Rock search range", min = 10, max = 400, step = 10, suffix = " st" },
				{ k = "chestRange", t = "slider", text = "Chest range", min = 20, max = 300, step = 10, suffix = " st" },
				{ k = "minTier", t = "slider", text = "Min rock tier", min = 1, max = 10, step = 1, suffix = "" },
				{ k = "skipAfter", t = "slider", text = "Skip a stuck rock after", min = 3, max = 30, step = 1, suffix = " s" },
			},
		},
		{
			name = "Combat",
			icon = "sword",
			items = {
				{ k = "combat", t = "feat", text = "Fight mobs" },
				{ k = "chase", t = "feat", text = "Chase and circle the target" },
				{ k = "dodge", t = "feat", text = "Dodge attacks" },
				{ k = "autoRoll", t = "feat", text = "Roll out of attacks" },
				{ k = "mobPriority", t = "combo", text = "Mob priority", items = { "Smart", "Ores first", "Always fight" } },
				{ k = "dangerTime", t = "slider", text = "Delve timer: ignore mobs below", min = 0, max = 30, step = 1, suffix = " s" },
				{ k = "lowHpPct", t = "slider", text = "Stop chasing below HP", min = 0, max = 90, step = 5, suffix = " %" },
				{ k = "crowdSize", t = "slider", text = "Fight when this many mobs are up", min = 2, max = 20, step = 1, suffix = "" },
				{ k = "fightDist", t = "slider", text = "Circle distance", min = 2, max = 30, step = 1, suffix = " st" },
				{ k = "flankDodge", t = "toggle", text = "Dodge past enemies to keep hitting them" },
				{ k = "exploreForMobs", t = "toggle", text = "Search the room until all mobs left are found" },
				{ k = "rangedFirst", t = "toggle", text = "Take out shooters first when they're a threat" },
				{ k = "attackRoll", t = "combo", text = "Attack rolls (roll into the target)", items = { "On", "Off" } },
				{ k = "bossRolls", t = "toggle", text = "Roll through bosses when no attack is near" },
			},
		},
		{
			name = "Relics",
			icon = "gem",
			items = {
				{ k = "cardPick", t = "toggle", text = "Pick relics and blessings" },
				{ k = "relicExplore", t = "toggle", text = "Try relics it has never taken (to learn the index)" },
				{ k = "forkPath", t = "combo", text = "Tunnel fork path", items = { "Smart", "Safe", "Cursed" } },
				{ k = "afterBossPath", t = "combo", text = "After Worldheart", items = { "Descend", "Ascend", "Let the brain decide" } },
				{ k = "afterUnmaker", t = "combo", text = "After the Unmaker: which portal", items = { "Prestige portal", "Vesper's shop (?????)", "Neither" } },
				{ k = "traderBuy", t = "toggle", text = "Buy from traders" },
				{ k = "traderMinScore", t = "slider", text = "Trader: buy if score is at least", min = -50, max = 100, step = 1, suffix = "" },
			},
		},
		{
			name = "Brain",
			icon = "brain",
			items = {
				{ k = "autoIndexScan", t = "toggle", text = "Scan Index, Stats and Equipment (T menu)" },
				{ k = "scanEveryRuns", t = "slider", text = "Scan every", min = 1, max = 50, step = 1, suffix = " runs" },
			},
		},
		{
			name = "Discord",
			icon = "send",
			items = {
				{ k = "webhookOn", t = "toggle", text = "Post when a run is done" },
				{ k = "webhookUrl", t = "input", text = "Webhook URL", placeholder = "https://discord.com/api/webhooks/..." },
				{ k = "webhookDelay", t = "slider", text = "Screenshot delay", min = 0, max = 10, step = .5, suffix = " s" },
				{ k = "dropWebhook", t = "toggle", text = "Post rare drops" },
				{ k = "pingUserId", t = "input", text = "Discord user ID to ping", placeholder = "e.g. 123456789012345678" },
				{ k = "pingRuns", t = "toggle", text = "Ping on Run Complete" },
				{ k = "pingDrops", t = "toggle", text = "Ping on rare drops" },
				{ k = "pingDisconnect", t = "toggle", text = "Ping if disconnected, stuck or Roblox closes" },
				{ k = "rareDropOdds", t = "slider", text = "Drops with no tier: 1 in at least", min = 1000, max = 1000000, step = 1000, suffix = "" },
			},
		},
		{
			name = "Settings",
			icon = "settings",
			items = {
				{ k = "startClosed", t = "toggle", text = "Start with this window closed" },
				{ k = "niceToasts", t = "toggle", text = "Game-style pop-ups" },
				{ k = "uiFont", t = "combo", text = "Window font", items = { "Game font", "Mixed", "Clean" } },
				{ k = "relicNotify", t = "toggle", text = "Pop-ups: relic, trader and path choices" },
				{ k = "mechNotify", t = "toggle", text = "Pop-ups: new relics and mechanics" },
				{ k = "background", t = "toggle", text = "Background mode (work while tabbed out)" },
				{ k = "silentAim", t = "toggle", text = "Silent aim (don't move my mouse)" },
				{ k = "antiAfk", t = "toggle", text = "Anti-AFK" },
				{ k = "dangerView", t = "toggle", text = "Show what it sees (danger map)" },
			},
		},
	};

	local function apply(it, value)
		local key = it.k;
		if it.t == "feat" then
			Q.feat[key] = value and true or false;
			if Q.on then
				Q[key] = Q.feat[key];
			end;
		elseif it.t == "toggle" then
			Q[key] = value and true or false;
			if key == "autoStats" and value then
				r.statsFound = false;
				fQ(true);
			end;
			if key == "uiGameFont" and r.applyGameFont then task.spawn(r.applyGameFont); end;
			if key == "centerFarm" and not value then r.centerFarmChest = nil; r.strayTrip = false; end;
			if key == "background" or key == "silentAim" then
				if value then
					inp.ensureSilent();
				end;
				Pl();
				inp.clearAim();
			end;
		elseif it.t == "slider" then
			local num = tonumber(value);
			if not num then
				return;
			end;
			Q[key] = num;
		elseif it.t == "input" then
			Q[key] = tostring(value or "");
		elseif it.t == "combo" then
			if type(value) == "number" then
				value = it.items[value];
			end;
			if type(value) == "string" then
				Q[key] = value;
			end;
			if key == "uiFont" and r.applyGameFont then task.spawn(r.applyGameFont); end;
		end;
		if r.sync then
			r.sync();
		end;
	end;

	-- scan the game's stats and apply them (reach/radius), using a safe reach scale
	local function rescan()
		Q.autoStats = true;
		Q.reachScale = 1;
		r.statsFound = false;
		if r.sync then
			r.sync();
		end;
		fQ(false);
		if dQ then
			dQ();
		end;
	end;

	notify("Loading WindUI…", "Delve v3");
	local url = "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua";
	local downloaded, source = pcall(function() return game:HttpGet(url); end);
	assert(downloaded, "WindUI download failed: " .. tostring(source));
	local chunk, compileError = loadstring(source, "WindUI");
	assert(chunk, "WindUI compile failed: " .. tostring(compileError));
	local WindUI = chunk();
	assert(type(WindUI) == "table" and type(WindUI.CreateWindow) == "function", "WindUI did not return its window API");
	do
		-- pop-ups styled like the game: its own pixel font, dark card, coloured title, stacked bottom-right
		local TS = game:GetService("TweenService");
		local holder, font, seq = nil, nil, 0;
		local function gameFont()
			if font then return font; end;
			local pg = l:FindFirstChild("PlayerGui");
			local counts, best, bestN, seen = {}, nil, 0, 0;
			for _, o in ipairs(pg and pg:GetDescendants() or {}) do
				if o:IsA("TextLabel") and o.Text ~= "" then
					seen = seen + 1;
					if seen > 400 then break; end;
					local okF, ff = pcall(function() return o.FontFace; end);
					if okF and ff then
						counts[ff.Family] = (counts[ff.Family] or 0) + 1;
						if counts[ff.Family] > bestN then best, bestN = ff, counts[ff.Family]; end;
					end;
				end;
			end;
			if best and bestN >= 10 then
				font = Font.new(best.Family, Enum.FontWeight.Regular);
				return font;
			end;
			return Font.fromEnum(Enum.Font.Arcade);
		end;
		r.gameFont = gameFont;
		r.gameFontReady = function() return font ~= nil; end;
		local function ensure()
			if holder and holder.Parent and holder.Parent.Parent then return true; end;
			local sg = Instance.new("ScreenGui");
			sg.Name, sg.ResetOnSpawn, sg.IgnoreGuiInset, sg.DisplayOrder = "DelveToasts", false, true, 9999;
			sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
			local parent = type(gethui) == "function" and gethui() or nil;
			if not (parent and pcall(function() sg.Parent = parent; end)) then
				if not pcall(function() sg.Parent = game:GetService("CoreGui"); end) then sg.Parent = l:WaitForChild("PlayerGui"); end;
			end;
			holder = Instance.new("Frame");
			holder.BackgroundTransparency, holder.AnchorPoint = 1, Vector2.new(1, 1);
			holder.Position, holder.Size = UDim2.new(1, -18, 1, -18), UDim2.fromOffset(360, 700);
			holder.Parent = sg;
			local lay = Instance.new("UIListLayout");
			lay.VerticalAlignment, lay.HorizontalAlignment = Enum.VerticalAlignment.Bottom, Enum.HorizontalAlignment.Right;
			lay.SortOrder, lay.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 8);
			lay.Parent = holder;
			return true;
		end;
		local ACCENTS = {
			{ "ERROR", Color3.fromRGB(255, 92, 92) }, { "DROP", Color3.fromRGB(255, 200, 70) }, { "TRADER", Color3.fromRGB(120, 225, 120) },
			{ "PATH", Color3.fromRGB(80, 220, 205) }, { "RELIC", Color3.fromRGB(110, 170, 255) }, { "CODEX", Color3.fromRGB(205, 145, 255) },
			{ "MECHANIC", Color3.fromRGB(205, 145, 255) }, { "WEBHOOK", Color3.fromRGB(120, 140, 230) }, { "FARM", Color3.fromRGB(120, 225, 120) },
			{ "INDEX", Color3.fromRGB(255, 200, 70) }, { "GEAR", Color3.fromRGB(120, 225, 120) },
		};
		r.toast = function(message, title)
			if not ensure() then return; end;
			message = tostring(message);
			local head = tostring(title or "Delve"):gsub("^Delve%s*", ""):upper();
			if head == "" or head:find("^V%d") then head = "DELVE"; end;
			local accent = Color3.fromRGB(255, 165, 60);
			for _, a2 in ipairs(ACCENTS) do
				if head:find(a2[1], 1, true) then accent = a2[2]; break; end;
			end;
			if message:find("[Ee]rror") or message:find("Couldn't") then accent = ACCENTS[1][2]; end;
			seq = seq + 1;
			local ff = gameFont();
			local card = Instance.new("CanvasGroup");
			card.LayoutOrder, card.Size, card.AutomaticSize = seq, UDim2.fromOffset(340, 0), Enum.AutomaticSize.Y;
			card.BackgroundColor3, card.BackgroundTransparency, card.BorderSizePixel = Color3.fromRGB(16, 15, 22), .06, 0;
			card.GroupTransparency, card.Active = 1, true;
			local corner = Instance.new("UICorner");
			corner.CornerRadius = UDim.new(0, 4);
			corner.Parent = card;
			local stroke = Instance.new("UIStroke");
			stroke.Color, stroke.Thickness, stroke.Transparency = accent, 2, .25;
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
			stroke.Parent = card;
			local pad = Instance.new("UIPadding");
			pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 9), UDim.new(0, 10);
			pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 12), UDim.new(0, 12);
			pad.Parent = card;
			local lay = Instance.new("UIListLayout");
			lay.SortOrder, lay.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 5);
			lay.Parent = card;
			local function label(text, size, color, order)
				local t = Instance.new("TextLabel");
				t.BackgroundTransparency, t.LayoutOrder = 1, order;
				t.Size, t.AutomaticSize = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y;
				t.FontFace, t.TextSize, t.TextColor3 = ff, size, color;
				t.TextWrapped, t.TextXAlignment, t.TextYAlignment = true, Enum.TextXAlignment.Left, Enum.TextYAlignment.Top;
				t.TextStrokeTransparency, t.TextStrokeColor3 = .55, Color3.new(0, 0, 0);
				t.Text = text;
				t.Parent = card;
				return t;
			end;
			label(head, 18, accent, 1);
			local rule = Instance.new("Frame");
			rule.LayoutOrder, rule.Size, rule.BorderSizePixel = 2, UDim2.new(1, 0, 0, 2), 0;
			rule.BackgroundColor3, rule.BackgroundTransparency = accent, .55;
			rule.Parent = card;
			label(message, 15, Color3.fromRGB(232, 230, 238), 3);
			card.Parent = holder;
			-- keep the newest 5
			local kids = {};
			for _, c in ipairs(holder:GetChildren()) do
				if c:IsA("CanvasGroup") then kids[#kids + 1] = c; end;
			end;
			table.sort(kids, function(x, y) return x.LayoutOrder < y.LayoutOrder; end);
			for k = 1, #kids - 5 do kids[k]:Destroy(); end;
			TS:Create(card, TweenInfo.new(.2, Enum.EasingStyle.Quad), { GroupTransparency = 0 }):Play();
			local function close()
				if not card.Parent then return; end;
				local tw = TS:Create(card, TweenInfo.new(.35, Enum.EasingStyle.Quad), { GroupTransparency = 1 });
				tw.Completed:Connect(function() card:Destroy(); end);
				tw:Play();
			end;
			card.InputBegan:Connect(function(io)
				if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then close(); end;
			end);
			task.delay(math.clamp(4.5 + #message / 45, 4.5, 12), close);
		end;
	end;
	-- LEARNING CURVE window: depth per run (bars), 5-run average (line), hits per run, and recent vs earlier.
	-- Reads DelveRuns.jsonl; draws only when opened and after each run while open.
	do
		local Hs = game:GetService("HttpService");
		local cv = { gui = nil };
		local C_BG, C_PANEL, C_TEXT, C_DIM = Color3.fromRGB(16, 15, 22), Color3.fromRGB(26, 25, 34), Color3.fromRGB(232, 230, 238), Color3.fromRGB(140, 138, 150);
		local C_OK, C_DIED, C_SKIP, C_LINE, C_HIT = Color3.fromRGB(110, 205, 120), Color3.fromRGB(230, 95, 95), Color3.fromRGB(95, 95, 110), Color3.fromRGB(255, 200, 70), Color3.fromRGB(205, 145, 255);
		local function font() return (r.gameFont and r.gameFont()) or Font.fromEnum(Enum.Font.Arcade); end;
		local function readRuns()
			local runs = {};
			pcall(function()
				if type(isfile) == "function" and not isfile("DelveRuns.jsonl") then return; end;
				for line in tostring(readfile("DelveRuns.jsonl")):gmatch("[^\n]+") do
					local okD, rec = pcall(Hs.JSONDecode, Hs, line);
					if okD and type(rec) == "table" then runs[#runs + 1] = rec; end;
				end;
			end);
			return runs;
		end;
		local function label(parent, text, size, color, x, y, w, h, align)
			local t = Instance.new("TextLabel");
			t.BackgroundTransparency, t.FontFace, t.TextSize, t.TextColor3 = 1, font(), size, color;
			t.Position, t.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h);
			t.TextXAlignment = align or Enum.TextXAlignment.Left;
			t.Text = text;
			t.Parent = parent;
			return t;
		end;
		local function box(parent, color, x, y, w, h, z)
			local f2 = Instance.new("Frame");
			f2.BorderSizePixel, f2.BackgroundColor3 = 0, color;
			f2.Position, f2.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(math.max(1, w), math.max(1, h));
			f2.ZIndex = z or 2;
			f2.Parent = parent;
			return f2;
		end;
		local function lineSeg(parent, x1, y1, x2, y2, color)
			local dx, dy = x2 - x1, y2 - y1;
			local len = math.sqrt(dx * dx + dy * dy);
			local seg = box(parent, color, (x1 + x2) / 2 - len / 2, (y1 + y2) / 2 - 1, len, 3, 4);
			seg.Rotation = math.deg(math.atan2(dy, dx));
		end;
		local function avg(list, a2, b2)
			local sum, n = 0, 0;
			for k = math.max(1, a2), math.min(#list, b2) do sum, n = sum + list[k], n + 1; end;
			return n > 0 and sum / n or nil, n;
		end;
		-- one chart: last 100 runs of a mode as bars, 10-run average line, and the last 50 vs the 50 before
		local SHOW, CMP = 100, 50;
		local function section(body, y0, title, all, metric, unit)
			label(body, title, 16, C_LINE, 16, y0, 300, 20);
			local runs = {};
			for k = math.max(1, #all - SHOW + 1), #all do runs[#runs + 1] = all[k]; end;
			if #runs == 0 then
				label(body, "No runs recorded yet.", 14, C_DIM, 16, y0 + 26, 500, 20);
				return;
			end;
			local cx, cy, cw, ch = 50, y0 + 26, 590, 130;
			box(body, C_PANEL, cx, cy, cw, ch, 1);
			local vals = {};
			local maxV = 1;
			for k, rr in ipairs(runs) do
				vals[k] = tonumber(metric(rr)) or 0;
				maxV = math.max(maxV, vals[k]);
			end;
			local step = maxV > 2000 and 1000 or (maxV > 200 and 50 or 10);
			maxV = math.ceil(maxV / step) * step;
			for g = 0, 4 do
				local gy = cy + ch - ch * g / 4;
				box(body, Color3.fromRGB(40, 39, 50), cx, gy, cw, 1, 1);
				local v = maxV * g / 4;
				label(body, v >= 1000 and string.format("%dk", math.floor(v / 1000 + .5)) or tostring(math.floor(v + .5)), 11, C_DIM, 0, gy - 8, 46, 16, Enum.TextXAlignment.Right);
			end;
			local bw = cw / math.max(#runs, 20);
			for k, rr in ipairs(runs) do
				local h = ch * vals[k] / maxV;
				local col = rr.learned == false and C_SKIP or (rr.died and C_DIED or C_OK);
				box(body, col, cx + (k - 1) * bw + bw * .12, cy + ch - h, math.max(1, bw * .76), h, 2);
			end;
			local prevX, prevY;
			for k = 1, #runs do
				local a10 = avg(vals, k - 9, k);
				local x = cx + (k - .5) * bw;
				local y = cy + ch - ch * a10 / maxV;
				if prevX then lineSeg(body, prevX, prevY, x, y, C_LINE); end;
				prevX, prevY = x, y;
			end;
			-- the last 50 runs against the 50 before (all runs of this mode, not just the ones drawn)
			local allVals, allHits = {}, {};
			for k, rr in ipairs(all) do allVals[k], allHits[k] = tonumber(metric(rr)) or 0, tonumber(rr.hits) or 0; end;
			local n = #all;
			local r50, nr = avg(allVals, n - CMP + 1, n);
			local p50, np = avg(allVals, n - 2 * CMP + 1, n - CMP);
			local h50 = avg(allHits, n - CMP + 1, n);
			local ph50 = avg(allHits, n - 2 * CMP + 1, n - CMP);
			local deaths, best = 0, 0;
			for k = math.max(1, n - CMP + 1), n do if all[k].died then deaths = deaths + 1; end; end;
			for _, v in ipairs(allVals) do best = math.max(best, v); end;
			local function pct(x, y) return (x and y and y > 0) and string.format("%+.0f%%", (x - y) / y * 100) or "not enough runs yet"; end;
			local sy = cy + ch + 8;
			label(body, string.format("Last %d runs: avg %s %s  (%s vs the %d before)", nr, r50 and string.format("%.0f", r50) or "?", unit, pct(r50, p50), np), 14, C_TEXT, 16, sy, 640, 18);
			label(body, string.format("Hits/run %s (%s)   Deaths %d of %d   Best %d %s   Runs %d",
				h50 and string.format("%.1f", h50) or "?", pct(h50, ph50), deaths, nr, best, unit, n), 13, C_TEXT, 16, sy + 20, 640, 18);
		end;
		local function draw()
			local win = cv.win;
			if not win then return; end;
			for _, chd in ipairs(win:GetChildren()) do
				if chd.Name == "Body" then chd:Destroy(); end;
			end;
			local body = Instance.new("Frame");
			body.Name, body.BackgroundTransparency, body.Size, body.Position = "Body", 1, UDim2.new(1, 0, 1, -36), UDim2.fromOffset(0, 36);
			body.Parent = win;
			local all = readRuns();
			local delve, waves = {}, {};
			for _, rr in ipairs(all) do
				if rr.mode == "delve" and tonumber(rr.depth) then delve[#delve + 1] = rr;
				elseif rr.mode == "waves" then waves[#waves + 1] = rr; end;
			end;
			section(body, 4, "DELVE  (depth per run)", delve, function(rr) return rr.depth; end, "m");
			section(body, 228, "MINES  (wave reached per run)", waves, function(rr) return rr.wave; end, "waves");
			label(body, "Bars: green survived, red died, grey not learned from.  Gold line: 10-run average.", 12, C_DIM, 16, 452, 640, 18);
		end;
		local function open()
			if cv.gui and cv.gui.Parent then cv.gui.Enabled = true; draw(); return; end;
			local sg = Instance.new("ScreenGui");
			sg.Name, sg.ResetOnSpawn, sg.IgnoreGuiInset, sg.DisplayOrder = "DelveCurve", false, true, 9998;
			local parent = type(gethui) == "function" and gethui() or nil;
			if not (parent and pcall(function() sg.Parent = parent; end)) then
				if not pcall(function() sg.Parent = game:GetService("CoreGui"); end) then sg.Parent = l:WaitForChild("PlayerGui"); end;
			end;
			local win = Instance.new("Frame");
			win.Size, win.Position, win.AnchorPoint = UDim2.fromOffset(660, 520), UDim2.fromScale(.5, .5), Vector2.new(.5, .5);
			win.BackgroundColor3, win.BackgroundTransparency, win.BorderSizePixel, win.Active = C_BG, .04, 0, true;
			win.Parent = sg;
			local corner = Instance.new("UICorner");
			corner.CornerRadius = UDim.new(0, 6);
			corner.Parent = win;
			local stroke = Instance.new("UIStroke");
			stroke.Color, stroke.Thickness, stroke.Transparency = C_LINE, 2, .3;
			stroke.Parent = win;
			label(win, "LEARNING CURVE", 20, C_LINE, 16, 8, 400, 24);
			local close = Instance.new("TextButton");
			close.Size, close.Position, close.BackgroundTransparency = UDim2.fromOffset(30, 30), UDim2.new(1, -38, 0, 6), 1;
			close.FontFace, close.TextSize, close.TextColor3, close.Text = font(), 20, C_TEXT, "X";
			close.Parent = win;
			close.MouseButton1Click:Connect(function() sg.Enabled = false; end);
			-- drag by the title area
			local dragging, start, startPos;
			win.InputBegan:Connect(function(io)
				if io.UserInputType == Enum.UserInputType.MouseButton1 and io.Position.Y - win.AbsolutePosition.Y < 36 then
					dragging, start, startPos = true, io.Position, win.Position;
				end;
			end);
			win.InputEnded:Connect(function(io)
				if io.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false; end;
			end);
			game:GetService("UserInputService").InputChanged:Connect(function(io)
				if dragging and io.UserInputType == Enum.UserInputType.MouseMovement then
					local dl = io.Position - start;
					win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + dl.X, startPos.Y.Scale, startPos.Y.Offset + dl.Y);
				end;
			end);
			cv.gui, cv.win = sg, win;
			draw();
		end;
		r.curveOpen = function() pcall(open); end;
		r.curveRefresh = function()
			if cv.gui and cv.gui.Parent and cv.gui.Enabled then pcall(draw); end;
		end;
	end;
	uiNotify = function(message, title)
		if CFG.niceToasts ~= false and r.toast and pcall(r.toast, message, title) then return; end;
		if type(WindUI.Notify) == "function" then
			WindUI:Notify({ Title = title, Content = message, Duration = 6 });
		end;
	end;

	local window = WindUI:CreateWindow({
		Title = "Delve v5.41 | Brain",
		Folder = "DelveV3",
		Size = UDim2.fromOffset(900, 700),
		ToggleKey = Enum.KeyCode.RightShift,
		OpenButton = {
			Title = "Open Delve",
			CornerRadius = UDim.new(0, 4),
			Enabled = true,
			Draggable = true,
			OnlyMobile = false,
		},
	});
	task.delay(1, function()
		pcall(function()
			local places = {};
			if type(gethui) == "function" then pcall(function() places[#places + 1] = gethui(); end); end;
			pcall(function() places[#places + 1] = game:GetService("CoreGui"); end);
			for _, place in ipairs(places) do
				for _, o in ipairs(place:GetDescendants()) do
					if o:IsA("TextLabel") and o.Text == "Open Delve" then
						local a = o.Parent;
						for _ = 1, 4 do
							if not a then break; end;
							for _, c in ipairs(a:GetChildren()) do
								if c:IsA("UICorner") then c.CornerRadius = UDim.new(0, 4); end;
							end;
							a = a.Parent;
						end;
					end;
				end;
			end;
		end);
	end);
	local visible = true;
	r.win = {
		alive = true,
		Close = function() pcall(function() window:Close(); end); end,
		IsVisible = function() return visible; end,
		Unload = function(self)
			self.alive = false;
			window:Destroy();
		end,
	};
	window:OnOpen(function() visible = true; end);
	window:OnClose(function() visible = false; end);
	window:OnDestroy(function()
		r.win.alive = false;
		visible = false;
		r.stop();
	end);

	local main = window:Tab({ Title = "Farm", Icon = "play" });
	local farmToggle;
	-- ONE switch for farming: on = farm in the run, and from the hub start the chosen stage (old "Auto Farm").
	-- On load it shows what will actually happen: on only if the farm is coming back on by itself.
	Q.autoStage = r.autoStart and true or false;
	local function farmSwitch(enabled)
		if enabled then r.f2Paused = nil; end; -- Auto Farm on (F2 or the menu) ends an F2 pause
		if not enabled then
			r.autoStart, r.hubForScan = false, nil;
			Q.autoStage = false;
			N(false);
			pcall(r.saveSettings);
			return;
		end;
		if missingInput and Q.background ~= true then
			notify(missingInput, "Delve");
			if farmToggle then pcall(farmToggle.Set, farmToggle, false); end;
			return;
		end;
		Q.autoStage = true;
		if Q.on then return; end;
		if farmBlocker() then
			-- in the hub: start the stage from GO MINE, the farm turns on once the run loads
			if not r.autoStart then
				r.autoStart = true;
				notify("Auto Farm on: starting your stage from the hub.", "Delve");
			end;
		else
			r.autoStart = false;
			N(true);
		end;
		pcall(r.saveSettings);
	end;
	r.farmSwitch = farmSwitch;
	farmToggle = main:Toggle({
		Title = "Auto Farm",
		Value = r.autoStart and true or false,
		Callback = farmSwitch,
	});
	r.farmToggle = farmToggle;
	local synced = {};
	local function current(item)
		if item.t == "feat" then return Q.feat[item.k] ~= false; end;
		return Q[item.k];
	end;
	-- INFO TEXT under every setting: what it does, then a recommendation. Shown as the setting's description.
	local INFO = {
		autoStage = { "The one on/off switch (also F2). In a run: mines, fights, dodges and picks relics. In the hub: opens GO MINE!, picks the stage below and starts it; the farm turns on once the run loads.", "Recommended: ON for AFK farming." },
		stage = { "Which stage Auto Farm starts from the hub.", "Recommended: Delve." },
		stageOther = { "Type a stage name that isn't in the list. Anything here overrides the Stage list.", "Recommended: leave empty." },
		autoRejoin = { "After a disconnect while farming (lost connection, server shut down, no response), it joins a new Delve server inside the same Roblox, so Volt stays connected and the script loads again by itself; farming carries on and Discord gets a note. Never when you were kicked or banned, or when your account joined from another device (that would throw your other session out). At most 5 rejoins an hour. If Roblox itself closes or crashes, press Launch in Volt (the helper pings you).", "Recommended: ON for AFK farming." },
		autoReplay = { "Clicks BACK TO MINE on the end screen so the next run starts by itself (only while Auto Farm is on; F2 pauses it).", "Recommended: ON for AFK farming." },
		replayDelay = { "Seconds to wait on the end screen before playing again (gives the screenshot time to be taken).", "Recommended: 2.5 s. Don't go below 1.5 s if Discord posts are on." },
		autoStartFarm = { "Turns the farm back on by itself after you rejoin or re-run the script.", "Recommended: ON." },
		mine = { "Mines rocks and ores. Turning it off means fight-only.", "Recommended: ON. Delve needs ores mined to beat the timer." },
		walk = { "Walks to the next rock instead of only mining what's in reach.", "Recommended: ON." },
		chests = { "Walks to and opens chests after a floor is cleared.", "Recommended: ON." },
		centerFarm = { "Stands at the chest / arena center and mines from there (for wave stages with a fixed center).", "Recommended: OFF for Delve. Only for wave arenas." },
		centerCleanup = { "With center mining, still walks out to ores that are out of reach.", "Recommended: OFF unless center mining is on." },
		mineRange = { "How far it looks for rocks to walk to.", "Recommended: 150 st. Higher wanders off, lower misses ores." },
		chestRange = { "How far it looks for chests to walk to.", "Recommended: 120 st." },
		minTier = { "Ignores rocks below this tier (1 = mine everything).", "Recommended: 1 in Delve (every ore counts toward the timer)." },
		skipAfter = { "If a rock can't be reached or broken for this long, it moves on to another one.", "Recommended: 9 s." },
		combat = { "Fights mobs with your weapon.", "Recommended: ON. Delve needs mobs and bosses killed." },
		chase = { "Follows the target and circles it while hitting.", "Recommended: ON." },
		dodge = { "Steps out of attack zones (red areas, beams, slams) before they land. The core of staying alive.", "Recommended: ON. Never turn this off." },
		autoRoll = { "Uses the roll to get out of attacks when walking isn't fast enough.", "Recommended: ON." },
		mobPriority = { "Smart: ores first, fights bosses, threats and mob floors. Ores first: avoids fights. Always fight: kills everything.", "Recommended: Smart." },
		dangerTime = { "When the Delve floor timer is at or below this, it ignores mobs (except bosses and mobs on top of you) and only mines.", "Recommended: 15 s. Raise it if you get caved in." },
		lowHpPct = { "Below this HP it stops chasing and keeps its distance from bosses.", "Recommended: 35 %. With Glass Soul (1 HP) this has no effect." },
		crowdSize = { "When this many mobs are up at once, it clears them before mining.", "Recommended: 5." },
		fightDist = { "How close it circles the target while fighting.", "Recommended: 8 st. Lower hits more but gets hit more." },
		flankDodge = { "Dodges past the enemy (behind or beside it) instead of backing away, so it keeps hitting.", "Recommended: ON." },
		exploreForMobs = { "When the HUD says more mobs are left than it can see (pylons at the top of a boss room), it walks up the room to find them.", "Recommended: ON." },
		rangedFirst = { "Kills mobs that shoot or hit from far away first, but only when they're actually firing at you.", "Recommended: ON." },
		attackRoll = { "Rolls into the target when nothing is about to hit you (good with roll perks like Onibi Step).", "Recommended: On." },
		bossRolls = { "In boss fights, rolls through the boss for extra damage, but only when no attack zone is within 18 st (25 st on a 1-HP run), nothing is winding up and no boss attack is expected for 2 s.", "Recommended: ON." },
		cardPick = { "Picks relics, blessings, forks and trader buys by itself using the brain's scores.", "Recommended: ON for AFK. OFF shows the pick but lets you choose." },
		relicExplore = { "Now and then takes a relic it has never taken, so the brain learns the whole relic index. Never instead of a second chance, luck relic or set completion.", "Recommended: ON." },
		forkPath = { "Safe or Cursed tunnel at forks. Smart picks Cursed when the run is healthy, Safe when it's in trouble.", "Recommended: Smart." },
		afterBossPath = { "After Worldheart: Descend (more mobs, combat relics first) or Ascend (more rock, mining relics first).", "Recommended: Descend." },
		afterUnmaker = { "After the Unmaker the Prestige portal and Vesper's shop portal (?????) stand side by side. Prestige portal: keeps going deeper. Vesper's shop: walks into the shop. Whenever you arrive at Vesper's shop (walked by the bot or by you), Discord pings you and everything pauses like F2; press F2 to start farming again. The bot never buys or sells anything there. Neither: it stays in the room.", "Recommended: Prestige portal." },
		traderBuy = { "Buys from the in-run relic trader when a relic is worth it. Uses in-run currency only.", "Recommended: ON." },
		traderMinScore = { "Only buys from the trader when the relic's score is at least this.", "Recommended: 5." },
		autoIndexScan = { "Every few runs goes to the hub and reads the T menu (Index, Stats, Equipment) so the brain knows drop odds and your gear.", "Recommended: ON." },
		scanEveryRuns = { "How many runs between scans. The count starts over every time you join or rejoin.", "Recommended: 10-30." },
		webhookOn = { "Posts a Run Complete message with a screenshot to your Discord webhook.", "Recommended: ON once the webhook URL is set." },
		webhookUrl = { "Your Discord channel webhook (Server Settings > Integrations > Webhooks > Copy URL). Keep it private.", "Recommended: paste it, then send a test post." },
		webhookDelay = { "Seconds before the screenshot is taken, so the end screen is fully shown.", "Recommended: 1.5 s." },
		dropWebhook = { "Posts Mythic, Forsaken and Eternal drops (and very rare untiered ones) to Discord.", "Recommended: ON." },
		pingUserId = { "Your Discord user ID (number). Mentions you in posts so your phone buzzes. Stays only in your local settings.", "Recommended: set it if you want pings." },
		pingRuns = { "Pings you on every Run Complete post.", "Recommended: your choice. OFF if it's too many pings." },
		pingDrops = { "Pings you on rare drop posts.", "Recommended: ON." },
		pingDisconnect = { "Pings you if Roblox disconnects you, or closes / crashes / freezes while the bot is on (needs the screenshot helper running), and if it has been standing still in a Delve for 3 minutes (it keeps trying to move on; DelveStall.txt says why).", "Recommended: ON. Turn the bot off before closing Roblox yourself." },
		rareDropOdds = { "Drops with no tier name are posted only if they're at least this rare.", "Recommended: 1 in 100,000." },
		startClosed = { "Hides this window on load. Right Shift or Open Delve shows it.", "Recommended: ON." },
		niceToasts = { "Pop-ups styled like the game instead of plain Roblox notifications.", "Recommended: ON." },
		uiFont = { "Game font: the game's pixel font everywhere, lighter for normal text. Mixed: pixel titles, clean text. Clean: clean font everywhere.", "Recommended: Game font." },
		relicNotify = { "Pop-up for each relic, trader and path choice and why it picked it.", "Recommended: ON while watching, OFF if it's distracting." },
		mechNotify = { "Pop-up when it meets a new relic or mechanic.", "Recommended: ON." },
		background = { "Keeps farming while Roblox is tabbed out (sends input without your real mouse/keyboard).", "Recommended: ON if you use the PC while farming." },
		silentAim = { "Aims without moving your real mouse cursor.", "Recommended: ON together with Background mode, otherwise OFF." },
		antiAfk = { "Stops Roblox from kicking you for being idle.", "Recommended: ON for AFK farming." },
		dangerView = { "Draws the danger zones, safe spots and route it sees on screen.", "Not recommended for farming (costs FPS). Use it to watch what it thinks." },
	};
	local function infoText(it)
		local i = INFO[it.k];
		if not i then return nil; end;
		return i[1] .. "\n\n" .. i[2];
	end;
	for _, group in ipairs(spec) do
		local tab = group.main and main or window:Tab({ Title = group.name, Icon = group.icon });
		for _, item in ipairs(group.items) do
			local it = item;
			local value = current(it);
			local widget;
			local function changed(newValue)
				apply(it, newValue);
				if synced[it.k] then synced[it.k].value = current(it); end;
			end;
			if it.t == "input" then
				local okInput, inputWidget = pcall(function()
					return tab:Input({
						Title = it.text,
						Placeholder = it.placeholder or "",
						Value = tostring(value or ""),
						Callback = changed,
					});
				end);
				widget = okInput and inputWidget or nil;
			elseif it.t == "slider" then
				widget = tab:Slider({
					Title = it.text,
					Step = it.step,
					Value = { Min = it.min, Max = it.max, Default = tonumber(value) or it.min },
					Callback = changed,
				});
			elseif it.t == "combo" then
				widget = tab:Dropdown({
					Title = it.text,
					Values = it.items,
					Value = value,
					AllowNone = false,
					Callback = changed,
				});
			else
				widget = tab:Toggle({ Title = it.text, Value = value == true, Callback = changed });
			end;
			synced[it.k] = { widget = widget, value = value, item = it };
		end;
		if group.rescan then tab:Button({ Title = "Read mining stats now", Callback = rescan }); end;
		if group.main then
			tab:Button({ Title = "Start the stage now", Callback = function() if r.launchStage then r.launchStage(); end; end });
			tab:Paragraph({
				Title = "How it works",
				Desc = "From the hub it clicks GO MINE!, scrolls to your stage, selects it and descends. The farm turns on once the run loads. Right Shift or the Open Delve button shows this window. F2 stops all farming; F2 again resumes. F8 saves a capture (with the helper's recorder on).",
			});
			tab:Button({ Title = "Stop and unload", Callback = r.stop });
		end;
		if group.name == "Discord" then
			tab:Button({
				Title = "Send test post",
				Callback = function()
					task.spawn(function()
						r.sendRunWebhook({ mode = run.modeName and run.modeName() or "?", score = 0, z = 0, depth = run.depth, wave = run.wave, cash = 0, seconds = 0, relics = {} }, true);
					end);
				end,
			});
			tab:Paragraph({
				Title = "Screenshots",
				Desc = "Double-click 'Start Delve Screenshots.bat' (Volt scripts folder) and leave it open to attach a screenshot. Without it, runs are posted as text.",
			});
		end;
		if group.name == "Brain" then
			tab:Button({
				Title = "Show last relic draft scores",
				Callback = function()
					notify(r.lastDraft and table.concat(r.lastDraft, "\n") or "No relic draft seen yet.", "Delve relic");
				end,
			});
			tab:Button({
				Title = "Show what the brain learned",
				Callback = function()
					local dd = brain.dodge;
					local reach = {};
					for name, v in pairs(brain.mobReach) do reach[#reach + 1] = string.format("%s %.1f", name, tonumber(v) or 0); end;
					local threat = {};
					for mode, v in pairs(brain.threat) do threat[#threat + 1] = string.format("%s %.1f st", mode, tonumber(v) or 0); end;
					notify(relicAPI.report() .. string.format("\nDodge: +%.2f st margin, roll %+.2fs earlier, %d hits / %d clean rolls\nRuns learned from: %d",
						tonumber(dd.extra) or 0, tonumber(dd.leadAdj) or 0, tonumber(dd.hits) or 0, tonumber(dd.dodges) or 0, tonumber(brain.runCount) or 0)
						.. (#reach > 0 and ("\nMob reach: " .. table.concat(reach, ", ")) or "")
						.. (#threat > 0 and ("\nFight mobs within: " .. table.concat(threat, ", ")) or ""), "Delve brain");
				end,
			});
			tab:Button({
				Title = "Scan Index + Equipment now",
				Callback = function()
					task.spawn(indexAPI.scan, "manual");
				end,
			});
			tab:Button({
				Title = "Show learning curve (graph)",
				Callback = function() if r.curveOpen then r.curveOpen(); end; end,
			});
			tab:Button({
				Title = "Show recent reasoning (combat + relics)",
				Callback = function()
					local lines = {};
					for k = math.max(1, #r.whyLines - 12), #r.whyLines do lines[#lines + 1] = r.whyLines[k]; end;
					notify(#lines > 0 and table.concat(lines, "\n") or "Nothing yet. Full log: DelveReasoning.txt in the Volt workspace.", "Delve reasoning");
				end,
			});
			tab:Button({
				Title = "Show danger learned (attacks, floors, bosses)",
				Callback = function()
					local out = {};
					local list = {};
					for sig, a in pairs(brain.attacks or {}) do
						if type(a) == "table" then list[#list + 1] = { sig = sig, a = a }; end;
					end;
					table.sort(list, function(x, y) return (tonumber(x.a.hits) or 0) > (tonumber(y.a.hits) or 0); end);
					for k = 1, math.min(6, #list) do
						local a = list[k].a;
						out[#out + 1] = string.format("%s: %d hits, %d deaths, %d perfect dodges, +%.1f st, roll %+.2fs%s", (list[k].sig:gsub("^%a+:", "")),
							tonumber(a.hits) or 0, tonumber(a.deaths) or 0, tonumber(a.perfect) or 0, tonumber(a.extra) or 0, tonumber(a.lead) or 0, a.noHole and ", no safe ring" or "");
					end;
					for sig, fr in pairs(brain.floorHaz or {}) do
						if type(fr) == "table" and (tonumber(fr.hits) or 0) >= 2 then
							out[#out + 1] = string.format("Floor %s: %d hits (avoided)", sig:match("^[^|]*"), tonumber(fr.hits) or 0);
						end;
					end;
					for boss, book in pairs(brain.bossAdds or {}) do
						for add, rec in pairs(type(book) == "table" and book or {}) do
							if type(rec) == "table" and (tonumber(rec.score) or 0) >= 1 then
								out[#out + 1] = string.format("Boss %s: kill %s first", boss, add);
							end;
						end;
					end;
					for boss, pt in pairs(brain.patterns or {}) do
						if type(pt) == "table" then
							local ns = 0;
							for _ in pairs(pt.sigs or {}) do ns = ns + 1; end;
							out[#out + 1] = string.format("Boss %s: %d attacks seen, %d kinds", boss, tonumber(pt.n) or 0, ns);
						end;
					end;
					notify(#out > 0 and table.concat(out, "\n") or "Nothing learned yet. It learns from every hit and death.", "Delve danger");
				end,
			});
			tab:Button({
				Title = "Show mechanics learned",
				Callback = function()
					local list = {};
					for _, m in pairs(brain.mech) do
						if type(m) == "table" and m.kind ~= "screen" then list[#list + 1] = m; end;
					end;
					table.sort(list, function(x, y) return (tonumber(x.first) or 0) > (tonumber(y.first) or 0); end);
					local out = {};
					for k = 1, math.min(15, #list) do
						local m = list[k];
						local n = tonumber(m.n) or 0;
						out[#out + 1] = string.format("[%s] %s: seen %dx, %s", tostring(m.kind), tostring(m.sample or m.text), tonumber(m.seen) or 0,
							n > 0 and string.format("%+.2f over %d runs", (tonumber(m.zsum) or 0) / n, n) or "no runs yet");
					end;
					notify(#list .. " mechanics known (newest first).\n" .. table.concat(out, "\n"), "Delve mechanics");
				end,
			});
			tab:Button({
				Title = "Show index knowledge",
				Callback = function()
					notify(indexAPI.report(), "Delve index");
				end,
			});
			tab:Button({
				Title = "Show relic codex (every relic seen)",
				Callback = function()
					local list = {};
					for _, cx in pairs(brain.codex) do
						if type(cx) == "table" then list[#list + 1] = cx; end;
					end;
					table.sort(list, function(x, y) return (tonumber(x.lastScore) or 0) > (tonumber(y.lastScore) or 0); end);
					local out = {};
					for k = 1, math.min(15, #list) do
						local cx = list[k];
						local cats = type(cx.cats) == "table" and table.concat(cx.cats, "/") or "?";
						out[#out + 1] = string.format("%s [%s] %s, seen %dx", tostring(cx.name), tostring(cx.tier), cats, tonumber(cx.seen) or 0);
					end;
					notify(#list .. " relics known.\n" .. table.concat(out, "\n"), "Delve codex");
				end,
			});
			tab:Button({
				Title = "Save brain now",
				Callback = function()
					local okS, why = saveBrain(true);
					notify(okS and "Saved to DelveBrain.json"
						or (type(writefile) ~= "function" and "This executor has no writefile; learning lasts until you rejoin." or ("Not saved: " .. tostring(why))), "Delve brain");
				end,
			});
			tab:Button({
				Title = "Reset everything the brain learned",
				Callback = function()
					r.brainBackup("before-reset");
					brain.relics, brain.cat, brain.sets, brain.runs, brain.mobReach = {}, {}, {}, {}, {};
					brain.dodge = { extra = 0, leadAdj = 0, hits = 0, dodges = 0 };
					if r.sync then r.sync(); end;
					brainState.shrinkOk = true; -- (v5.40) a reset may make the file much smaller
					saveBrain(true);
					notify("Brain reset.", "Delve brain");
				end,
			});
		end;
		if group.name == "Combat" then
			tab:Button({
				Title = "Report sword range",
				Callback = function()
					uQ(d(), true);
					local message = r.range
						and string.format("Estimated sword range: %.2f studs. Orbit distance: %.2f studs.", r.range, YQ())
						or string.format("No sword range detected. Manual orbit distance: %.2f studs.", YQ());
					notify(message, "Delve combat");
				end,
			});
		end;
	end;
	do
		local credits = window:Tab({ Title = "Credits", Icon = "heart" });
		credits:Paragraph({
			Title = "Delve Brain",
			Desc = "GitHub: github.com/pokemoncombi145-sys/delve\nSource, README and the full changelog live there.",
		});
		credits:Button({
			Title = "Copy GitHub link",
			Callback = function()
				local okC = pcall(function() setclipboard("https://github.com/pokemoncombi145-sys/delve"); end);
				notify(okC and "GitHub link copied." or "Couldn't copy: github.com/pokemoncombi145-sys/delve", "Delve");
			end,
		});
		credits:Paragraph({
			Title = "Built with Claude",
			Desc = "Code, the learning brain and log reviews written with Claude (Anthropic), shaped by real runs and feedback.",
		});
		credits:Paragraph({
			Title = "Updates",
			Desc = "The version is in the window title. Every change, with the evidence behind it, is in CHANGELOG.md on GitHub.",
		});
	end;
	-- INFO ICONS: a small (i) after each setting's name; hovering it shows what the setting does and the
	-- recommendation in a tooltip. Hidden otherwise, so the list stays short.
	task.delay(1, function()
		pcall(function()
			local byTitle = { ["Auto Farm"] = infoText({ k = "autoStage" }) };
			for _, group in ipairs(spec) do
				for _, it in ipairs(group.items) do
					local txt0 = infoText(it);
					if txt0 then byTitle[it.text] = txt0; end;
				end;
			end;
			local root;
			local okU, mainUI = pcall(function() return window.UIElements and window.UIElements.Main; end);
			if okU and typeof(mainUI) == "Instance" then root = mainUI:FindFirstAncestorWhichIsA("LayerCollector"); end;
			if not root then return; end;
			local tip = Instance.new("Frame");
			tip.Name = "DelveInfoTip";
			tip.Visible = false;
			tip.ZIndex = 1000;
			tip.Size = UDim2.fromOffset(320, 0);
			tip.AutomaticSize = Enum.AutomaticSize.Y;
			tip.BackgroundColor3 = Color3.fromRGB(24, 24, 28);
			tip.BorderSizePixel = 0;
			local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = tip;
			local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(150, 110, 255); stroke.Thickness = 1; stroke.Parent = tip;
			local pad = Instance.new("UIPadding");
			pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10), UDim.new(0, 8), UDim.new(0, 8);
			pad.Parent = tip;
			local tipText = Instance.new("TextLabel");
			tipText.Name = "Text";
			tipText.BackgroundTransparency = 1;
			tipText.Size = UDim2.new(1, 0, 0, 0);
			tipText.AutomaticSize = Enum.AutomaticSize.Y;
			tipText.TextWrapped = true;
			tipText.TextXAlignment = Enum.TextXAlignment.Left;
			tipText.TextYAlignment = Enum.TextYAlignment.Top;
			tipText.TextColor3 = Color3.fromRGB(235, 235, 240);
			tipText.TextSize = 15;
			tipText.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium);
			tipText.ZIndex = 1001;
			tipText.Parent = tip;
			tip.Parent = root;
			local function showTip(icon, text)
				tipText.Text = text;
				local cam = workspace.CurrentCamera;
				local vw = cam and cam.ViewportSize.X or 1920;
				local x = icon.AbsolutePosition.X + icon.AbsoluteSize.X + 8;
				if x + 330 > vw then x = icon.AbsolutePosition.X - 330; end;
				tip.Position = UDim2.fromOffset(x, icon.AbsolutePosition.Y - 4);
				tip.Visible = true;
			end;
			local done = {};
			for _, o in ipairs(root:GetDescendants()) do
				if o:IsA("TextLabel") and byTitle[o.Text] and not done[o.Text] and o.Name ~= "Text" then
					done[o.Text] = true;
					local label, text = o, byTitle[o.Text];
					local icon = Instance.new("TextButton");
					icon.Name = "DelveInfoIcon";
					icon.Text = "i";
					icon.AutoButtonColor = false;
					icon.Size = UDim2.fromOffset(16, 16);
					icon.AnchorPoint = Vector2.new(0, .5);
					icon.BackgroundColor3 = Color3.fromRGB(70, 70, 82);
					icon.TextColor3 = Color3.fromRGB(230, 230, 240);
					icon.TextSize = 12;
					icon.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold);
					icon.ZIndex = label.ZIndex + 1;
					local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(1, 0); ic.Parent = icon;
					local function place()
						local tb = label.TextBounds.X;
						if label.TextXAlignment == Enum.TextXAlignment.Center then
							tb = label.AbsoluteSize.X / 2 + tb / 2;
						end;
						icon.Position = UDim2.new(0, math.min(tb + 6, math.max(0, label.AbsoluteSize.X - 2)), .5, 0);
					end;
					label.ClipsDescendants = false;
					icon.Parent = label;
					place();
					label:GetPropertyChangedSignal("TextBounds"):Connect(place);
					label:GetPropertyChangedSignal("AbsoluteSize"):Connect(place);
					icon.MouseEnter:Connect(function() icon.BackgroundColor3 = Color3.fromRGB(150, 110, 255); showTip(icon, text); end);
					icon.MouseLeave:Connect(function() icon.BackgroundColor3 = Color3.fromRGB(70, 70, 82); tip.Visible = false; end);
				end;
			end;
		end);
	end);
	-- F2: stop everything (farm, Play again, Auto Farm, scan-trip restarts). F2 again: back on as it was.
	pcall(function()
		-- (v5.39) the pause itself, also used when you arrive at Vesper's shop; false if it was already paused
		r.f2Pause = function()
			if r.f2Paused then return false; end;
			r.f2Paused = { farm = Q.on == true };
			r.autoStart = false;
			r.hubForScan = nil;
			farmSwitch(false);
			if farmToggle then pcall(farmToggle.Set, farmToggle, false); end;
			pcall(dQ);
			return true;
		end;
		if r.f2Conn then pcall(function() r.f2Conn:Disconnect(); end); end;
		r.f2Conn = game:GetService("UserInputService").InputBegan:Connect(function(io)
			if io.KeyCode == Enum.KeyCode.F8 then
				-- F8: capture record now (and the last 5 s + next 2 s of video with the recorder on)
				if d() - (r.f8At or -1e9) > 1.5 and r.plan and r.plan.requestCapture then
					r.f8At = d();
					pcall(r.plan.requestCapture, "manual", 0);
					local on = r.plan.captureOn and r.plan.captureOn();
					notify(on and "F8: saving the last 5 s and the next 2 s." or "F8: written to the dodge log (start the helper with the recorder to save video).", "Delve");
				end;
				return;
			end;
			if io.KeyCode ~= Enum.KeyCode.F2 then return; end;
			if d() - (r.f2At or -1e9) < .4 then return; end;
			r.f2At = d();
			if not r.f2Paused then
				r.f2Pause();
				notify("F2: everything paused (farm, walking, relic picks, Play again, stage start). Press F2 again to resume.", "Delve");
				if r.why then r.why("run", "F2 pressed: farming stopped (everything paused, you have control)"); end;
			else
				r.f2Paused = nil;
				farmSwitch(true);
				if farmToggle then pcall(farmToggle.Set, farmToggle, true); end;
				pcall(dQ);
				notify("F2: Auto Farm on.", "Delve");
				if r.why then r.why("run", "F2 pressed: farming resumed"); end;
			end;
		end);
	end);
	dQ = function()
		for _, setting in pairs(synced) do
			local value = current(setting.item);
			if value ~= setting.value and setting.widget and type(setting.widget.Set) == "function" then
				setting.value = value;
				pcall(setting.widget.Set, setting.widget, value);
			end;
		end;
	end;
	-- the game's pixel font for this window too (every label, button and text box, including ones added later)
	do
		local original = setmetatable({}, { __mode = "k" });
		local root, conn;
		local function findRoot()
			if root and root.Parent then return root; end;
			local okU, main = pcall(function() return window.UIElements and window.UIElements.Main; end);
			if okU and typeof(main) == "Instance" then
				root = main:FindFirstAncestorWhichIsA("LayerCollector") or main;
				return root;
			end;
			local places = {};
			if type(gethui) == "function" then pcall(function() places[#places + 1] = gethui(); end); end;
			pcall(function() places[#places + 1] = game:GetService("CoreGui"); end);
			places[#places + 1] = l:FindFirstChild("PlayerGui");
			for _, place in ipairs(places) do
				local okD, all = pcall(function() return place:GetDescendants(); end);
				for _, o in ipairs(okD and all or {}) do
					if o:IsA("TextLabel") and o.Text:find("Delve v", 1, true) and o.Text:find("Brain", 1, true) then
						root = o:FindFirstAncestorWhichIsA("LayerCollector");
						return root;
					end;
				end;
			end;
			return nil;
		end;
		local origSize = setmetatable({}, { __mode = "k" });
		local clean = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium);
		if (tonumber(CFG.dangerTimeV) or 0) < 1 then
			CFG.dangerTimeV = 1;
			if tonumber(CFG.dangerTime) == 10 then CFG.dangerTime = 15; task.defer(function() pcall(dQ); end); end;
		end;
		if (tonumber(CFG.replayFixV) or 0) < 1 then
			CFG.replayFixV = 1;
			if CFG.autoReplay == false then
				CFG.autoReplay = true;
				notify("Play again was switched off by an F2 bug: turned back on.", "Delve");
				task.defer(function() pcall(dQ); end);
			end;
		end;
		if (tonumber(CFG.uiFontV) or 0) < 2 then
			CFG.uiFontV, CFG.uiFont = 2, "Game font"; -- v5.25: the game's font (lighter) is the new default
			task.defer(function() pcall(dQ); end);
		end;
		local function fontMode()
			local m = tostring(CFG.uiFont or "Game font");
			if CFG.uiGameFont == false and CFG.uiFont == nil then m = "Clean"; end;
			return m;
		end;
		local function setOne(o, ff)
			if (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) and o.Name ~= "DelveInfoIcon" and not o:FindFirstAncestor("DelveInfoTip") then
				if original[o] == nil then original[o], origSize[o] = o.FontFace, o.TextSize; end;
				local mode = fontMode();
				local size0 = origSize[o] or o.TextSize;
				local isTitle = size0 >= 18 or tostring(o.Text):find("Delve v", 1, true) ~= nil or o.Text == "Open Delve";
				if mode == "Game font" and ff then
					-- titles keep their weight, everything else one step lighter so the pixel font isn't too heavy
					o.FontFace = Font.new(ff.Family, isTitle and Enum.FontWeight.Regular or Enum.FontWeight.Light, original[o].Style);
					o.TextSize = size0;
					o.TextTransparency = math.max(o.TextTransparency, isTitle and 0 or .06);
				elseif mode == "Mixed" and ff and isTitle then
					o.FontFace = Font.new(ff.Family, original[o].Weight, original[o].Style);
					o.TextSize = size0;
				else
					o.FontFace = Font.new(clean.Family, original[o].Weight == Enum.FontWeight.Bold and Enum.FontWeight.Bold or Enum.FontWeight.Medium, original[o].Style);
					o.TextSize = size0 + 1;
				end;
			end;
		end;
		r.applyGameFont = function()
			local g = findRoot();
			if not g then return; end;
			local ff = r.gameFont and r.gameFont() or nil;
			for _, o in ipairs(g:GetDescendants()) do pcall(setOne, o, ff); end;
			if conn then conn:Disconnect(); conn = nil; end;
			conn = g.DescendantAdded:Connect(function(o) task.defer(function() pcall(setOne, o, ff); end); end);
		end;
		task.delay(.5, function() pcall(r.applyGameFont); end);
		-- the game's HUD may not be fully loaded yet: try again once it is
		task.delay(15, function()
			if r.gameFontReady and not r.gameFontReady() then pcall(r.applyGameFont); end;
		end);
	end;
	if CFG.startClosed ~= false then
		task.delay(.3, function() pcall(function() window:Close(); end); end);
		notify("Loaded. Press Right Shift or Open Delve for settings.", "Delve");
	else
		window:Open();
	end;
end)();

inp.ensureSilent();
r.runStep = function()
		local ok, err = pcall(r.step);
		if not ok then
			pcall(Pl);
			pcall(NQ, 0, true);
			pcall(vQ);
			if MQ.phase == "down" then pcall(inp.mouseUp); end;
			MQ.phase = "idle";
			local now = d();
			if now - (r.errAt or -1000) > 5 then
				r.errAt = now;
				notify(tostring(err), "Delve error");
			end;
		end;
	end;
r.lastRender = d();
r.conn = q.RenderStepped:Connect(function()
		r.lastRender = d();
		r.runStep();
	end);
-- RenderStepped stops firing when the window is minimized or throttled in the background;
-- in background mode Heartbeat keeps the farm running whenever rendering has stalled
r.conn2 = q.Heartbeat:Connect(function()
		if d() - r.lastRender > .1 then
			if Q.background == true then
				r.runStep();
			else
				local now = d();
				pcall(brainTick, now);
				pcall(LQ, now);
			end;
		end;
	end);

r.connectAntiAfk();
if Q.autoStats ~= false then
	fQ(true);
end;
notify("Settings opened. Use Right Shift or Open Delve to reopen them.", "Delve v3");
end;

local ok, err = xpcall(start, function(message)
	return debug.traceback(tostring(message), 2);
end);
if not ok then
	local env = type(getgenv) == "function" and getgenv();
	local state = env and env.Delve;
	if state and state.stop then pcall(state.stop); end;
	notify(err, "Delve startup error");
end;