---
name: deep-disk-cleanup
description: Collaborative deep storage cleanup for WSL + Windows. Measure usage, separate regenerable caches from real data, confirm ambiguous deletes with the user, reclaim space, and compact the WSL/Docker vhdx so Windows actually sees it freed. Use when the user wants to free disk space, "clean up storage", do a "deep clean", remove residual/old files, partition a disk for dual-boot, or asks why deleting files in WSL didn't free space in Windows.
---

# Deep Disk Cleanup (WSL + Windows)

Collaborative cleanup: **you measure and categorize, the user decides on anything ambiguous.** Never bulk-delete data or history without asking. The goal is maximum *safe* reclaim.

## The one thing people get wrong

WSL stores the whole Linux filesystem in a single virtual disk (`ext4.vhdx`). It **grows but never shrinks on its own** — deleting files inside WSL does NOT free space in Windows until you **compact** the vhdx. Same for Docker's `docker_data.vhdx`. Always finish with the compact step (see REFERENCE.md), or the user won't see any space back.

## Workflow

1. **Measure first, delete nothing yet.**
   - Inside WSL: `df -h /` and `du -sh /home/<user>` then `du -sh .[!.]* * 2>/dev/null | sort -rh | head -40`. Also scan *outside* home (`/usr /var /tmp /opt`) — it lives in the same vhdx.
   - On Windows: don't `du` over `/mnt/c` (the 9p bridge is painfully slow). Tell the user to install **WizTree** (reads the MFT, scans 500 GB in seconds) and send a screenshot of the tree + the extension panel. You read it for them.

2. **Categorize everything into three buckets** (see REFERENCE.md for the full lists):
   - 🟢 **Regenerable** — caches (npm/pip/uv/pnpm, browser cache, build caches, headless browsers, IDE remote servers). Safe to delete; they re-download/re-create.
   - 🟡 **Data / history** — sessions, profiles, logins, downloads, AI-tool memory. Deleting loses things → **ask the user per item** (use AskUserQuestion with sizes).
   - 🔴 **System — never touch** — `Windows`, `WinSxS`, `Program Files`, `/usr/lib/wsl`, `pagefile.sys`, `System Volume Information`, shared libs.

3. **Reclaim, biggest-and-safest first.** Confirm the explicitly-authorized targets, then walk the user through the rest. For Windows, **write `.ps1` scripts to disk and have them run with `-ExecutionPolicy Bypass`** — never make them paste multi-line commands (newlines mangle on paste). Bundled templates are in `scripts/`.

4. **Compact the vhdx(es)** so Windows sees the space — the finale. See REFERENCE.md.

5. **Clean up loose ends** — remove stale rc-file references to anything you uninstalled (e.g. `.cargo/env` after removing Rust), or shells will error on every launch.

## Bundled scripts (copy to the user's `%USERPROFILE%`, then run)

- `scripts/scan-disco.ps1` — read-only diagnostic: top folders, biggest files, known junk spots.
- `scripts/limpieza-profunda.ps1` — prompted (s/n) deletion of dev caches, dead apps, Chromium browser cache (all profiles, keeps logins).
- `scripts/limpiar-residuales.ps1` — kills a curated dead-app list + every empty (0-byte) folder under AppData\Local.

Edit the dead-app list and cache targets per user before running. Each script prompts before deleting and reports GB freed.

## Hard rules

- Confirm before each irreversible delete unless the user explicitly pre-authorized that exact target.
- Inspect a target before deleting (is a process using it? is it recently modified?). Surface surprises instead of plowing ahead.
- Dead app folders that weigh **KB–few MB are not worth chasing individually** — sweep them with the empty-folder pass instead. Don't burn time on cosmetic cruft unless the user asks.

See **[REFERENCE.md](REFERENCE.md)** for the categorized target lists, diskpart compact steps, Docker empty-without-uninstall, and gotchas.
