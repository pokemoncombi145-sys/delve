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
		autoLoadouts = true,
		bossSet = true,
		autoSell = true,
		sellEveryRuns = 5,
		autoRace = true,
		setRace1 = "Drakon",
		setRace2 = "Shura",
		setRace3 = "Drakon",
		stage = "Delve",
		stageOther = "",
		startClosed = true,
		niceToasts = true,
		uiGameFont = true,
		mechNotify = true,
		dangerTime = 10,
		forkPath = "Smart",
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
		webhookUrl = "",
		webhookDelay = 1.5,
		dropWebhook = true,
		rareDropOdds = 100000,
		attackRoll = "Auto",
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
env.Delve = { cfg = (G and G.cfg) or m };
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
		pcall(appendfile, "dodge_log.txt", string.format("%.2f %s\n", d(), m));
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
	local okRead, raw = pcall(function()
		if type(isfile) == "function" and not isfile(BRAIN_FILE) then return nil; end;
		return type(readfile) == "function" and readfile(BRAIN_FILE) or nil;
	end);
	if okRead and type(raw) == "string" and #raw > 2 then
		local okDec, data = pcall(Http.JSONDecode, Http, raw);
		if okDec and type(data) == "table" then
			for k, v in pairs(data) do
				if type(v) == type(brain[k]) or brain[k] == nil then
					brain[k] = v;
				end;
			end;
		end;
	end;
	for _, key in ipairs({ "relics", "cat", "sets", "runs", "mobReach", "windups", "codex", "pairs", "catMode", "threat", "mech", "attacks", "floorHaz" }) do
		if type(brain[key]) ~= "table" then brain[key] = {}; end;
	end;
	if type(brain.dodge) ~= "table" then brain.dodge = {}; end;
	if okRead and type(raw) == "string" and #raw > 2 then
		local migrating = (tonumber(brain.learnV) or 0) < 2 or (tonumber(brain.cleanV) or 0) < 3;
		if migrating or os.time() - (tonumber(brain.lastBackupAt) or 0) > 21600 then
			if r.brainBackup(migrating and "before-migration" or "auto", raw) then brain.lastBackupAt = os.time(); end;
		end;
	end;
	if (tonumber(brain.learnV) or 0) < 2 then
		-- v5.4 audit: every attack shared one bucket ("Hazards/Part") so its numbers sat at their caps,
		-- category weights were all at the 2.5 cap, the run baseline mixed abandoned 40 s runs with real
		-- ones, and a sword reach of 119 studs was learned from proc damage. Start those fresh.
		brain.learnV = 2;
		brain.attacks, brain.patterns, brain.swordHit, brain.runs = {}, {}, {}, {};
		brain.cat, brain.catMode = {}, {};
		brain.dodge.iframe = .35;
		brain.dodge.leadAdj = 0;
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
local brainState = { dirty = false, savedAt = -1e9 };
local function saveBrain(force)
	local now = d();
	if not force and (not brainState.dirty or now - brainState.savedAt < 15) then return; end;
	brainState.dirty, brainState.savedAt = false, now;
	if type(writefile) ~= "function" then return; end;
	if type(r.windups) == "table" then
		for name, dur in pairs(r.windups) do brain.windups[tostring(name)] = dur; end;
	end;
	pcall(function() writefile("DelveBrain.json", game:GetService("HttpService"):JSONEncode(brain)); end);
end;
local function markBrain() brainState.dirty = true; end;
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
		r.centerFarmTiles, r.centerFarmTile, r.centerFarmChest = nil, nil, nil;
		r.statsFound = false;
	end;
	local N = Q:FindFirstChild("Ground");
	local S = N and N:GetChildren();
	local w = S and ((S[1] and instanceId(S[1])));
	local tileCount = S and #S or 0;
	if w ~= s or tileCount ~= r.groundTileCount then
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
local function Ql(m, G)
	L, u = nil, nil;
	local e = {};
	-- rock search range (0 = unlimited) and minimum tier filter
	local rng = tonumber(Q.mineRange) or 0;
	local rngSq = rng > 0 and rng * rng or nil;
	local minTier = tonumber(Q.minTier) or 1;
	for pass = 1, 2 do
		local hasTarget = false;
		for rockName, r in pairs(D) do
			local Q = r.wy - m.Y;
			if (math.abs(Q) < 6 or (Q >= 6 and (Q < 40 and not r.settled))) and (pass == 2 or not rngSq or (r.wx - m.X) ^ 2 + (r.wz - m.Z) ^ 2 <= rngSq) then
				r.name = rockName;
				local wt = (r.skipUntil and r.skipUntil > G) and 0 or C(r.kind);
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
local function gl(m, G, r, Q)
	local e = math.max(r / 2, .6);
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
			local N2 = math.min(w * il, sl);
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
local dangerMem = { floorZones = {}, refreshAt = -1e9 };
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
	if not z.seenAt and kind ~= "mob" and kind ~= "floor" then
		z.seenAt = d();
		pcall(dangerMem.onAttack, z, z.seenAt);
	end;
end;
function dangerMem.holes(list)
	for _, z in ipairs(list) do z.hole, z.safeHole = nil, nil; end;
	for i, big in ipairs(list) do
		if big.circle and (big.h1 or 0) >= 7 and not big.noHole then
			for j, small in ipairs(list) do
				if j ~= i and small.circle and (small.h1 or 0) < big.h1 * .5 and (small.h1 or 0) >= 1.5
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
	local pt = type(brain.patterns[key]) == "table" and brain.patterns[key] or { n = 0, sigs = {}, trans = {} };
	pt.n = (tonumber(pt.n) or 0) + 1;
	local sg = type(pt.sigs[z.sig]) == "table" and pt.sigs[z.sig] or { n = 0 };
	sg.n = (tonumber(sg.n) or 0) + 1;
	if z.circle then
		sg.r = math.max(tonumber(sg.r) or 0, z.h1 or 0);
		sg.onBoss = boss.x and (z.x - boss.x) ^ 2 + (z.z - boss.z) ^ 2 < 9 or false;
	end;
	if z.hole then sg.hole = z.hole; end;
	pt.sigs[z.sig] = sg;
	local live = dangerMem.live;
	if live and live.boss == key and live.sig and now - live.at < 20 then
		pt.trans[live.sig] = type(pt.trans[live.sig]) == "table" and pt.trans[live.sig] or {};
		local tr = type(pt.trans[live.sig][z.sig]) == "table" and pt.trans[live.sig][z.sig] or { n = 0, gap = 0 };
		tr.n = (tonumber(tr.n) or 0) + 1;
		tr.gap = (tonumber(tr.gap) or 0) + (now - live.at);
		pt.trans[live.sig][z.sig] = tr;
	end;
	brain.patterns[key] = pt;
	-- predict: the attack that most often came next, and after how long
	local nextSig, bestN, gap = nil, 0, nil;
	for ns, tr in pairs(type(pt.trans[z.sig]) == "table" and pt.trans[z.sig] or {}) do
		if type(tr) == "table" and (tonumber(tr.n) or 0) > bestN then nextSig, bestN, gap = ns, tonumber(tr.n), tr.gap / tr.n; end;
	end;
	dangerMem.live = { boss = key, sig = z.sig, at = now };
	local totalN = 0;
	for _, tr in pairs(type(pt.trans[z.sig]) == "table" and pt.trans[z.sig] or {}) do
		if type(tr) == "table" then totalN = totalN + (tonumber(tr.n) or 0); end;
	end;
	local conf = totalN > 0 and bestN / totalN or 0;
	-- only act on a prediction seen 5+ times that comes true most of the time
	dangerMem.predict = (nextSig and bestN >= 5 and conf >= .6)
		and { boss = key, sig = nextSig, at = now + gap, info = pt.sigs[nextSig], conf = conf } or nil;
