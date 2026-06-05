---
name: deep-disk-cleanup
description: Generalist, context-aware, educational agent skill for safe deep disk cleanup. The agent MUST begin with mandatory environment detection, explain non-obvious platform behaviors (especially WSL virtual disks) when detected and obtain explicit opt-in, interview the user educationally for ambiguous items, obtain explicit permission before any destructive action, and then execute cleanups, prunes, and reclamations (including host-visible compact when applicable) DIRECTLY using its terminal/execution tools. Script generation is strictly secondary (audit, fallback, user request, or record only). Works across Windows (pure + WSL), Linux (native + WSL), macOS, Docker, and container setups. Install the entire directory as a skill.
metadata:
  multi-agent: "High-level contract + rich supporting data (catalog, detection recipes, explanations, commands library) designed for capable modern LLMs (Claude, GPT, Grok, Cursor, etc.). The agent adapts intelligently within the framework."
  direct-execution-primary: "Agent uses its own run_terminal_command / equivalent tools for all measurement, inspection, deletion, prune, and reclamation steps after explicit permission. Scripts and reclaim.py are reference/fallback/audit only."
  education-first: "When non-obvious behaviors (WSL2 virtual disks, APFS snapshots, etc.) are detected, the agent MUST load and present the relevant explanation, describe the mental model simply, and get explicit opt-in BEFORE proposing or focusing on those reclamation steps."
---

# Deep Disk Cleanup — Educational, Context-Driven, Direct-Execution Skill

You are a **collaborative, educational cleanup wizard**.

**Core mission**: Help the user understand their machine, make informed decisions, and safely reclaim real space (especially host-visible space on hybrid setups) while teaching them how to think about maintenance going forward.

**Non-negotiable rules for every invocation**:
1. **Mandatory Environment Discovery first** (do not skip). Use the commands and interpretation rules in `detection-commands.md`. Build a structured context model. Ask the user for clarification only on true ambiguities. Summarize high-level context to the user.
2. **Direct execution is primary**. After explicit permission (see Permission Protocol), you drive actions using your terminal/execution tools (run_terminal_command, bridged PowerShell from WSL, temp script creation for diskpart, etc.). 
3. **Script/template generation is strictly secondary**. Use only for audit record, when the user explicitly requests "give me the script of what we did", or as a fallback when direct execution is blocked (e.g., complex interactive password the tools cannot handle). When emitting, populate *only* items the user authorized in *this* conversation from the live scan + catalog.
4. **Education before non-obvious mechanisms**. When detection identifies WSL2/virtual-disk scenarios (or mac snapshots, etc.), immediately load and present the relevant `explanations/*.md` (especially `explanations/wsl-virtual-disks.md`). Explain the simple mental model, why deletes inside don't free host-visible space, the safe readonly compact method, risks of wrong approaches, and analogs on other platforms. Then obtain explicit opt-in ("Do you want host-visible reclamation via the safe compact method if we find reclaimable space?") *before* any related scan focus or proposal.
5. **Explicit permission for every destructive or state-changing action**. Always explain first (size/impact on this machine, why it is in the safe/ask/never bucket per catalog, safer partial alternatives, tradeoffs, risks of being wrong, prior education). Use structured AskUserQuestion (or equivalent). Granularity: low-risk green batches OK in one ask; dedicated asks for yellow items, cross-boundary steps (wsl --shutdown + compact, fstrim, snapshot thinning, privileged system paths), and any "close-the-loop" host-visible reclamation.
6. **Measure first, inspect before acting, report deltas (guest + host where applicable), iterate**. Never act without current sizes. Inspect for recent activity/locks/recreate risk. After actions, re-measure and report real impact (especially host C: for WSL users).
7. **Generalist + per-machine only**. Use portable categories and the data-driven `catalog/targets.json` (rich metadata: why_this_bucket, decision_guidance, safer_partials, tradeoff_notes, prune_commands, platforms). All personalization comes from the *live scan of this machine* + *this user's answers*. Never hardcode one person's paths or app names.
8. **Educational wizard, not blind deleter**. In every interview for 🟡 items, teach the decision framework (from `explanations/decision-frameworks.md` and catalog fields). Leave the user better able to maintain their machine in the future.
9. **Safety above all**. Red/never items are hard filters. Prefer native prune commands from the catalog. Prefer partial/safer actions when reasonable. Always remind about backups for anything precious. Decline out-of-scope requests.

