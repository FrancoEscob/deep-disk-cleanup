# Privilege & Cross-Context Bridging

The agent often runs in one context (inside WSL guest) but needs to affect host-visible state or run privileged ops. Detection (Level 1 priv + context) tells you the capabilities. Always respect limits; prefer direct where possible, guide or tiny targeted fallback otherwise.

## Privilege Levels (from detection)
- **Full root / Admin**: `sudo cmd` or run as admin pwsh. Can do journal vacuum, fstrim, apt, system changes. Still **always** perm first.
- **nopass sudo**: `sudo -n cmd` works in non-interactive tool calls. Great for agent direct.
- **Needs password**: Direct sudo in agent pipe may fail or prompt hidden. Options:
  - Guide user: "Run this one command with sudo yourself after we plan: `sudo journalctl --vacuum...`"
  - Emit a tiny one-step script for that action only (user inspects + runs with sudo).
  - AskUserQuestion "I can prepare the exact command — will you run it with sudo now or later?"
- **Standard Windows user**: Fine for own profile + own WSL vhd xs (no elevation for personal compact usually). System-wide (WinSxS cleanup) needs DISK CLEANUP tool or elevation.
- Limited container/VM guest: only inside FS; note outer for user.

Detection commands include the exact probes (`id -u`, `sudo -n true`, Windows IsInRole Admin, net session).

## Bridging WSL <-> Windows Host (the hybrid superpower)
**From inside WSL (most common for dev agents)**:
- Reach host: `powershell.exe -NoProfile -NonInteractive -Command "..."` or `cmd.exe /c "..."` (if interop enabled — detection confirms HOST_PWSH_REACHABLE).
- Run WSL commands from host side later if needed: but for inside deletes, agent shell is perfect.
- For compact: bridge the wsl --shutdown + diskpart script creation + diskpart /s .

Example bridge for shutdown + measure:
```bash
powershell.exe -NoProfile -NonInteractive -Command "wsl --shutdown; Write-Output 'SHUTDOWN_OK'"
# Then diskpart via script as in close-the-loop.md
```

**From Windows host pwsh (agent running on host)**:
- Can drive everything.
- To do inside-guest work: `wsl -d Ubuntu -- bash -c 'rm -rf ~/.npm && echo DONE'`
- Or `wsl -d Ubuntu -- /bin/bash -c '...' `
- Perfect for direct execution of guest actions + host compact in one session.
- List/distros: `wsl --list -v`

**Detecting bridge health**: see detection-commands.md Level 1 (the powershell.exe probe + wsl --list from host).

## Writing & Invoking Temporary Scripts (diskpart, multi-step)
See common-patterns.md for safe temp creation (user TEMP, unique name, ASCII for PS compat, cleanup after).

For diskpart (interactive by nature but scriptable):
- Agent writes the .txt with the exact select/attach/compact/detach for **only the vhdx the user authorized in this run**.
- Invokes `diskpart /s $tmp` (from host pwsh or bridged).
- Captures output.
- Deletes tmp.
- Reports.

Never hardcode paths in the emitted script — populate from live detection model + user confirms.

## sudo -n in Tool Calls
```bash
sudo -n fstrim -v / 2>&1 || echo "SUDO_FAILED_OR_NO_NOPASS: $?"
```
Agent tools often simulate tty; -n is safest non-interactive.

If tool call for sudo blocks on password: surface and fallback to user-run guidance.

## When Direct Is Blocked — Fallback Protocol (per SKILL.md)
1. Explain the exact impact and command(s).
2. Offer AskUserQuestion: "Run it yourself now? (I'll give the precise line)" or "Emit a minimal one-action script for this step only?"
3. If script: write a tiny, well-commented .ps1 or .sh containing **only** the authorized action (e.g. one diskpart block for the 2 vhd x user said yes to), with before/after measure, prompts if interactive, report.
4. Place it in user's home or TEMP, tell path, "inspect then run".
5. Never emit a giant "do everything" script by default.

## Elevation for Compact / Diskpart
Usually your own vhdx can be compacted as standard user (the registry BasePath is under your HKCU). If relocated to protected area, may need admin — detection + error will surface; guide accordingly.

## Docker in Bridged Contexts
`docker` CLI inside WSL or on host talks to the right backend (WSL or native). Prune inside the backend's storage; compact the backing vhdx if WSL.

## macOS / Linux sudo
Similar nopass detection. Most user bloat (Library/Caches, ~/*) doesn't need sudo. System (journal, apt, fstrim root) does.

## General Rule for Agent
- Use detection priv + context model to choose: direct sudo -n, bridged host cmd, wsl -d wrapper, or "prepare for user".
- Never silently skip privileged reclamation; always surface the option with education ("this step needs sudo — here's impact").
- For the Permission Protocol: when the step crosses boundary or requires priv, call it out explicitly in the ask ("This will use sudo -n journal vacuum and pause nothing critical — OK?").

See SKILL.md "Privilege filter on all direct actions", explanations/platform-notes.md, detection-commands.md priv section.

This enables true direct execution across the real-world mixed environments (inside WSL devcontainer on Windows host is common).
