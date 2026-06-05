# Common Patterns — Universal Helpers for Direct Execution

These are building blocks used across all other command files. Agent: copy the relevant block, adapt, wrap in your execution calls. Always pair with measure/inspect from inspect-and-measure.md.

## 1. Safe Temp File Creation (for diskpart scripts, one-off command lists, etc.)
**Why**: diskpart /s requires a file. Avoids interactive prompts. Clean up after.
**Platform**: Windows / bridged from WSL. Use unique name with pid or timestamp.
**Safety**: Write to user-writable temp (not system), use after permission for the whole sequence.

```powershell
# From Windows host pwsh (or bridged)
$tmp = Join-Path $env:TEMP "ddc-compact-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$PID.txt"
@"
select vdisk file="C:\exact\path\to\ext4.vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
"@ | Set-Content -Path $tmp -Encoding ASCII
Write-Host "Wrote script to $tmp"
# ... later after use
Remove-Item $tmp -ErrorAction SilentlyContinue
```

```bash
# From WSL (bridge to write on host side or use /tmp if running diskpart via other means — rare)
# Prefer writing via powershell.exe bridge:
powershell.exe -NoProfile -NonInteractive -Command @"
\$tmp = Join-Path \$env:TEMP 'ddc-compact-xxx.txt'
@'
select vdisk file="..."
...
'@ | Set-Content \$tmp -Encoding ASCII
Write-Output \$tmp
"@
```

## 2. Before/After Measure + Human Report (Guest + Host)
Use before any batch/close, after.

**POSIX (Linux/WSL/mac inside guest)**:
```bash
echo "=== BEFORE ==="
df -h /   # or the target mount
du -sh {{TARGET_DIR}} 2>/dev/null || true

# ... action ...

echo "=== AFTER ==="
df -h /
du -sh {{TARGET_DIR}} 2>/dev/null || true
```

**Windows host (for host-visible, esp. after WSL compact)**:
```powershell
$before = (Get-PSDrive C).Free
# or for specific vhdx
$vhdx = "C:\path\to\ext4.vhdx"
$b = (Get-Item $vhdx -ErrorAction SilentlyContinue).Length
# after
$a = (Get-Item $vhdx).Length
Write-Host "VHDX delta: $([math]::Round(($b-$a)/1GB,2)) GB"
$afterFree = (Get-PSDrive C).Free
Write-Host "C: free increased by $([math]::Round(($afterFree - $before)/1GB,2)) GB"
```

**Hybrid report (agent surfaces both views)**:
"Inside guest: / went from 78% (120G used) to 62% (85G used). Host C: free +62 GB after compact (vhdx shrank 68 GB)."

## 3. Auto-Skip Absent + Conditional Run
```bash
# POSIX
for p in ~/.npm ~/.cache/uv ...; do
  if [ -e "$p" ]; then
    sz=$(du -sh "$p" 2>/dev/null | cut -f1)
    echo "Would act on $p ($sz)"
    # after perm: rm -rf "$p" or the prune_cmd
  fi
done
```

```powershell
# Windows
foreach ($p in @("$env:LOCALAPPDATA\npm-cache", ...)) {
  if (Test-Path $p) {
    # size + ask + Remove-Item -Recurse -Force
  }
}
```

## 4. Human-Readable Size (simple, no deps)
POSIX (in scripts or one-liner):
```bash
human() { du -sh "$1" 2>/dev/null | cut -f1; }
```

Python (reclaim.py uses this style) or just rely on `du -sh` output.

## 5. Safe Recursive Delete with Confirmation Echo
```bash
# After perm, for a resolved {{PATH}}
echo "Deleting {{PATH}} (measured $(du -sh {{PATH}} 2>/dev/null | cut -f1) ) ..."
rm -rf "{{PATH}}" && echo "Done." || echo "Partial error (some locked?)"
```

PowerShell equivalent uses -Force -Recurse, with try/catch in full script.

## 6. Empty 0-Byte Folder Sweep Pattern (Generic Residuals)
See dedicated empty-sweeps.md for full safe lists + logic.
Core:
```bash
find ~ -maxdepth 2 -type d -empty 2>/dev/null | grep -vE '(\.git|node_modules|target|Microsoft)' | head -20
# then after list + perm: xargs rm -rf or loop with rmdir
```

PowerShell version in scripts/limpiar-residuales.ps1 uses Get-ChildItem + Measure count==0 + skip list.

## 7. Graceful Degradation + || true
Every probe/prune should tolerate absence:
`cmd 2>/dev/null || echo "CMD_UNAVAILABLE_OR_FAILED"`
`sudo -n cmd || echo "NEEDS_PASS_OR_NO_SUDO"`

This is data for context.

## 8. Batch Low-Risk Green with Single Perm
After one edu + "OK to clear all these regenerable (total 4.2 GB from catalog green)?"
Then for each resolved: run the prune or rm block, collect deltas.

## Cross-Refs
- Full safety inspect: `inspect-and-measure.md`
- Privilege/bridge: `privilege-bridging.md`
- Catalog often suggests the inner prune_command; wrap it with these patterns.
- For WSL close: combine with `close-the-loop.md`

Agent: these patterns appear inline in your direct tool calls or in small emitted fallbacks. They make every run consistent and safe.
