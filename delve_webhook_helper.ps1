<#
  Delve webhook screenshot helper
  --------------------------------
  Keeps running in the background. When the Delve script finishes a run it drops a job file in
  <executor workspace>\DelveWebhook\. This helper screenshots your primary monitor and posts it to
  your Discord webhook as "Run Complete" with the run stats.

  Run it:   powershell -ExecutionPolicy Bypass -File .\delve_webhook_helper.ps1
  If it can't find your executor's workspace folder on its own:
            powershell -ExecutionPolicy Bypass -File .\delve_webhook_helper.ps1 -Workspace "C:\path\to\Volt\workspace"
  (the workspace folder is the one that contains DelveSettings.json once the script has run once)

  Capture mode (optional, local only):  add -Capture
    Keeps the last few seconds of the screen in memory. When the script reports a hit, a death or F8,
    it saves about 5 s before and 2 s after (frames), the matching dodge and reasoning log lines, and the
    script's record of what it knew (nearest planned shot, boss at spawn, start point used, the drawn bullet
    next to you, roll / server dodge) to <workspace>\DelveCaptures\<time>_<reason>\. Open index.html there.
    Nothing is uploaded and nothing here affects how the bot moves or dodges.
    Automatic: hits in boss fights or while planned attacks are around, deaths, every bullet storm, and near
    misses are saved without you; the newest 40 clips are kept (-Keep 0 keeps everything).
    Options: -Fps 8 -Scale 0.6 -Quality 70 -PreMs 5000 -PostMs 2000 -Keep 40
#>
param(
    [string]$Workspace,
    [switch]$Capture,
    [int]$Fps = 8,
    [double]$Scale = 0.6,
    [int]$Quality = 70,
    [int]$PreMs = 5000,
    [int]$PostMs = 2000,
    [int]$Keep = 40,
    [switch]$SelfTest
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class DelveDpi { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }
"@
[void][DelveDpi]::SetProcessDPIAware()   # capture the real 1920x1080, not a scaled-down image

function Find-Workspace {
    $roots = @($env:LOCALAPPDATA, $env:APPDATA, "$env:USERPROFILE\Desktop", "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Documents", "$env:USERPROFILE") |
        Where-Object { $_ -and (Test-Path $_) }
    foreach ($root in $roots) {
        $hit = Get-ChildItem -Path $root -Filter "DelveSettings.json" -Recurse -Depth 4 -File -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($hit) { return $hit.DirectoryName }
    }
    return $null
}

if ($SelfTest) {
    # pipeline test: generated frames instead of the screen, fake logs in a temp workspace (pass -Workspace)
    $Capture = $true
}
if (-not $Workspace -and (Test-Path "$env:LOCALAPPDATA\Volt\workspace")) {
    $Workspace = "$env:LOCALAPPDATA\Volt\workspace"   # Volt's default workspace
}
if (-not $Workspace) {
    Write-Host "Looking for the executor workspace (folder with DelveSettings.json)..."
    $Workspace = Find-Workspace
}
if (-not $Workspace -or -not (Test-Path $Workspace)) {
    Write-Host "Couldn't find it. Run the Delve script once in Roblox, or pass -Workspace ""C:\path\to\workspace""." -ForegroundColor Red
    exit 1
}
$dir = Join-Path $Workspace "DelveWebhook"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$alive = Join-Path $dir "helper_alive.txt"
$curl = (Get-Command curl.exe -ErrorAction SilentlyContinue).Source
if (-not $curl) { Write-Host "curl.exe not found (it ships with Windows 10/11)." -ForegroundColor Red; exit 1 }
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Take-Screenshot([string]$path) {
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap($b.Width, $b.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.CopyFromScreen($b.Left, $b.Top, 0, 0, $bmp.Size)
        $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $g.Dispose(); $bmp.Dispose() }
}

# ------------------------------------------------------------------------------------------------
# CAPTURE MODE: rolling frame buffer + saving clips with the matching log lines
# ------------------------------------------------------------------------------------------------
$frames = New-Object System.Collections.Generic.List[object]
$pending = New-Object System.Collections.Generic.List[object]
$capOn = Join-Path $dir "capture_on.txt"
$capRoot = Join-Path $Workspace "DelveCaptures"
if ($Capture) {
    $Fps = [Math]::Max(1, [Math]::Min(20, $Fps))
    $Scale = [Math]::Max(0.2, [Math]::Min(1.0, $Scale))
    $capBounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $capW = [int]($capBounds.Width * $Scale)
    $capH = [int]($capBounds.Height * $Scale)
    $fullBmp = New-Object System.Drawing.Bitmap($capBounds.Width, $capBounds.Height)
    $fullG = [System.Drawing.Graphics]::FromImage($fullBmp)
    $smallBmp = New-Object System.Drawing.Bitmap($capW, $capH)
    $smallG = [System.Drawing.Graphics]::FromImage($smallBmp)
    $smallG.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::Bilinear
    $stampFont = New-Object System.Drawing.Font("Consolas", 12)
    $stampBack = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(170, 0, 0, 0))
    $stampFore = [System.Drawing.Brushes]::White
    $jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" } | Select-Object -First 1
    $encParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)
    New-Item -ItemType Directory -Force -Path $capRoot | Out-Null
}

