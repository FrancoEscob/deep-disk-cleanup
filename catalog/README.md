# Catalog — Data-Driven Targets for Deep Disk Cleanup

This directory holds the **core data-driven catalog** (`targets.json`) that powers the skill's generality, education, and adaptability.

The catalog is the single source of truth for common portable bloat targets. Agents (and the standalone `reclaim.py`) load it to:

- Seed live per-machine scans with known high-value locations (instead of hard-coded lists in the agent's "mind" or in scripts).
- Categorize findings immediately into the three portable buckets using the embedded rich metadata.
- Deliver **built-in education** during interviews: every entry carries `why_this_bucket`, `decision_guidance`, `safer_partials`, `tradeoff_notes` so the agent can quote or adapt consistently without hallucinating rationale.
- Recommend the best prune method (`prune_commands` keyed by platform/ecosystem — prefer the tool's native command over raw `rm`).
- Support community extensibility: new safe targets are added here via PR with real evidence.

**Why data-driven (this candidate's focus)**: Textual lists in REFERENCE.md or hardcoded arrays in scripts/Python are fragile, hard to contribute to, and don't travel with rich decision/education context. A structured file (JSON chosen for zero-dep parse in reclaim.py + universal readability) makes the skill truly generalist and future-proof. The LLM is smart: give it the data + principles (in SKILL.md minimal powerful contract + adaptive decision tree) + decision frameworks (explanations/) and it adapts intelligently to the live machine + user answers.

## Schema (targets.json)

Top level:
- `meta`: version, description, usage instructions for agents, extensibility notes, category definitions, path resolution guidance.
- `targets`: array of objects.

Each target object:
- `id`: stable unique slug (kebab-case). Used for logging/references.
- `paths`: array of strings. Portable patterns using `~`, `$HOME`, `%LOCALAPPDATA%`, common Windows vars, POSIX variants. Agent resolves/expands for the detected context (Windows vs POSIX, WSL home vs host mounts, mac ~). Some entries intentionally have empty `paths` (e.g. "abandoned-project-artifacts", "docker-system") because they are patterns or command-driven discovered live.
- `category`: "green" | "yellow" | "red" (maps to 🟢 🟡 🔴 in UI/docs).
- `platforms`: array subset of ["windows", "linux", "macos", "wsl"]. "wsl" for entries especially relevant inside guests or for hybrid.
- `description`: one-line human label.
- `why_this_bucket`: explanation the agent uses to teach the user *why* this landed in green/yellow/red. (Core of education.)
- `decision_guidance`: suggested questions/phrasing + signals (size, mtime, contents) the agent should surface in the personalized interview. Never decide unilaterally.
- `safer_partials`: list of lower-risk alternatives the agent must offer (e.g. "use the tool's prune command", "only specific sub-items", "official UI uninstall").
- `tradeoff_notes`: what the user gives up (re-download time, first-run slowness, loss of rollback) so consent is informed.
- `prune_commands`: object with platform or ecosystem keys (e.g. "all", "posix", "apt", "macos_linux") giving the exact recommended command string(s). Agent prefers these after permission. Empty object = "direct targeted delete of the resolved paths after inspect + confirm".
- `notes`: gotchas, special handling (e.g. "browser caches: only subdirs", "requires sudo", "live-scan pattern only").

Red entries exist primarily as an explicit "do not touch" reference list so broad scans (top du, AppData dir walks, WizTree) can be filtered intelligently and the agent never accidentally proposes them.

## How the Agent Uses the Catalog (per SKILL.md)

After **mandatory Environment Discovery** (detection-commands.md) and context summary + any non-obvious education (explanations/ + WSL virtual disks opt-in):

1. Load `catalog/targets.json` (read the meta + scan the targets array).
2. Adapt the list to current context:
   - Filter by `platforms` matching detected (WSL inside → linux + wsl; pure Windows host → windows; mac → macos; native Linux → linux).
   - Resolve paths (expanduser, env var substitution, handle /mnt/c vs Linux home, mac ~/Library vs /Users).
   - For hybrid: include both guest paths and any host-visible notes.
3. During live scan (context-appropriate: `du -sh` targeted on *nix/WSL, PowerShell Get-ChildItem + WizTree rec on Windows, `diskutil` + `du` on mac):
   - Always measure the catalog paths that exist (auto-skip absent).
   - Also do broader discovery (top-N largest in ~ / AppData/Local / Library/Caches, docker system df, etc.) for items not (yet) in catalog.
   - For discovered unknowns: apply the portable decision frameworks (REFERENCE + explanations/decision-frameworks.md) to bucket them. The catalog seeds the "known good" cases with rich metadata.
4. Categorize + educate:
   - 🟢 : batch into low-regret groups. Explain category once using the `why_this_bucket` etc. Then one permission for the batch (or sensible sub-batches).
   - 🟡 : for each (or logical groups), present real measured size + recency + rough contents + the `decision_guidance` + `safer_partials` + `tradeoff_notes`. Use AskUserQuestion (or equiv) with options including "tell me more / list top files", "keep", "partial", "delete".
   - 🔴 : filter out of proposals. If a broad scan surfaces something matching a red path, explicitly note "skipped because it is a protected system area (see catalog red entry)".
5. Prune preference: if `prune_commands` has a matching key for the platform/ecosystem, propose/execute that (after permission) rather than raw rm of the path. Examples: `npm cache clean --force`, `pnpm store prune`, `docker system prune...`, `journalctl --vacuum...`, `brew cleanup`.
6. Special cases noted in entries (browser cache subfolders only, docker command-driven not path rm, abandoned projects = live pattern + interview question, etc.).
7. Record which catalog ids + exact resolved paths + user authorizations for the run.
8. After actions: re-measure the same paths, report deltas (guest + host-visible where WSL hybrid), offer iteration.

The catalog makes education consistent and high-quality without the agent (or author) having to re-invent rationale per target. It also makes the skill "install and go" for any new agent — just point it at the dir.

Scripts in `scripts/` and the old lists in REFERENCE are now **illustrative / reference / audit artifacts only**. commands/ is the primary library of granular patterns for direct execution (preferred over emitting). They may embed a few examples for standalone manual use, but the master is here. When the agent emits a fallback script for the user (rare), it should populate only from the *user-confirmed* subset of catalog entries (plus any live ad-hoc items the user ok'd) and draw command text from commands/ snippets.

## Standalone reclaim.py Usage of Catalog

`reclaim.py` (stdlib-only) now loads `../catalog/targets.json` relative to itself (or the installed location). It falls back to a minimal internal list if the catalog file is missing/unreadable (for robustness in old installs or minimal envs).

It uses the `category`, `description`, `paths` for its scan + interview + direct shutil deletes. It does not yet surface the full education text (that's the agent's job in the primary flow), but the structure is ready for future enrichment of the CLI.

Run with `--list-only` or `--dry` to preview without touching the catalog-driven targets.

## Contributing / Extending the Catalog (Community)

See the full process in `CONTRIBUTING.md` ("How to propose a new safe target").

High-level for catalog additions:
1. Run a real scan on *your* machine (agent deep-disk-cleanup, or `reclaim.py`, or WizTree/ncdu/dust + du).
2. Identify a sizeable, recurring bloat item that is:
   - Clearly 🟢 regenerable for many people, **or**
   - Worth asking about (🟡) with a good decision question, **or** (rarely)
   - A 🔴 you want the skill to explicitly protect against.
3. Open a PR (or issue first for discussion) that:
   - Adds one well-formed object to the `targets` array.
   - Fills **all** fields with accurate, non-marketing language.
   - Provides evidence: size on your machine, why it grew, platforms it appeared on, how you prune today.
   - Justifies the category against the definitions in `meta.categories`.
   - Does not propose anything under red paths or that would require blind mass-delete of user data.
4. Test: On your machine, have an agent (or manually) load the catalog, scan the new entry, and walk the interview/permission flow (use --dry where possible).
5. Update `meta.last_updated`.
6. Small PRs for single targets are welcome and high-value.

Example minimal good addition (paraphrased):
```json
{
  "id": "gradle-cache",
  "paths": ["~/.gradle/caches", "%LOCALAPPDATA%\\gradle\\caches"],
  "category": "green",
  ...
}
```
With your scan data in the PR description.

New platforms, better prune commands, refinements to decision text, or splitting an entry (e.g. separate Firefox caches) are also great contributions.

Over time this becomes a living, community-curated knowledge base of safe reclamation opportunities — exactly what a generalist skill needs.

## Relationship to Other Files

- `SKILL.md`: The *minimal powerful binding contract* (principles + adaptive decision tree). References loading catalog for scanning/categorization/education.
- `REFERENCE.md`: Rich narrative companion (deep WSL mechanics, platform gotchas, WizTree, uninstall, frameworks summary). No longer duplicates target lists — points to catalog.
- `explanations/decision-frameworks.md`: Portable 3-bucket + signals + "how to decide" tree applied to catalog entries *and* live unknowns.
- `explanations/*.md` + `detection-commands.md`: Non-obvious edu (WSL mandatory first), platform notes, probe recipes + rules. Catalog complements.
- `commands/`: The comprehensive **portable safe command reference library** (modular .md with rich reusable cross-platform snippets, helpers, full sequences for scan/inspect/prune/close/bridge/empty-sweeps/browser/docker/etc.). The primary source of executable patterns for the agent's **direct execution** (read specific file when context matches, adapt live paths from catalog resolution + detection + user auth, invoke via terminal tools after permission per SKILL.md). Catalog `prune_commands` are the seeds; commands/ provides the safe full wrappers + platform variants + inspect + temp script creation + reporting. This makes the skill very self-contained with excellent reusable assets for capable LLMs.
- `scripts/`: Safe reference / fallback / audit. Headers point to catalog as master and to commands/ for the granular patterns. Demonstrate composition of ideas from commands/ + catalog. Agent emulates equivalent logic directly or emits tiny personalized copies.
- `reclaim.py`: Catalog-driven for its targets (direct in CLI). Great manual + agent fallback. Complements commands/ for cases where a full Python CLI is preferred.
- `CONTRIBUTING.md`, `README.md`, etc.: Reflect catalog as contrib/implementation focus + direct-exec philosophy + commands/ as the reusable execution library.

## Future Evolution Ideas (not blocking)

- Optional YAML source + generated JSON (for comments in source).
- Validation script / schema (JSON Schema) + CI lint on PRs.
- Richer per-entry fields (e.g. "typical_size_range", "last_modified_signals", "conflicts_with").
- Sub-entries or "prune_profiles" for more granularity.
- Agent can propose "add this live discovery to catalog" with pre-filled template after user confirms it's a recurring win.

The catalog makes the deep-disk-cleanup skill **the reference implementation for data-driven, educational, portable agent skills** in the sysadmin / dev hygiene space.

Load it. Use it. Extend it safely. Reclaim space thoughtfully.