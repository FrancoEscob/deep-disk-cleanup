# Deep Disk Cleanup — Reference (Deep Knowledge Base)

Shared rich knowledge + explanatory companion. Agents load relevant sections on live detection. Complements (does not duplicate) the *minimal high-level contract + adaptive decision tree* in `SKILL.md`, probe recipes in `detection-commands.md`, and deep standalone modules in `explanations/`.

**Key principle**: Categories deliberately broad/portable. Personalization = live per-machine scan + user interview. Catalog (targets.json) is now the structured source of targets + rich why/decision/safer/tradeoff/prune metadata (see its README). `commands/` is the rich portable safe command reference library (snippets, helpers, sequences) for the agent's direct execution after permission. This file focuses on deep mechanics (WSL first), platform narrative, gotchas, frameworks summary, and "why the design".

## 1. Why Deleting Inside WSL/Docker WSL Backend Does Not Free Host Space (Deep Explanation)

(For the fullest simple educational presentation to users, also load and quote from `explanations/wsl-virtual-disks.md`.)

WSL2 (and Docker Desktop's WSL2 backend) keeps the **entire Linux filesystem** inside one (or more) virtual disk file(s) on the Windows host — typically `ext4.vhdx`.

- The file lives on the host filesystem (NTFS). Common locations (discovered via registry, see detection-commands.md):
  - WSL distros: `<BasePath>\ext4.vhdx` where BasePath comes from `HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss`. Users frequently relocate these (e.g. to `D:\WSL\...` or `C:\WSL\...`). The registry query always finds the truth.
  - Docker: usually `C:\Users\<user>\AppData\Local\Docker\wsl\disk\docker_data.vhdx` (or similar under the Packages tree for some installs).

**Mechanics (simple model)**:
- The vhdx is a container. Linux (ext4) inside it sees normal file operations: create grows the used space inside the guest FS; delete marks blocks free *inside the guest*.
- `df -h /` inside WSL reflects the guest view.
- The vhdx file on Windows grows to the historical high-water mark of usage inside. It does **not** automatically shrink when space is freed inside. The "deleted" blocks are now unused from Linux's perspective, but the file on the host still occupies the full allocated size on your C: (or other) drive.
- Result: you can delete 80 GB inside WSL and the Windows "This PC" or Settings → Storage graph shows zero change. This is expected virtual-disk behavior.

**Safe reclamation of host-visible space**:
1. Actually delete the junk *inside* (the agent's main job, after education + permission).
2. `wsl --shutdown` (from host or bridged) so the guest is not mounted/locked.
3. From Windows (PowerShell recommended):
   ```
   diskpart
   ```
   Then, **one at a time** for each relevant vhdx:
   ```
   select vdisk file="C:\exact\path\to\the\ext4.vhdx"
   attach vdisk readonly
   compact vdisk
   detach vdisk
   ```
4. `exit`. Re-measure: `(Get-Item "path\to\ext4.vhdx").Length / 1GB` should now be close to the real used inside (`df`).
5. The delta is now free on the host drive.

**Why readonly compact?** It is the documented, safe Microsoft method for this use case. It lets the virtualization layer release the now-unused blocks back to NTFS.

**Strongly avoid `--set-sparse`**:
- `wsl --manage <Distro> --set-sparse true` was an experimental auto-shrink.
- Microsoft disabled it by default due to data corruption risk in some scenarios.
- It often errors `E_INVALIDARG` unless you add `--allow-unsafe` (which the skill never recommends).
- Use the diskpart readonly compact instead.

**Docker without uninstalling**:
- `docker system prune -a --volumes` (or interactive without `-f` first) reclaims inside the docker_data.vhdx.
- Then compact that specific vhdx as above.
- Full removal (if desired): uninstall Docker Desktop + `wsl --unregister docker-desktop` (deletes its vhdx).

**Timing**: Compact after inside cleanup. Compact a "dirty" or still-growing guest is less effective. After compact you can restart WSL normally.

**Detection responsibility**: The agent locates exact current paths via the commands in detection-commands.md (registry probe from inside or host) and only surfaces compact after WSL context detection + full education + explicit user opt-in.

See also `explanations/wsl-virtual-disks.md` and `explanations/platform-notes.md`.

## 2. Categorized Targets — Data-Driven Catalog (Primary Source)

**The structured, extensible, rich-metadata catalog (`catalog/targets.json`) is the core for generality and built-in education.** (See catalog/README.md for schema + exact agent usage recipe post-detection + contribution.)

Load full (or platform-filtered); resolve `paths` for detected context. Every entry has `category` (🟢🟡🔴), platform-aware `paths` (or empty for live patterns), `description`, rich `why_this_bucket` / `decision_guidance` / `safer_partials` / `tradeoff_notes`, `prune_commands`, `notes`.

Agent uses embedded fields for consistent edu/decision without hallucinating. Prefer `prune_commands` (native smarter) after perm. Reds = explicit filter. Patterns (e.g. abandoned projects, docker) discovered live + frameworks.

**Design rationale (this candidate)**: JSON data + rich per-target metadata + high-level principles (SKILL.md) + adaptive tree lets the intelligent LLM do per-machine adaptation + interview. No duplicated long lists here; catalog is master + community-extensible. Old textual lists moved/expanded there. Use catalog (seeds knowns) + frameworks (live unknowns) together.

See `catalog/targets.json` for current targets + metadata. Contribute via catalog (CONTRIBUTING.md + catalog/README.md).

(Everything below preserves deep explanatory value — WSL mechanics, platforms, etc. — not duplicated target lists.)

## 3. Platform-Specific Notes & Gotchas (see also explanations/platform-notes.md)

**Windows host**:
- Use WizTree for fast full-disk visual (tree sorted by size, extension panel shows .vhdx vs .pak game data, file tab for single huge files). Run as admin for everything.
- PowerShell folder sizing is fine for targeted areas; full recursive on C: is slow — that's why WizTree.
- Empty level-1 folder sweep in AppData\Local is powerful for residual tech debt (reference the skip list in scripts/limpiar-residuales.ps1 logic).

**WSL hybrid**:
- See section 1 + explanations/wsl-virtual-disks.md.
- Deleting under /mnt/c/* is host-visible immediately (NTFS). Good for cleaning Windows Downloads from inside Linux, but watch for locks from Windows apps.
- Never touch /usr/lib/wsl.

**Native Linux**:
- fstrim after deletes on SSDs (see platform-notes).
- If inside a VM on a Windows/Mac host, the outer virtual disk may need its own shrink step (analog education).

**macOS**:
- Local snapshots via tmutil are the "space not returned" analog. Thin them.
- Library/Caches, Application Support (selective), Xcode/DerivedData, iOS Simulator devices.
- Recommend DaisyDisk / GrandPerspective for visuals.
- brew, asdf, etc. have their own clean commands.

**Docker (any host)**:
- See section 1. `docker system prune` variants are the inside step.

**General gotchas**:
- Do not `du` over /mnt/c from WSL — glacial. Use host scanner.
- sudo in non-tty (piped) often needs `-S`. Agent tools usually provide a tty-like context, but be aware.
- For scripts emitted as fallback: keep ASCII (PS 5.1), prompt per block, report GB before/after, auto-skip absent.
- Inspect mtime + processes before delete.
- After removing a toolchain the user confirmed dead: clean the rc-file sourcing lines (small follow-up permissioned step) so shells don't source missing env.
- 0-byte empty folders: generic win, but skip known system names (Microsoft*, etc.).

## 4. Decision Framework (Summary — Full in explanations/decision-frameworks.md)

Apply (with the richer version there) to catalog entries *and* live discoveries:

1. Regenerable/recreatable by tool? → 🟢 (confirm via perm; prefer catalog native `prune_commands`).
2. User data/history/preference/chosen? → 🟡 (interview w/ live size+recency+contents + catalog `decision_guidance`/safer partials + framework questions; recovery cost).
3. OS/driver/active app core/pagefile/protected? → 🔴 (guide to uninstaller; never raw delete. Catalog reds = explicit filters).

Extra signals: old mtime+large; cache subdirs in abandoned projects; small-file hoards vs single huge files (models).

Catalog + frameworks guide the *user* through reasoning. Catalog provides ready edu for commons; frameworks + LLM intelligence handle live per-machine + personalization.

## 5. Other Reference

**Uninstalling cleanly**:
- Windows: Settings → Apps (or winget). Store apps remove their whole Package tree (including any bundled vhd xs).
- After uninstall, revisit the residual location as 🟡.

**Reading WizTree (Windows)**: as above.

**Empty Docker without full removal**: prune + (if WSL backend) compact the docker vhdx.

This REFERENCE is the rich *narrative companion* (deep WSL mechanics, gotchas, platform notes, uninstall, WizTree, frameworks summary). The **living structured extensible catalog** (`catalog/targets.json` + its README) is the core for targets + rich per-entry education/decision metadata.
`commands/` (see commands/README.md) is the **comprehensive portable safe command reference library** — rich, modular, cross-platform command snippets, helpers, and sequences (scan-readonly, green-prune with native cmds, close-the-loop with full WSL readonly diskpart temp-script + bridge examples, inspect-and-measure, privilege-bridging, empty-sweeps, browser-caches, docker-specific, followup-edits, reporting, common-patterns) that capable agents directly load/adapt/invoke for the primary direct-execution path after permission. This implementation emphasizes these reusable assets to make the skill exceptionally self-contained and powerful for smart LLMs.

Contribute by extending the catalog (real scan evidence, full metadata, category justification, prune, platforms, gotchas) or adding/improving snippets in commands/ (full comments, platform variants, safety/inspect notes, adaptation guidance, expected output). See CONTRIBUTING.md + catalog/README.md + commands/README.md. Small targeted additions high value.

Agent educational narrative: combine catalog per-target metadata + this REFERENCE + `explanations/` deep modules + SKILL.md's minimal principles + adaptive decision tree + permission + detection + commands/ library (for the actual executable steps).

Design keeps original high-value WSL 100s-GB power (virtual disk full cycle) while fully generalist, direct-execution primary, deeply educational, portable across platforms for any agent. Catalog = community-owned future-proof heart; commands/ = excellent reusable execution assets.
