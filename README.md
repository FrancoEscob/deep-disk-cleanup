# deep-disk-cleanup

> **Safely reclaim 50–200+ GB** from WSL, Docker, AI tool caches, old toolchains, and browser junk — **and actually get the space back on your host disk** (plus clean native Linux/macOS/Windows machines).

An interactive **educational, context-aware cleanup wizard** (primary: agent skill with direct execution + permission; also excellent standalone) for **Windows, Linux (native + WSL), macOS**. 

**Primary model (agent)**: Mandatory environment detection → context-triggered education (especially WSL virtual disks and equivalents) → live per-machine scan + personalized interview using broad portable categories → **explicit permission for every destructive step** (size/impact/risk/alternatives) → **direct execution via the agent's own terminal tools**. 

Script/template generation is secondary (audit/fallback only). The skill also shines standalone.

It safely reclaims space and — for WSL/Docker hybrids — walks through the critical readonly compact so the host actually sees the freed space.

**The non-obvious truth most people learn the hard way**: Deleting files *inside* WSL or a container does **not** shrink the `.vhdx` files on Windows. They only grow. This tool handles the full cycle, including the correct, safe `diskpart compact` step.

## Why people love it (and why it stands out)

- **Safety-first + educational by design** — Broad portable categories (🟢 Regenerable, 🟡 Data/history — always asks with live sizes + tradeoffs, 🔴 System never touched). No blind `rm -rf`. Teaches you *how to decide* for the future.
- **Direct execution primary (agent)** — After mandatory detection + education + your explicit permission (via structured questions), the agent uses its own tools to run the cleanups, prunes, compacts (where possible), and reports. Scripts are reference/fallback/audit only.
- **Context-aware & generalist** — Works on pure Windows, native Linux, macOS, inside WSL, Docker containers, hybrids. Detection drives adaptive strategies; no hardcoded assumptions or one user's paths.
- **Actually finishes the job for hybrids** — For WSL2 + Docker Desktop WSL backend (the classic case), detection triggers deep education on virtual disks first + explicit opt-in, then inside cleanup + the safe readonly `diskpart` compact so the host C: drive actually shrinks. (Preserves the original 50-200+ GB wins.)
- **Agent-native but fully standalone-capable** — Install the whole dir as a skill for Claude Code, Cursor, Aider, Grok Build, Windsurf, Codex, etc. Also excellent manual use via `reclaim.py` + reference scripts.
- **Deep education on the non-obvious** — Especially WSL virtual disks (how they work, why deletes inside don't free host space, best readonly compact practice, why not --set-sparse), macOS snapshots, trim, privilege implications, etc. See `explanations/` and `REFERENCE.md`.

If you develop with WSL2 + Docker + local AI tools (or just accumulate caches/toolchains on any modern OS), you have felt this pain. This refactored skill is the thoughtful, deeply educational, direct-execution, generalist solution that works for any capable agent and any machine.

## Quick start (choose your path)

### 1. With an AI coding agent (fastest, smartest)
```bash
git clone https://github.com/FrancoEscob/deep-disk-cleanup.git ~/.claude/skills/deep-disk-cleanup
# or for Grok users: ~/.grok/skills/deep-disk-cleanup
```

Then just say:
> "do a deep disk cleanup" or "run deep-disk-cleanup on my machine"

The agent will:
- Perform mandatory environment detection (OS, WSL vs host vs native, Docker, privs, FS, toolchains, vhdx locations... — see `detection-commands.md`).
- Trigger education for non-obvious behaviors (especially the full simple explanation of WSL virtual disks + explicit opt-in before any compact topic).
- Do a live scan of *this* machine, categorize with portable rules, interview you decision-oriented style for ambiguous items (real sizes, tradeoffs, partial options, "how to decide").
- Ask explicit permission (with impact) for every batch or action.
- Execute **directly** with its tools for what you authorize (primary path).
- Report before/after (guest + host-visible where relevant) and iterate.

Scripts/templates are used only as reference library, for audit artifacts, or true fallbacks.

Works great with Claude Code, Cursor, Windsurf, Aider, Grok Build, Codex, and similar modern agents. Install the *entire directory* as the skill.

### 2. Standalone (no agent required)
Copy the scripts and run manually:

**Windows (PowerShell):**
```powershell
# Diagnostic (read-only, safe) — reference implementation
powershell -ExecutionPolicy Bypass -File ".\scripts\scan-disco.ps1"

# The .ps1 files in scripts/ are now reference examples / audit helpers / fallbacks.
# See headers inside them. Primary agent experience uses direct execution.
# You can still run the templates manually (they prompt) or let the agent emit
# a lightly personalized copy as an auditable artifact when useful.
```

**Linux / WSL / macOS (manual powerful commands from the wizard):**
```bash
bash scripts/scan-disco.sh
```
See the scan steps, full context, and modern direct-execution flow in [SKILL.md](SKILL.md), the data-driven [catalog/](catalog/) (targets.json is the extensible core for targets + education metadata), [commands/](commands/) (the portable safe command reference library — load e.g. close-the-loop.md or green-prune.md for the snippets the agent adapts and runs directly), [REFERENCE.md](REFERENCE.md), [detection-commands.md](detection-commands.md), and the `explanations/` directory. The scripts/ + reclaim.py are high-quality reference library / fallback, not the default path.

### 3. Standalone `reclaim.py` (Python, zero deps — first-class manual + fallback)
A minimal stdlib-only interactive reclaimer that does **direct execution** (with your confirms):
```bash
python3 reclaim.py --help
python3 reclaim.py --conservative --dry     # safe preview
python3 reclaim.py                         # interactive direct (asks before anything)
python3 reclaim.py --list-only             # just scan/report, no questions
```
It scans, categorizes (🟢/🟡/🔴), interviews for ambiguous items, deletes only what you explicitly authorize, reports, and educates/reminds about the vhdx compact (and platform analogs).

This is both an excellent no-agent path and aligned with the skill's direct-execution philosophy. See the top of reclaim.py for relationship to the full package.

Copy it from the repo or (after install) from the skill directory. Richer catalog-driven / TUI / parity features continue to evolve with the skill (see ACCELERATION-PLAN.md).

## The non-obvious step for WSL/Docker hybrids (compact the vhdx) — education first

**Detection triggers this.** When the agent detects a WSL2 / virtual-disk context, it **first** presents the deep, simple educational explanation (from `explanations/wsl-virtual-disks.md` + REFERENCE) of how virtual disks work, why deletes inside the guest do not shrink the host file, the safe readonly compact best practice, and risks of alternatives. Then it asks for **explicit opt-in** before the topic or steps are proposed.

Only then (and only after inside cleanup + separate permission for the shutdown/compact action) does it help execute:

```powershell
wsl --shutdown
diskpart
# then for each relevant vhdx discovered via detection (Ubuntu, docker-desktop, etc.):
select vdisk file="C:\exact\path\to\ext4.vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
exit
```

The skill (via detection-commands.md) finds the exact current paths (registry probe, common Docker locations, user-relocated ones). We use the safe readonly method exclusively.

See [explanations/wsl-virtual-disks.md](explanations/wsl-virtual-disks.md), [REFERENCE.md](REFERENCE.md), and [detection-commands.md](detection-commands.md) for the full story, Docker handling, analogs on other platforms (mac snapshots, fstrim), WizTree tips, and gotchas.

This is what lets WSL users actually see the 50-200+ GB return on their host C: drive.

## What it typically finds (examples — discovered live per machine)

**🟢 Regenerable (safe after batch confirmation, prefer native prune cmds):**
- npm/pnpm/uv/pip caches, node-gyp, Go build, Cypress/NuGet, headless browser caches (Playwright etc.)
- Browser *Cache* subfolders only (logins/history untouched)
- IDE remote servers (`.cursor-server`, `.vscode-server`...)
- System: apt/dnf clean, journal vacuum, brew cleanup (context-appropriate)
- (Full portable set with education metadata: see `catalog/targets.json` — the agent loads it live)

**🟡 Asks you (live sizes + recency + decision questions + partial options):**
- Old / forgotten local AI model stores (Ollama, LM Studio, HF, etc.)
- Rust toolchains + cargo (and offers to clean shell rc lines if removed)
- Games / large launcher installs (prefer launcher uninstall UI)
- Duplicate/old toolchains and managers (nvm/fnm/asdf + their nodes), massive Downloads, abandoned project build artifacts, old browser profiles, residuals from uninstalled apps

**🔴 Never touches:**
- Windows / WinSxS / Program Files*, pagefile*, `/usr/lib/wsl`, core system paths, actively used app data, protected locations, etc. (guide to proper uninstallers instead)

## Safety & philosophy (the binding contract)

- **Mandatory detection + education + explicit permission first** for everything non-obvious and every destructive action (see SKILL.md Permission Protocol). Direct execution only after your informed yes (via AskUserQuestion-style).
- **Live per-machine only**. No hard-coded paths from anyone else's PC.
- **Inspect before act** (recent activity, locks, recreate risk).
- **Measure + report** before/after (guest view + host-visible for hybrids).
- **Generalist portable categories + interview** for anything ambiguous. The user decides with full context, tradeoffs, and partial options.
- **Scripts as reference library only** (headers inside document this). Agent emits personalized copies only as secondary artifacts.
- **Biggest-and-safest-first** + iteration. Generic sweeps for small stuff.
- You (and the frameworks in `explanations/decision-frameworks.md`) stay in control.

**Always** have backups of anything precious. This is a power tool for informed humans + capable agents.

## Current status & roadmap

This is the refactored modern generalist educational skill: mandatory robust detection engine, deep educational explanations (WSL virtual disks first-class), explicit permission + direct execution primary (agent tools), adaptive context-driven strategies, scripts as reference/fallback only, full portability across Windows/Linux/macOS + hybrids.

See **[ACCELERATION-PLAN.md](ACCELERATION-PLAN.md)** (and the memory of design decisions) for history and ongoing evolution (richer catalog, TUI polish on reclaim.py, more platform helpers, community contributions, packaging, etc.).

The core skill package (SKILL.md as binding contract + REFERENCE + explanations/ + detection-commands.md + commands/ (portable safe command ref library) + reference scripts) is complete and ready to install as a skill for any capable agent.

## Contribute (high impact, low friction)

The easiest and most valuable contributions:
1. Run it on your machine (agent or manual) and report what you freed + your setup in an issue ("Freed 87 GB on WSL Ubuntu 24.04 + Docker Desktop").
2. Propose new safe targets (with category, why it's regenerable or why it needs asking, platform).
3. Improve docs, add macOS/Linux scanner snippets, test scripts on exotic setups.
4. Star the repo if it helped you — it genuinely helps visibility for the project and makes it easier to justify continued work (including for programs like Codex for OSS).

See [CONTRIBUTING.md](CONTRIBUTING.md) (creating) for the exact safe process to suggest targets.

## Install as a reusable skill (for agents — recommended)

The complete package (SKILL.md contract + catalog/ (the data-driven extensible targets core with rich metadata) + commands/ (the comprehensive portable safe command reference library — rich reusable cross-platform snippets, helpers, and sequences that agents load, adapt with live data, and execute directly via tools after permission; the focus of this implementation for self-contained excellent assets for capable LLMs) + REFERENCE.md + explanations/ deep edu modules + detection-commands.md + reference scripts + reclaim.py) is designed to be dropped into any modern agent's skills directory. The high-level principles, detection recipes, permission protocol, decision frameworks, catalog, and commands/ library let capable LLMs (Claude, Grok, Cursor, etc.) execute intelligently without over-specification.

```bash
# Claude Code / Cursor / Aider / Windsurf / similar
git clone https://github.com/FrancoEscob/deep-disk-cleanup.git ~/.claude/skills/deep-disk-cleanup

# Grok (and similar)
git clone https://github.com/FrancoEscob/deep-disk-cleanup.git ~/.grok/skills/deep-disk-cleanup
```

Then just ask the agent: "perform a deep disk cleanup" or "run the deep-disk-cleanup skill on my machine with full education".

The dir is self-contained and ready to copy (catalog/ travels with it as the living targets knowledge base). See SKILL.md for invocation expectations.

## License

MIT — see [LICENSE](LICENSE).

---

**If this project helped you reclaim real space without drama, star it and tell a friend (or the thread where you saw it).** Real tools that solve painful problems for the people who build open source deserve to be discovered.

Made for (and by) people tired of their dev machine eating their disk.
