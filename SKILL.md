---
name: deep-disk-cleanup
description: Interactive wizard for collaborative deep storage cleanup on WSL + Windows (and Linux/macOS). The agent scans the disk, categorizes what it finds, asks the user about anything ambiguous, GENERATES a personalized cleanup script for that machine, reclaims space, and compacts the WSL/Docker vhdx so the host OS sees it freed. Use when the user wants to free disk space, "clean up storage", do a "deep clean", remove residual/old files, partition a disk for dual-boot, or asks why deleting files in WSL didn't free space in Windows.
---

# Deep Disk Cleanup — Interactive Wizard

You are a **collaborative cleanup wizard**, not a fixed script. The bundled `.ps1` files are **templates/scaffolds** — you SCAN the specific machine, then GENERATE a personalized script from those templates containing only the targets that actually exist on *this* user's disk and that they confirmed. Never ship someone else's app names to another machine.

**Golden rule:** measure → categorize → *ask about anything ambiguous* → generate a per-user script → reclaim → **compact the vhdx**.

## The non-obvious thing (say it early)

Deleting files inside WSL does **not** free space in Windows. The whole Linux fs lives in one virtual disk (`ext4.vhdx`) that grows but never shrinks on its own — you must **compact** it (`diskpart`, see REFERENCE.md). Same for Docker. Without this final step the user sees zero space back.

## Wizard flow

### Phase 0 — Quick scan (measure, delete nothing)
- WSL/Linux: `df -h /`, `du -sh ~`, `du -sh .[!.]* * 2>/dev/null | sort -rh | head -40`, and scan *outside* home (`/usr /var /tmp /opt`) — it's in the same vhdx.
- Windows: copy `scripts/scan-disco.ps1` to `%USERPROFILE%` and have the user run it (`powershell -ExecutionPolicy Bypass -File ...`). For a full visual map, recommend **WizTree** (reads the MFT, scans 500 GB in seconds) and have them send a screenshot. **Never** `du` over `/mnt/c` — the bridge is glacial.

### Phase 1 — Categorize what the scan returned
Sort every sizeable item into three buckets (full catalog in REFERENCE.md):
- 🟢 **Regenerable** — caches (npm/pip/uv/pnpm, browser cache, build caches, headless browsers, IDE remote servers). Safe.
- 🟡 **Data / history** — sessions, profiles, logins, downloads, AI-tool memory, toolchains, games. **Ask per item.**
- 🔴 **System — never touch** — `Windows`, `WinSxS`, `Program Files`, `/usr/lib/wsl`, `pagefile.sys`, etc.

### Phase 2 — Interview the user (this is the heart of the skill)
For every 🟡 item, ask with **sizes shown** (use AskUserQuestion). Good questions: "I found `nomic.ai` (12 GB) — that's GPT4All from 2023, still use it?", "Rust toolchains are 1.9 GB — do you compile Rust?", "Games (Epic) are 106 GB — keep them?". Let them confirm/deny each. Don't assume; the same folder is junk for one user and precious for another.

### Phase 3 — Generate the personalized script
Copy the relevant template from `scripts/` and **fill in only the confirmed targets** in the marked `# >>> PERSONALIZE <<<` regions. Write the finished script to `%USERPROFILE%\cleanup-<user>.ps1`. Keep the universal helper functions; populate the dead-app list and cache targets from *this* scan. Keep it ASCII-only (PS 5.1 encoding) and prompted (s/n per block).

### Phase 4 — Reclaim
User runs the generated script (`-ExecutionPolicy Bypass`). It prompts before each delete and reports GB freed. Biggest-and-safest first.

### Phase 5 — Compact the vhdx (the finale)
`wsl --shutdown` then `diskpart` → `compact vdisk` on each vhdx (Ubuntu, Docker). See REFERENCE.md. This is what actually returns space to the host.

### Phase 6 — Loose ends
Remove rc-file references to anything uninstalled (e.g. `.cargo/env` after removing Rust) so shells don't error. Re-scan to confirm.

## Bundled templates (`scripts/`)

- `scan-disco.ps1` — **generic, run as-is**: top folders, biggest files, junk spots.
- `limpieza-profunda.ps1` — **TEMPLATE**: universal dev/browser caches pre-wired (auto-skip if absent); a `# >>> PERSONALIZE <<<` block where you add the user's confirmed dead apps from the scan.
- `limpiar-residuales.ps1` — **TEMPLATE**: empty `$dead` list for you to fill + a generic 0-byte-folder sweep that needs no customization.

Treat them as scaffolding, not as a fixed list to run blindly.

## Hard rules

- Confirm before each irreversible delete unless the user explicitly pre-authorized that exact target.
- Inspect a target before deleting (running process? recently modified? a service that recreates it?). Surface surprises.
- Don't hardcode one machine's app names into another's script. Every cleanup script is generated from a fresh scan.
- KB–few-MB dead folders aren't worth chasing one by one — sweep them with the empty-folder pass.

See **[REFERENCE.md](REFERENCE.md)** for the categorized catalog, diskpart steps, Docker empty-without-uninstall, and gotchas.
