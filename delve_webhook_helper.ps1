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
#>
param([string]$Workspace)

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

Write-Host "Delve webhook helper running. Watching $dir" -ForegroundColor Green
Write-Host "Leave this window open while you play. Ctrl+C to stop."
# The script writes game_alive.json every 10 s while the bot is on. If that stops for 2+ minutes,
# Roblox closed, crashed or froze: post the alert the script left in that file (pings you), once.
$heartbeat = Join-Path $dir "game_alive.json"
$staleSent = $false
$lastBeatCheck = 0
$retryAt = @{}
while ($true) {
    try {
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        [System.IO.File]::WriteAllText($alive, "$now", $utf8)
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
    Start-Sleep -Milliseconds 250
}
