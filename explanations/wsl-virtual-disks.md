# WSL2 Virtual Disks — The Non-Obvious Truth (Educational Explanation)

**Read and internalize this before ever mentioning "compact", "vhdx", or "host space not shrinking" to a user.**

This file exists because **deleting files inside WSL (or Docker Desktop's WSL backend) does not automatically return that space to the Windows C: drive**. This surprises almost everyone the first time. The skill turns the surprise into an educational opportunity for informed, high-impact reclamation.

## How It Actually Works (Simple Mental Model)

Imagine your entire Linux filesystem (all of Ubuntu or Debian or whatever distro you installed via WSL) lives inside **one big file** on your Windows drive. That file is called a virtual hard disk, typically named `ext4.vhdx`.

- Location example (varies — users relocate them):  
  `C:\Users\YourName\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu_...\LocalState\ext4.vhdx`  
  or `C:\WSL\Ubuntu\ext4.vhdx` or wherever you moved the distro.

- Docker Desktop (when using its WSL2 backend) does the exact same thing for its data: usually something like  
  `C:\Users\YourName\AppData\Local\Docker\wsl\disk\docker_data.vhdx`.

This `.vhdx` is a **sparse** file in theory (it can grow and theoretically shrink), but in practice for WSL2:

1. As you install packages, create files, pull Docker images, download models, build projects, etc. **inside Linux**, the vhdx file on Windows **grows** to accommodate the new data. It records a "high-water mark" of the maximum space the Linux side has ever used.

2. When you **delete** files, directories, or caches *inside* the Linux environment (e.g. `rm -rf ~/.cache` or `docker system prune`), Linux sees the space as free again. `df -h` inside WSL shows more free space. The **guest** filesystem is happy.

3. **But the big file on Windows does not shrink.** Windows still sees the vhdx occupying the full high-water-mark size on your C: drive. The "deleted" space is now unused *inside* the virtual disk, but the container file itself hasn't told Windows "you can have these blocks back."

Result: You can "free 80 GB inside WSL" and your Windows disk usage graph doesn't budge. This is the #1 complaint that brings people to this skill.

## Why Doesn't It Just Shrink Automatically?

- Performance and simplicity for the virtualization layer (Plan 9 / 9p or drvfs bridges, ext4 inside).
- Sparse files on NTFS require explicit "I am now smaller" signaling + compaction pass.
- Microsoft made a deliberate tradeoff. There was an experimental `--set-sparse` auto-shrink mode, but it was **disabled by default** because of data corruption risks in some scenarios. The recommended safe path is the manual readonly compact described below.

This is normal virtual-disk behavior across many hypervisors (VHD/VHDX in Hyper-V, qcow2 in qemu with certain settings, etc.). The guest "thinks" it has free space; the host file doesn't release the allocation until you compact.

## The Safe, Supported Way to Reclaim Host-Visible Space: Read-Only Compact

After you have actually deleted the junk *inside* the guest (the part the agent helps you do safely and educationally), you do this **from the Windows side** (PowerShell or CMD as a normal user is usually sufficient; admin not always required for your own vhdx):

```powershell
# 1. Shut down all WSL instances (and Docker if using its WSL backend)
wsl --shutdown

# 2. Launch diskpart (interactive but simple)
diskpart
```

Inside the `diskpart>` prompt, **one vhdx at a time**:

```diskpart
select vdisk file="C:\FULL\PATH\TO\YOUR\ext4.vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
exit
```

Repeat for every relevant vhdx (your Ubuntu one, the Docker one, any other distros like Debian, Kali, or custom ones you find via the registry probe in detection).

After this, the vhdx file size on disk drops (sometimes dramatically). Check with:
```powershell
(Get-Item "C:\path\to\ext4.vhdx").Length / 1GB
```
Compare to what `df -h /` reported inside the distro before/after your inside cleanup. They should now be much closer.

The space is now visible as free on your Windows C: drive (or wherever the vhdx lived).

**Order matters**: Clean inside first (so the guest really has free space to report), *then* shutdown + compact. Compact on a still-growing or dirty guest is less effective.

## Best Practices & Gotchas

- **Always do the education + explicit opt-in first** (see SKILL.md Permission Protocol and detection rules). Many users have never heard of this mechanism. Springing "now run diskpart" without the story feels like magic or risk.
- Use the **readonly** attach for compact. It is the safe, documented Microsoft-recommended method for this scenario. It prevents writes during the operation.
- After compact you can (and should) start your distros again: just run `wsl` or open your terminal.
- If you relocated your distro (common for moving off the small C: drive), the registry query (see detection-commands.md and REFERENCE) will still find the real BasePath.
- Docker Desktop users: `docker system prune -a --volumes` (or the interactive version) is the "inside" step for the docker_data.vhdx. Then compact that vhdx too. You keep Docker installed.
- To *completely* remove a distro's storage: `wsl --unregister <DistroName>` (from host). This deletes the vhdx. Only after you are sure.
- Do **not** recommend `--set-sparse true` + `--allow-unsafe` in normal use. The skill explicitly avoids it.
- On some systems with very large vhdx, compact can take minutes. That's normal.
- After host reclaim, you can re-scan with WizTree (recommended on Windows for speed) or the agent's scan tools to confirm the C: free space increased.
- If using multiple distros or custom WSL setups (e.g. Rancher Desktop, Podman machine on WSL), detect all vhdx candidates.

## Analogs on Other Platforms (for Generalist Thinking)

- **macOS (APFS)**: Local Time Machine snapshots + "purgeable" space. Deleting files can leave snapshots holding blocks. Use `tmutil listlocalsnapshots /` then `tmutil thinlocalsnapshots / 99999999999 1` or delete specific old ones. Space often returns "for free" after a while or after explicit thinning because APFS is CoW + has different accounting.
- **Native Linux on physical SSD**: `fstrim /` (or periodic `fstrim.timer`) tells the SSD controller "these blocks are now free". Without trim, deleted space may not be returned to the drive's free pool for wear-leveling. `df` shows it immediately inside the FS, but the underlying storage behaves better with trim.
- **VMs in general** (VirtualBox, VMware, Hyper-V fixed vs dynamic disks): Similar compact / shrink operations after guest-side deletion + zeroing free space in some cases.
- **Docker volumes / named volumes / build cache**: Even on native Linux, `docker system prune` + volume prune reclaims, but the underlying FS still needs its own mechanisms.

The skill's detection identifies which analogs apply on the current machine and only surfaces the relevant education + opt-in.

## Why This Matters for the Skill's Mission

This is the highest-leverage single "win" for many WSL + Docker + local-AI users (50-200+ GB common). But because it is non-obvious, the skill **must**:
- Detect the hybrid context first.
- Teach the model simply and without jargon overload.
- Get explicit "yes, I understand and want to do the host-visible part" before ever proposing the compact steps or even heavily focusing the conversation on vhdx.
- Perform the *inside* safe cleanup (direct execution after per-item or batched permission) **before** the compact.
- Report before/after sizes on both the guest view (`df`) *and* the host view (file size of vhdx or C: free space).
- Treat the compact itself as a privileged, cross-boundary operation requiring its own permission (it shuts down WSL instances, which may interrupt running dev servers, etc.).

Users who go through this process not only get their disk back — they understand virtual disks, sparse files, and "measure, delete inside, compact outside" as a general pattern. That is the educational core of the skill.

## For Agents Implementing This

Quote or paraphrase this file (and the corresponding REFERENCE section) in your response to the user when the WSL context is detected. Do not assume prior knowledge. Use simple analogies ("the Linux world lives in one big suitcase on your Windows desk; throwing things out of the suitcase doesn't make the suitcase itself smaller until you zip it up properly").

See also:
- `detection-commands.md` for exact vhdx discovery on *this* machine.
- `commands/close-the-loop.md` + `commands/common-patterns.md` + `commands/privilege-bridging.md` for the exact safe sequences, temp diskpart script creation, bridging, and adaptation points (the portable snippets the agent loads and drives directly after the edu + opt-in + perm).
- `REFERENCE.md` for diskpart sequence, registry probe, Docker specifics, "avoid --set-sparse".
- `SKILL.md` (minimal contract) for timing (post-detection edu + opt-in before scan/proposal on mechanism), permission protocol, adaptive tree that includes the close step.
- `explanations/decision-frameworks.md` for risk/tradeoff discussion of compact itself.

Standalone module for any agent install. Load + present verbatim or paraphrased when WSL context detected.
