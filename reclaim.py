#!/usr/bin/env python3
"""
reclaim.py — Minimal standalone interactive disk reclaimer.

This is a **standalone / fallback** implementation (stdlib-only, zero deps).
It performs direct actions (with interactive confirms via stdin) when run manually.

In the primary modern skill (see SKILL.md — minimal powerful high-level principles + adaptive decision tree contract):
- Mandatory Environment Detection first (detection-commands.md).
- Context-triggered education (explanations/, esp WSL virtual disks + opt-in).
- Live per-machine scan + decision-oriented interview using broad portable categories + catalog.
- Explicit permission for every destructive step (AskUserQuestion style).
- **Direct execution** via the agent's terminal tools is PRIMARY (agent drives rm/prune/compact etc after your yes).
- Script generation is strictly secondary (audit/fallback/user request or direct impossible).

This Python tool is excellent for:
- Manual use without an agent.
- Quick --list-only / --dry / --conservative previews.
- Situations where the agent chooses to fall back to a simple executable.

Cross-platform friendly (strongest on Linux/WSL/macOS; Windows users get guidance
and can use the reference .ps1 scripts in scripts/ as examples, or the commands/ library for granular patterns).

Usage:
  python3 reclaim.py
  python3 reclaim.py --help
  python3 reclaim.py --list-only
  python3 reclaim.py --conservative --dry     # safe preview without deleting

It will:
- Load the data-driven catalog (catalog/targets.json) for the master list of portable targets
  (with categories, descriptions, and basic notes). This is the single source of truth;
  see catalog/README.md + SKILL.md for how the full agent skill uses the rich metadata
  (why/decision/safer/tradeoff/prune_commands) for education and direct execution.
- Scan resolved paths from the catalog + a few dynamic ones (Downloads, /tmp)
- Categorize (🟢 safe/regenerable, 🟡 ask, 🔴 never)
- Interview for 🟡 items (or auto-skip in conservative)
- Perform direct deletions (shutil) only for what you confirm
- Report and strongly remind about the critical vhdx compact step on WSL/Windows hybrids
  (after inside cleanup, only if relevant per detection/education/opt-in)

See the full skill package (SKILL.md minimal contract + adaptive decision tree + catalog/ + REFERENCE.md + explanations/ + detection-commands.md + commands/ (the comprehensive portable safe command reference library of reusable cross-platform snippets, helpers, and patterns that capable agents read + adapt + execute directly via tools after permission; this CLI is a stdlib standalone/fallback that demonstrates direct execution + catalog use)) for the generalist, educational, direct-execution-first design (any agent).
This file is small/self-contained for usability; consumes catalog for targets so community additions benefit standalone + fallback too (graceful).
"""
import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

SAFE_GREEN = "🟢"
ASK_YELLOW = "🟡"
NEVER_RED = "🔴"

# NEVER_TOUCH kept for fast filtering (also present in catalog as red entries for the full agent).
NEVER_TOUCH = [
    "/usr/lib/wsl",
    "/System",
    "/Windows",
    "pagefile.sys",
    "WinSxS",
]


def _find_catalog_path() -> Path:
    """Locate catalog/targets.json relative to this file or CWD (installed skill or repo root)."""
    here = Path(__file__).resolve().parent
    candidates = [
        here / "catalog" / "targets.json",
        here.parent / "catalog" / "targets.json",  # when run from scripts/ or similar
        Path.cwd() / "catalog" / "targets.json",
        Path.cwd().parent / "catalog" / "targets.json",
        # Common install locations for the skill package
        Path.home() / ".claude" / "skills" / "deep-disk-cleanup" / "catalog" / "targets.json",
        Path.home() / ".grok" / "skills" / "deep-disk-cleanup" / "catalog" / "targets.json",
    ]
    for c in candidates:
        if c.exists():
            return c
    return None


