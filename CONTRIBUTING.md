# Contributing to deep-disk-cleanup

Thank you for helping make dev machines less painful to live on. This project succeeds when it is **extremely safe** and **actually reclaims host-visible space** (the vhdx compact part).

We welcome contributions of all sizes: bug reports, docs, new safe targets, platform support, CLI code, tests, and "I freed X GB on [setup]" stories.

## Ground rules (non-negotiable for safety)

1. **Never add a target that isn't clearly safe or explicitly "ask the user"**.
   - 🟢 Regenerable caches only if they are truly re-downloaded/recreated by the tool.
   - 🟡 Anything with user data, history, logins, preferences, or long setup time → must ask with size.
   - 🔴 System paths, Windows components, WSL kernel bits (`/usr/lib/wsl`), pagefile, etc. are forbidden.

2. **Every new target must come from a real scan on a real machine.** No guessing paths from other people's machines.

3. **Any emitted artifact or direct action** must prompt/confirm before irreversible changes (primary is direct execution after Permission Protocol in SKILL.md) and report sizes before/after. Reference scripts still do this for audit/manual cases.

4. **Test on your own machine first.** Prefer `--dry` or read-only where possible. Report what happened.

5. **Respect the "educational wizard + direct execution, scripts as reference" philosophy.** Primary flow (SKILL.md): detection → education (esp. non-obvious) + opt-in → interview → explicit permission → direct agent execution. Scripts/templates in `scripts/` and reclaim.py are safe reference library / fallback / audit artifacts only (see their headers and SKILL.md). Personalization still comes only from live scan + this user's confirms. Don't turn this into a giant hardcoded list.

## How to propose a new safe target (highest value contrib)

1. Run a scan on your machine (agent or the `scan-disco.ps1` / `du`/`df` commands).
2. Identify a sizeable folder/file that is:
   - Clearly junk for *many* people in a similar setup, **or**
   - Regenerable, **or**
   - Worth asking about (with a good question + size).
3. Open an issue with:
   - Exact path(s) / glob (or pattern description for live-scan items)
   - Size on your machine + why it grew
   - Category (🟢 / 🟡 / 🔴) + justification against the definitions
   - Platform(s) it applies to
   - How to prune it safely (command or "just delete the dir") — this will become `prune_commands`
   - The education text you would want an agent to say: why this bucket, good decision questions (`decision_guidance`), safer partials, tradeoffs
   - Any gotchas (recreates itself? needs app closed? service?)
4. If accepted, we'll add a rich entry (following the exact schema in catalog/targets.json + catalog/README.md) to `catalog/targets.json` (the data-driven core and single source of truth for targets + education metadata). REFERENCE.md is now the narrative companion and no longer holds the primary lists. Small PRs directly editing the catalog entry (with evidence in description) are ideal.

Example good issue: "Propose: `~/.cache/huggingface` as 🟡 (large model downloads, user may still want some)" — include the full metadata fields for the catalog/targets.json entry.

## Adding / improving scripts, CLI, and reference artifacts

- The `scripts/*.ps1`, `scripts/*.sh`, `reclaim.py`, and especially the new `commands/` directory (the portable safe command reference library) are **reference implementations / helpers / fallbacks / direct-execution pattern sources** (see updated headers; reclaim.py loads catalog; commands/ are the modular rich snippets the agent prefers to read + adapt + drive directly). Improve their quality, safety, comments, cross-platform logic, adaptation guidance, and example patterns so the agent (or humans) can use the commands/ snippets as high-fidelity reusable assets for direct tool calls, or emit tiny composed artifacts as audit when needed. Add new command families (e.g. for a new package manager or backend) with full platform coverage and comments.
- Keep the same safety patterns: categorize (per catalog or frameworks), prompt/confirm before delete, report GB, auto-skip absent, respect 🔴.
- When the primary skill evolves (SKILL.md detection, permission protocol, adaptive branches, education mandates, catalog schema), reflect high-level consistency in the reference artifacts.
- The real "generation" is now minimal (agent may copy + populate only confirmed targets for audit, drawing from catalog); focus improvements on making the references excellent and the core skill (detection + direct exec + education + catalog) robust.

## Documentation & examples

- Improve README, REFERENCE, this file, or add examples.
- "Freed GB" reports are gold — open an issue or PR adding a short entry to a future `WINS.md` or the README examples section.
- Screenshots, terminal recordings (asciinema), or short videos are hugely appreciated.

## Agent skill usage

The `SKILL.md` (plus `catalog/` as the data-driven targets/education core, `commands/` as the comprehensive portable safe command reference library of reusable snippets for direct execution, detection-commands.md, explanations/, REFERENCE.md) is the binding contract for agents. It emphasizes: mandatory detection, load catalog for categorization + built-in rich education, load commands/ for execution patterns, educational responsibilities (esp. WSL virtual disks with opt-in), Permission Protocol for direct execution, adaptive context-driven strategies (scripts secondary). Changes to core flow, principles, detection, catalog schema, or commands/ library must be reflected in SKILL.md / catalog/README.md / commands/README.md / supporting files. The package must remain installable and portable for any modern agent (Claude, Grok, Cursor, etc.).

## Code style & practicalities

- PowerShell: keep compatible with PS 5.1 (Windows default) — ASCII where possible, no fancy features.
- New shell scripts: POSIX-ish bash, clear comments, `set -euo pipefail` where reasonable, always ask before rm.
- Python (CLI): prefer stdlib + optional nice TUI libs with graceful fallback. Keep deps minimal for easy `pipx` / one-file use.
- No telemetry by default. If we add optional "share my win" stats later, it will be opt-in and privacy-respecting.

## Pull requests

- Small & focused is best.
- For new targets: include evidence from your scan + the reasoning. Provide suggested full JSON object for `catalog/targets.json`.
- Update docs (README at minimum) when behavior or quickstarts change.
- Run the scan + a dry/test pass on your machine and mention the results in the PR description.

## Reporting issues

- "Disk still full after" → include before/after `df`, the script you ran, WSL/Windows versions, and whether you did the compact step.
- False positive / something got deleted you wanted → tell us the path and how it was categorized. We'll make the interview smarter.
- Feature request: the more specific ("support pruning old Ollama models by last-used + size"), the better.

## Code of conduct

Be kind, assume good intent, and remember the goal: help people (including OSS maintainers) keep their machines healthy without drama or data loss.

Thanks for contributing — every safe target or doc improvement makes the tool better for the whole community of hybrid devs, container users, and local AI experimenters.

If this project helped you, starring it helps others find it and gives us better signals that the tool matters for the ecosystem (useful for programs like Codex for OSS).