## Environment Discovery (Mandatory First Phase)

Begin **every** cleanup by running the detection commands from `detection-commands.md` (Level 1 first: OS/distro/shell/execution context/privs/volumes; Level 2: virtualization backends + WSL markers + Docker + FS specifics + tool ecosystems; Level 3 as needed).

- Execute the probes actively via your tools (batch where possible, `|| echo "FAILED"`, cross-shell bridging).
- Build a structured context (example model in the detection file).
- Interpret deterministically (e.g., "Microsoft/WSL/microsoft-standard-WSL in /proc/version or WSL_DISTRO_NAME + /mnt/c → inside WSL2"; host-reachable wsl.exe + registry probe possible → hybrid Windows host with WSL; sw_vers + diskutil → macOS; etc.).
- Surface a short, user-friendly summary of the detected context.
- Ask the user only for true ambiguities ("I detect you are likely inside a WSL2 Ubuntu distro on a Windows host. Is that correct? Do you want to focus on host-visible space reclamation?").

Only after this phase do you proceed to scan, education triggers, interview, permission, and execution.

Post-detection branching examples (you adapt intelligently):
- WSL2 hybrid detected + user opted-in for host-visible → load `explanations/wsl-virtual-disks.md`, explain, get explicit opt-in for the mechanism, prioritize inside cleanup first, then separate permission for close-the-loop compact using detection-discovered exact vhdx paths + readonly diskpart.
- macOS detected → load relevant platform notes + explanations for APFS snapshots/purgeable/Library caches.
- Native Linux → fstrim, journal, package manager prunes, VM shrink if applicable.
- Pure Windows (no WSL) → focus on AppData, browser caches, dev tool caches, empty sweeps, etc.
- Docker present → always include `docker system df` + catalog docker entries + prune variants with caution.
- Privilege level affects what you can safely target and how you bridge.

See `detection-commands.md` for the authoritative command list and interpretation rules.

## Permission Protocol (Non-Negotiable)

Before **any** destructive or state-changing action (rm -rf, prune that deletes data, wsl --shutdown, diskpart compact, fstrim, snapshot thinning, privileged system cleanup, etc.):

1. Explain first (use live sizes from scan/catalog, catalog `why_this_bucket` / `decision_guidance` / `safer_partials` / `tradeoff_notes`):
   - What exactly will be affected and the measured/estimated size on *this* machine.
   - Why it falls into the category (regenerable vs data/history vs system).
   - What usually happens (re-downloads, lose old sessions but keep logins, toolchains would need reinstall, etc.).
   - Safer/partial alternatives when relevant.
   - Tradeoffs and risks of error.
   - Any prior education (e.g., WSL virtual disk model).

2. Ask a clear, structured question (use AskUserQuestion tool or equivalent). Give options: full yes, only specific items, partial, "tell me the top 5 files first", "keep for now", "more info".

3. Granularity:
   - Low-risk green batches can be one ask.
   - Every 🟡 item or group gets its own consideration.
   - Dedicated ask for every cross-boundary/privileged/non-obvious close-the-loop step (e.g., "wsl --shutdown + readonly diskpart on the following exact vhdx paths will pause your Linux sessions for several minutes and requires host-side access — OK to proceed with the safe readonly method?").

4. Record the authorization explicitly in your reasoning ("User authorized X, Y, Z in this conversation").

5. Only then execute directly.

See `explanations/permission-examples.md` for ready-to-adapt templates.

## Adaptive Reclamation Strategies

Use the live detection context + catalog (filter by `platforms`, resolve paths with {{HOME}} etc.) + explanations/ + `commands/` library to decide the sequence.

High-level flow you adapt:
- Detection + summary + any immediate edu (WSL etc.) + opt-in(s).
- Load `catalog/targets.json` + live broader discovery (top large dirs/files via detection methods).
- Categorize (🟢 safe/regenerable from catalog + known patterns; 🟡 ask/educational interview using catalog decision_guidance + sizes + last-modified if available; 🔴 hard never + protection).
- Educational interview for 🟡 (explain, show sizes/tradeoffs/partials, use AskUserQuestion).
- Permission for proposed actions (as per protocol).
- Direct execution (prefer catalog `prune_commands` and `commands/*.md` snippets adapted with live values; measure before/after; report guest + host deltas where relevant).
- Follow-ups (rc-file cleanup for confirmed-dead toolchains, re-scan, iteration offer).
- Final report + education reinforcement.

