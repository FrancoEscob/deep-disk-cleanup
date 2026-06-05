# Portable Safe Command Reference Library

**This is a core reusable asset of the deep-disk-cleanup skill.** It provides high-quality, cross-platform, safe, commented command snippets, small sequences, helpers, and patterns that a capable LLM agent can **directly read, adapt using live detection/scan results, and invoke via its terminal/execution tools** (after explicit user permission per the Permission Protocol in SKILL.md).

## Philosophy & Role (Critical — Internalize)
- **Direct execution primary**: After detection (detection-commands.md), context edu + opt-ins (explanations/), live catalog-driven scan + interview, and **explicit permission** (AskUserQuestion or equiv explaining size/impact/risks/alts), the agent **drives** the actions itself using `run_terminal_command` (or equiv). This library supplies the exact, safe, battle-tested command text to paste/adapt into those calls.
- **Scripts/ are secondary reference library too**: The `scripts/` (and reclaim.py) demonstrate full flows or standalone use. This `commands/` is the granular, atomic, mix-and-match library for the agent's direct path. When the agent must emit an audit/fallback artifact (rare), it can compose from here + only user-authorized targets.
- **High-level for smart LLMs**: No rigid "run this exact", but rich, self-contained, commented blocks with:
  - Platform/context applicability
  - Safety notes, inspect prerequisites, measure before/after
  - Adaptation points (replace `{{VHDX_PATH}}`, `{{TARGET}}`, sudo logic, bridging)
  - Expected output / success signals
  - Gotchas + graceful degradation
  - Cross-refs to catalog entries, SKILL.md sections, explanations/
- **Generalist & portable**: Uses variables, env, common patterns. Never contains one user's paths. Agent resolves from live context (WSL home vs host, %LOCALAPPDATA% -> $env, /mnt/c bridges, etc.).
- **Safety baked in**: Every destructive or state-changing snippet assumes prior permission, includes or calls for pre-measure (`du -sh`, `Get-Item`), post-measure, and often a "dry" or list-first variant. Respect reds from catalog. Privilege-aware.
- **Educational**: Snippets often include `echo "Explanation..."` or comments the agent can surface. Teaches user via the process.

**How the agent uses this library (per SKILL.md adaptive tree + direct exec responsibilities)**:
1. Post-detection + catalog load + scan: decide which command groups apply (e.g. WSL-hybrid → load wsl-hybrid-specific.md + close-loop).
2. For a green batch or authorized yellow item: read the matching prune snippet(s), adapt paths from catalog resolution + live du results, confirm the adapted command text to user in the permission ask ("I will run: `...` — impact: ~X GB, safe because..."), then execute via tool.
3. For close-the-loop (compact, fstrim, etc.): only if context + opt-in + dedicated perm; use the full sequence snippets (often multi-step: write temp file for diskpart, invoke, cleanup temp).
4. For inspect: always interleave patterns from inspect-and-measure.md.
5. Bridge when needed (WSL <-> host): use patterns from privilege-bridging.md and detection knowledge.
6. After any: re-measure using scan patterns, report deltas (guest + host where applicable), offer iterate.
7. Fallback emit: if needed, cat relevant snippet + personalize with only authorized items into a temp script the user can review.

Load specific files with your `read_file` / open tool when the context matches — they are lean but deep.

Update this library when reliable new safe patterns emerge (new tool prunes, better bridging, OS changes). Keep commands practical, ASCII-friendly where possible (esp. for PS 5.1), and commented for both humans and agents.

See:
- `SKILL.md`: Permission Protocol, direct exec primary, adaptive decision tree, agent responsibilities.
- `catalog/targets.json` + catalog/README.md: master targets + `prune_commands` hints (prefer those; this lib expands them with full safe wrappers + platform variants).
- `detection-commands.md`: probes that locate the live values (vhdx paths etc.) this lib's snippets consume.
- `explanations/`: deep edu to deliver before using close-loop snippets (esp. wsl-virtual-disks.md).
- `scripts/`: full reference flows that compose ideas from here.
- `REFERENCE.md`: narrative companion.

This design keeps the skill **extremely self-contained and excellent for capable LLMs** (Claude, Grok, Cursor, any): principles + data (catalog) + recipes (detection) + deep edu (explanations) + **this granular executable library** = agent can act intelligently, safely, educationally on any machine without the original author.

## Directory Contents (Modular for Targeted Loading)
- `common-patterns.md`: Universal helpers (measure, human sizes, before/after, temp file safe creation, auto-skip absent, empty dir logic snippets).
- `scan-readonly.md`: Fast, safe, context-native discovery and sizing commands (df/du variants, top-N, docker df, no expensive crosses).
- `green-prune.md`: Preferred native prune commands + safe rm wrappers for 🟢 catalog items (npm, pnpm, uv, pip, docker, journal, brew, apt, browser-cache-only, ide-servers, etc.). List-first + execute variants.
- `yellow-patterns.md`: Inspect + targeted delete helpers for 🟡 (models, toolchains, downloads, abandoned artifacts). Emphasize per-item or scoped.
- `close-the-loop.md`: The critical platform "finish the job" steps (WSL readonly vhdx compact full sequences with diskpart script gen + bridge, macOS tmutil snapshot thin, native Linux fstrim, VM shrink notes). **Requires prior edu + opt-in + dedicated perm**.
- `inspect-and-measure.md`: Safety inspection (locks, recency, processes, recreate risk) and precise before/after measurement patterns.
- `privilege-bridging.md`: Cross-context execution (sudo -n, powershell.exe bridge from WSL, wsl.exe from host, diskpart /s, elevation notes, when to guide user vs direct).
- `empty-sweeps.md`: Generic 0-byte / residual folder sweeps with safe skip lists (AppData, /tmp variants). Reference impl of the pattern in scripts/.
- `docker-specific.md`: docker system df + prune variants, volume caution, WSL-backend notes.
- `browser-caches.md`: Only-cache clears for Chromium/Firefox families (never whole profiles). Close-browser reminder.
- `followup-edits.md`: Small post-delete cleanups (rc-file sourcing lines for removed toolchains, PATH, etc.). Separate small perm.
- `reporting.md`: Before/after reporting snippets and templates (guest + host-visible deltas, iteration offers).

**Usage example for agent (internal)**:
```
# After WSL detection + WSL edu + opt-in + inside green batch authorized:
read commands/close-the-loop.md  (focus on WSL section)
# adapt the diskpart block with exact {{VHDX_PATH}} from detection JSON model
# write temp script using echo/cat + run_terminal_command with heredoc or printf
# separate AskUserQuestion: "Ready for wsl --shutdown + readonly compact on the 3 discovered vhd x? (will pause WSL for minutes; host C: will shrink after)"
# then run the bridged wsl --shutdown; diskpart /s /tmp/compact-xxx.txt ; etc.
# re-measure with Get-Item on host bridge + df inside
```

All snippets are **ready to adapt and run**. They prioritize safety, portability, and education.

Contribute: Add a new snippet family with evidence it is safe/recurring, full comments, platform coverage, adaptation notes. PR against the commands/ files (or new .md). Test mentally against the Permission Protocol.

This library + the rest of the package = the reference implementation for **portable, direct-execution, educational agent skills**.