def _load_catalog_for_cli():
    """Load targets from the JSON catalog and convert to the simple (raw, cat, label, note) tuples
    that the rest of reclaim.py expects. Only includes entries that have at least one path.
    Prefers POSIX-style paths for this CLI (full agent does richer platform resolution).
    Graceful: returns [] on any error so we can fall back.
    """
    cat_path = _find_catalog_path()
    if not cat_path:
        return []

    try:
        import json
        data = json.loads(cat_path.read_text(encoding="utf-8"))
        targets = data.get("targets", [])
        converted = []
        for t in targets:
            paths = t.get("paths") or []
            if not paths:
                continue  # patterns like abandoned-projects or command-driven (docker) are handled by full agent scan
            # Pick a reasonable first path for CLI (prefer ones with ~ or $HOME or / )
            raw = None
            for p in paths:
                if p.startswith("~") or p.startswith("$HOME") or p.startswith("/") or "Library" in p or "cache" in p.lower():
                    raw = p
                    break
            if not raw:
                raw = paths[0]
            cat = t.get("category", "yellow")
            sym = SAFE_GREEN if cat == "green" else (ASK_YELLOW if cat == "yellow" else NEVER_RED)
            label = t.get("description", raw)
            # Use a short note derived from why or notes (truncated for CLI)
            why = t.get("why_this_bucket") or t.get("notes") or ""
            note = (why[:80] + "...") if len(why) > 80 else why
            if cat == "red":
                continue  # CLI lists but main flow skips; avoid surfacing reds in found for list-only
            converted.append((raw, sym, label, note))
        return converted
    except Exception:
        # Silent graceful fallback — catalog missing, unreadable, or bad json in this env
        return []


# Load from the data-driven catalog (the core of the refactored skill).
# Falls back to a tiny conservative list if catalog not found (old install, minimal env, etc.).
CATALOG_TARGETS = _load_catalog_for_cli()

if not CATALOG_TARGETS:
    # Minimal fallback (kept in sync with a few high-value entries from catalog/targets.json)
    CATALOG_TARGETS = [
        ("~/.cache", ASK_YELLOW, "User cache (~/.cache)", "Often safe but may contain useful things for some tools"),
        ("~/.npm", SAFE_GREEN, "npm cache", "Regenerable with npm cache clean or reinstall"),
        ("~/.cache/pip", SAFE_GREEN, "pip cache", "Regenerable"),
        ("~/.cache/uv", SAFE_GREEN, "uv cache", "Regenerable"),
        ("~/.cargo", ASK_YELLOW, "Cargo / Rust user data", "Toolchains + git checkouts. Only delete if you don't use Rust."),
        ("~/.rustup", ASK_YELLOW, "rustup toolchains", "~1-2GB typical. Ask before nuking."),
        ("~/.local/share/pnpm", SAFE_GREEN, "pnpm store", "Regenerable"),
        ("~/.cache/node-gyp", SAFE_GREEN, "node-gyp cache", "Regenerable"),
        ("~/.cursor-server", SAFE_GREEN, "Cursor remote server", "Re-downloads on reconnect"),
        ("~/.vscode-server", SAFE_GREEN, "VS Code remote server", "Re-downloads on reconnect"),
        ("~/.ollama", ASK_YELLOW, "Ollama models & data", "Large. You may want to keep some models."),
        ("~/.cache/huggingface", ASK_YELLOW, "Hugging Face cache", "Downloaded models/datasets. Expensive to re-download."),
        ("~/Library/Caches", ASK_YELLOW, "macOS user caches", "Generally safe; some apps may be slower first run"),
    ]

def expand(p: str) -> Path:
    return Path(p).expanduser()

def human(n_bytes: int) -> str:
    for unit in ["B", "KB", "MB", "GB", "TB"]:
        if n_bytes < 1024:
            return f"{n_bytes:.1f}{unit}"
        n_bytes /= 1024
    return f"{n_bytes:.1f}PB"

def dir_size(path: Path) -> int:
    if not path.exists():
        return 0
    total = 0
    try:
        for root, dirs, files in os.walk(path, topdown=True, onerror=lambda e: None):
            # Skip some expensive / protected areas quickly
            dirs[:] = [d for d in dirs if not d.startswith(('.', 'proc', 'sys'))]
            for f in files:
                try:
                    total += (Path(root) / f).stat().st_size
                except Exception:
                    pass
    except Exception:
        pass
    return total

def is_never(path: Path) -> bool:
    s = str(path).lower()
    for bad in NEVER_TOUCH:
        if bad.lower() in s:
            return True
    return False

def scan_targets():
    found = []
    for raw, cat, label, note in CATALOG_TARGETS:
        p = expand(raw)
        if p.exists():
            sz = dir_size(p)
            if sz > 10 * 1024 * 1024:  # only report >10MB to keep noise down
                found.append((p, cat, label, note, sz))
    # Also add a couple dynamic ones (these are also represented in the catalog but as yellow patterns)
    for extra in [Path.home() / "Downloads", Path("/tmp")]:
        if extra.exists():
            sz = dir_size(extra)
            if sz > 50 * 1024 * 1024:
                found.append((extra, ASK_YELLOW, f"Large: {extra.name}", "Review contents", sz))
    found.sort(key=lambda x: -x[4])
    return found

