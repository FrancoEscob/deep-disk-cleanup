# Environment Detection Commands & Interpretation Rules

**This document is part of the binding skill contract (see SKILL.md minimal powerful principles + adaptive decision tree).** Every invocation **MUST** begin with thorough, active Environment Detection. The agent executes the commands below (using `run_terminal_command` / equiv tools), interprets live output, resolves ambiguities by asking the user (via `AskUserQuestion` or equiv) **only** when unclear/contradictory/missing, and builds internal context model to drive all subsequent adaptive behavior per the tree.

**Never skip detection. Never assume platform or context** (e.g. do not default to "run the .ps1" or "do the diskpart compact" — conditional on detection + edu + opt-in + perm only).

Detection is **per-invocation and live** on the machine where the agent is operating right now. It enables true generality across:
- Pure Windows (host, no WSL)
- Windows host + WSL2 (hybrid — the classic value case)
- Native Linux (bare metal or VM)
- WSL from inside (the guest view)
- macOS (native or containerized)
- Inside Docker / other containers (Linux or otherwise)
- Mixed privilege, relocated stores, etc.

After detection, the agent explicitly summarizes key findings to the user (high-level, no command spam) before moving on, and uses the context to select the right scanning methods, educational modules, safe commands, and reclamation strategies.

## Agent Execution Rules for Detection

- **Use your tools directly**: Run commands via the agent's execution capabilities. Capture full stdout/stderr.
- Prefer safe, read-only, non-interactive forms. Append `2>/dev/null || true`, `|| echo "CMD_FAILED"`, timeouts where supported.
- Run in logical batches; one or a few tool calls can cover multiple `;` or `&&` separated commands.
- Cross-shell awareness: If current shell is bash/zsh/fish inside WSL/Linux/mac, use POSIX commands. If pwsh/cmd on Windows, use PowerShell equivalents. When inside WSL you can often bridge with `powershell.exe -NoProfile -Command "..."` or `cmd.exe /c ...` to probe the Windows host.
- Graceful degradation: Absence of a command or permission error **is data** (e.g. "no docker in PATH", "sudo requires password", "user-level only").
- For interactive-heavy tools later (diskpart), detection only *locates*; actual use is later under Permission Protocol.
- Record structured context (in your reasoning): e.g.
  ```json
  {
    "os_family": "linux",
    "distro": "ubuntu-24.04",
    "context": "inside-wsl2",
    "host_os": "windows-11",
    "privileges": "non-root-sudo-available",
    "primary_fs": "ext4",
    "volumes": ["/ (ext4, 80% full, 120GB used)"],
    "virtualization": ["wsl2-vhdx", "docker-desktop-wsl-backend"],
    "vhdx_candidates": ["C:\\Users\\fran\\...\\ext4.vhdx", "C:\\Users\\...\\docker_data.vhdx"],
    "tool_ecosystems": ["node/npm", "python/uv/pip", "rust/cargo", "docker", "ollama"],
    "ide_remotes": [".cursor-server", ".vscode-server"],
    "mac_specific": null,
    "docker_inside": false,
    "user_shell": "zsh",
    "home": "/home/fran",
    "host_home_equiv": "/mnt/c/Users/fran"
  }
  ```
- Only surface ambiguities to user (e.g. "Detection shows WSL markers and /mnt/c, but 'wsl --list' from inside failed. Are you on WSL2? Can the agent call host PowerShell?").

## Level 1 — Mandatory First: OS, Context, Privileges, Core Storage (run these immediately)

### 1.1 OS Family, Distribution, Version, Architecture, Shell
```bash
# Universal / POSIX-first (bash, zsh, sh)
uname -a
uname -srm
cat /etc/os-release 2>/dev/null || cat /etc/lsb-release 2>/dev/null || echo "no-release-file"
sw_vers 2>/dev/null || echo "no-sw_vers (not macOS)"
hostnamectl 2>/dev/null || true

# If shell is PowerShell (detect via $PSVersionTable or $env:OS)
# $PSVersionTable
# [System.Environment]::OSVersion
# Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory, CsSystemType
# systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
```

**Interpretation rules**:
- `Darwin` in uname → **macOS**. Parse `sw_vers` for ProductVersion/Build.
- Linux + `/etc/os-release` with `ID=ubuntu`, `NAME=Ubuntu`, or `microsoft` → Linux base. Check further for WSL.
- Windows strings (`Windows_NT`, `Microsoft Windows`, `$env:OS -eq "Windows_NT"`) → **Windows**.
- Distro/version strings feed later safe-command choices (apt vs dnf vs brew vs winget/choco vs none).
- Shell: `$SHELL`, `echo $0`, `ps -p $$ -o comm=` or PowerShell `$Host`.
- Architecture (x86_64/arm64) matters for some toolchain caches.

