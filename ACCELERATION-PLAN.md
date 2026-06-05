# deep-disk-cleanup Acceleration Plan
## Goal: Turn this into a *really good*, loved open source project that helps real people (sysadmin / dev machine maintenance) and qualifies strongly for OpenAI Codex for OSS (and similar programs).

**Date**: 2026-06 (rolling updates)

## The Opportunity (from @nicos_ai post + form)
- OpenAI Codex for OSS: 6 months ChatGPT Pro + Codex + possible API credits + Codex Security for maintainers of public OSS repos with "meaningful usage, broad adoption, or clear importance to the ecosystem".
- Applications rolling. Form asks for: public repo URL, your role (primary/core maintainer), why it qualifies (stars/downloads/importance), how you'll use credits.
- Community hack: many posting half-done/vibe projects + asking for stars in the thread. Bar for acceptance seems practical / good-faith, not ultra-strict (yet).
- **Our advantage**: We have a *real* tool with unique insight, not a demo. We can legitimately claim it helps the ecosystem (devs who maintain OSS often live in WSL/Docker/AI-tool hell and lose hours + disk to bloat).

**Legitimacy boosters we can build fast**:
- Real utility + safety focus.
- Growing stars from genuine "this freed 80GB safely" usage.
- Evidence of maintenance (issues, PRs, updates).
- Clear "importance": WSL2 + containers are table stakes for cross-platform OSS work. Keeping machines healthy = more OSS contribution capacity.
- Active README with usage stories.

