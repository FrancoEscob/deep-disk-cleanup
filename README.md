# deep-disk-cleanup

A [Claude Code](https://claude.com/claude-code) **Agent Skill** for collaborative, deep storage cleanup on **WSL + Windows**.

The agent measures disk usage, separates *regenerable caches* from *real data*, asks you before deleting anything ambiguous, reclaims space, and — crucially — **compacts the WSL/Docker `.vhdx`** so Windows actually sees the freed space.

> Born from a real session that freed **~9 GB inside WSL + ~81 GB on Windows C:** (399 GB → 482 GB free) to make room for a Linux dual-boot partition.

## Why it exists

Deleting files inside WSL **does not** free space in Windows. WSL stores the whole Linux filesystem in a single virtual disk (`ext4.vhdx`) that grows but never shrinks on its own. You have to compact it. This skill bakes in that knowledge — plus a safe, categorized cleanup methodology — so an agent can run a thorough cleanup *with* you instead of blindly `rm -rf`-ing.

## What it does

1. **Measures first** — `df`/`du` inside WSL, WizTree on Windows (never `du` over the slow `/mnt/c` bridge).
2. **Categorizes** every target into:
   - 🟢 **Regenerable** — dev caches (npm/pip/uv/pnpm), browser cache, build caches, headless browsers, IDE remote servers → safe to delete.
   - 🟡 **Data / history** — sessions, profiles, logins, AI-tool memory → **asks you per item**.
   - 🔴 **System** — `Windows`, `WinSxS`, `pagefile.sys`, `/usr/lib/wsl`, etc. → never touched.
3. **Reclaims** biggest-and-safest first, via prompted PowerShell scripts (written to disk, not pasted — newlines mangle on paste).
4. **Compacts** the `.vhdx` with `diskpart` so Windows sees the space.
5. **Cleans loose ends** — e.g. removes stale `.cargo/env` lines after uninstalling Rust.

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Main skill: workflow + hard rules |
| `REFERENCE.md` | Categorized target lists, diskpart steps, Docker empty-without-uninstall, gotchas |
| `scripts/scan-disco.ps1` | Read-only diagnostic (top folders, biggest files, junk spots) |
| `scripts/limpieza-profunda.ps1` | Prompted deletion of dev caches, dead apps, Chromium browser cache (all profiles, keeps logins) |
| `scripts/limpiar-residuales.ps1` | Curated dead-app list + sweep of every empty (0-byte) folder |

The `.ps1` scripts prompt before every delete and report GB freed. Customize the dead-app / cache target lists at the top of each before running.

## Install

Drop the folder into your Claude Code skills directory:

```bash
git clone https://github.com/FrancoEscob/deep-disk-cleanup.git ~/.claude/skills/deep-disk-cleanup
```

Then just ask Claude Code to "free up disk space" / "do a deep clean" / "why didn't deleting files in WSL free space in Windows" and the skill triggers.

## Safety

- Confirms before each irreversible delete (unless you explicitly pre-authorized that exact target).
- Inspects targets before deleting (running process? recently modified?).
- Never forces `wsl --manage --set-sparse` (disabled by Microsoft due to a data-corruption bug) — uses read-only `diskpart compact` instead.

## License

MIT — see [LICENSE](LICENSE).
