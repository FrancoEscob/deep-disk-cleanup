# ============================================================
#  scan-disco.ps1  -  Disk space diagnostic (READ ONLY) — REFERENCE / FALLBACK
#  Deletes nothing. Shows what is taking up space.
#
#  ROLE IN THE SKILL (minimal reliance on generation; direct primary): Safe reference impl + standalone helper.
#  In primary agent flow (see SKILL.md minimal powerful principles + adaptive decision tree): agent performs
#  env detection first, *loads catalog/targets.json* (data-driven core w/ rich metadata for cat+edu+prune), then
#  **uses its *own* tools for live scanning + DIRECT EXECUTION after explicit permission**.
#  This script used as:
#  - Manual diagnostic (no agent; illustrative).
#  - Rare audit/ref (read/adapt; populate *only* confirmed catalog entries + live authorized *this run*).
#  - Fallback (direct impossible or user *explicitly* requests runnable artifact).
#  NEVER default delivery.
#
#  Catalog = master source of portable targets, 🟢🟡🔴, why/decision/safer/tradeoff, recommended cmds.
#  Scripts demonstrate patterns (dynamic top-folder scans powerful on Windows; agent emulates in direct or tiny emit).
#
#  Run (standalone): powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\scan-disco.ps1"
#  See SKILL.md, catalog/, REFERENCE.md, detection-commands.md, explanations/, and commands/ (the rich portable safe command reference library of cross-platform snippets, helpers, and patterns — agent reads specific .md, adapts live paths from detection/catalog, invokes directly via tools after permission) for the
#  full modern generalist direct-execution educational skill.
#  This file is a reference for Windows PowerShell dynamic scanning patterns.
# ============================================================

function Get-FolderSizeGB($path) {
    try {
        $s = (Get-ChildItem $path -Recurse -File -Force -ErrorAction SilentlyContinue |
              Measure-Object Length -Sum).Sum
        return [math]::Round($s / 1GB, 2)
    } catch { return 0 }
}

Write-Host ""
Write-Host "=== DISK SPACE C: ===" -ForegroundColor Cyan
Get-PSDrive C | Select-Object @{N='Used_GB';E={[math]::Round($_.Used/1GB,1)}},
                              @{N='Free_GB';E={[math]::Round($_.Free/1GB,1)}} |
    Format-Table -AutoSize

Write-Host "=== TOP 15 folders in AppData\Local (app caches) ===" -ForegroundColor Cyan
Get-ChildItem "$env:LOCALAPPDATA" -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    [PSCustomObject]@{ GB = (Get-FolderSizeGB $_.FullName); Folder = $_.Name }
} | Sort-Object GB -Descending | Select-Object -First 15 | Format-Table -AutoSize

Write-Host "=== TOP 12 folders in the user profile ===" -ForegroundColor Cyan
Get-ChildItem $env:USERPROFILE -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    [PSCustomObject]@{ GB = (Get-FolderSizeGB $_.FullName); Folder = $_.Name }
} | Sort-Object GB -Descending | Select-Object -First 12 | Format-Table -AutoSize

Write-Host "=== KNOWN JUNK SPOTS (illustrative — master in catalog/targets.json) ===" -ForegroundColor Yellow
Write-Host "    (See catalog/ for the full data-driven list with education metadata. Agent uses catalog + this style of dynamic top-N scan.)" -ForegroundColor DarkGray
[PSCustomObject]@{ GB = (Get-FolderSizeGB "$env:LOCALAPPDATA\Temp"); What = "User Temp (deletable)" }
[PSCustomObject]@{ GB = (Get-FolderSizeGB "$env:USERPROFILE\Downloads"); What = "Downloads (review)" } |
    Format-Table -AutoSize

Write-Host "=== TOP 20 largest files in the profile ===" -ForegroundColor Cyan
Get-ChildItem $env:USERPROFILE -Recurse -File -Force -ErrorAction SilentlyContinue |
    Sort-Object Length -Descending | Select-Object -First 20 |
    Select-Object @{N='GB';E={[math]::Round($_.Length/1GB,2)}}, FullName |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Done. Screenshot or paste the output back." -ForegroundColor Green
Write-Host "TIP: for a full-disk visual map, install WizTree (scans the MFT in seconds)." -ForegroundColor DarkGray
