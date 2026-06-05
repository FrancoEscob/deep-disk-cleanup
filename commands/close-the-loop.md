# Close-the-Loop Platform Steps (Reclaim Host-Visible / Underlying Storage)

**MANDATORY PRECONDITIONS (non-negotiable per SKILL.md + education mandates)**:
- Detection must have identified the context (WSL2 vhdx, Docker WSL backend, mac APFS snapshots, native SSD, etc.).
- Full educational explanation delivered (load `explanations/wsl-virtual-disks.md` + relevant REFERENCE + platform-notes sections; paraphrase simply with analogy).
- Explicit opt-in via AskUserQuestion for the mechanism ("do you want host-visible reclamation via compact / thinning / trim in the plan?").
- Inside-guest cleanup performed first (so guest reports real free space).
- **Separate dedicated permission** for the close step itself (impact: "will shutdown WSL sessions for minutes", "IO heavy on large FS", "removes old snapshots you can't easily recover").
- Only then: drive directly with these sequences.

These are the "finish the job" analogs:
- WSL/Docker: readonly compact of .vhdx so host NTFS sees the shrinkage.
- macOS: thin local snapshots / purgeable.
- Native Linux SSD: fstrim tells controller the blocks are reusable.
- Others: analogous shrink after guest delete + (sometimes) zero free space.

## WSL2 / Docker WSL Backend — Readonly Compact (Highest Value)
**Full sequence** (agent drives as much as possible).

1. wsl --shutdown (from host or bridge; affects all distros + Docker if WSL backend).

```powershell
# From Windows host pwsh (preferred) or bridged via powershell.exe from inside WSL
wsl --shutdown
Write-Host "WSL shut down. All sessions paused."
```

2. For **each** discovered vhdx (from detection registry probe + common Docker loc; one at a time):

```powershell
# Build minimal diskpart script (use common-patterns.md temp creation)
$vhdx = "C:\Users\YourName\AppData\Local\Packages\... \ext4.vhdx"   # <-- ADAPT from live detection
$tmpScript = Join-Path $env:TEMP "ddc-vhdx-compact-$(Get-Date -Format yyyyMMddHHmmss).txt"

@"
select vdisk file="$vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
"@ | Set-Content -Path $tmpScript -Encoding ASCII

Write-Host "Running readonly compact on $vhdx (script: $tmpScript) ..."
diskpart /s $tmpScript

Remove-Item $tmpScript -EA SilentlyContinue
```

Measure the file size change:
```powershell
$after = (Get-Item $vhdx).Length / 1GB
Write-Host "New vhdx size: $after GB"
```

Repeat for docker_data.vhdx if present and pruned inside.

3. Restart: just `wsl` or open terminal; distros come back.

**From inside WSL (bridge everything)**:
Use `powershell.exe -NoProfile -NonInteractive -Command "..."` for wsl --shutdown and the diskpart script write + invoke. Detection will have confirmed HOST_PWSH_REACHABLE.

**Safety notes**:
- readonly attach is the documented safe Microsoft way.
- Order: inside delete first, then compact.
- Large vhdx: can take several minutes — normal.
- After: compare guest df used vs new vhdx size (they converge).
- Host C: (or the drive containing the vhdx) free space increases.
- Never recommend --set-sparse + --allow-unsafe in this skill.

**Docker Desktop specific**: `docker system prune -a --volumes` (with volume caution) is the "inside" for docker_data.vhdx, then compact that vhdx. You keep Docker.

## macOS — Local Snapshot Thinning (APFS Purgeable)
After detection + edu on snapshots + opt-in + inside cleanup.

```bash
# List first (show user)
tmutil listlocalsnapshots /
tmutil listlocalsnapshotdates / | head

# Thin (safe, conservative)
tmutil thinlocalsnapshots / 99999999999 1

# Or delete specific old ones
tmutil deletelocalsnapshots 2024-...
```

Measure with `diskutil apfs list` or `df` + purgeable grep. Space often surfaces after thin + time/reboot.

## Native Linux (SSD) — fstrim
```bash
# After priv check + perm (IO can be noticeable)
sudo -n fstrim -v / || echo "fstrim needs root or not supported"
# For all mounts: sudo fstrim -av
```

`lsblk --discard` to confirm support. df shows immediately; trim makes SSD controller happy long-term.

## Other Analogs
- Inside VM (VirtualBox/VMware etc.): after guest deletes, zero free space (sdelete on Windows guest, or `dd if=/dev/zero ...` then delete the zero file on Linux guest) + host-side shrink/compact of the VM disk file. Detection + edu first.
- Btrfs/zfs/LVM snapshots: list + delete specific snapshots (different commands).
- APFS on non-mac: similar thin.

## Agent Responsibilities for Close Steps
- Surface the simple explanation + opt-in **right after detection** for the mechanism (before heavy focus on scan or inside proposals).
- Separate perm step right before executing the shutdown/compact/thin/trim.
- Drive via tools (bridge as needed; write temp diskpart script safely; invoke).
- Re-measure on both sides, report actual deltas ("host C: now has +XX GB free").
- If direct blocked (e.g. no bridge, needs elevation that can't be scripted): guide user with the exact steps (or emit tiny one-purpose script containing only the authorized vhdx paths + the exact diskpart block).
- Re-offer restart WSL / remount after.

See:
- `explanations/wsl-virtual-disks.md` (quote heavily)
- `detection-commands.md` (the exact registry + common paths discovery that feeds the $vhdx vars)
- `privilege-bridging.md` for how to drive from inside vs host
- `common-patterns.md` for the temp script + measure helpers
- `SKILL.md` adaptive tree node 3 + Permission Protocol (granularity for cross-boundary)

These close steps are what turn "I deleted 80 GB inside" into "my C: drive actually has 80 GB more free". Education + permission makes it trustworthy.
