# ==============================================================
#  limpieza-profunda.ps1
#  Deletes large regenerable caches + confirmed-dead apps.
#  Prompts (s/n) before each block. Touches nothing system-level.
#  Customize the dev-cache and dead-app targets per user.
#  Run: powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\limpieza-profunda.ps1"
# ==============================================================

$L = $env:LOCALAPPDATA

function SizeGB($p) {
    if (-not (Test-Path $p)) { return 0 }
    try { return [math]::Round(((Get-ChildItem $p -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum)/1GB, 2) }
    catch { return 0 }
}

function AskDelete($path, $name) {
    if (-not (Test-Path $path)) { Write-Host "  ($name not present)" -ForegroundColor DarkGray; return }
    $gb = SizeGB $path
    Write-Host ""
    Write-Host "  $name : $gb GB" -ForegroundColor Yellow
    $r = Read-Host "    Delete? (s/n)"
    if ($r -eq 's') {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "    -> Deleted." -ForegroundColor Green
    } else { Write-Host "    -> Skipped." -ForegroundColor DarkGray }
}

# Clears only the cache subfolders of a Chromium browser (keeps logins/history)
function ClearChromiumCache($userDataPath, $name) {
    if (-not (Test-Path $userDataPath)) { Write-Host "  ($name not found)" -ForegroundColor DarkGray; return }
    $profiles = Get-ChildItem $userDataPath -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -eq 'Default' -or $_.Name -like 'Profile*' -or $_.Name -eq 'Guest Profile' }
    $totalGB = 0
    foreach ($p in $profiles) {
        foreach ($c in @('Cache','Code Cache','GPUCache','ShaderCache','DawnGraphiteCache','DawnWebGPUCache','GrShaderCache','Service Worker\CacheStorage')) {
            $cp = Join-Path $p.FullName $c
            if (Test-Path $cp) { $totalGB += SizeGB $cp; Remove-Item "$cp\*" -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
    Write-Host "    -> $name : freed approx $([math]::Round($totalGB,1)) GB of cache (logins untouched)." -ForegroundColor Green
}

Write-Host ""
Write-Host "######  DEEP CLEANUP  ######" -ForegroundColor Cyan
$freeBefore = [math]::Round((Get-PSDrive C).Free/1GB,1)
Write-Host "Free space before: $freeBefore GB" -ForegroundColor Cyan

# ---------- 1. Dev caches (regenerate) ----------
Write-Host ""
Write-Host "=== 1) DEV CACHES (safe, regenerate) ===" -ForegroundColor Cyan
AskDelete "$L\npm-cache"       "npm-cache"
AskDelete "$L\uv"             "uv (Python cache)"
AskDelete "$L\pip"            "pip (Python cache)"
AskDelete "$L\pnpm"           "pnpm store"
AskDelete "$L\pnpm-cache"     "pnpm-cache"
AskDelete "$L\node-gyp"       "node-gyp"
AskDelete "$L\Cypress\Cache"  "Cypress (binary cache)"
AskDelete "$L\NuGet\v3-cache" "NuGet (.NET cache)"

# ---------- 2. Old / unused apps (CUSTOMIZE per user) ----------
Write-Host ""
Write-Host "=== 2) OLD APPS YOU NO LONGER USE ===" -ForegroundColor Cyan
AskDelete "$L\nomic.ai"          "nomic.ai / GPT4All"
AskDelete "$L\lm-studio-updater" "lm-studio-updater"

# ---------- 3. Browser caches (Chromium family) ----------
Write-Host ""
Write-Host "=== 3) BROWSER CACHES (does not remove logins/history) ===" -ForegroundColor Cyan
Write-Host "    IMPORTANT: close the browsers first." -ForegroundColor Red
$r = Read-Host "    Browsers closed? Clear their caches? (s/n)"
if ($r -eq 's') {
    ClearChromiumCache "$L\Google\Chrome\User Data"    "Chrome"
    ClearChromiumCache "$L\Microsoft\Edge\User Data"   "Edge"
    ClearChromiumCache "$L\BraveSoftware\Brave-Browser\User Data" "Brave"
    ClearChromiumCache "$L\Perplexity\Comet\User Data" "Comet (Perplexity)"
}

# ---------- 4. Packaged-app bundled VM (optional, e.g. Claude Desktop) ----------
Write-Host ""
Write-Host "=== 4) Packaged-app bundled VM (optional) ===" -ForegroundColor Cyan
Write-Host "    If you will UNINSTALL the app, skip this (uninstalling removes it)."
$vm = Get-ChildItem "$L\Packages" -Directory -Filter "Claude_*" -ErrorAction SilentlyContinue |
      ForEach-Object { Join-Path $_.FullName "LocalCache\Roaming\Claude\vm_bundles" } |
      Where-Object { Test-Path $_ } | Select-Object -First 1
if ($vm) { AskDelete $vm "Claude vm_bundles" }
else { Write-Host "  (no bundled VM found)" -ForegroundColor DarkGray }

# ---------- Result ----------
Write-Host ""
$freeAfter = [math]::Round((Get-PSDrive C).Free/1GB,1)
Write-Host "######  DONE  ######" -ForegroundColor Green
Write-Host "Free before:  $freeBefore GB"
Write-Host "Free now:     $freeAfter GB"
Write-Host "Reclaimed:    $([math]::Round($freeAfter - $freeBefore,1)) GB" -ForegroundColor Green