def confirm(msg: str) -> bool:
    try:
        ans = input(f"{msg} [y/N]: ").strip().lower()
        return ans in ("y", "yes")
    except (EOFError, KeyboardInterrupt):
        print("\nAborted.")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Standalone reclaim wizard (early version)")
    parser.add_argument("--conservative", action="store_true", help="Only act on obvious safe (green) items; skip most questions")
    parser.add_argument("--dry", action="store_true", help="Never actually delete, just report")
    parser.add_argument("--list-only", action="store_true", help="Just scan and list, no questions at all (great for CI or review)")
    args = parser.parse_args()

    print("\n=== RECLAIM — Standalone Disk Wizard (early) ===\n")
    print("This is a minimal stdlib version. It is safe by default and educational.")
    print("For the full wizard experience (mandatory detection, deep education especially WSL vdisks + opt-in, decision-oriented interview, explicit permission, direct execution primary, adaptive strategies),")
    print("use the complete skill package (SKILL.md + supporting files) with a capable agent (Claude Code / Grok / Cursor etc.). This standalone is great for manual or fallback.\n")

    targets = scan_targets()

    if not targets:
        print("Nothing large found in the catalog (or fallback list). Try the full agent scan (with live broader discovery) or WizTree / ncdu / DaisyDisk for a complete picture.")
        return

    print("Found (sorted by size):\n")
    for p, cat, label, note, sz in targets:
        print(f"  {cat} {label:30} {human(sz):>10}  {p}")

    if args.list_only:
        print("\n--list-only: scan complete. No deletions attempted.")
        print("Run without --list-only (or with --dry) for the interactive plan.")
        return

    print("\n--- Plan (direct execution after your confirms; see SKILL.md for agent primary flow) ---")
    to_clean = []
    for p, cat, label, note, sz in targets:
        if cat == SAFE_GREEN:
            if confirm(f"Delete safe/regenerable {label} ({human(sz)})?"):
                to_clean.append((p, label, sz))
            continue
        if cat == ASK_YELLOW:
            if args.conservative:
                print(f"  Skipping (conservative): {label}")
                continue
            if confirm(f"Review & possibly delete {label} ({human(sz)})? {note}"):
                if confirm(f"  Really delete {label}?"):
                    to_clean.append((p, label, sz))
            continue
        # red never
        print(f"  {NEVER_RED} Skipping system/never: {label}")

    if not to_clean:
        print("\nNothing selected. Exiting cleanly.")
        return

    print("\n=== Selected for cleanup ===")
    total = 0
    for p, label, sz in to_clean:
        print(f"  {label}: {human(sz)}")
        total += sz
    print(f"\nPotential reclaim (inside guest): ~{human(total)}")

    if args.dry:
        print("\n--dry: not actually deleting. Would have removed the above.")
    else:
        if not confirm("\nProceed with deletions? (You will get per-item confirmation too)"):
            print("Aborted.")
            return
        for p, label, sz in to_clean:
            print(f"\n  -> Removing {label} ...")
            try:
                if p.is_dir():
                    shutil.rmtree(p, ignore_errors=True)
                else:
                    p.unlink(missing_ok=True)
                print(f"     Freed approx {human(sz)}")
            except Exception as e:
                print(f"     Error: {e}")

    print("\n=== IMPORTANT: Reclaim host-visible space (especially WSL/Windows hybrids) ===")
    print("Deleting inside WSL/Linux does NOT shrink the .vhdx on the Windows host (see explanations/wsl-virtual-disks.md).")
    print("After inside cleanup (and only if the context + user opt-in in the full skill warrant it):")
    print("  1. wsl --shutdown   (from Windows PowerShell or CMD, or bridged)")
    print("  2. Use diskpart (readonly compact) — see REFERENCE.md + detection-commands.md for exact steps and path discovery.")
    print("     Typical locations: Ubuntu ext4.vhdx and Docker's docker_data.vhdx")
    print("  3. On macOS/Linux the space should be visible immediately (or after fstrim / snapshot thin).")
    print("\nFor the full educational explanation, safe compact instructions, Docker tips, WizTree advice, platform notes,")
    print("primary direct-execution agent flow, and portable command snippets library, read SKILL.md, REFERENCE.md, explanations/, detection-commands.md, and commands/ (e.g. close-the-loop.md + common-patterns.md for the exact sequences to adapt).")

    print("\nDone (standalone/fallback path). If this helped, star the repo and consider contributing new targets via issues!")
    print("Run with --conservative for a quicker, safer pass next time.")
    print("For the full generalist educational experience with any agent: install the whole directory as a skill.")

if __name__ == "__main__":
    main()