end;
local function Xl(m, G)
	Fl = {};
	local e = G or d();
	local N = {};
	local S = {};
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
		if not l and (not d and ((G.Transparency or 0)) < .95) then
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
			q(r);
		end;
	end;
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
local function SQ(m, G)
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
	local r = G and G:FindFirstChild("Verbs");
	return r and r:FindFirstChild("Again");
end;
local function vQ()
	if VQ.phase == "down" then
		inp.mouseUp();
	end;
	VQ.phase = "idle";
end;
local function nQ(m)
	if not Q.autoReplay then
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
		{ "luck", { "LUCK", "RARITY", "DROP" } },
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
		elseif cat == "luck" or cat == "econ" then
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
	r.prio = {
		life = { "SECOND CHANCE", "SECOND LIFE", "EXTRA LIFE", "REVIVE", "RESURRECT", "CHEAT DEATH", "FATAL", "INSTEAD OF DYING",
			"WOULD DIE", "ON DEATH", "WHEN YOU DIE", "LAST STAND", "UNDYING", "PHOENIX", "SAVE THE RUN", "SAVES THE RUN", "SURVIVE A" },
		power = { "WEAPON POWER", "MINE POWER", "MINING POWER", "SWING SPEED", "ATTACK SPEED", "MINE SPEED", "MINING SPEED",
			"STRIKE TWICE", "STRIKES TWICE", "SWINGS", "SWING" },
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
				if r.prio.has(uc, r.prio.power) then
					pm, tag = 1.6, "power/speed";
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
		markBrain();
		saveBrain(true);
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
		elseif not draft.fork and Q.relicExplore ~= false and #scored >= 2 and scored[2].score > -1e5 and scored[2].score >= scored[1].score - 25 then
			local rec2 = brain.relics[scored[2].key];
			local n2 = type(rec2) == "table" and (tonumber(rec2.n) or 0) or 0;
			if n2 < 3 and math.random() < .08 then
				choice = scored[2];
				draft.explored = true;
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
			else head = "pick " .. (choice and choice.name or "?") .. (draft.explored and " (exploring a close 2nd)" or " (highest score)"); end;
			r.why("relic", string.format("%s | %s", tostring(draft.room or "draft"), head));
			for _, ln in ipairs(lines) do r.why("relic", "   " .. ln); end;
		end;
		if Q.relicNotify ~= false and draft.fork and choice then
			notify(string.format("Fork: taking %s (%s)", choice.name, tostring(draft.forkWhy)), "Delve path");
		elseif Q.relicNotify ~= false and draft.trader then
			notify(choice and string.format("Trader: buying %s%s (%.0f)", choice.name,
				choice.price and (" for $" .. tostring(choice.price)) or "", choice.score) or "Trader: nothing worth buying, walking on by", "Delve trader");
		elseif Q.relicNotify ~= false and choice then
			notify(string.format("%s %s (%.0f)%s", Q.cardPick and "Picking" or "I'd pick", choice.name, choice.score,
				draft.explored and " [exploring a close 2nd]" or ""), "Delve relic");
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
		if not Q.cardPick or draft.picked then
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

	local function readHud(now)
		local ls = leaderRead();
		if ls.depth and ls.depth > run.depth then run.depth = ls.depth; end;
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
						if u == "ACTIVE BUFFS" then hud.buffs = o; end;
					end;
				end;
			end;
		end;
		if not ls.depth and hud.depth and hud.depth.Parent then
			local v = tonumber((trim(txt(hud.depth)):upper():gsub(",", "")):match("^DEPTH%s*(%d+)"));
			if v and v > run.depth then run.depth = v; end;
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
		run.bossHud = (hud.boss and hud.boss.Parent and shown(hud.boss)) and true or false;
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
	local function runFinish(now)
		if not run.active then return; end;
		run.active = false;
		local dur = now - run.startAt;
		readHud(now);
		local snap = {
			relics = run.relics, depth = run.depth, wave = run.wave, died = run.died, hits = run.hits,
			cash0 = run.cash0, cashExact0 = run.cashExact0, level0 = run.level0, isDelve = run.isDelve,
			combatT = run.combatT, mineT = run.mineT, rare = run.rareSeen, close = run.dangerCount,
			mechs = run.mechs, newMechs = run.newMechs,
		};
		if dur < 20 then return; end;
		task.spawn(function()
			-- wait for the results screen, then until its numbers stop counting up
			local t0 = d();
			local res, prev;
			while d() - t0 < 7 do
				res = readResults(d());
				if res and prev and res.sig == prev.sig then break; end;
				prev = res;
				task.wait(res and .4 or .25);
			end;
			res = res or prev;
			local ok, err = pcall(finalizeRun, snap, res, dur);
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
			and not (r.bossFight and tostring(e.name) ~= r.bossFight) then
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
			local dur = mob.owned and mob.phase == "windup" and mob.windupAt and mob.x and r.windups[mob.name]
				and not (r.bossFight and tostring(mob.name) ~= r.bossFight);
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
-- Auto = only when your race has a roll perk (read from the Races tab, e.g. Onibi Step: the roll
-- drops spirit flames that hunt mobs). The roll distance is learned from real rolls.
local function attackRoll(m)
	local G = sQ();
	-- measure how far a roll actually goes
	local rf = r.rollFrom;
	if rf and G and m - rf.t >= .45 then
		r.rollFrom = nil;
		local dist = math.sqrt((G.X - rf.x) ^ 2 + (G.Z - rf.z) ^ 2);
		if dist > 1 and dist < 40 then
			brain.rollDist = math.max(2, math.min(20, (tonumber(brain.rollDist) or dist) * .8 + dist * .2));
		end;
	end;
	-- boss fights: keep every roll for defence. Cancel a queued attack roll too (and its lean toward the target).
	if r.bossFight then
		if r.offRollAt then r.offRollAt, r.forceDir = nil, nil; f("attack roll cancelled: boss fight"); end;
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
		if pr0 and pr0.at - m < 1.2 and pr0.at - m > -.5 then danger = true; end;
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
	local mode = CFG.attackRoll or "Auto";
	if mode == "Off" or (mode == "Auto" and not r.rollPerk) or WQ ~= "combat" or not G or not inp.active() then return; end;
	if CFG.autoRoll == false or m - (r.lastRoll or -1e9) < yl + .35 or r.offRollAt then return; end;
	-- a boss attack is predicted soon: keep the roll for it
	local pr = dangerMem.predict;
	if pr and pr.at - m < 1.2 and pr.at - m > -.5 then return; end;
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
	if not best then return; end;
	local dist = math.sqrt(bd);
	local rd = tonumber(brain.rollDist) or 6;
	if dist > rd + 8 then return; end;
	-- without a roll perk ("Always"), only use it to close the gap
	if not r.rollPerk and dist < (tonumber(CFG.fightDist) or 8) + 2 then return; end;
	local dx, dz = best.x - G.X, best.z - G.Z;
	if dist < 2.5 then dx, dz = -dz, dx; end; -- already on top of it: roll around it, not through it
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
	r.offRollWhy = string.format("%s, %.1f st%s", tostring(best.name), dist, r.rollPerk and (", " .. r.rollPerk) or "");
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
				if ul(w.zone, G.X + Q * N, G.Z + e * N, Vl) and (inp.active() and m - ((r.lastRoll or -1000000000.0)) >= yl) then
					if eQ(m) then
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
	local fkey = tostring(l:GetAttribute("RunId")) .. "|" .. tostring(run.depth);
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
		if cx and (nav.blocked[cx * 4096 + cz] or 0) > now then hit = true; break; end;
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
		if (z.x - px) ^ 2 + (z.z - pz) ^ 2 < reach * reach then near[#near + 1] = z; end;
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
	local function danger(key)
		local v = dangerCache[key];
		if v == nil then
			v = 0;
			local t = map[key];
			for _, z in ipairs(near) do
				local depth = ul(z, t.wx, t.wz, margin);
				if depth then v = v + depth + 1; end;
			end;
			dangerCache[key] = v;
		end;
		return v;
	end;
	local edgeSafe = tonumber(CFG.edgeSafe) or 6;
	local cornerOn = CFG.cornerAvoid ~= false;
	local dist, prev, heap = { [startKey] = 0 }, {}, {};
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
			local dg = danger(key);
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
							local cost = c + step + danger(k2) * cell * 3 + (rockCells[k2] and cell * 3 or 0);
							if cost < (dist[k2] or math.huge) then
								dist[k2], prev[k2] = cost, key;
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
	return { x = wp.wx, z = wp.wz, gx = gt.wx, gz = gt.wz, t = now, safe = best ~= nil, len = #path };
end;
local function Nh(m, G, r)
	if Qh and (r - Qh.t < .25 and not eh(Fl, Qh.gx or Qh.x, Qh.gz or Qh.z)) then
		if not Qh.gx or (Qh.x - m) ^ 2 + (Qh.z - G) ^ 2 > (nav.cell * .6) ^ 2 then
			return Qh;
		end;
	end;
	local esc = navEscape(m, G, Fl, r);
	if esc then
		Qh = esc;
		return Qh;
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
			r.dodging = true;
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
	bossStudy.safeCache[mob.addr] = { t = now, ok = ok, why = why };
	return ok, why;
end;
function bossStudy.bias(mob)
	local cur = bossStudy.cur;
	if not cur or mob.addr == cur.addr then return 0; end;
	local b = bossStudy.biasRaw(mob, cur);
	if b > 0 and (tonumber(mob.d) or 0) > 12 then
		local ok, why = bossStudy.pathSafe(mob);
		if not ok then
			-- not now: stay on safe ground (fight what's near) and go when the way is clear
			local key = tostring(mob.addr) .. tostring(why);
			if r.why and bossStudy.lastUnsafe ~= key then
				bossStudy.lastUnsafe = key;
				r.why("boss", string.format("%s is %.0f st away but %s: holding safe ground for now", tostring(mob.name), tonumber(mob.d) or 0, why));
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
	if pr == "Always fight" or not CFG.mine then
		r.fightWhy = "always";
		return true;
	end;
	local stage = (tostring(run.stage or "") .. " " .. tostring(run.objective or "")):upper();
	local boss = run.bossHud or stage:find("BOSS") ~= nil or stage:find("GUARDIAN") ~= nil;
	local minMax, maxMax = math.huge, 0;
	for _, mob in ipairs(list) do
		if mob.boss then boss = true; end;
		local mx = tonumber(mob.max) or 0;
		if mx > 0 then minMax, maxMax = math.min(minMax, mx), math.max(maxMax, mx); end;
	end;
	if #list >= 2 and maxMax > 0 and maxMax >= minMax * 5 then boss = true; end;
	run.bossNow = boss;
	if boss then r.fightWhy = "boss"; return true; end;
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
		if closest <= tooClose then
			r.fightWhy = string.format("too close (%.1f st): clear it, then mine", closest);
			return true;
		end;
	end;
	-- delve floor timer in the danger zone: ignore mobs, every second goes to ores / getting down
	local tl = tonumber(run.timeLeft);
	if tl and tl <= (tonumber(CFG.dangerTime) or 10) and now - (tonumber(run.timeAt) or -1e9) < 2 then
		r.fightWhy = nil;
		r.danger = true;
		return false;
	end;
	r.danger = false;
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
local function lh(m)
	local G = sQ();
	if not G then
		WQ, L, u, xQ = "idle", nil, nil, nil;
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
		});
		while #r.box > 20 do table.remove(r.box, 1); end;
	end;
	-- the "move closer" adjustment wears off when not fighting
	if WQ ~= "combat" and (tonumber(r.orbitShrink) or 0) > 0 then
		r.orbitShrink = math.max(0, r.orbitShrink - .01);
	end;
	r.mobCount = #S;
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
		if r.keepTarget == Q.addr then
			e = e - 4;
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
			or (r.danger and string.format("timer %ss: ignoring mobs", tostring(run.timeLeft)) or (#S > 0 and "mobs not a threat, ores first" or "no mobs"));
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
	if not e or iQ() then
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
	if WQ == "combat" and ((Q.combat and ((Q.chase and w)))) then
		qh(G, w, S, m);
		return;
	end;
	if Q.dodge and (#Fl > 0 and eh(Fl, G.X, G.Z)) then
		local Q = Nh(G.X, G.Z, m);
		if Q then
			if not r.dodging then
				f(string.format("escape to open ground %.1f studs away, zones=%d", math.sqrt(((Q.x - G.X)) ^ 2 + ((Q.z - G.Z)) ^ 2), #Fl));
			end;
			r.dodging = true;
			SQ(Q.x - G.X, Q.z - G.Z);
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
			r.dodging = true;
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
			if Q * Q + e * e > 1 then
				r.chestWalk = true;
				local okS, sx, sz = pcall(r.steerDir, G, m.x, m.z);
				if okS and sx then SQ(sx, sz); else SQ(Q, e); end;
				return;
			end;
		end;
	end;
	r.chestWalk = false;
	if WQ == "mine" and ((Q.walk and u)) then
		local okS, sx, sz = pcall(r.steerDir, G, u.X, u.Z);
		if okS and sx then SQ(sx, sz); else SQ(u.X - G.X, u.Z - G.Z); end;
		return;
	end;
	SQ(nil);
end;
-- ===================================================================================
-- DISCORD WEBHOOK: "Run Complete" post when a run ends
--   With delve_webhook_helper.ps1 running on your PC, the post includes a screenshot of your
--   screen (Roblox can't capture the screen itself, so the script drops a job file in the
--   executor's workspace\DelveWebhook folder and the helper screenshots + uploads it).
--   Without the helper it still posts the run stats as text.
-- ===================================================================================
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
		local job = { url = url, payload = { username = "Delve Brain", embeds = { embed } } };
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
		Body = Hs:JSONEncode({ username = "Delve Brain", embeds = { embed } }),
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
r.postEmbed = function(embed)
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
				Hs:JSONEncode({ url = url, payload = { username = "Delve Brain", embeds = { embed } } }));
		end);
		if ok then return true; end;
		embed.image = nil;
	end;
	local req = (type(request) == "function" and request) or (type(http_request) == "function" and http_request)
		or (type(syn) == "table" and syn.request) or (type(http) == "table" and http.request);
	if not req then return false; end;
	local ok, res = pcall(req, {
		Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" },
		Body = Hs:JSONEncode({ username = "Delve Brain", embeds = { embed } }),
	});
	return ok and type(res) == "table" and (tonumber(res.StatusCode) or 999) < 300;
end;
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
	local TIERS = { COMMON = 1, UNCOMMON = 2, RARE = 3, EPIC = 4, LEGENDARY = 5, MYTHIC = 6, EXOTIC = 6, DIVINE = 7, SECRET = 7 };
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
		p.race = you["RACE"] or p.race;
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
	local function scanRace()
		local function perksLabel()
			local pg = pgui();
			for _, o in ipairs(pg and pg:GetDescendants() or {}) do
				if isText(o) and shown(o) and trim(txt(o)):upper() == "RACE PERKS" then return o; end;
			end;
			return nil;
		end;
		if not perksLabel() then
			local tab = tabLabels("RACES")[1];
			if not tab then return nil; end;
			clickVerified(tab, function() return perksLabel() ~= nil; end, "RACES tab");
		end;
		local pl = perksLabel();
		if not pl then return nil; end;
		local win = sizedAncestor(pl, 300, 300) or pl.Parent;
		if not r.raceDumped then r.raceDumped = true; pcall(dump, win, "races"); end;
		local race = { perks = {}, at = os.time() };
		for _, o in ipairs(win:GetDescendants()) do
			if isText(o) and shown(o) and trim(txt(o)):upper():find("WORN", 1, true) then
				for _, s2 in ipairs(o.Parent:GetChildren()) do
					if isText(s2) and s2 ~= o and trim(txt(s2)):match("%a") then race.name = trim(txt(s2)); break; end;
				end;
			end;
		end;
		local list;
		for _, sf in ipairs(scrollers(win)) do
			if sf.AbsolutePosition.Y >= pl.AbsolutePosition.Y - 5 then list = sf; break; end;
		end;
		local seen = {};
		local function add(nm, desc)
			nm = trim(nm or "");
			if nm ~= "" and desc ~= "" and not seen[nm:upper()] then
				seen[nm:upper()] = true;
				race.perks[#race.perks + 1] = { name = nm, desc = desc };
			end;
		end;
		local function readPerks()
			local root = list or win;
			local loose = {};
			for _, row in ipairs(root:GetChildren()) do
				if row:IsA("GuiObject") and row.Visible then
					if isText(row) then
						if trim(txt(row)) ~= "" then loose[#loose + 1] = row; end;
					else
						local ls = {};
						for _, o in ipairs(row:GetDescendants()) do
							if isText(o) and o.Visible and trim(txt(o)) ~= "" then ls[#ls + 1] = o; end;
						end;
						table.sort(ls, function(x, y) return x.AbsolutePosition.Y < y.AbsolutePosition.Y; end);
						if #ls >= 2 then
							local desc = {};
							for k = 2, #ls do desc[#desc + 1] = trim(txt(ls[k])); end;
							add(txt(ls[1]), table.concat(desc, " "));
						end;
					end;
				end;
			end;
			-- name and description as separate labels straight in the list
			table.sort(loose, function(x, y) return x.AbsolutePosition.Y < y.AbsolutePosition.Y; end);
			for k = 1, #loose - 1, 2 do add(txt(loose[k]), trim(txt(loose[k + 1]))); end;
		end;
		if list then scrollThrough(list, readPerks, .25); else readPerks(); end;
		race.rollPerk = nil;
		for _, pk in ipairs(race.perks) do
			if pk.desc:upper():find("ROLL") then race.rollPerk = pk.name; end;
		end;
		brain.race = race;
		r.rollPerk = race.rollPerk;
		return #race.perks;
	end;
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
			local okR, nPerks = pcall(scanRace);
			if okR and nPerks then
				summary.perks = nPerks;
			else
				summary.failed = (summary.failed or "") .. " Races";
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
				color = isNew and 16766720 or (tierRank >= 5 and 15844367 or 10181046),
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
	-- ---------------------------------------------------------------- LOADOUTS (T menu > Equipment > Equipped items 1 / 2 / 3)
	--   1 = mining set, 2 = damage set (boss fights / hard mobs), 3 = sell set.
	--   Every few runs, between runs: set 3 > Backpack > Sell items > Ores > Select all > Accept, then back to set 1.
	--   Races (hub only): set 1 and 3 wear Drakon, set 2 wears Shura (editable). Never touches reroll or Robux buttons.
	local lo = { cur = nil, switchAt = -1e9, hubDone = false, hitsAt = 0, hitsT = 0, hardUntil = 0, raceChecked = false };
	lo.ROLL = { SHURA = "Onibi Step", DRAKON = "Flame Dash", OLYMPIAN = "Radiant Dash" };
	do
		local function P(n, d2) return { name = n, desc = d2 }; end;
		local seed = {
			ANDROS = { done = true, P("QUICK STUDY", "+10% XP from everything you mine."), P("WELL ROUNDED", "+5% Mine Speed and +5% Walk Speed.") },
			OLYMPIAN = { done = true, P("RADIANT DASH", "A longer, faster roll that lands in a burst of sunlight."), P("BLESSED", "+30% Luck, +15% Quantity and +15% XP."), P("SWIFT", "+15% Walk Speed."), P("SHINY", "+5% Luck, XP, Mine Power and Weapon Power.") },
			DACTYL = { done = true, P("STOUT", "14% shorter, built for tunnels."), P("DEEP DELVER", "+12% Mine Power and +10% Quantity.") },
			TITAN = { done = true, P("BRUTE FORCE", "+25% Weapon Power."), P("THICK HIDE", "+25 Max Health."), P("HEAVY SWING", "+8% Mine Power.") },
			DRYAD = { done = true, P("FOREST FORTUNE", "+10% Luck on every drop."), P("LIGHT STEP", "+10% Walk Speed."), P("LONG REACH", "+0.05 Mining Range.") },
			HYDRA = { done = true, P("REGROWTH", "Go 3s without a hit and heal 5% health a second."), P("SNAPPING HEADS", "Your heads bite the nearest mob every few seconds."), P("WIDE COIL", "+25% Mining Circle."), P("VENOM BITE", "+20% Weapon Power and +40 Max Health."), P("OLD BLOOD", "+20% Rune Find."), P("MANY EYES", "+20% Luck and +10% Quantity.") },
			-- partial (read the rest the first time they're worn)
			SHURA = { P("ONIBI STEP II", "Your roll drops 3 spirit flames that hunt the nearest mobs and burst."), P("WRATH", "Kills stack +2% Weapon Power, up to 10, while the fight lasts."), P("WAR GOD", "+50% Luck, +20% Quantity and +20% XP."), P("CROWNED", "+30% Mine Power and +30% Weapon Power."), P("HARDENED", "Take 10% less damage.") },
			DRAKON = { P("FLAME DASH", "Your roll scorches every mob it passes and leaves the ground burning."), P("DRAGON MIGHT", "+25% Mine Power and +25% Weapon Power.") },
		};
		brain.racePerks = type(brain.racePerks) == "table" and brain.racePerks or {};
		brain.racePerksDone = type(brain.racePerksDone) == "table" and brain.racePerksDone or {};
		for name, v in pairs(seed) do
			if brain.racePerks[name] == nil then
				local list = {};
				for _, pk in ipairs(v) do list[#list + 1] = pk; end;
				brain.racePerks[name] = list;
				if v.done then brain.racePerksDone[name] = true; end;
			end;
		end;
	end;
	function lo.raceOf(n)
		local v = trim(tostring(CFG["setRace" .. n] or "")):upper();
		if v == "" or v:find("DON'T", 1, true) then return nil; end;
		return v;
	end;
	-- the race worn with the active set decides whether attack rolls have a roll perk to use
	function lo.applyRace(n)
		local race = lo.raceOf(n);
		if not race then return; end;
		local perk = lo.ROLL[race];
		local perks = type(brain.racePerks) == "table" and brain.racePerks[race];
		if type(perks) == "table" then
			perk = nil;
			for _, pk in ipairs(perks) do
				if tostring(pk.desc):upper():find("ROLL") then perk = pk.name; end;
			end;
		end;
		r.rollPerk = perk;
	end;
	local LO_BAD = { "REROLL", "BUY", "R$", "ROBUX", "FAST ROLL", "SPIN", "GIFT" };
	function lo.unsafe(obj)
		local b = obj:IsA("GuiButton") and obj or obj:FindFirstAncestorWhichIsA("GuiButton") or obj;
		local list = b:GetDescendants();
		list[#list + 1] = b;
		for _, o in ipairs(list) do
			if isText(o) then
				local t = txt(o):upper();
				for _, w in ipairs(LO_BAD) do
					if t:find(w, 1, true) then return true; end;
				end;
			end;
		end;
		return false;
	end;
	function lo.click(obj, check, label, abort)
		if not obj or lo.unsafe(obj) then
			if r.why then r.why("gear", "refused to click " .. tostring(label) .. " (looks like a reroll/purchase button)"); end;
			return false;
		end;
		return clickVerified(obj, check, label, abort);
	end;
	-- "$321M" / "$4.28K" / "$1,733,355,148" -> number
	function lo.money(u)
		local num, suf = tostring(u):upper():match("%$([%d%.,]+)%s*(%a?)");
		if not num then return 0; end;
		local v = tonumber((num:gsub(",", ""))) or 0;
		local mult = ({ K = 1e3, M = 1e6, B = 1e9, T = 1e12 })[suf] or 1;
		return v * mult;
	end;
	function lo.screen() local pg = pgui(); return pg and pg:FindFirstChild("InventoryScreen"); end;
	function lo.btn(n) local sc = lo.screen(); return sc and sc:FindFirstChild("Loadout" .. n, true); end;
	-- which set is active: the green one
	function lo.greenOf(b)
		local best = -1;
		for _, o in ipairs(b:GetDescendants()) do
			if o:IsA("GuiObject") and o.Visible then
				local okC, c = pcall(function() return o.BackgroundColor3; end);
				if okC and c and o.BackgroundTransparency < .9 then best = math.max(best, c.G - math.max(c.R, c.B)); end;
			end;
		end;
		local okI, ic = pcall(function() return b.ImageColor3; end);
		if okI and ic then best = math.max(best, ic.G - math.max(ic.R, ic.B)); end;
		return best;
	end;
	function lo.current()
		local best, bv = nil, .12;
		for n = 1, 3 do
			local b = lo.btn(n);
			if b and shown(b) then
				local g = lo.greenOf(b);
				if g > bv then best, bv = n, g; end;
			end;
		end;
		return best;
	end;
	function lo.openMenu()
		if menuOpen() then return true, false; end;
		if not pressT() then return false, false; end;
		return waitFor(menuOpen, 2) ~= nil, true;
	end;
	function lo.closeMenu(opened)
		if opened and menuOpen() then
			pressT();
			task.wait(.4);
			if menuOpen() then pressT(); end;
		end;
	end;
	-- switch to set n (verified by the green highlight)
	-- is it safe to open the menu right now? (no attack coming, not near a hazard, no enemy in striking distance)
	function lo.safeNow()
		if next(Cl) then return false, "an attack is coming"; end;
		local G = sQ();
		if not G then return false, "no character"; end;
		for _, z in ipairs(Fl) do
			if ul(z, G.X, G.Z, 3) then return false, "standing at a hazard"; end;
		end;
		for _, mob in ipairs(ol()) do
			local reach = math.max(10, (tonumber(brain.mobReach[tostring(mob.name)]) or 0) + 4);
			if (mob.x - G.X) ^ 2 + (mob.z - G.Z) ^ 2 < reach * reach then
				return false, tostring(mob.name) .. " within striking distance";
			end;
		end;
		return true, nil;
	end;
	lo.stats = { attempted = 0, completed = 0, skipped = 0, failed = 0 };
	r.gearStats = lo.stats;
	function lo.note(kind, n, reason, detail, secs)
		lo.stats[kind] = (lo.stats[kind] or 0) + 1;
		if r.why then
			r.why("gear", string.format("set %d %s (%s)%s%s", n, kind, tostring(reason),
				detail and (": " .. tostring(detail)) or "", secs and string.format(" in %.1f s", secs) or ""));
		end;
	end;
	-- last resort if T didn't close the menu: the menu's own background "dismiss" button
	function lo.forceClose()
		local sc = lo.screen();
		local dis = sc and sc:FindFirstChild("Dismiss", true);
		if dis and r.fireAll then pcall(r.fireAll, dis); end;
		task.wait(.3);
		if menuOpen() then pressT(); end;
	end;
	-- switch to set n (verified by the green highlight). guarded = in a run: re-checks safety before clicking.
	-- Bounded to 8 s; always leaves the menu closed if it opened it; on failure the active set is "unknown"
	-- and it backs off before trying again.
	function lo.switch(n, reason, guarded)
		if r.loadoutBusy then return false; end;
		if guarded then
			local safe, why = lo.safeNow();
			if not safe then lo.note("skipped", n, reason, why); return false; end;
		end;
		r.loadoutBusy = true;
		local t0 = d();
		local deadline = t0 + 8;
		lo.note("attempted", n, reason);
		local openedHere = false;
		local ok, res, failWhy = pcall(function()
			local okM, opened = lo.openMenu();
			openedHere = opened;
			if not okM then return false, "menu didn't open"; end;
			task.wait(.3);
			local stopIf = function() return d() > deadline or (guarded and not lo.safeNow()); end;
			local win = openTab("EQUIPMENT", stopIf);
			if not win then
				return false, (d() > deadline and "timed out opening Equipment") or (guarded and not lo.safeNow() and "became unsafe opening Equipment") or "Equipment tab didn't open";
			end;
			task.wait(.3);
			if lo.current() ~= n then
				if guarded then
					local safe, why = lo.safeNow();
					if not safe then return false, "became unsafe: " .. tostring(why); end;
				end;
				if d() > deadline then return false, "timed out"; end;
				local btn = lo.btn(n);
				if not btn then return false, "set button not found"; end;
				local cd = btn:FindFirstChild("Cooldown");
				if cd and cd.Visible then
					if guarded then return false, "set swap on cooldown"; end;
					waitFor(function() return not cd.Visible; end, math.max(0, deadline - d()));
				end;
				-- every click attempt re-checks the deadline and (in a run) safety; it stops as soon as either fails
				local _, how = lo.click(btn, function() return lo.current() == n; end, "set " .. n, function()
					return d() > deadline or (guarded and not lo.safeNow());
				end);
				if how == "aborted" then
					return false, d() > deadline and "timed out while clicking" or "became unsafe while clicking";
				end;
			end;
			local now2 = lo.current();
			lo.cur = now2; -- nil = can't tell which set is on
			if now2 then pcall(lo.applyRace, now2); end;
			if now2 ~= n then
				local gs = {};
				for k = 1, 3 do local bk = lo.btn(k); gs[#gs + 1] = bk and string.format("%d:%.2f", k, lo.greenOf(bk)) or (k .. ":?"); end;
				return false, (now2 and ("set " .. now2 .. " is still on") or "can't tell which set is on") .. "; greenness " .. table.concat(gs, " ");
			end;
			return true;
		end);
		-- always put the menu back the way it was
		if openedHere and menuOpen() then
			lo.closeMenu(true);
			if menuOpen() then lo.forceClose(); end;
		end;
		r.loadoutBusy = false;
		lo.switchAt = d();
		local secs = d() - t0;
		if ok and res then
			lo.failStreak, lo.failUntil = 0, 0;
			lo.note("completed", n, reason, nil, secs);
			return true;
		end;
		lo.failStreak = (lo.failStreak or 0) + 1;
		lo.failUntil = d() + math.min(120, 30 * lo.failStreak);
		lo.note("failed", n, reason, ok and failWhy or ("error: " .. tostring(res)), secs);
		if not ok then lo.cur = nil; end;
		return false;
	end;
	-- race for a set (hub only): Races tab > slot > race page > WEAR on that race's row > CLOSE
	function lo.raceRow(name)
		local pg = pgui();
		for _, o in ipairs(pg and pg:GetDescendants() or {}) do
			local u0 = isText(o) and shown(o) and trim(txt(o)):upper() or "";
			if u0 == name or u0 == "SHINY " .. name then
				local row = o.Parent;
				for _ = 1, 2 do
					if row then
						for _, s2 in ipairs(row:GetDescendants()) do
							local u = isText(s2) and trim(txt(s2)):upper() or "";
							if u == "WEAR" or u:find("WORN", 1, true) then return row; end;
						end;
						row = row.Parent;
					end;
				end;
			end;
		end;
		return nil;
	end;
	function lo.rowWorn(row)
		for _, s2 in ipairs(row and row:GetDescendants() or {}) do
			if isText(s2) and shown(s2) and trim(txt(s2)):upper():find("WORN", 1, true) then return true; end;
		end;
		return false;
	end;
	function lo.racePageOpen()
		local pg = pgui();
		for _, o in ipairs(pg and pg:GetDescendants() or {}) do
			if isText(o) and shown(o) and trim(txt(o)):upper() == "RACE SLOTS" then return o; end;
		end;
		return nil;
	end;
	function lo.setRace(name, reason)
		name = trim(tostring(name or "")):upper();
		if name == "" or run.active or inRun() or r.loadoutBusy then return false; end;
		r.loadoutBusy, r.scanning = true, true;
		local ok, res = pcall(function()
			if not lo.racePageOpen() then
				local okM = lo.openMenu();
				if not okM then return false; end;
				task.wait(.3);
				local tab = tabLabels("RACES")[1];
				if not tab then return false; end;
				lo.click(tab, function() return findWindow("RACES"); end, "Races tab");
				local rw = waitFor(function() return findWindow("RACES"); end, 2);
				if not rw then return false; end;
				task.wait(.4);
				-- any race slot card opens the race page
				local slot;
				for _, o in ipairs(rw:GetDescendants()) do
					if isText(o) and shown(o) and trim(txt(o)):upper() == name then slot = o; break; end;
				end;
				if not slot then
					for _, o in ipairs(rw:GetDescendants()) do
						if isText(o) and shown(o) and trim(txt(o)):upper():match("^SLOT %d") then slot = o; break; end;
					end;
				end;
				if not slot then return false; end;
				lo.click(slot, function() return lo.racePageOpen() ~= nil; end, "race slot");
				if not waitFor(function() return lo.racePageOpen(); end, 3) then return false; end;
			end;
			task.wait(.5);
			if not r.racePageDumped then
				r.racePageDumped = true;
				local rp = lo.racePageOpen();
				pcall(dump, rp and (sizedAncestor(rp, 300, 300) or rp.Parent), "racepage");
			end;
			local row = lo.raceRow(name);
			if not row then
				if r.why then r.why("gear", "race " .. name .. " isn't in your race slots"); end;
				return false;
			end;
			if not lo.rowWorn(row) then
				local wear;
				for _, s2 in ipairs(row:GetDescendants()) do
					if isText(s2) and trim(txt(s2)):upper() == "WEAR" then wear = s2; break; end;
				end;
				lo.click(wear or row, function() return lo.rowWorn(lo.raceRow(name)); end, "wear " .. name);
				task.wait(.6);
			end;
			local worn = lo.rowWorn(lo.raceRow(name));
			-- capture this race's perks (only shown for the race you wear), once: races already captured are skipped
			brain.racePerks = type(brain.racePerks) == "table" and brain.racePerks or {};
			brain.racePerksDone = type(brain.racePerksDone) == "table" and brain.racePerksDone or {};
			if worn and not brain.racePerksDone[name] then
				local okP, nP = pcall(scanRace);
				if okP and (nP or 0) > 0 and type(brain.race) == "table" then
					brain.racePerks[name] = brain.race.perks;
					brain.racePerksDone[name] = true;
					brain.race.name = name;
					markBrain();
					if r.why then r.why("gear", string.format("captured %d perks for %s", nP, name)); end;
				end;
			elseif worn and r.why then
				r.why("gear", name .. " perks already known: skipped reading them");
			end;
			if r.why then r.why("gear", string.format("race %s %s (%s)", name, worn and "worn" or "not confirmed", tostring(reason))); end;
			-- leave the race page
			local pg = pgui();
			for _, o in ipairs(pg and pg:GetDescendants() or {}) do
				if isText(o) and shown(o) and trim(txt(o)):upper() == "CLOSE" then
					lo.click(o, function() return lo.racePageOpen() == nil; end, "close race page");
					break;
				end;
			end;
			task.wait(.4);
			if menuOpen() then lo.closeMenu(true); end;
			return worn;
		end);
		r.loadoutBusy, r.scanning = false, false;
		return ok and res;
	end;
	-- sell ores with set 3, then back to set 1
	function lo.sell(reason)
		if run.active or inRun() or r.loadoutBusy then return false; end;
		local sellT0 = r.scanStart("Selling ores (set 3)");
		local switched = lo.switch(3, "selling");
		r.loadoutBusy, r.scanning = true, true;
		local gained;
		local ok, err = pcall(function()
			-- only sell when set 3 was confirmed green by the switch
			if not switched then
				if r.why then r.why("gear", "sell skipped: set 3 isn't confirmed green"); end;
				return;
			end;
			local okM, opened = lo.openMenu();
			if not okM then return; end;
			task.wait(.3);
			-- Backpack (ores), never the Equipment tab's sell
			local bp = findWindow("PERSONAL BACKPACK") or findWindow("SELLING");
			if not bp then
				local tab = tabLabels("BACKPACK")[1];
				if tab then lo.click(tab, function() return findWindow("PERSONAL BACKPACK"); end, "Backpack tab"); end;
				bp = waitFor(function() return findWindow("PERSONAL BACKPACK"); end, 2);
			end;
			if not bp then lo.closeMenu(opened); return; end;
			if not findWindow("SELLING") then
				local sb;
				for _, o in ipairs(bp:GetDescendants()) do
					if isText(o) and shown(o) and trim(txt(o)):upper() == "SELL ITEMS" then sb = o; break; end;
				end;
				lo.click(sb, function() return findWindow("SELLING"); end, "Sell items");
			end;
			local sw = waitFor(function() return findWindow("SELLING"); end, 2);
			if not sw then lo.closeMenu(opened); return; end;
			-- make sure this is the ore sell screen and the Ores category is selected
			local oresTab;
			for _, o in ipairs(sw:GetDescendants()) do
				if isText(o) and shown(o) and trim(txt(o)):upper() == "ORES" then oresTab = o; break; end;
			end;
			if not oresTab then
				if r.why then r.why("gear", "sell stopped: this isn't the ore sell screen"); end;
				lo.closeMenu(opened);
				return;
			end;
			lo.click(oresTab, function() return true; end, "Ores");
			task.wait(.4);
			local function total()
				for _, o in ipairs(sw:GetDescendants()) do
					if isText(o) and shown(o) then
						local u = trim(txt(o)):upper();
						if u:find("^TOTAL") then return lo.money(u), u; end;
					end;
				end;
				return 0, nil;
			end;
			local sa;
			for _, o in ipairs(sw:GetDescendants()) do
				if isText(o) and shown(o) and trim(txt(o)):upper() == "SELECT ALL" then sa = o; break; end;
			end;
			lo.click(sa, function() return total() > 0; end, "Select all");
			local tv, tt = total();
			if tv <= 0 then
				if r.why then r.why("gear", "nothing to sell"); end;
				lo.closeMenu(opened);
				return;
			end;
			local acc;
			for _, o in ipairs(sw:GetDescendants()) do
				if isText(o) and shown(o) and trim(txt(o)):upper() == "ACCEPT" then acc = o; break; end;
			end;
			local function soldText()
				local sc = lo.screen();
				for _, o in ipairs(sc and sc:GetDescendants() or {}) do
					if isText(o) and shown(o) then
						local u = trim(txt(o));
						if u:match("^%+%$[%d,]+") then return u; end;
					end;
				end;
				return nil;
			end;
			lo.click(acc, function() return soldText() ~= nil or total() == 0; end, "Accept");
			gained = waitFor(soldText, 3) or tt;
			lo.closeMenu(opened);
		end);
		-- never leave the menu open after selling (also after an error)
		if menuOpen() then lo.closeMenu(true); if menuOpen() then lo.forceClose(); end; end;
		r.loadoutBusy, r.scanning = false, false;
		brain.runsAtSell = tonumber(brain.runCount) or 0;
		markBrain();
		if gained then
			notify("Sold ores: " .. tostring(gained), "Delve gear");
			if r.why then r.why("gear", "sold ores " .. tostring(gained) .. " (" .. tostring(reason) .. ")"); end;
			brain.sales = type(brain.sales) == "table" and brain.sales or {};
			table.insert(brain.sales, { t = os.time(), amount = tostring(gained) });
			while #brain.sales > 50 do table.remove(brain.sales, 1); end;
		elseif not ok then
			notify("Sell error: " .. tostring(err), "Delve gear");
		end;
		lo.switch(1, "back to mining after selling");
		r.scanEnd("Selling ores", sellT0, gained and ("Sold " .. tostring(gained) .. ".") or "Nothing sold.");
		return gained ~= nil;
	end;
	-- when to use which set
	function lo.tick(now)
		if CFG.autoLoadouts == false or r.loadoutBusy or busy or launch.busy then return; end;
		if relicAPI.hasDraft() then return; end;
		if run.active then
			lo.hubDone = false;
			-- damage set on boss fights and when the mobs on this floor are hurting you; mining set otherwise
			if now - lo.hitsT > 30 then lo.hitsAt, lo.hitsT = run.hits, now; end;
			if run.hits - lo.hitsAt >= 4 then lo.hardUntil = now + 60; lo.hitsAt, lo.hitsT = run.hits, now; end;
			-- floors where a boss showed up before: put set 2 on at the start of that floor (the safest moment)
			if run.depth ~= lo.floorDepth then lo.floorDepth, lo.floorAt = run.depth, now; end;
			brain.bossFloors = type(brain.bossFloors) == "table" and brain.bossFloors or {};
			if r.bossFight and (run.depth or 0) > 0 then brain.bossFloors[tostring(run.depth)] = r.bossFight; end;
			local bossFloor = brain.bossFloors[tostring(run.depth)];
			local boss = r.bossFight or run.bossNow or bossFloor;
			local want = (boss and CFG.bossSet ~= false) and 2 or (now < lo.hardUntil and 2 or 1);
			local why = boss and (r.bossFight and "boss fight" or "boss floor") or (now < lo.hardUntil and "mobs hitting hard" or "mining");
			if want ~= lo.cur and now - lo.switchAt > 20 and now > (lo.failUntil or 0) then
				local safe, unsafeWhy = lo.safeNow();
				if safe then
					lo.switchAt = now;
					task.spawn(lo.switch, want, why .. (now - (lo.floorAt or now) < 8 and ", floor start" or ""), true);
				elseif lo.skipKey ~= want .. unsafeWhy or now - (lo.skipAt or 0) > 10 then
					-- not safe: don't force it; note it (at most every 10 s) and try again when it is
					lo.skipKey, lo.skipAt = want .. unsafeWhy, now;
					lo.note("skipped", want, why, unsafeWhy);
				end;
			end;
			return;
		end;
		if inRun() or now - lo.switchAt < 5 then return; end;
		-- between runs: sell when due, then make sure set 1 + its race are on
		local every = math.max(1, math.floor(tonumber(CFG.sellEveryRuns) or 5));
		local runsSince = (tonumber(brain.runCount) or 0) - (tonumber(brain.runsAtSell) or 0);
		if not lo.raceChecked then
			lo.raceChecked = "running";
			lo.switchAt = now;
			task.spawn(function()
				if CFG.autoRace ~= false then
					-- once per load: each set wears the race picked for it (the game keeps the race with the set)
					local t0 = r.scanStart("Race check for sets 1-3");
					local okN = 0;
					for n = 1, 3 do
						local race = lo.raceOf(n);
						if race and lo.switch(n, "race check") and lo.setRace(race, "set " .. n) then okN = okN + 1; end;
					end;
					r.scanEnd("Race check", t0, string.format("%d of 3 sets confirmed.", okN));
				end;
				lo.switch(1, "ready to run");
				lo.raceChecked = true;
			end);
			return;
		end;
		if lo.raceChecked ~= true then return; end;
		if CFG.autoSell ~= false and runsSince >= every then
			lo.switchAt = now;
			task.spawn(lo.sell, string.format("after %d runs", runsSince));
			return;
		end;
		if not lo.hubDone then
			lo.hubDone = true;
			lo.switchAt = now;
			task.spawn(function()
				if lo.current() ~= 1 or lo.cur ~= 1 then lo.switch(1, "between runs"); end;
			end);
		end;
	end;
	r.loadout = lo;
	if type(brain.race) == "table" then r.rollPerk = brain.race.rollPerk; end;
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
		startedAt = startedAt or now;
		if not addConn then hook(); end;
		pcall(gearTick);
		-- one scan per launch, outside a run, once Roblox is focused; then it's done
		-- scan every N finished runs (mine or delve), between runs; the very first time as soon as possible
		local every = math.max(1, math.floor(tonumber(CFG.scanEveryRuns) or 10));
		local runsSince = (tonumber(brain.runCount) or 0) - (tonumber(brain.runsAtScan) or 0);
		local due = brain.indexScannedAt == nil or runsSince >= every;
		if due and not busy and not r.launching and not r.loadoutBusy and CFG.autoIndexScan ~= false and now - startedAt > 10
			and not run.active and not relicAPI.hasDraft() and now - (r.scanTryAt or 0) > 10 then
			r.scanTryAt = now;
			task.spawn(scan, brain.indexScannedAt == nil and "first scan" or string.format("after %d runs", runsSince));
		end;
		if now - startedAt > 10 then pcall(lo.tick, now); end;
		-- in the hub with Auto Farm on: open GO MINE and start the chosen stage
		if CFG.autoStage == true and not busy and not launch.busy and not r.loadoutBusy and now - startedAt > 10 and not inRun()
			and (CFG.autoLoadouts == false or lo.raceChecked == true)
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
		-- nothing explains this damage: it's the floor (lava strips etc.). Remember what you were standing on.
		if not inZone and not best then
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
		hs.lastHitSigs, hs.lastHitAt, hs.lastHitMob = sigs, now, best and best.name or nil;
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
		r.disconnectAntiAfk();
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
	local RACES = { "Drakon", "Shura", "Hydra", "Olympian", "Titan", "Dryad", "Dactyl", "Andros", "Kobalos", "Sphinx", "Lithos", "Nymph", "Yasha", "Nyx", "Phantom", "Don't change" };
	local STAGES = { "Delve", "Grasslands", "Sun Flats", "Frostbite", "Mycelia", "Pirates Cove", "Infernia", "The Abyss" };
	local spec = {
		{
			name = "Farm",
			main = true,
			items = {
				{ k = "autoStage", t = "toggle", text = "Auto Farm: start a stage from the hub" },
				{ k = "stage", t = "combo", text = "Stage", items = STAGES },
				{ k = "stageOther", t = "input", text = "Other stage (overrides the list)", placeholder = "Type a stage name, e.g. THE ABYSS" },
				{ k = "autoReplay", t = "toggle", text = "Play again when a run ends" },
				{ k = "replayDelay", t = "slider", text = "Play again after", min = .5, max = 10, step = .5, suffix = " s" },
				{ k = "autoStartFarm", t = "toggle", text = "Turn the farm back on after a restart" },
			},
		},
		{
			name = "Gear",
			icon = "shirt",
			items = {
				{ k = "autoLoadouts", t = "toggle", text = "Switch sets: 1 mining, 2 damage" },
				{ k = "bossSet", t = "toggle", text = "Damage set (2) on boss fights" },
				{ k = "autoSell", t = "toggle", text = "Sell ores with set 3" },
				{ k = "sellEveryRuns", t = "slider", text = "Sell every", min = 1, max = 30, step = 1, suffix = " runs" },
				{ k = "autoRace", t = "toggle", text = "Check each set's race once per load (hub)" },
				{ k = "setRace1", t = "combo", text = "Set 1 race (mining)", items = RACES },
				{ k = "setRace2", t = "combo", text = "Set 2 race (damage)", items = RACES },
				{ k = "setRace3", t = "combo", text = "Set 3 race (selling)", items = RACES },
			},
		},
		{
			name = "Mining",
			icon = "pickaxe",
			rescan = true,
			items = {
				{ k = "mine", t = "feat", text = "Mine rocks" },
				{ k = "walk", t = "feat", text = "Walk to rocks" },
				{ k = "chests", t = "feat", text = "Collect chests" },
				{ k = "centerFarm", t = "toggle", text = "Mine from the chest / arena center" },
				{ k = "centerCleanup", t = "toggle", text = "Center: walk to ores out of reach" },
				{ k = "autoStats", t = "toggle", text = "Read mining reach and radius from the game" },
				{ k = "reach", t = "slider", text = "Mining reach", min = .3, max = 20, step = .01, suffix = " st" },
				{ k = "radius", t = "slider", text = "Mining radius", min = .1, max = 10, step = .01, suffix = " st" },
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
				{ k = "attackRoll", t = "combo", text = "Attack rolls (Auto = if your race has a roll perk)", items = { "Auto", "Always", "Off" } },
				{ k = "rollKey", t = "combo", text = "Roll key", items = { "Q", "E", "R", "F", "C", "V", "X", "Z", "G", "Space", "LShift" } },
			},
		},
		{
			name = "Relics",
			icon = "gem",
			items = {
				{ k = "cardPick", t = "toggle", text = "Pick relics and blessings" },
				{ k = "relicExplore", t = "toggle", text = "Sometimes try a close 2nd (to learn)" },
				{ k = "forkPath", t = "combo", text = "Tunnel fork path", items = { "Smart", "Safe", "Cursed" } },
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
				{ k = "rareDropOdds", t = "slider", text = "Drops with no tier: 1 in at least", min = 1000, max = 1000000, step = 1000, suffix = "" },
			},
		},
		{
			name = "Settings",
			icon = "settings",
			items = {
				{ k = "startClosed", t = "toggle", text = "Start with this window closed" },
				{ k = "niceToasts", t = "toggle", text = "Game-style pop-ups" },
				{ k = "uiGameFont", t = "toggle", text = "Use the game's font in this window" },
				{ k = "relicNotify", t = "toggle", text = "Pop-ups: relic, trader and path choices" },
				{ k = "mechNotify", t = "toggle", text = "Pop-ups: new relics and mechanics" },
				{ k = "background", t = "toggle", text = "Background mode (work while tabbed out)" },
				{ k = "silentAim", t = "toggle", text = "Silent aim (don't move my mouse)" },
				{ k = "bgKeyMethod", t = "combo", text = "Background key method", items = { "Auto", "VirtualInputManager", "Input connections" } },
				{ k = "bgMoveMethod", t = "combo", text = "Background walk method", items = { "Both", "Humanoid:Move", "Velocity" } },
				{ k = "useLearned", t = "toggle", text = "Use learned equip remotes in background" },
				{ k = "autoEquip", t = "toggle", text = "Auto-equip tools" },
				{ k = "pickSlot", t = "slider", text = "Pickaxe slot", min = 1, max = 9, step = 1, suffix = "" },
				{ k = "weaponSlot", t = "slider", text = "Weapon slot", min = 1, max = 9, step = 1, suffix = "" },
				{ k = "antiAfk", t = "toggle", text = "Anti-AFK" },
				{ k = "dodgeLog", t = "toggle", text = "Log dodges to file" },
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
	uiNotify = function(message, title)
		if CFG.niceToasts ~= false and r.toast and pcall(r.toast, message, title) then return; end;
		if type(WindUI.Notify) == "function" then
			WindUI:Notify({ Title = title, Content = message, Duration = 6 });
		end;
	end;

	local window = WindUI:CreateWindow({
		Title = "Delve v5.8.2 | Brain",
		Folder = "DelveV3",
		Icon = "pickaxe",
		Size = UDim2.fromOffset(620, 480),
		ToggleKey = Enum.KeyCode.RightShift,
		OpenButton = {
			Title = "Open Delve",
			Enabled = true,
			Draggable = true,
			OnlyMobile = false,
		},
	});
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
	farmToggle = main:Toggle({
		Title = "Farm enabled",
		Value = false,
		Callback = function(enabled)
			r.autoStart = false;
			local blocker = enabled and farmBlocker();
			if blocker then
				notify(blocker, "Delve");
				if farmToggle then farmToggle:Set(false); end;
				return;
			end;
			N(enabled);
		end,
	});
	r.farmToggle = farmToggle;
	local synced = {};
	local function current(item)
		if item.t == "feat" then return Q.feat[item.k] ~= false; end;
		return Q[item.k];
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
				Title = "Auto Farm",
				Desc = "From the hub it clicks GO MINE!, scrolls to your stage, selects it and descends. The farm turns on once the run loads. Right Shift or the Open Delve button shows this window.",
			});
			tab:Button({ Title = "Stop and unload", Callback = r.stop });
		end;
		if group.name == "Settings" then
			tab:Button({
				Title = "Test background support",
				Callback = function()
					notify(inp.report(), "Delve background");
				end,
			});
			tab:Button({
				Title = "Learn weapon equip (then press the key in game)",
				Callback = function()
					inp.learn("weapon", mQ);
				end,
			});
			tab:Button({
				Title = "Learn pickaxe equip (then press the key in game)",
				Callback = function()
					inp.learn("pickaxe", Il);
				end,
			});
			tab:Button({
				Title = "Forget learned equips",
				Callback = function()
					inp.learned.weapon, inp.learned.pickaxe = nil, nil;
					notify("Learned equip remotes cleared.", "Delve learn");
				end,
			});
		end;
		if group.name == "Gear" then
			tab:Button({ Title = "Sell ores now (set 3)", Callback = function() if r.loadout then task.spawn(r.loadout.sell, "manual"); end; end });
			for n = 1, 3 do
				tab:Button({ Title = "Switch to set " .. n, Callback = function() if r.loadout then task.spawn(r.loadout.switch, n, "manual"); end; end });
			end;
			tab:Paragraph({
				Title = "How it works",
				Desc = "In delves it uses set 1, and set 2 for boss fights or when mobs hit hard (switches at most every 20 s). Every few runs, between runs, it swaps to set 3, sells your ores and goes back to set 1. Once per load, in the hub before the first run, it checks each set wears the race picked above (the set keeps it). It never opens Races during a run and never clicks reroll or Robux buttons.",
			});
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
					saveBrain(true);
					notify(type(writefile) == "function" and "Saved to DelveBrain.json" or "This executor has no writefile; learning lasts until you rejoin.", "Delve brain");
				end,
			});
			tab:Button({
				Title = "Reset everything the brain learned",
				Callback = function()
					r.brainBackup("before-reset");
					brain.relics, brain.cat, brain.sets, brain.runs, brain.mobReach = {}, {}, {}, {}, {};
					brain.dodge = { extra = 0, leadAdj = 0, hits = 0, dodges = 0 };
					if r.sync then r.sync(); end;
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
		local function setOne(o, ff)
			if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
				if original[o] == nil then original[o] = o.FontFace; end;
				if ff then
					o.FontFace = Font.new(ff.Family, original[o].Weight, original[o].Style);
				else
					o.FontFace = original[o];
				end;
			end;
		end;
		r.applyGameFont = function()
			local g = findRoot();
			if not g then return; end;
			local ff = CFG.uiGameFont ~= false and r.gameFont and r.gameFont() or nil;
			for _, o in ipairs(g:GetDescendants()) do pcall(setOne, o, ff); end;
			if conn then conn:Disconnect(); conn = nil; end;
			if ff then
				conn = g.DescendantAdded:Connect(function(o) pcall(setOne, o, ff); end);
			end;
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