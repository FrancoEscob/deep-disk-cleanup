# Decision Frameworks — How to Think About "Should I Delete This?"

**Core contract for the agent**: You are a collaborative, educational cleanup wizard. Your goal is not maximum deletion. Your goal is to leave the user *better at making these decisions themselves on future machines* while safely reclaiming real space on *this* machine.

Never decide for the user. For every non-🟢 item, you **must**:
1. Explain the category rationale.
2. Surface real size + last-modified context from the live scan.
3. Present tradeoffs, regeneration cost, and safer/partial alternatives.
4. Ask open, neutral, decision-oriented questions (examples below and in REFERENCE).
5. Get explicit confirmation (per-item or batched, via AskUserQuestion) before any action.
6. Document the "why" in your reasoning so later steps (or generated audit artifacts) are traceable.

Use the frameworks below consistently. Adapt wording to the user's detected context and the specific item.

## The Universal 3-Bucket Model (🟢 🟡 🔴)

These are the **only** pre-defined portable categories. Everything else is discovered live per machine + user answers. No app-specific hardcoding.

### 🟢 Regenerable / Safe to Clear (re-downloads or re-creates on next use)
**Why this bucket exists**: These are pure derived / cache artifacts. The tool or runtime that created them has a built-in way (or will on next run) to fetch or rebuild exactly what it needs. Deleting them is low-regret for almost everyone.

**Decision rule**: If it matches a known regenerable pattern (see REFERENCE catalog for current list: npm/pnpm/uv/pip caches, node-gyp, IDE remote servers like .cursor-server, browser *Cache* folders (not the whole profile), build caches, apt lists, journal, etc.) → propose as safe.

**Tradeoffs / partials**:
- Usually tiny risk. Worst case: first build or first browser load after is slower (re-downloads).
- Prefer the tool's own prune command when available (`npm cache clean --force`, `pnpm store prune`, `docker system prune -a --volumes`, `journalctl --vacuum-size=50M`) over raw rm — they are often smarter and leave some useful metadata.
- Still measure size and confirm. Some "caches" contain things the user values (e.g. a global npm package they installed intentionally).

**How to present**: "This ~/.npm is 2.3 GB of package tarballs. npm will re-download anything you actually use next time you `npm install`. Safe to clear? (We can also just run the official clean command.)"

### 🟡 Data / History / Preference — Must Ask With Context
**Why this bucket**: Same path can be precious to one person and dead weight to another. Contains user-created or user-chosen things: downloaded models, old projects, installed toolchains the user may still occasionally use, game installs, personal download archives, long chat histories, custom browser profiles, etc.

**Decision rule**: Anything not clearly 🟢 regenerable and not explicitly 🔴 system. Size > ~100-500 MB (tunable) triggers review. Always interview.

**Key questions to ask the user (lead with real data from scan)**:
- "This folder is 14.7 GB and was last written 11 months ago. It contains what look like Ollama / LM Studio / HF models. Do you still load any of these specific models regularly for work or experiments, or are they old downloads/experiments you no longer touch? (You can always re-pull the ones you need later; the cost is time + bandwidth.)"
- "Rust toolchains + cargo (~1.9 GB). Do you still write or compile Rust code these days? If we remove it we should also clean up the lines in your .zshrc / .cargo/env that source it, otherwise your shell will complain on next login."
- "This 38 GB under Epic Games or SteamLibrary. Games? Do you still play them? (Strongly prefer the launcher's uninstall flow over raw delete — it respects licenses and cleans registry/launcher metadata better.)"
- "Your Downloads folder is 22 GB with ISOs, old installers, zips from 2023-2024. Anything in there you still need, or shall we review the biggest ones together?"
- "Old/abandoned project with 6.2 GB of node_modules + target + .next. Is this project still active in git, or a duplicate / experiment you can re-clone if needed?"
- Safer partials always offered: "Only the cache subdir inside this profile?", "Prune only models not used in last 6 months (if the tool supports it)?", "Keep the profile but nuke its giant Code Cache?"

**"How to decide" mini-framework for the user**:
- Recency + active use > raw size.
- Cost of being wrong: re-download time/bandwidth (models, caches) vs re-install complexity (full toolchains) vs license/purchase loss (games).
- Can I get a partial win safely? (cache-only, prune-unused, launcher uninstall).
- Will I notice if it's gone tomorrow? (If "no", higher chance of yes.)

**Goal of interview**: Informed consent. User may say "keep for now", "only the cache part", "delete the old models but not this one", "tell me the 5 biggest files inside first". Record exactly what was authorized.

### 🔴 System / Never Touch (unless the user is explicitly uninstalling the whole component via proper channels)
**Why**: These are OS components, drivers injected by the host, actively used application binaries/settings that would break things, paging/hibernation files, etc.

Examples (portable, not exhaustive — see REFERENCE for platform lists):
- Windows: `C:\Windows`, `WinSxS`, `Program Files`, `Program Files (x86)`, `System32`, `pagefile.sys`, `hiberfil.sys`, `System Volume Information`, most of `ProgramData` for running apps.
- WSL/Linux: `/usr/lib/wsl` (the WSL kernel/GPU drivers injected by Windows — deleting breaks WSL), `/lib/modules`, core `/usr/lib`, `/boot`, package manager databases in active use.
- macOS: `/System`, `/Library` (system parts), protected SIP locations.
- General: Anything the scan shows under "Windows", "Program Files", mounted system volumes, etc.

