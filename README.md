# Delve v3

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/pokemoncombi145-sys/delve/main/delve_v3.lua"))()
```

- Tile-map dodge pathfinding, corner avoidance, learning from hits
- Relic codex + learning relic picker (per run type, combos, your own picks)
- Ores first, fights on boss stages / threats
- Settings autosave (`DelveSettings.json`), brain (`DelveBrain.json`), run log (`DelveRuns.jsonl`)
- Discord "Run Complete" posts. For screenshots, keep this running on your PC:

```
powershell -ExecutionPolicy Bypass -File .\delve_webhook_helper.ps1
```
