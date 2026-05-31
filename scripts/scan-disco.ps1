# ============================================================
#  scan-disco.ps1  -  Disk space diagnostic (READ ONLY)
#  Deletes nothing. Shows what is taking up space.
#  Run: powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\scan-disco.ps1"
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

Write-Host "=== KNOWN JUNK SPOTS ===" -ForegroundColor Yellow
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
