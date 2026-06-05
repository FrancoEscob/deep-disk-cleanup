# Platform Notes — Reclamation Mechanics, Gotchas, and Safe Commands by OS/Context

This is shared deep knowledge for the agent. Quote relevant sections when the detected context matches. Keep it high-level and educational; the live detection + REFERENCE catalog supply the exact current targets.

## Windows (Native Host, PowerShell / CMD Context)

- Primary visibility tool for full picture: **WizTree** (free, reads MFT directly, scans 500GB+ in seconds). Recommend it when agent is on Windows host and user wants visual map. Agent can still do PowerShell folder-size scans for targeted areas.
- User profile bloat lives mostly in `%LOCALAPPDATA%` (AppData\Local) and `%APPDATA%`. `Get-PSDrive C` for overall.
- Safe user-writable areas: everything under user profile except explicit 🔴.
- Uninstall properly: Settings → Apps (or winget / choco). Deleting the Program Files folder leaves registry, Start menu, and updater cruft.
- Packaged / Store / Electron apps (Claude Desktop, some AI tools): their `Packages\<App>_<hash>` under LocalCache can contain bundled Linux VMs (`vm_bundles\*.vhdx`). Uninstalling the app via Settings removes the whole tree.
- For cross-WSL: agent running in host pwsh can directly invoke `wsl --shutdown`, `wsl --list`, registry probes, and `diskpart /s script.txt` for compact. This is powerful for direct execution.
- Privilege: standard user is fine for own profile + own WSL vhd xs. Elevation needed for some system clean (e.g. WinSxS cleanup is special "Disk Cleanup" tool or DISM, not raw delete).
- NTFS specifics: deleted files go to Recycle Bin (bypass with Shift or direct Remove-Item -Force). No trim equivalent the user usually runs.

## Windows + WSL2 Hybrid (the highest-value context for this skill)

- See the dedicated `explanations/wsl-virtual-disks.md` for the full story and compact procedure. Detection must have triggered the education + opt-in.
- Inside WSL the world looks like normal Linux (ext4). `df -h /` shows the guest view of used/free *inside the virtual disk*.
- From WSL you see Windows drives at `/mnt/c`, `/mnt/d` etc. (drvfs). Deleting something under `/mnt/c/Users/you/Downloads` affects the host *immediately* (no compact needed). These are good candidates but be careful with locks (files open in Windows Explorer or apps).
- `/usr/lib/wsl` is injected by Windows — never touch from inside.
- To affect the host C: free space for WSL data, you must do inside cleanup + host compact.
- Agent options for directness:
  - If agent shell is inside WSL: great for `rm`, `docker system prune`, apt clean, etc. For compact, bridge with `powershell.exe ...` for `wsl --shutdown` and for writing a diskpart script + invoking `diskpart /s ...`.
  - If agent shell is on Windows host: can drive everything, including asking user to confirm inside-WSL deletes if needed (or use `wsl -d Ubuntu -- bash -c 'rm -rf ...'` for direct inside actions from host!).
- Common relocated stores: users move the vhdx off C: to D: or external for space. Detection's registry probe finds them regardless.
- Docker Desktop WSL backend: its data is a separate vhdx. Prune inside Docker, compact the docker vhdx.

## Native Linux (Desktop, Server, VM — No WSL Layer)

- `df -h`, `du -sh`, `ncdu` / `dust` / `gdu` for interactive viz.
- After deletes on SSD: run `sudo fstrim -v /` (or `-a` for all). This is the analog that makes the underlying storage "see" the freed blocks. The FS itself (`df`) shows the space immediately.
- Package managers: `sudo apt autoremove --purge && sudo apt clean` (Debian/Ubuntu), equivalents for dnf, pacman, zypper. `journalctl --vacuum-size=100M --vacuum-time=2weeks`.
- User caches in `~/.cache`, `~/.local/share`, `~/.npm` etc. — same 🟢/🟡 as everywhere.
- If this Linux is *inside* a VM (VirtualBox, VMware, UTM, etc.): the VM's virtual disk file on the *host* may need its own compact/shrink step after guest-side deletion + zero-fill free space in some tools. Detection should note "linux-inside-vm?" via user or hypervisor markers and trigger analogous education.
- Snapshots / LVM / btrfs / zfs subvolumes: extra care; list snapshots first (`lvdisplay`, `btrfs sub list`, `zfs list -t snapshot`). Deleting files inside a subvol doesn't free the parent snapshot.
- Privilege: sudo is common; agent prefers nopass or guides the user for one-time commands.