## Current State Review (as of clone)
**Strengths (excellent seed for sysadmin OSS)**:
- Solves a *nasty, recurring, non-obvious* problem: "I deleted 100GB in WSL but Windows disk didn't budge". The vhdx compact + correct `diskpart` readonly flow is gold (most tutorials are incomplete or suggest dangerous `--set-sparse`).
- Safety + education architecture (refactored): mandatory Environment Discovery first, context-triggered deep education (WSL virtual disks etc. with explicit opt-in), broad portable categories only, live per-machine scan + decision-oriented interview (tradeoffs, partials, "how to decide"), explicit Permission Protocol (size/impact/risk, AskUserQuestion-style), **direct agent execution via tools primary** after permission (for all cleanups, compacts, etc.), scripts/templates strictly as safe reference library / audit / fallback only (no hard-coded other people's apps), always prompt + report GB (guest + host-visible). This is now the differentiated, generalist model for any agent.
- Educational: REFERENCE.md is high quality.
- Agent-collaborative: SKILL.md turns any capable agent (Claude Code today) into a personalized wizard. Smart pattern.
- MIT license, clean structure.
- Targets the exact audience that cares about Codex/tools (power users, AI-heavy devs, container users).

**Current weaknesses (why only ~3 stars, feels "internal")**:
- Primarily a *Claude Code skill* + PS1 templates. Most GitHub visitors can't try it immediately.
- No standout "wow" demo or visuals in README.
- Limited platform support in shipped code (Windows PS1 dominant; Linux mentioned but no scripts).
- No easy CLI / TUI / one-liner for non-agent users.
- README is accurate but not magnetic (no hero metrics/promise, no "before/after", weak CTAs).
- No community signals yet (no "freed X GB" examples, no contribution guide for new targets).
- Spanish filenames mixed (limpieza-*) — charming for some, friction for international.
- No packaging, releases, or "install for everyone".
- Scope narrow (only deep cleanup); could expand to "personal sysadmin companion" without losing focus.

**Verdict on base**: **Outstanding foundation**. The core ideas (hybrid OS awareness, safety interview, script generation, final compact step) are differentiated and valuable. Far better starting point than 95% of "vibe repo for stars" entries. This is real sysadmin tooling with AI leverage. Perfect niche for "sysadmin and administración de sistemas" that people actually want (not theoretical).

## Recommended Direction (Primary)
**Evolve deep-disk-cleanup in place** (no full rename yet) into **the safe, delightful, AI-optional disk & environment reclaimer for developers**.

- **Tagline ideas**: "Safely reclaim 50-200 GB from WSL, Docker, AI caches & old toolchains — and actually get the space back on the host."
- "Your collaborative sysadmin for dev machine bloat. Works with agents or standalone."
- Keep repo name for now (descriptive + existing GH link). Introduce `reclaim` as the user-facing command/tool name.

**Why this over bigger alternatives?**
- Leverages existing high-quality work (don't throw away the wizard logic + REFERENCE).
- Solves one painful thing *extremely well* → higher chance of real love + organic shares ("I just got 120GB back").
- Fast path to "meaningful usage" signals for the OSS program.
- Natural expansion surface: once people trust it for disk, add "prune toolchains", "container gc", "journal vacuum", "dev env doctor" as sibling commands or profiles.
- Aligns with "sysadmin for individuals / power users / hybrid Windows-Linux devs".

**Alternatives considered (if we want to pivot or do multiple repos)**:
1. **Broader "devsys" or "maint" toolkit** (disk + toolchains + services + logs). Higher ambition, more maintenance. Could contain this as `devsys reclaim`.
2. **WSL-specific power user suite** (disk + distro mgmt + interop doctor + compact/backup tools). Very targeted, loyal users.
3. **AI-local-infra maintainer** (prune Ollama/LMStudio/HF caches/models by last-used, + general dev bloat). Timely with local AI boom.
4. **TUI-centric** (build on grok-pi-tui patterns): beautiful ratatui TUI for all maintenance tasks. Higher dev cost, huge polish win.
5. **Agent Skills Standard**: Make this the reference implementation + catalog for "portable agent skills for sysadmin". More meta, ecosystem play.

**We start with #Primary (evolve this)**. If it takes off, we can extract modules.

## Phased Plan (focus on speed to "really good" + signals)

### Phase 0 — Immediate (today / 1 day) — Apply-ready polish + visibility
- [ ] Revamp README: hero, problem, magic (the vhdx thing), quickstarts for *multiple* paths (Claude, manual, future CLI), safety, "share your win", star CTA tied to helping the project + program.
- [ ] Add visuals: ASCII flow, suggested WizTree screenshot description, before/after example (fake or real).
- [ ] Add "Demo" section: instructions to record 60-90s video of a full flow (detection + education for WSL virtual disk + opt-in + live scan + interview with real sizes + explicit permission + direct execution + reporting + compact if applicable). Host on X or YouTube unlisted, embed/link. (Agent direct-execution version preferred; script fallback secondary.)
- [ ] (Historical) Add Linux quick manual path in docs (commands now live in detection-commands.md + SKILL.md Environment Discovery section).
- [ ] Update SKILL.md + README to position as multi-agent friendly ("Claude Code, Cursor, Aider, Grok Build, Codex, etc.").
- [ ] Add basic wins / examples section (seed with hypothetical or previous runs).
- [ ] Create this ACCELERATION-PLAN.md (or move to docs/).
- [ ] Copy/adapt SKILL.md to `~/.grok/skills/deep-disk-cleanup/` so Grok users benefit too.
- [ ] Post in the original @nicos_ai thread + relevant places with improved link + "real tool for a real problem, not a weekend vibe app".
- [ ] Apply to the form (even with current state — it's already better than most) while we improve.

### Phase 1 — Standalone & Cross-Platform (2-7 days) — 10x usability
- [ ] Add a zero/low-dep Python CLI (`reclaim` or `python -m reclaim` or single `reclaim.py`).
  - `reclaim scan` (or default): cross-platform disk scan + categorize (use psutil or pure stdlib + du/df calls).
  - Interactive interview using stdlib or optional `questionary`/`rich` (graceful fallback).
  - Generate + write personalized cleanup script (bash for *nix, ps1 for win) using the templates logic.
  - Guide through compact step with auto-detect of vhdx locations where possible.
  - `--dry`, `--yes` for power, categories filter.
- [ ] Port core logic: Linux/macOS scanner + bash template equivalents of `limpieza-profunda.sh` and `limpiar-residuales.sh`.
- [ ] macOS specific targets (Library/Caches, Xcode, Time Machine snapshots via tmutil, brew, etc.).
- [x] Make catalog data-driven: introduced `catalog/targets.json` (JSON chosen for stdlib parse in reclaim.py + agent readability; YAML alternative possible later) with rich entries: paths/globs, category, platforms, description, why-this-bucket, decision-guidance, safer-partials, tradeoff-notes, prune-commands + full meta for extensibility + agent usage recipe. Agent/CLI (reclaim.py) loads it. Community adds entries easily via PR. See catalog/README.md and the full refactor in SKILL/REFERENCE. (Done as primary focus of this candidate implementation.)
- [x] Update PS1 (and sh) templates headers + comments to reference the master catalog as source of truth (scripts remain illustrative reference; agent populates confirmed catalog items only). Full consumption left simple for standalone compatibility.
- [ ] Installer helper: `curl -fsSL ... | bash` that places scripts + symlink or adds to PATH.
- [ ] Update install instructions: "Works standalone or as agent skill".

### Phase 2 — Polish, Signals & Community (ongoing, parallel)
- [ ] Beautiful docs: screenshots/GIFs (use terminal recorder or asciinema for CLI), troubleshooting, "what not to delete and why".
- [ ] "Share your win" template in issues or a simple form; encourage "I reclaimed XX GB on [setup]".
- [ ] GitHub: good labels, PR template, issue templates ("new safe target", "platform support", "I freed X GB").
- [ ] CONTRIBUTING.md focused on "adding a target safely" (the process: scan, categorize, propose, test on your machine).
- [ ] Add a simple GitHub Action? (lint md, shellcheck on new .sh, validate yaml catalog).
- [ ] Releases: GitHub releases with changelog. Tag early.
- [ ] Optional: opt-in anonymous "I used reclaim and freed N GB" ping (privacy first, or just manual).
- [ ] i18n: English primary, Spanish translations for key strings/docs (or bilingual README).
- [ ] Expand targets: more dev (gradle, maven, sbt, zig, elixir, ruby bundler, etc.), more AI (ollama models by size/last use, vllm, etc.), browsers (Firefox too), package managers (snap, flatpak, winget cache).
- [ ] Safety upgrades: pre-delete checks (process lsof/ps, mtime recent?), trash instead of direct rm where possible (or --trash flag), dry-run always available.
- [ ] Metrics in output: "Equivalent to ~N local LLM models" or "saved ~M minutes of future builds".

### Phase 3 — Expansion & Ecosystem (after signals)
- Sibling commands or submodules: `reclaim toolchains`, `reclaim containers`, `reclaim logs`.
- TUI mode (optional, using rich or external).
- Integration with popular agents: provide ready "skills" or rules files for multiple tools.
- Package: Homebrew, winget, pipx, cargo? (if Rust rewrite core later), AUR, etc.
- "reclaim doctor" mode: full health report + recommended actions.
- Community catalog hosted or auto-updated.

## Success Metrics (for the OSS program + real value)
- Stars: aim 100+ quickly via genuine shares (not just friend spam). 500+ makes "broad adoption" easy to claim.
- Usage signals: GitHub clones, "freed GB" reports in issues/comments, forks for distro-specific.
- Maintenance: merged PRs (even small catalog additions), regular commits.
- Ecosystem: mentioned in WSL/Docker/AI dev threads, "the tool I use for ...".
- For form: "This project helps thousands of OSS contributors (who develop on hybrid WSL/Docker setups) stay unblocked by their own machines. We've already helped users reclaim 100s of GB safely. Active development, clear maintainer (me). Will use credits to accelerate features + add Codex Security reviews for the tool itself."

## Risks & Mitigations
- Low stars at apply time: Apply anyway (program says "if it plays an important role... still apply and explain"). Improvements + promotion happen in parallel. "Projects a medias" accepted per community.
- Safety incident: Extremely conservative rules + "never touch" list + detection-first + education + explicit permission (direct exec) + prompts + inspect + measure/report. Add more pre-flight checks in future.
- Scope creep: Stay laser on "reclaim space + related env cleanup" for v1. Everything else is v2+.
- Platform bugs: Test on real WSL/Ubuntu, macOS, pure Win, multiple distros. Document "run at your own risk" + backups reminder.
- Name/branding: Keep "deep-disk-cleanup" for repo clarity; brand the experience around "Reclaim" or "Deep Reclaim".

## Immediate Next Actions (after this plan)
1. Revamp README + add demo section (biggest star driver).
2. Create basic Linux support + manual path.
3. Add the Python standalone CLI skeleton (even if interview is simple input() at first).
4. Sync improved SKILL + new files to ~/.claude/skills and ~/.grok/skills.
5. Record/post a demo + ask for stars in the thread.
6. Fill the form with honest current + "actively improving" story.
7. Iterate from real user feedback.

This base is good. With focused 1-week push on accessibility + proof + promotion, it becomes one of the stronger, more useful entries — and actually helps people with sysadmin pain.

Let's build it.