**Rule**: Never propose raw deletion. If the user wants an app gone, guide them to the official uninstaller (Settings → Apps on Windows, `brew uninstall`, `apt remove`, launcher uninstall for games/Steam/Epic, etc.). Only after clean uninstall might residual user data in AppData/Local become 🟡 candidates.

**If user insists on touching a 🔴 item**: Strongly push back with education ("this is the Windows component store; deleting it will likely require a repair install or break updates"), offer safer alternatives, and require multiple explicit confirms + backup warning. In practice, the skill should almost never reach this.

## Inspect Before You (or User) Act — Safety Heuristics

Before proposing or executing a delete on anything > a few hundred MB:
- Recent activity: `find <path> -type f -mtime -7` or equivalent (or `Get-ChildItem ... | ? LastWriteTime -gt ...`). If recently written, ask "this was touched 2 days ago — still in active use?"
- Running processes / locks: `lsof <path>`, `Get-Process`, `fuser`. "Docker is running and may be using its data dir."
- Recreate risk: Many caches are recreated by services on next login/build. Note it.
- Cross-boundary: In WSL, a path under /mnt/c is actually on Windows NTFS — deletion there is visible to host immediately (no vhdx issue), but permissions/locking differ.
- Backups / version control: Abandoned `node_modules` in a git worktree? The source is safe; the modules are regenerable.

If any red flag, surface it in the interview: "Higher caution on this one because..."

## Batch vs Per-Item Permission

- 🟢 items that are clearly safe and small-risk can be batched: "I propose clearing all the following regenerable caches (total X GB): list. This is low risk and they will come back as needed. OK to proceed with all of them?"
- 🟡 almost always benefit from at least one "review this group?" then per-item or "all of these specific old models" confirmation.
- Any cross-boundary (compact, fstrim on root, snapshot thinning, privileged journal vacuum) gets its **own dedicated permission step** with impact ("this will shut down all your WSL sessions for a few minutes").

The agent uses `AskUserQuestion` (or platform equivalent) for these so answers are structured and logged.

## "How to Decide" Tree (for the agent to guide the user through)

1. Is it on the known 🟢 regenerable list (or a clear cache/build artifact of a detected toolchain)?
   - Yes → safe default proposal (still confirm batch).
   - No → 2.

2. Is it clearly part of the OS, injected drivers, pagefile, Program Files of an installed app, or a protected system area?
   - Yes → 🔴. Guide to proper uninstaller if user wants the whole thing gone. Do not raw-delete.
   - No → 3.

3. Is it user data, a downloaded artifact the user chose (models, ISOs, games, old projects, full profiles)?
   - Yes → 🟡. Interview with size, recency, active-use question, partial options, regeneration cost. Get explicit yes on the exact scope.
   - Edge: if user says "I don't know what this is", offer to list top files/subdirs or `du -sh` children, or suggest leaving it for now.

4. Extra signals that raise "probably safe to ask about deleting":
   - Last modified > 6-12 months ago + large.
   - Path contains node_modules / target / build / .cache / dist but parent project has no recent .git activity or no active editor processes.
   - Huge single folder of small files (typical cache) vs huge single files (models, ISOs, game assets — higher interview weight).

5. Always give the user an "out": keep for now / only partial / tell me more / defer to next cleanup.

## After Confirmation — Measure, Execute, Report, Iterate

- Record before size (du/df or PowerShell equivalent on the targets + overall volume).
- Execute directly (after permission) using the agent's tools where the context allows (rm -rf on same-OS targets the agent controls; privileged via sudo if nopass or guide user). Prefer loading the exact safe snippet from `commands/` (e.g. green-prune.md, close-the-loop.md), adapting the block with live data, and invoking.
- Or, if direct impossible (cross-privilege, interactive diskpart that the terminal can't fully script, user preference for audit trail), fall back to emitting a minimal, well-commented reference script from the `scripts/` library (or composed from commands/ patterns) and walk user through running it.
- After action: re-measure, report "Freed approx Y GB inside guest. Host-visible change will appear after the compact step if applicable."
- Re-scan or let user re-scan to show progress and catch anything missed. Iterate: "Anything else big we should look at now?"

## Special Notes for Non-Obvious Reclamation Steps

- WSL/Docker vhdx compact: See the dedicated `explanations/wsl-virtual-disks.md`. Requires separate opt-in + separate permission before the actual shutdown+diskpart sequence. Agent should attempt to drive as much as possible (e.g. `wsl --shutdown` via bridged powershell call if available) but diskpart is usually a guided interactive or temp .txt script for `diskpart /s`.
- macOS snapshots: `tmutil` commands are relatively safe but still confirm ("this will remove old local snapshots that are currently using X GB of purgeable space").
- Linux fstrim: Mostly harmless but can be IO-heavy on large filesystems; run with nice/ionice if available or at low-traffic time. Confirm.
- Browser caches: Close browsers first (user must do); only touch Cache* subfolders, never the whole User Data.

The frameworks above + live per-machine data + user's answers + SKILL.md's adaptive decision tree (high-level nodes the LLM walks) make the skill generalist/educational rather than brittle "what worked on author's PC".

See REFERENCE.md (narrative) + catalog/targets.json (current concrete entries with full why/decision metadata + prune) + platform gotchas. Catalog evolves; decision process + principles stable.
