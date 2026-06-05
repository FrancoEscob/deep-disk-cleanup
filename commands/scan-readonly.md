# Scan & Read-Only Discovery Commands

**Always read-only first.** Use these (or native equivalents) for initial df, targeted catalog path sizing, broader top-N discovery, docker df, etc. **Never cross FS expensively** (e.g. avoid deep du over /mnt/c from inside WSL — use host PowerShell instead).

Context-native:
- Inside POSIX (Linux/WSL/mac guest or native): bash/zsh + df/du/findmnt/diskutil/tmutil
- Windows host: PowerShell (Get-ChildItem, Get-PSDrive, etc.)
- Bridge as needed (see privilege-bridging.md)

## Core Volume Usage (Level 1, always)
```bash
df -h
df -hT 2>/dev/null || df -T 2>/dev/null || true
# Detailed FS
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,RO 2>/dev/null | cat || true
findmnt -n -o TARGET,SOURCE,FSTYPE,OPTIONS / 2>/dev/null || true
```

```powershell
Get-PSDrive -PSProvider FileSystem | Format-Table -AutoSize
Get-Volume | Select-Object DriveLetter, SizeRemaining, Size, FileSystem | Format-Table
```

macOS:
```bash
diskutil list
diskutil info / | grep -E 'Container|APFS|Snapshot|Capacity|Free|Used'
```

## Targeted Catalog Path Sizing (after resolving paths from catalog/targets.json for current context)
```bash
# For each resolved existing path from green/yellow catalog entries
du -sh ~/.npm 2>/dev/null || true
du -sh ~/.cache/uv ~/.local/share/pnpm 2>/dev/null || true
# mac
du -sh ~/Library/Caches 2>/dev/null || true
```

PowerShell targeted (faster for known):
```powershell
function Get-FolderSizeGB($path) {
  if (-not (Test-Path $path)) { return 0 }
  try {
    $s = (Get-ChildItem $path -Recurse -File -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
    [math]::Round($s / 1GB, 2)
  } catch { 0 }
}
Get-FolderSizeGB "$env:LOCALAPPDATA\npm-cache"
```

## Broader Live Discovery (Top Consumers in Home / AppData / Library)
POSIX (safe depth; skip expensive):
```bash
# Top 15 under home (limit depth or use --max-depth=3 on GNU du)
du -ah ~ --max-depth=2 2>/dev/null | sort -rh | head -20

# Or find + du for speed on some systems
find ~ -maxdepth 3 -type d -exec du -sh {} + 2>/dev/null | sort -rh | head -15
```

Windows (AppData/Local is gold for dev bloat):
```powershell
Get-ChildItem "$env:LOCALAPPDATA" -Directory -Force -EA SilentlyContinue |
  ForEach-Object { [PSCustomObject]@{ GB = (Get-FolderSizeGB $_.FullName); Name = $_.Name } } |
  Sort-Object GB -Descending | Select-Object -First 20 | Format-Table -AutoSize
```

macOS Library (use du or recommend DaisyDisk):
```bash
du -sh ~/Library/Caches/* ~/Library/Application\ Support/* 2>/dev/null | sort -rh | head -15
```

## Docker / Container Usage (always run if docker present)
```bash
docker system df -v 2>/dev/null || docker system df 2>/dev/null || echo "docker present but df failed"
# Full breakdown for interview
```

## IDE Remotes, Toolchain Markers, AI Stores (quick existence + size)
```bash
ls -1d ~/{.cursor-server,.vscode-server,.zed_server,.ollama,.cache/huggingface,.rustup/toolchains} 2>/dev/null | xargs -I {} du -sh {} 2>/dev/null || true
```

## Filesystem / Reclamation Mechanics Probes (trim, snapshots — Level 2)
```bash
# Linux/WSL
findmnt -n -o FSTYPE,OPTIONS /
lsblk --discard 2>/dev/null | cat || true
fstrim -v / --dry-run 2>/dev/null || echo "fstrim dry-run unavailable or needs root"

# macOS snapshots (huge hidden)
tmutil listlocalsnapshots / 2>/dev/null | cat || echo "no tmutil snapshots"
tmutil listlocalsnapshotdates 2>/dev/null | head -5 || true
diskutil apfs list 2>/dev/null | grep -i purgeable || true
```

## Privilege / Tool Presence (affects what you can execute later)
```bash
id -u
sudo -n true 2>/dev/null && echo "SUDO_NOPASS" || echo "SUDO_NEEDS_PASS"
command -v apt brew docker journalctl fstrim tmutil diskpart wsl 2>/dev/null || true
```

## Windows Host WSL + VHDX Discovery (from host or bridged — see detection-commands.md for full registry)
```powershell
wsl --list --verbose 2>$null || echo "no wsl or no distros"
# LXSS registry for exact BasePath + ext4.vhdx candidates (critical for close-the-loop)
Get-ChildItem -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -EA SilentlyContinue |
  ForEach-Object {
    $d = $_.GetValue('DistributionName')
    $b = $_.GetValue('BasePath') -replace '^\\\\\?\\',''
    if ($b) { "WSL_VHDX:$d | $b\\ext4.vhdx" }
  }
# Docker Desktop common
$dv = "$env:LOCALAPPDATA\Docker\wsl\disk\docker_data.vhdx"
if (Test-Path $dv) { "DOCKER_VHDX:$dv" }
```

## Recommendations if Slow
If no `ncdu`, `dust`, `gdu`, `baobab`, `duf`, `WizTree` (Windows — recommend strongly on host for full visual MFT scan in seconds):
```bash
command -v ncdu dust gdu 2>/dev/null || echo "Consider installing one for interactive viz on future runs."
```

## Agent Adaptation Notes
- Resolve catalog paths first using detected context (WSL ~ vs Windows %LOCALAPPDATA%, /mnt/c for host paths visible from guest).
- Only size existing paths (auto-skip).
- For live unknowns (abandoned projects): use top-N + mtime signals + frameworks from explanations/decision-frameworks.md.
- Record sizes + rough contents (ls -1 | head) for the interview step.
- After any action: re-run the exact same sizing commands for delta report.

See `common-patterns.md` for before/after wrapper, `inspect-and-measure.md` for pre-action safety, `docker-specific.md` for more docker.

These commands are the "measure first" half of "Measure-inspect-confirm-report-iterate".