function Get-NowMs { return [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
function Get-LocalTimeText([int64]$ms) { return [DateTimeOffset]::FromUnixTimeMilliseconds($ms).ToLocalTime().ToString("HH:mm:ss.fff") }

function Grab-Frame([int64]$ms) {
    if ($SelfTest) {
        $smallG.Clear([System.Drawing.Color]::FromArgb(30, 30, 40))
        $smallG.DrawString("self-test frame", $stampFont, $stampFore, 20, 40)
    } else {
        $fullG.CopyFromScreen($capBounds.Left, $capBounds.Top, 0, 0, $fullBmp.Size)
        $smallG.DrawImage($fullBmp, 0, 0, $capW, $capH)
    }
    # wall-clock stamp on every frame (same clock as the script's ms)
    $smallG.FillRectangle($stampBack, 0, 0, 150, 22)
    $smallG.DrawString((Get-LocalTimeText $ms), $stampFont, $stampFore, 4, 2)
    $mem = New-Object System.IO.MemoryStream
    try {
        $smallBmp.Save($mem, $jpeg, $encParams)
        return ,$mem.ToArray()
    } finally { $mem.Dispose() }
}

function Read-Tail([string]$path, [int]$bytes) {
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    $fs = [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $len = $fs.Length
        $start = [Math]::Max([int64]0, $len - $bytes)
        [void]$fs.Seek($start, [System.IO.SeekOrigin]::Begin)
        $buf = New-Object byte[] ([int]($len - $start))
        $read = $fs.Read($buf, 0, $buf.Length)
        $text = $utf8.GetString($buf, 0, $read)
    } finally { $fs.Dispose() }
    $lines = @($text -split "`r?`n")
    if ($start -gt 0 -and $lines.Count -gt 1) { $lines = $lines[1..($lines.Count - 1)] }   # first line may be cut
    return $lines
}

function Fmt-Offset([int64]$off) {
    if ($off -ge 0) { return ("+{0:N2}s" -f ($off / 1000.0)) }
    return ("{0:N2}s" -f ($off / 1000.0))
}

function Save-Capture($cap) {
    $m = [int64]$cap.ms
    $reason = [string]$cap.reason
    if (-not $reason) { $reason = "capture" }
    $reason = ($reason -replace '[^A-Za-z0-9_-]', '')
    $stamp = [DateTimeOffset]::FromUnixTimeMilliseconds($m).ToLocalTime().ToString("yyyy-MM-dd_HH-mm-ss-fff")
    $out = Join-Path $capRoot ("{0}_{1}" -f $stamp, $reason)
    $fdir = Join-Path $out "frames"
    New-Item -ItemType Directory -Force -Path $fdir | Out-Null

    # frames from PreMs before to PostMs after the event
    $list = @()
    $i = 0
    foreach ($fr in $frames.ToArray()) {
        $off = [int64]$fr.ms - $m
        if ($off -ge -$PreMs -and $off -le $PostMs) {
            $i++
            $name = ("f{0:D3}_{1}ms.jpg" -f $i, $off)
            [System.IO.File]::WriteAllBytes((Join-Path $fdir $name), [byte[]]$fr.bytes)
            $list += [pscustomobject]@{ f = "frames/$name"; o = $off; t = (Get-LocalTimeText ([int64]$fr.ms)) }
        }
    }

    # dodge_log.txt: "<os.clock> text"; the record's clock + ms map it onto the same time line
    $logRows = @()
    $clock0 = [double]$cap.clock
    foreach ($ln in (Read-Tail (Join-Path $Workspace "dodge_log.txt") 600000)) {
        if ($ln -match '^(\d+\.\d+) (.*)$') {
            $c = [double]$Matches[1]
            $off = [int64][Math]::Round(($c - $clock0) * 1000)
            if ($off -ge (-$PreMs - 500) -and $off -le ($PostMs + 500)) {
                $logRows += [pscustomobject]@{ o = $off; src = "dodge"; text = $Matches[2] }
            }
        }
    }
    # DelveReasoning.txt: "HH:MM:SS [kind] text" (whole seconds, local time)
    $day = [DateTimeOffset]::FromUnixTimeMilliseconds($m).ToLocalTime()
    foreach ($ln in (Read-Tail (Join-Path $Workspace "DelveReasoning.txt") 300000)) {
        if ($ln -match '^(\d\d):(\d\d):(\d\d) (.*)$') {
            $t = New-Object DateTimeOffset($day.Year, $day.Month, $day.Day, [int]$Matches[1], [int]$Matches[2], [int]$Matches[3], $day.Offset)
            $lms = $t.ToUnixTimeMilliseconds()
            if ($lms - $m -gt 43200000) { $lms -= 86400000 } elseif ($m - $lms -gt 43200000) { $lms += 86400000 }
            $off = $lms - $m
            if ($off -ge (-$PreMs - 1000) -and $off -le ($PostMs + 1000)) {
                $logRows += [pscustomobject]@{ o = $off; src = "reasoning (1 s)"; text = $Matches[4] }
            }
        }
    }
    $logRows = @($logRows | Sort-Object o)
    $logText = ($logRows | ForEach-Object { "{0,8}  {1,-15} {2}" -f (Fmt-Offset $_.o), $_.src, $_.text }) -join "`r`n"
    [System.IO.File]::WriteAllText((Join-Path $out "logs.txt"), ("time 0 = {0} ({1})`r`n{2}" -f (Get-LocalTimeText $m), $reason, $logText), $utf8)

    # the death black box, if this was a death
    if ($reason -eq "death") {
        foreach ($ln in (Read-Tail (Join-Path $Workspace "DelveDeaths.jsonl") 200000)) {
            if ($ln -match '"t"\s*:\s*(\d+)') {
                $dt = [int64]$Matches[1] * 1000 - $m
                if ($dt -ge -5000 -and $dt -le 8000) { [System.IO.File]::WriteAllText((Join-Path $out "death_blackbox.json"), $ln, $utf8) }
            }
        }
    }

    # the script's record + a plain summary
    $recJson = $cap | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText((Join-Path $out "impact.json"), $recJson, $utf8)
    $sum = New-Object System.Collections.Generic.List[string]
    $sum.Add(("{0} at {1}, v{2}" -f $reason, (Get-LocalTimeText $m), ([string]$cap.version).TrimStart('v')))
    $sum.Add(("player at x={0:N1} z={1:N1}, HP after {2}, loss {3}" -f $cap.player.x, $cap.player.z, $cap.hp, $cap.loss))
    $ns = $cap.nearestShot
    if ($ns) {
        $sum.Add(("nearest planned shot: {0:N1} st from you (model), spawned {1:N2}s before (at {2}), fromMob={3}, speed {4:N1} st/s, radius {5}" -f `
            $ns.distance, ($ns.spawnBeforeMs / 1000.0), (Get-LocalTimeText ([int64]$ns.spawnMs)), $ns.fromMob, $ns.speed, $ns.radius))
        if ($ns.bossAtSpawn) { $sum.Add(("  boss at spawn:     x={0:N1} z={1:N1}" -f $ns.bossAtSpawn.x, $ns.bossAtSpawn.z)) }
        if ($ns.originUsed) { $sum.Add(("  start point used:  x={0:N1} z={1:N1}" -f $ns.originUsed.x, $ns.originUsed.z)) }
        if ($ns.planFrom) { $sum.Add(("  plan's own start:  x={0:N1} z={1:N1}" -f $ns.planFrom.x, $ns.planFrom.z)) }
        if ($ns.bossAtSpawn -and $ns.originUsed) {
            $g = [Math]::Sqrt([Math]::Pow($ns.bossAtSpawn.x - $ns.originUsed.x, 2) + [Math]::Pow($ns.bossAtSpawn.z - $ns.originUsed.z, 2))
            $sum.Add(("  start used vs boss at spawn: {0:N2} st apart" -f $g))
        }
        $sum.Add(("  modelled bullet at time 0: x={0:N1} z={1:N1}" -f $ns.modeled.x, $ns.modeled.z))
    } else { $sum.Add("nearest planned shot: none") }
    $vb = $cap.visibleBullet
    if ($vb) {
        $sum.Add(("drawn bullet nearest you: x={0:N1} z={1:N1}, {2:N1} st away; nearest modelled bullet to it {3:N2} st ({4} drawn within 30 st)" -f `
            $vb.x, $vb.z, $vb.distance, $vb.modelError, $vb.drawnNearby))
    } else { $sum.Add("drawn bullet nearest you: none within 30 st") }
    if ($cap.bulletCheck) {
        $sum.Add(("last bullet model check ({0} ms before): {1} drawn bullets, model off by median {2:N2} st, max {3:N2} st" -f `
            $cap.bulletCheck.msAgo, $cap.bulletCheck.n, $cap.bulletCheck.median, $cap.bulletCheck.max))
    }
    $d = $cap.dodge
    if ($d) {
        $sum.Add(("roll: {0}; escape picked: {1}; server dodge: {2} {3}" -f `
            $(if ($null -ne $d.rollMsAgo) { "$($d.rollMsAgo) ms before" } else { "none" }),
            $(if ($null -ne $d.escapeMsAgo) { "$($d.escapeMsAgo) ms before" } else { "none" }),
            $(if ($null -ne $d.serverDodgeMsAgo) { "$($d.serverDodgeMsAgo) ms before" } else { "none" }),
            [string]$d.serverDodgeInfo))
    }
    $sum.Add(("frames: {0} ({1} fps, {2:N0}% size); logs: {3} lines" -f $list.Count, $Fps, ($Scale * 100), $logRows.Count))
    [System.IO.File]::WriteAllText((Join-Path $out "summary.txt"), ($sum -join "`r`n"), $utf8)

    # a small local viewer: frames with their offset, log lines near the current frame highlighted
    $framesJson = ConvertTo-Json -InputObject @($list) -Compress
    $logsJson = ConvertTo-Json -InputObject @($logRows | ForEach-Object { [pscustomobject]@{ o = $_.o; s = $_.src; t = $_.text } }) -Compress
    $sumJson = ConvertTo-Json -InputObject ($sum -join "`n") -Compress
    $html = @'
<!doctype html><html><head><meta charset="utf-8"><title>Delve capture</title>
<style>
body{font:14px system-ui,Segoe UI,sans-serif;background:#121214;color:#ddd;margin:16px}
img{width:100%;border:1px solid #333;background:#000}
.row{display:flex;gap:16px;flex-wrap:wrap}.l{flex:2 1 560px}.r{flex:1 1 320px;min-width:0}
pre{white-space:pre-wrap;font:12px Consolas,monospace;margin:0}
#log{max-height:62vh;overflow:auto;border:1px solid #333;padding:6px}
.hit{color:#ff8080}.near{background:#40381a}.ctl{margin:8px 0}input[type=range]{width:100%}
button{background:#2a2a30;color:#ddd;border:1px solid #444;padding:4px 10px}
</style></head><body>
<pre id="sum"></pre>
<div class="ctl"><button id="prev">&lt;</button> <button id="play">play</button> <button id="next">&gt;</button>
 <b id="off"></b> <span id="clock"></span></div>
<input type="range" id="s" min="0" value="0">
<div class="row"><div class="l"><img id="img" alt="frame"></div><div class="r"><div id="log"></div></div></div>
<script>
const F=__FRAMES__;const L=__LOGS__;document.getElementById('sum').textContent=__SUM__;
const s=document.getElementById('s'),img=document.getElementById('img'),off=document.getElementById('off'),clk=document.getElementById('clock'),log=document.getElementById('log');
s.max=Math.max(F.length-1,0);
let k=0;F.forEach((f,i)=>{if(Math.abs(f.o)<Math.abs(F[k].o))k=i});
L.forEach(l=>{const d=document.createElement('pre');d.textContent=(l.o>=0?'+':'')+(l.o/1000).toFixed(2)+'s  '+l.s+'  '+l.t;if(/hit|death|capture/.test(l.t))d.className='hit';d.dataset.o=l.o;log.appendChild(d)});
function show(i){if(!F.length)return;k=Math.max(0,Math.min(F.length-1,i));s.value=k;const f=F[k];img.src=f.f;off.textContent=(f.o>=0?'+':'')+(f.o/1000).toFixed(2)+'s';clk.textContent=f.t;
 let first=null;for(const d of log.children){const n=Math.abs(+d.dataset.o-f.o)<=300;d.classList.toggle('near',n);if(n&&!first)first=d}if(first)first.scrollIntoView({block:'nearest'})}
s.oninput=()=>show(+s.value);document.getElementById('prev').onclick=()=>show(k-1);document.getElementById('next').onclick=()=>show(k+1);
let t=null;document.getElementById('play').onclick=e=>{if(t){clearInterval(t);t=null;e.target.textContent='play';return}e.target.textContent='pause';t=setInterval(()=>{if(k>=F.length-1){clearInterval(t);t=null;e.target.textContent='play';return}show(k+1)},150)};
show(k);
</script></body></html>
'@
    $safe = { param($x) $x -replace '</', '<\/' }
    $html = $html.Replace('__FRAMES__', (& $safe $framesJson)).Replace('__LOGS__', (& $safe $logsJson)).Replace('__SUM__', (& $safe $sumJson))
    [System.IO.File]::WriteAllText((Join-Path $out "index.html"), $html, $utf8)
    Write-Host ("[{0}] Saved {1}: {2} frames, {3} log lines -> {4}" -f (Get-Date -Format T), $reason, $list.Count, $logRows.Count, $out) -ForegroundColor Magenta
    return $out
}

# keep the newest $Keep clips (only folders this recorder made: <date>_<time>_<reason>)
function Prune-Captures {
    if ($Keep -le 0) { return }
    $dirs = @(Get-ChildItem -LiteralPath $capRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d{4}-\d\d-\d\d_\d\d-\d\d-\d\d-\d{3}_[A-Za-z0-9_-]+$' } | Sort-Object Name)
    if ($dirs.Count -le $Keep) { return }
    foreach ($old in $dirs[0..($dirs.Count - $Keep - 1)]) {
        Remove-Item -LiteralPath $old.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Poll-CaptureRequests {
    foreach ($capFile in Get-ChildItem -Path $dir -Filter "cap_*.json" -File -ErrorAction SilentlyContinue) {
        try {
            $cap = Get-Content -Raw -LiteralPath $capFile.FullName | ConvertFrom-Json
            if ($cap.ms) { $pending.Add($cap) }
        } catch {
            Write-Host ("[{0}] Bad capture request: {1}" -f (Get-Date -Format T), $_.Exception.Message) -ForegroundColor Red
        } finally {
            Remove-Item -LiteralPath $capFile.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($SelfTest) {
    # fake logs around a fake hit 2.5 s from now, then exit once the capture is saved
    $t0 = (Get-NowMs) + 2500
    $clock0 = 1000.0
    $dl = New-Object System.Collections.Generic.List[string]
    foreach ($k in -60..40) { $dl.Add(("{0:F2} self-test dodge line {1}" -f ($clock0 + $k * 0.1), $k)) }
    [System.IO.File]::WriteAllText((Join-Path $Workspace "dodge_log.txt"), (($dl -join "`n") + "`n"), $utf8)
    $rs = New-Object System.Collections.Generic.List[string]
    foreach ($k in -8..4) { $rs.Add(("{0} [combat] self-test reasoning {1}" -f [DateTimeOffset]::FromUnixTimeMilliseconds($t0 + $k * 1000).ToLocalTime().ToString("HH:mm:ss"), $k)) }
    [System.IO.File]::WriteAllText((Join-Path $Workspace "DelveReasoning.txt"), (($rs -join "`n") + "`n"), $utf8)
    [System.IO.File]::WriteAllText((Join-Path $Workspace "DelveDeaths.jsonl"), ('{"t":' + [int64]($t0 / 1000) + ',"boss":"PaleWarden","samples":[]}' + "`n"), $utf8)
    $req = @{ reason = "death"; version = "v5.32"; ms = $t0; clock = $clock0; srv = 0; loss = 44; hp = 0; player = @{ x = 8010; z = -3800 };
        nearestShot = @{ key = "694:s1"; mob = "PaleWarden"; fromMob = $true; spawnMs = $t0 - 1420; spawnBeforeMs = 1420; bossAtSpawn = @{ x = 8012; z = -3720 };
            originUsed = @{ x = 8012; z = -3720 }; planFrom = @{ x = 8000; z = -3700 }; modeled = @{ x = 8011; z = -3798 }; distance = 2.1; radius = 2; speed = 16; life = 4.375 };
        visibleBullet = @{ x = 8011.3; z = -3798.4; distance = 1.9; modelKey = "694:s1"; modelError = 0.31; drawnNearby = 6 };
        dodge = @{ rollMsAgo = 110; escapeMsAgo = 2400 } }
    [System.IO.File]::WriteAllText((Join-Path $dir ("cap_{0}.json" -f $t0)), ($req | ConvertTo-Json -Depth 6), $utf8)
}

if ($Capture) {
    Write-Host ("Capture mode ON: keeping the last {0:N0} s at {1} fps; saves {0:N0} s before and {2:N0} s after hits, deaths, bullet storms, near misses and F8 to {3}" -f ($PreMs / 1000), $Fps, ($PostMs / 1000), $capRoot) -ForegroundColor Magenta
    Write-Host ("Keeps the newest {0} clips. Keep Roblox visible on the main screen (it can be unattended; a locked screen records nothing useful)." -f $Keep) -ForegroundColor Magenta
}
Write-Host "Delve webhook helper running. Watching $dir" -ForegroundColor Green
Write-Host "Leave this window open while you play. Ctrl+C to stop."
# The script writes game_alive.json every 10 s while the bot is on. If that stops for 2+ minutes,
# Roblox closed, crashed or froze: post the alert the script left in that file (pings you), once.
$heartbeat = Join-Path $dir "game_alive.json"
$staleSent = $false
$lastBeatCheck = 0
$retryAt = @{}
$frameEvery = [int](1000 / [Math]::Max(1, $Fps))
$nextFrame = [int64]0
$nextJobs = [int64]0
while ($true) {
    $nowMs = Get-NowMs
    if ($Capture -and $nowMs -ge $nextFrame) {
        $nextFrame = $nowMs + $frameEvery
        try { $frames.Add([pscustomobject]@{ ms = $nowMs; bytes = (Grab-Frame $nowMs) }) } catch { }
        $cut = $nowMs - $PreMs - 4000
        while ($frames.Count -gt 0 -and [int64]$frames[0].ms -lt $cut) { $frames.RemoveAt(0) }
    }
    if ($nowMs -ge $nextJobs) {
        $nextJobs = $nowMs + 250
        try {
            $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
            [System.IO.File]::WriteAllText($alive, "$now", $utf8)
            if ($Capture) {
                [System.IO.File]::WriteAllText($capOn, "$now", $utf8)
                Poll-CaptureRequests
            }
            if ($now - $lastBeatCheck -ge 5 -and (Test-Path -LiteralPath $heartbeat)) {
                $lastBeatCheck = $now
                try {
                    $beat = Get-Content -Raw -LiteralPath $heartbeat | ConvertFrom-Json
                    $age = $now - [int64]$beat.t
                    if ($age -lt 60) { $staleSent = $false }
                    elseif ($age -ge 120 -and -not $staleSent -and $beat.farming -and -not $beat.alerted -and $age -lt 3600) {
                        $staleSent = $true
                        $stale = @{ url = $beat.url; payload = $beat.payload; retry = $true } | ConvertTo-Json -Depth 12 -Compress
                        [System.IO.File]::WriteAllText((Join-Path $dir ("job_stale_{0}.json" -f $now)), $stale, $utf8)
                        Write-Host ("[{0}] No heartbeat from the script for {1} s: sending the alert" -f (Get-Date -Format T), $age) -ForegroundColor Yellow
                    }
                } catch { }
            }
            foreach ($jobFile in Get-ChildItem -Path $dir -Filter "job_*.json" -File -ErrorAction SilentlyContinue) {
                $keep = $false
                $job = $null
                try {
                    $job = Get-Content -Raw -Path $jobFile.FullName | ConvertFrom-Json
                    # alerts that failed (internet down) are retried every 15 s for up to 30 minutes
                    if ($job.retry -and $retryAt.ContainsKey($jobFile.Name) -and $now -lt $retryAt[$jobFile.Name]) { $keep = $true; continue }
                    # "snap" job: just take the picture now (the end-of-run screen) and keep it for the post
                    if ($job.snap) {
                        $snapName = [System.IO.Path]::GetFileName([string]$job.snap)
                        Take-Screenshot (Join-Path $dir $snapName)
                        Write-Host ("[{0}] Captured end screen" -f (Get-Date -Format T)) -ForegroundColor Cyan
                        continue
                    }
                    $url = [string]$job.url
                    if ($url -notmatch '^https://([a-z]+\.)?discord(app)?\.com/api/webhooks/') { throw "not a Discord webhook URL" }
                    $png = Join-Path $dir "run.png"
                    $payloadPath = Join-Path $dir "payload.json"
                    $snapFile = $null
                    if ($job.image) { $snapFile = Join-Path $dir ([System.IO.Path]::GetFileName([string]$job.image)) }
                    if ($snapFile -and (Test-Path -LiteralPath $snapFile)) {
                        Copy-Item -LiteralPath $snapFile -Destination $png -Force
                        Remove-Item -LiteralPath $snapFile -Force -ErrorAction SilentlyContinue
                    } else {
                        Take-Screenshot $png
                    }
                    [System.IO.File]::WriteAllText($payloadPath, ($job.payload | ConvertTo-Json -Depth 12 -Compress), $utf8)
                    $code = & $curl -s -o NUL -w "%{http_code}" -F "payload_json=<$payloadPath" -F "files[0]=@$png;type=image/png;filename=run.png" $url
                    if ($code -match '^2') {
                        Write-Host ("[{0}] Posted to Discord" -f (Get-Date -Format T)) -ForegroundColor Green
                    } else {
                        Write-Host ("[{0}] Discord answered HTTP {1}" -f (Get-Date -Format T), $code) -ForegroundColor Yellow
                        if ($job.retry -and $jobFile.CreationTime -gt (Get-Date).AddMinutes(-30)) { $keep = $true }
                    }
                } catch {
                    Write-Host ("[{0}] Job failed: {1}" -f (Get-Date -Format T), $_.Exception.Message) -ForegroundColor Red
                    if ($job -and $job.retry -and $jobFile.CreationTime -gt (Get-Date).AddMinutes(-30)) { $keep = $true }
                } finally {
                    if ($keep) {
                        if (-not $retryAt.ContainsKey($jobFile.Name) -or $now -ge $retryAt[$jobFile.Name]) { $retryAt[$jobFile.Name] = $now + 15 }
                    } else {
                        $retryAt.Remove($jobFile.Name)
                        Remove-Item -LiteralPath $jobFile.FullName -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        } catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
    # captures are saved once PostMs has passed after the event
    if ($Capture -and $pending.Count -gt 0) {
        for ($pIdx = $pending.Count - 1; $pIdx -ge 0; $pIdx--) {
            $cap = $pending[$pIdx]
            if ($nowMs -ge ([int64]$cap.ms + $PostMs + 150)) {
                $pending.RemoveAt($pIdx)
                try {
                    $saved = Save-Capture $cap
                    Prune-Captures
                    if ($SelfTest) { Write-Host "SELFTEST_OK $saved"; exit 0 }
                } catch {
                    Write-Host ("[{0}] Capture save failed: {1} (line {2})" -f (Get-Date -Format T), $_.Exception.Message, $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
                    if ($SelfTest) { exit 2 }
                }
            }
        }
    }
    if ($SelfTest -and (Get-NowMs) - $t0 -gt 15000) { Write-Host "SELFTEST_TIMEOUT"; exit 3 }
    Start-Sleep -Milliseconds $(if ($Capture) { 10 } else { 50 })
}