### 1.2 Execution Context (the most important branch driver): WSL / Host / Native / Container
Run these **from the current environment**:

```bash
# Inside potential Linux/WSL/mac container
cat /proc/version 2>/dev/null || echo "no-/proc/version"
cat /proc/sys/kernel/osrelease 2>/dev/null || echo "no-osrelease"
ls -ld /mnt/c /mnt/d 2>/dev/null || echo "no-/mnt/c (typical WSL Windows mounts)"
echo "WSL_DISTRO_NAME=${WSL_DISTRO_NAME:-<not-set>}"
echo "WSL_INTEROP=${WSL_INTEROP:-<not-set>}"
echo "WSLENV=${WSLENV:-<not-set>}"
mount | grep -iE 'drvfs|wsl|9p' 2>/dev/null | head -5 || echo "no special mounts"
test -f /.dockerenv && echo "DOCKERENV_PRESENT" || echo "no-.dockerenv"
cat /proc/1/cgroup 2>/dev/null | grep -iE 'docker|kubepods|container' | head -3 || echo "no-container-cgroup-markers"

# Bridge probe to Windows host (works from WSL if interop enabled)
powershell.exe -NoProfile -NonInteractive -Command "Write-Output 'HOST_PWSH_REACHABLE_FROM_HERE'; [Environment]::OSVersion" 2>/dev/null || cmd.exe /c "echo HOST_CMD_REACHABLE_FROM_HERE" 2>/dev/null || echo "NO_HOST_SHELL_BRIDGE"
```

**From a detected Windows PowerShell / CMD host shell**:
```powershell
# Windows host detection of WSL + distros
wsl --list --verbose 2>$null || wsl -l -v 2>$null || echo "wsl-cli-not-present-or-no-distro"
Get-ChildItem -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction SilentlyContinue |
  ForEach-Object {
    $distro = $_.GetValue('DistributionName')
    $base = $_.GetValue('BasePath')
    if ($base) { $base = $base -replace '^\\\\\?\\',''; Write-Output "LXSS_Distro:$distro BasePath:$base ext4.vhdx-candidate:$base\\ext4.vhdx" }
  }
# Docker Desktop WSL backend vhdx (common)
$dockerVhdx = "$env:LOCALAPPDATA\Docker\wsl\disk\docker_data.vhdx"
if (Test-Path $dockerVhdx) { "DOCKER_VHDX:$dockerVhdx" }
# Also check for other relocated vhdx via Get-ChildItem -Recurse -Filter *.vhdx on known drives (expensive; do only if user consents later or limit depth)
```

**Interpretation rules (set context flags)**:
- `/proc/version` or `osrelease` contains `Microsoft`, `WSL`, `microsoft-standard-WSL` or `WSL_DISTRO_NAME` is set → **Inside WSL** (usually WSL2 for ext4.vhdx behavior; WSL1 rarer now).
- `/mnt/c` (or similar) exists as drvfs/9p mount + above → inside WSL with Windows host filesystem bridged.
- `HOST_PWSH_REACHABLE_FROM_HERE` or ability to run `wsl.exe` from inside → **Hybrid WSL + host Windows** (highest value for "free space on C:").
- Running in pwsh/cmd on Windows + `wsl --list` succeeds + distros listed → **Windows host machine that has WSL installed** (agent can drive host-side commands).
- `DOCKERENV_PRESENT` or cgroup markers or `docker` in path with container-like → **Inside a Docker (or container) environment**. Reclamation inside container is limited to container FS; host-visible requires host actions.
- Linux + no WSL markers + no /mnt/c drvfs → **Native Linux** (server, desktop, or VM — ask user "Is this a VM / cloud instance / bare metal?" only if reclamation strategy differs).
- macOS → **macOS** (Darwin). Snapshots, purgeable space, etc. are the analogs of vhdx compact.
- If ambiguous (e.g. WSL markers but no host bridge), **ask user once**: "It looks like you may be inside WSL2 on Windows. Is the goal to reclaim space that appears on the Windows C: drive? (yes = hybrid case requiring later compact education)".

### 1.3 Privilege / Elevation Level (affects what agent can do directly)
```bash
id -u
id -Gn 2>/dev/null || whoami
sudo -n true 2>/dev/null && echo "SUDO_NOPASS_AVAILABLE" || echo "SUDO_NEEDS_PASS_OR_UNAVAILABLE"
# mac/Linux: groups
# Windows (pwsh):
# $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
# if ($isAdmin) { "ADMIN" } else { "STANDARD_USER" }
# net session >$null 2>&1 ; if ($LASTEXITCODE -eq 0) { "ADMIN_VIA_NET_SESSION" }
```

