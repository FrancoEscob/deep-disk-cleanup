# Empty Folder & Residual Sweeps (Generic Tech Debt Cleanup)

Useful for "AppData\Local junk" residuals after uninstalls, temp dirs, empty package caches left behind, etc. Low-regret but still measure + list + perm. Generic win after the big targeted items.

## Safety Rules (Baked Into Patterns)
- **Never mass-delete without showing the list** (or at least count + sample + total size).
- **Strong skip lists** for known system / injected / dangerous names. Evolve the lists (Microsoft*, Packages, etc.).
- Limit depth (level-1 or level-2 under AppData/Local or ~/Library or /tmp variants).
- 0-byte check: a dir with only empty subdirs may still be "empty" for practical purposes, but start with no files.
- On WSL: /mnt/c/... deletes are host-visible immediately (good for Windows Downloads residuals, but watch locks).
- After sweep: re-scan the parent to show impact.

## POSIX Version (Linux/WSL/mac guest or native)
```bash
# Example: empty dirs under home (shallow)
find ~ -maxdepth 2 -type d -empty 2>/dev/null \
  | grep -vE '(\.git|node_modules|target|__pycache__|\.cargo|\.rustup|Microsoft|Packages|Program|AppData|Library/Caches)' \
  | head -30

# Under AppData equiv on WSL (/mnt/c/Users/.../AppData/Local) — be careful, slow if deep
# Prefer running equivalent from host PowerShell when possible.
```

For /tmp stale (careful — some apps use it live):
```bash
find /tmp -maxdepth 1 -type d -empty -mtime +7 2>/dev/null | head -10
```

## Windows / PowerShell (Primary for AppData\Local residuals)
See the reference impl in `scripts/limpiar-residuales.ps1` (Part B). Core logic:

```powershell
$L = $env:LOCALAPPDATA
$skip = @('Microsoft','Microsoft SDKs','PackageManagement','ElevatedDiagnostics',
          'Diagnostics','PeerDistRepub','Deployment','Temp','Packages','Comms',
          'ConnectedDevicesPlatform','VirtualStore','Programs','Google',
          'NVIDIA','AMD','Intel','Dropbox','OneDrive')   # extend as needed

$empty = Get-ChildItem $L -Directory -Force -EA SilentlyContinue | Where-Object {
    $name = $_.Name
    ($skip -notcontains $name) -and
    (-not ($name -like 'Microsoft*')) -and
    (-not ($name -like 'Package*')) -and
    ( (Get-ChildItem $_.FullName -Recurse -File -Force -EA SilentlyContinue | Measure-Object).Count -eq 0 )
}

if ($empty.Count -gt 0) {
    Write-Host "Found $($empty.Count) empty level-1 folders under LOCALAPPDATA:"
    $empty | Select -Expand Name | Sort | Format-Wide -Column 4
    # total size is 0 by definition, but parent may shrink slightly from metadata
    $r = Read-Host "Delete all these empty folders? (s/n)"
    if ($r -eq 's') {
        $empty | ForEach-Object { Remove-Item $_.FullName -Recurse -Force -EA SilentlyContinue }
    }
}
```

## Curated Dead-App Residuals (Part A in the script)
```powershell
$dead = @(
    # Populated ONLY with names the user explicitly confirmed dead in this run's interview/scan
    # e.g. 'nom ic.ai', 'lm-studio-updater', 'old-game-residual'
)
foreach ($m in $dead) {
    $p = Join-Path $L $m
    if (Test-Path $p) {
        $sz = ... measure ...
        # AskDelete or direct after batch perm
    }
}
```

## macOS Analog
```bash
# Empty under ~/Library (but many are intentional; be selective)
find ~/Library -maxdepth 2 -type d -empty 2>/dev/null | grep -vE '(Caches|Containers|Saved Application State|Microsoft)' | head
```

## Agent Usage
- Run as a "small generic win" after the high-confidence big items (or as part of green batch if user wants exhaustive).
- Always surface the actual list or count + examples + "these are empty, no data loss".
- Combine with catalog "empty residual" thinking (no static entry, but live pattern).
- On hybrid: running the PS version from host (or bridged) is better for /mnt/c paths.
- After delete: note that space reclaimed is usually tiny per folder (directory entries), but hundreds of them add up + reduce visual clutter.

## Reference Implementations
- `scripts/limpiar-residuales.ps1` : full working example with skip list + curated dead + prompts + size (even though 0).
- `scripts/` headers point back to catalog and this library for patterns.

## Gotchas
- Some "empty" dirs are recreated immediately by launchers/services on next login (e.g. certain updaters). Note it.
- Packages\ folder on Windows contains Store app data — heavily skipped.
- Never include "Temp" in auto-delete without age + list (user may have active downloads).

This is the "generic small" cross-cutting in SKILL.md. Safe, satisfying, educational (user learns what leaves junk behind).