## macOS (Darwin / APFS)

- Primary tools: `df -h`, `du -sh ~/*`, `diskutil`, `tmutil`, DaisyDisk or GrandPerspective for visuals (recommend when agent is local on mac).
- Big hidden consumer: **local Time Machine snapshots**. `tmutil listlocalsnapshots /` (or `listlocalsnapshotdates`). They can hold many GB of "purgeable" space. Safe to thin: `tmutil thinlocalsnapshots / 99999999999 1` (or delete specific old ones with `tmutil deletelocalsnapshots <date>`).
- After delete, space may not appear instantly due to purgeable accounting and snapshots. Thinning + waiting or restart often surfaces it.
- Caches: `~/Library/Caches`, `~/Library/Application Support` (some apps), `~/Library/Logs`. Browser caches similar.
- Xcode / iOS sims / derived data: huge, often safe (🟡 if user still does iOS dev).
- Brew: `brew cleanup`, `brew autoremove`.
- No WSL/vhdx, but container backends (Docker Desktop on mac uses its own VM, Lima/colima, OrbStack) have their own disk images that may need prune + shrink.
- SIP / protected locations: agent must not propose touching `/System` etc.
- Privilege: `sudo` for system, but most user bloat is in home/Library.
- APFS is copy-on-write + has snapshots; the "compact" analog is snapshot management + letting the FS coalesce.

## Docker (Regardless of Host)

- `docker system df` and `docker system df -v` to see images, containers, volumes, build cache.
- Safe reclaim while keeping Docker: `docker system prune -a --volumes -f` (the `-a` removes unused images; volumes too — be careful if user has important named volumes).
- For full reset of Docker data (keeps the app): on WSL-backend it's the docker_data.vhdx compact after prune; on native it's the underlying FS after prune.
- To remove Docker entirely: proper uninstall + (on WSL) `wsl --unregister docker-desktop`.
- Inside containers themselves: cleanup is limited to what the container FS allows; the interesting space is usually the Docker data dir on the host/VM.

## General Cross-Cutting Gotchas (All Platforms)

- **Measure first, always**: `du`/`df` or platform equivalent *before* and *after* any action the agent takes or recommends. Report delta in guest view and (when relevant) host-visible view.
- **Inspect targets**: Recent mtime, open handles (`lsof`, `Get-Process -IncludeUserName`, `handle.exe` on Windows), running services that may recreate the dir immediately.
- **Do not cross FS boundaries blindly** with du: on WSL `du` over /mnt/c is extremely slow; use host tools instead.
- **0-byte / empty folder sweeps**: Useful generic cleanup for residual AppData/Local junk (see scripts/ for example implementation). Skip known system dirs (Microsoft*, etc.).
- **Shell rc / PATH cleanup**: If you remove a toolchain (Rust, nvm, etc.) that the user confirmed is dead, also offer to comment out or remove the sourcing lines in .zshrc/.bashrc/.profile/.zprofile etc. so future shells don't error. This is a separate small permissioned edit step.
- **Generated artifacts vs source**: In project dirs, `node_modules`, `target`, `build`, `.next`, `dist` are usually regenerable if the project source is still there (`package.json` + lockfile or `Cargo.toml`). Abandoned projects where the source itself is the bloat (giant ISOs checked in years ago) are different.
- **Backups**: "Always have backups of anything precious." The skill states this; the agent reminds for high-regret items (irreplaceable personal data, not caches).
- **Audit / fallback**: When direct execution isn't possible or user wants a reviewable artifact, the `scripts/` directory contains safe, well-commented reference templates (PowerShell and shell) and the `commands/` directory is the primary library of granular reusable snippets/patterns (agent reads e.g. close-the-loop.md or empty-sweeps.md, adapts, executes directly via tools). The agent can copy + lightly personalize from commands/ + scripts (fill only confirmed targets) and write the result to the user's machine for them to inspect/run. This is secondary to direct `rm` etc. after permission.

## How the Agent Uses These Notes

After detection (L1+L2), load matching sections from this + deeper WSL module, present relevant edu (not everything at once), activate only corresponding branches in the Adaptive Decision Tree (see SKILL.md minimal contract + tree).

Example: macOS + large purgeable via tmutil detected → brief edu on snapshots holding deleted data + opt-in for thinning in plan → if yes, fold into scan/interview/execution/close.

These + detection-commands.md + catalog (targets.json) = portable generalist knowledge base. No machine-specific paths here.

Update on platform changes (WSL evo, APFS, Docker drivers, etc.).