**Interpretation**:
- uid=0 or ADMIN → full power for system commands (journalctl, apt, trim, etc.). Still **always** confirm before destructive.
- Non-root + SUDO_NOPASS → agent can use `sudo -n <cmd>` for direct execution of privileged steps.
- Needs password → direct execution of sudo steps is blocked for agent; prefer user-run or explain and use `AskUserQuestion` for "run this with sudo yourself after we plan".
- Standard Windows user → limited to user profile/AppData/Local etc.; system-wide or Program Files require elevation or proper uninstallers.

### 1.4 Primary Storage, Volumes, Mounts, Usage (measure first, always)
```bash
df -h
df -hT 2>/dev/null || df -T 2>/dev/null || true
# Linux detailed
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,RO 2>/dev/null | cat || true
findmnt -n -o TARGET,SOURCE,FSTYPE,OPTIONS / 2>/dev/null || true

# macOS
diskutil list 2>/dev/null || true
diskutil info / 2>/dev/null | grep -E 'Container|APFS|Snapshot|Capacity' || true

# Windows (pwsh host or bridged)
Get-PSDrive -PSProvider FileSystem | Format-Table -AutoSize
# Or for more: Get-Volume | select DriveLetter, SizeRemaining, Size, FileSystem, DriveType
```

**Interpretation**:
- Identify root FS usage (the one that "feels full").
- Note separate large mounts (e.g. /home on different FS, external, NAS — don't cross unnecessarily).
- On WSL hybrid: the "inside" df reflects the vhdx consumption; host Get-PSDrive C: shows the .vhdx file size impact.
- Record "used GB on target volume" for later before/after reporting.

## Level 2 — Critical for Reclamation Strategy: Virtualization Backends, FS Peculiarities, Ecosystems

### 2.1 Virtualization / Backed Storage (the source of "deleted but space not returned")
**WSL2 vhdx discovery** (run only if Level 1 says inside-WSL or host-with-WSL):
```bash
# From inside WSL (preferred bridge)
powershell.exe -NoProfile -NonInteractive -Command @"
Get-ChildItem -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss -ErrorAction SilentlyContinue | ForEach-Object {
  $d = $_.GetValue('DistributionName')
  $b = $_.GetValue('BasePath') -replace '^\\\\\?\\',''
  if ($b) { Write-Output \"WSL_VHDX:$d|$b\\ext4.vhdx\" }
}
"@
# Also probe Docker Desktop common location from WSL bridge
$dockerBase = "$env:LOCALAPPDATA\Docker\wsl\disk"
if (Test-Path $dockerBase) { Get-ChildItem $dockerBase -Filter *.vhdx -Recurse -ErrorAction SilentlyContinue | Select-Object -Expand FullName }
```

**From Windows host pwsh** (same commands without the .exe bridge).

Also:
```bash
# List all *.vhdx the user might care about (limit scope; do not full C: recurse without consent)
# Example safe: under known user/AppData + Packages + Docker
```

**Docker (Desktop or engine)**:
```bash
docker --version 2>/dev/null || echo "no-docker-cli"
docker info 2>/dev/null | grep -E '^(Server Version|Storage Driver|Docker Root Dir|Backing Filesystem|WSL)' || true
docker system df -v 2>/dev/null || true
# Check backend
docker info 2>/dev/null | grep -i wsl || echo "docker-not-wsl-backend-or-not-detected"
```

Interpretation: If Docker + WSL backend → its data lives in a separate vhdx (`docker_data.vhdx` or similar). `docker system prune` reclaims *inside* that vhdx; compact makes it visible on host.

Other: Podman, Lima, colima, etc. — detect via cli presence; similar patterns.

### 2.2 Filesystem & Reclamation Mechanics (snapshots, trim, sparse, etc.)
```bash
# Root FS type + options
findmnt -n -o FSTYPE,OPTIONS / 2>/dev/null || true
# TRIM / discard support (Linux)
lsblk --discard 2>/dev/null | cat || true
fstrim -v / 2>/dev/null --dry-run || echo "fstrim not available or needs root" 

# macOS local snapshots (huge hidden space consumer)
tmutil listlocalsnapshots / 2>/dev/null | cat || echo "no-tmutil-snapshots"
tmutil listlocalsnapshotdates 2>/dev/null | head -5 || true
# Purgeable space
diskutil apfs list 2>/dev/null | grep -i purgeable || true

# Windows (from host): NTFS compression / sparse not directly, but we use diskpart for WSL vhdx
```

**Interpretation & education triggers**:
- ext4 (typical WSL) + virtual disk → classic "grows only" behavior. Requires explicit compact.
- APFS (mac) → local snapshots + purgeable space. `tmutil thinlocalsnapshots` or delete old ones can free without "delete files".
- Btrfs / zfs / LVM → snapshot / subvol implications; different tools.
- If snapshots or thin provisioning detected → surface education + ask opt-in before proposing snapshot thinning as a reclamation step.

### 2.3 Key Tool Ecosystems & Bloat Sources (drive what to scan + what prune commands are safe)
```bash
for t in node npm pnpm yarn corepack python pip uv conda rustup cargo go docker ollama lm-studio huggingface-cli; do
  command -v "$t" 2>/dev/null && echo "HAS:$t" || true
done

# Quick cache dir probes (existence + rough size later in scan)
ls -1d ~/{.npm,.cache,.cargo,.rustup,.local/share/pnpm,.ollama,.cache/huggingface,.cursor-server,.vscode-server,.zed_server} 2>/dev/null || true
# mac
ls -1d ~/Library/{Caches,Application\ Support} 2>/dev/null | head -5 || true

# Browser profiles (for cache-only clears)
ls -1d ~/{.config,.mozilla,.cache}/ 2>/dev/null | cat || true   # partial
```

This tells the agent: "node ecosystem present → include npm/pnpm cache in 🟢 regenerable scan". "ollama present → probe ~/.ollama/models size and treat as 🟡 ".

## Level 3 — Supporting / Nice-to-Have
- Home resolution: `echo "$HOME"`, `$env:USERPROFILE`, `wslpath -w ~` from inside WSL for host equiv.
- Better visual scanners present? `command -v ncdu dust gdu baobab duf` etc. Recommend if scan is slow.
- Multi-user / other homes: `ls /home /Users 2>/dev/null | head`.
- WSL-specific distro details: `wsl -l -v` (from host), `cat /etc/wsl.conf`.
- Package managers: `command -v apt brew dnf pacman winget choco scoop`.
- Recent activity indicators for safety (used in inspect step): `find ~ -maxdepth 3 -type d -mtime -7 2>/dev/null | head` (but expensive; use judiciously).

## Post-Detection: Context-Triggered Education + Branching

**Immediately after detection and before any scan or proposal**:

1. If context indicates WSL2 / virtual disk backends (any vhdx candidate found or WSL markers):
   - **Load and present the deep educational explanation** (see `explanations/wsl-virtual-disks.md` and REFERENCE.md "Why..." section).
   - Explain simply: virtual disk file on host grows monotonically; deletes inside Linux only mark space free *inside* the guest FS; the .vhdx file on Windows stays large until compacted read-only.
   - Best practice: readonly `attach vdisk` + `compact vdisk` via diskpart (or equivalent).
   - Risks of alternatives (`--set-sparse` disabled by MS for corruption reasons).
   - Then: **Explicit opt-in question** via AskUserQuestion:
     "Now that you understand how WSL virtual disks work and why space may not return to Windows after deletes inside, do you want the agent to include steps for host-visible reclamation (the readonly compact) in this cleanup if we identify reclaimable space? This requires a wsl --shutdown + diskpart session and is the only way the host C: drive actually shrinks. (Yes / No / Tell me more)"

2. Similar for other non-obvious:
   - macOS local snapshots: brief edu + "want to include snapshot thinning as a safe option?"
   - Docker Desktop: edu on prune vs full unregister.
   - If low-priv: explain limitations and alternatives.

Only branches that match detected context + for which user has opted-in (for non-obvious) are activated in the Adaptive Decision Tree (SKILL.md).

**Then** proceed to live scan (context-adapted: du/df on *nix/WSL, PS + WizTree rec on Windows host, diskutil on mac, etc.), using portable categories + catalog from the contract.

Detection output is never shown raw to user unless helpful; agent interprets and educates at the right moments.

## Updating This File

This is living guidance. When new platforms, backends (e.g. new container runtimes, WSLg changes, APFS evolutions), or reliable detection tricks appear, add commands + interpretation rules here. Keep commands practical and the rules deterministic where possible so any capable agent (Grok, Claude, Cursor, etc.) can follow them without the original author present.

See also: `SKILL.md` (how detection fits the overall responsibilities), `REFERENCE.md` (deep explanations + gotchas per platform), `explanations/`, and `commands/` (after detection, the agent loads relevant command snippets from the portable safe command reference library — e.g. close-the-loop.md for compact using the vhdx paths discovered here — adapts them, and executes directly after permission).
