# ==============================================================
#  limpiar-residuales.ps1
#  Kills "tech debt" in AppData\Local:
#    A) curated list of confirmed-dead app folders
#    B) EVERY level-1 folder that is 100% empty (0 bytes)
#  Shows everything and asks before deleting.
#  Customize $dead per user before running.
#  Run: powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\limpiar-residuales.ps1"
# ==============================================================

$L = $env:LOCALAPPDATA

# --- A) Curated dead/old app folders (EDIT per user) ---
$dead = @(
    # 'com.voxidian.app', 'Terax', 'draw.io-updater', 'Honeygain',
    # 'DaVinci Resolve Welcome', 'Saints Row IV', 'EvilDead', 'lm-studio-updater',
    # 'realtimeboard-updater', 'crossover-updater', 'cron-web-updater',
    # 'StreamingVideoProvider', 'sshfs-win-manager-updater', 'termius-updater', 'obsidian-updater'
)

function SizeMB($p) {
    if (-not (Test-Path $p)) { return 0 }
    try { return [math]::Round(((Get-ChildItem $p -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum)/1MB, 1) }
    catch { return 0 }
}

Write-Host ""
Write-Host "######  RESIDUAL CLEANUP  ######" -ForegroundColor Cyan

# ===== PART A: confirmed-dead apps =====
Write-Host ""
Write-Host "=== A) Confirmed-dead app folders ===" -ForegroundColor Cyan
$toDelA = @()
foreach ($m in $dead) {
    $path = Join-Path $L $m
    if (Test-Path $path) { $toDelA += [PSCustomObject]@{ MB = (SizeMB $path); Name = $m } }
}
if ($toDelA.Count -gt 0) {
    $toDelA | Sort-Object MB -Descending | Format-Table -AutoSize
    $r = Read-Host "Delete these $($toDelA.Count) folders? (s/n)"
    if ($r -eq 's') {
        foreach ($x in $toDelA) { Remove-Item (Join-Path $L $x.Name) -Recurse -Force -ErrorAction SilentlyContinue }
        Write-Host "-> Dead apps removed." -ForegroundColor Green
    }
} else { Write-Host "  (none found / list empty - edit `$dead at top of script)" -ForegroundColor DarkGray }

# ===== PART B: empty (0-byte) level-1 folders =====
Write-Host ""
Write-Host "=== B) Empty (0-byte) folders in AppData\Local ===" -ForegroundColor Cyan
Write-Host "    (Microsoft/Windows folders are skipped for safety)"

$skip = @('Microsoft','Microsoft SDKs','PackageManagement','ElevatedDiagnostics',
          'Diagnostics','PeerDistRepub','Deployment','Temp','Packages','Comms',
          'ConnectedDevicesPlatform','VirtualStore','Programs','Google')

$empty = Get-ChildItem $L -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
    $skip -notcontains $_.Name -and
    (-not ($_.Name -like 'Microsoft*')) -and
    (((Get-ChildItem $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue) | Measure-Object).Count -eq 0)
}

if ($empty.Count -gt 0) {
    Write-Host "  Found $($empty.Count) empty folders:" -ForegroundColor Yellow
    $empty | Select-Object -ExpandProperty Name | Sort-Object | Format-Wide -Column 3
    $r = Read-Host "Delete all these empty folders? (s/n)"
    if ($r -eq 's') {
        foreach ($v in $empty) { Remove-Item $v.FullName -Recurse -Force -ErrorAction SilentlyContinue }
        Write-Host "-> $($empty.Count) empty folders removed." -ForegroundColor Green
    }
} else { Write-Host "  (no empty folders)" -ForegroundColor DarkGray }

Write-Host ""
Write-Host "######  DONE  ######" -ForegroundColor Green
