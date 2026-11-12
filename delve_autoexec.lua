-- Delve auto-load: put this file in Volt's autoexec folder (%LOCALAPPDATA%\Volt\autoexec).
-- It only does anything in Delve: it waits for the game to load, then 10 more seconds, then loads the script.
local DELVE_PLACE = 132273490031319

local function savedGameId()
	local ok, v = pcall(function()
		return type(isfile) == "function" and isfile("DelveGameId.txt") and readfile("DelveGameId.txt") or nil
	end)
	return ok and v and v:match("%d+") or nil
end

local inDelve = game.PlaceId == DELVE_PLACE or (savedGameId() ~= nil and tostring(game.GameId) == savedGameId())
if not inDelve then return end
if game.PlaceId == DELVE_PLACE then
	-- remember the game's id so the script also loads inside Delve's other places (mines, runs)
	pcall(function() if type(writefile) == "function" then writefile("DelveGameId.txt", tostring(game.GameId)) end end)
end

local env = (type(getgenv) == "function" and getgenv()) or _G
if env.DelveAutoLoaded then return end
env.DelveAutoLoaded = true

if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
while not Players.LocalPlayer do task.wait(0.2) end
task.wait(10)
loadstring(game:HttpGet("https://raw.githubusercontent.com/pokemoncombi145-sys/delve/main/delve_v3.lua"))()