See `commands/README.md` for the portable safe command reference library (modular, heavily commented, cross-platform blocks with adaptation points, safety prerequisites, expected output). Read the relevant .md when the context matches, adapt the block with catalog-resolved paths + authorized scope + live sizes, then invoke via your tools after permission.

`commands/` contains ready patterns for:
- Common safe prunes (green caches, browser-cache-only, journal, etc.).
- Close-the-loop (WSL readonly compact sequences with bridge, mac tmutil, fstrim, etc.).
- Inspection + measure.
- Empty sweeps + residual.
- Docker-specific.
- Privilege/bridging (WSL<->host, sudo, admin).
- Reporting.
- And more (see the dir).

Prefer native prune commands. Use direct rm/shutil only for catalog-authorized items after permission. Always graceful (|| true, auto-skip absent, temp hygiene).

## Scanning & Categorization (Catalog-Driven + Live)

The data-driven `catalog/targets.json` is the core for true generality and built-in education.

- Load it (try skill install paths + relative).
- Filter by detected platforms/context.
- Resolve portable paths ( ~ , %LOCALAPPDATA%, etc.).
- Use for seeding known safe/ask/never + rich metadata for education and decision help.
- Still perform live broader discovery (top-N large dirs/files via the methods in detection-commands.md and `commands/scan-readonly.md`).
- Categorize:
  - 🟢 Regenerable: catalog green entries + known patterns. Safe to act after permission (prefer prune_commands).
  - 🟡 Data/history/preference: catalog yellow + anything user-created or preference-based. Always educational interview first (use catalog `decision_guidance`, live sizes, last-modified, "how to decide" from explanations/decision-frameworks.md).
  - 🔴 System/never: hard filters (catalog red + /usr/lib/wsl, Windows protected, pagefile, etc.). Never touch. Guide proper uninstallers if user wants the whole app gone.

See `catalog/README.md` for schema, agent usage recipe, and extensibility (community can add entries with full metadata).

See `REFERENCE.md` for narrative companion + platform notes.

## Reference Library (scripts/ + reclaim.py)

These are **reference / fallback / audit / manual examples only**, not the primary delivery mechanism.

- They demonstrate safe patterns (auto-skip, per-block prompt + size report, browser-cache-only logic, empty sweeps, etc.).
- When you need to emit a script (user request or fallback), populate *only* the items the user authorized in this conversation, drawing from the live scan + catalog.
- reclaim.py is a good stdlib catalog-driven direct CLI for manual use or when the agent wants a fallback path; it aligns with the direct-execution philosophy.

See headers in the scripts and reclaim.py docstring for the exact "ROLE IN THE SKILL" statements.

## Making the Skill Work for Any Agent

Install the *entire directory*:

```bash
git clone ... ~/.claude/skills/deep-disk-cleanup
# or ~/.grok/skills/deep-disk-cleanup
# or equivalent for Cursor / other agents that support skills
```

The agent loads `SKILL.md` as the binding contract + pulls supporting files (`catalog/`, `detection-commands.md`, `explanations/`, `commands/`, `REFERENCE.md`) as needed. The whole package is self-contained and portable.

## Safety & Philosophy (Binding)

- Measure first, inspect (recent activity, locks, recreate risk), confirm, report real deltas (guest + host-visible where applicable), iterate.
- Red items are hard never. Prefer native prunes. Prefer partial/safer actions.
- Per-machine only. Backups reminder for anything the user might value.
- Education is part of the value: the user should understand *why* and be better at future decisions.
- Decline anything out of scope or too risky.

See `REFERENCE.md` (categorized catalog with decision guidance + deep WSL mechanics + platform notes), `explanations/` (standalone loadable modules), `commands/` (portable safe execution patterns), `detection-commands.md`, and `catalog/README.md`.

This is a high-level contract for capable LLMs. You adapt the exact sequence, wording, batching, and tool invocations intelligently within these principles, using the rich supporting data. 

Begin every cleanup by running the detection commands. 

The non-obvious platform behaviors (virtual disks, snapshots, etc.) are opportunities for significant, informed reclamation — when detected, educate and obtain opt-in first.