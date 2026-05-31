# ==============================================================
#  limpieza-profunda.ps1  --  TEMPLATE (not run-as-is)
#
#  The agent (Claude) generates a PERSONALIZED copy of this after
#  scanning the machine: it keeps the helpers + universal caches and
#  fills the >>> PERSONALIZE <<< block with the user's CONFIRMED dead
#  apps from the scan. Save the result as cleanup-<user>.ps1.
#
#  Every block prompts (s/n) and reports GB freed. Touches nothing
#  system-level. Universal caches auto-skip if not present.
#  Run: powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\cleanup-<user>.ps1"
# ==============================================================

$L = $env:LOCALAPPDATA

function SizeGB($p) {
    if (-not (Test-Path $p)) { return 0 }
    try { return [math]::Round(((Get-ChildItem $p -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum)/1GB, 2) }
    catch { return 0 }
}

function AskDelete($path, $name) {
    if (-not (Test-Path $path)) { return }   # auto-skip what this machine doesn't have
    $gb = SizeGB $path
    Write-Host ""
    Write-Host "  $name : $gb GB" -ForegroundColor Yellow
    $r = Read-Host "    Delete? (s/n)"
    if ($r -eq 's') {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "    -> Deleted." -ForegroundColor Green
    } else { Write-Host "    -> Skipped." -ForegroundColor DarkGray }
}

# Clears ONLY the cache subfolders of a Chromium browser (keeps logins/history)
function ClearChromiumCache($userDataPath, $name) {
    if (-not (Test-Path $userDataPath)) { return }
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

# ---------- 1. Dev caches (universal, regenerate; absent ones auto-skip) ----------
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
AskDelete "$L\go-build"       "Go build cache"
AskDelete "$L\Yarn\Cache"     "Yarn cache"

# ---------- 2. Old / unused apps ----------
#  >>> PERSONALIZE <<<  Claude: add ONE AskDelete line per dead app the user
#  CONFIRMED in the interview. Use the real folder name from the scan.
#  Delete the examples below. Keep this empty if nothing was confirmed.
Write-Host ""
Write-Host "=== 2) OLD APPS YOU NO LONGER USE ===" -ForegroundColor Cyan
# Example shape (replace with the user's actual confirmed-dead apps):
#   AskDelete "$L\nomic.ai"          "GPT4All (old AI app)"
#   AskDelete "$L\lm-studio-updater" "LM Studio (uninstalled)"
#  >>> END PERSONALIZE <<<

# ---------- 3. Browser caches (Chromium family; absent ones auto-skip) ----------
Write-Host ""
Write-Host "=== 3) BROWSER CACHES (does not remove logins/history) ===" -ForegroundColor Cyan
Write-Host "    IMPORTANT: close the browsers first." -ForegroundColor Red
$r = Read-Host "    Browsers closed? Clear their caches? (s/n)"
if ($r -eq 's') {
    ClearChromiumCache "$L\Google\Chrome\User Data"              "Chrome"
    ClearChromiumCache "$L\Microsoft\Edge\User Data"             "Edge"
    ClearChromiumCache "$L\BraveSoftware\Brave-Browser\User Data" "Brave"
    ClearChromiumCache "$L\Vivaldi\User Data"                    "Vivaldi"
    ClearChromiumCache "$L\Perplexity\Comet\User Data"           "Comet (Perplexity)"
    #  >>> PERSONALIZE <<<  add any other Chromium browser found in the scan
}

# ---------- 4. Packaged-app bundled VMs (optional) ----------
#  Some Store/Electron apps ship a Linux VM (vm_bundles\*.vhdx). Uninstalling
#  the app removes it; this is only for apps the user keeps installed.
#  >>> PERSONALIZE <<<  point this at the bundled VM found in the scan, if any.
Write-Host ""
Write-Host "=== 4) Packaged-app bundled VM (optional) ===" -ForegroundColor Cyan
# Example:
#   $vm = Get-ChildItem "$L\Packages" -Directory -Filter "Claude_*" -EA SilentlyContinue |
#         ForEach-Object { Join-Path $_.FullName "LocalCache\Roaming\Claude\vm_bundles" } |
#         Where-Object { Test-Path $_ } | Select-Object -First 1
#   if ($vm) { AskDelete $vm "Claude vm_bundles" }

# ---------- Result ----------
Write-Host ""
$freeAfter = [math]::Round((Get-PSDrive C).Free/1GB,1)
Write-Host "######  DONE  ######" -ForegroundColor Green
Write-Host "Free before:  $freeBefore GB"
Write-Host "Free now:     $freeAfter GB"
Write-Host "Reclaimed:    $([math]::Round($freeAfter - $freeBefore,1)) GB" -ForegroundColor Green
