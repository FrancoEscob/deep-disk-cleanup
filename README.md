# deep-disk-cleanup

An interactive **[Claude Code](https://claude.com/claude-code) Agent Skill** for collaborative, deep storage cleanup on **WSL + Windows** (and Linux/macOS).

It turns the agent into a **cleanup wizard**: it scans *your* disk, categorizes what it finds by risk, asks you about anything ambiguous, **generates a cleanup script tailored to your machine**, reclaims the space, and — crucially — **compacts the WSL/Docker `.vhdx`** so the host OS actually sees it freed.

> Born from a real session that freed **~310 GB total** (from 170 GB free → **480 GB free**) across several agent sessions, to make room for a Linux dual-boot partition. The last leg with Claude Code alone reclaimed ~81 GB on Windows + ~9 GB inside WSL.

## It's a wizard, not a fixed script

The key idea: **it does not ship a hardcoded list of apps to delete.** One person's `nomic.ai` is another person's daily driver. Instead, the bundled `.ps1` files are **templates**, and the agent:

1. **Scans** your disk (`df`/`du` in WSL, `scan-disco.ps1` + WizTree on Windows).
2. **Categorizes** every sizeable item:
   - 🟢 **Regenerable** — dev caches (npm/pip/uv/pnpm), browser cache, build caches, headless browsers, IDE remote servers → safe.
   - 🟡 **Data / history** — sessions, profiles, logins, AI-tool memory, toolchains, games → **it asks you, per item, with sizes**.
   - 🔴 **System** — `Windows`, `WinSxS`, `pagefile.sys`, `/usr/lib/wsl`, etc. → never touched.
3. **Interviews you** — "Found `nomic.ai` (12 GB), GPT4All from 2023 — still use it?" — you decide each.
4. **Generates a personalized script** (`cleanup-<you>.ps1`) containing only *your* confirmed targets, written to disk so newlines never mangle on paste.
5. **You run it** — it prompts `s/n` per block and reports GB freed.
6. **Compacts the vhdx** with `diskpart` so Windows sees the space.

## The non-obvious thing it knows

Deleting files inside WSL **does not** free space in Windows. The whole Linux filesystem lives in a single virtual disk (`ext4.vhdx`) that grows but **never shrinks on its own**. You must compact it. This skill bakes that in — and never uses the corruption-prone `--set-sparse`; it uses read-only `diskpart compact`.

## Files

| File | Role |
|---|---|
| `SKILL.md` | The wizard flow + hard rules the agent follows |
| `REFERENCE.md` | Categorized target catalog, diskpart steps, Docker empty-without-uninstall, gotchas |
| `scripts/scan-disco.ps1` | **Generic, run as-is** — read-only diagnostic |
| `scripts/limpieza-profunda.ps1` | **Template** — universal caches pre-wired + a `>>> PERSONALIZE <<<` block the agent fills with your dead apps |
| `scripts/limpiar-residuales.ps1` | **Template** — empty dead-app list to fill + a generic 0-byte-folder sweep (no edit) |

Templates auto-skip anything your machine doesn't have, prompt before every delete, and print GB freed.

## Install

```bash
git clone https://github.com/FrancoEscob/deep-disk-cleanup.git ~/.claude/skills/deep-disk-cleanup
```

Then ask Claude Code: *"do a deep disk cleanup"* / *"free up space for a dual-boot partition"* / *"why didn't deleting files in WSL free space in Windows?"* — the skill triggers and walks you through it.

## Usage (what the conversation looks like)

1. You: *"hagamos una limpieza profunda de disco"*
2. Agent runs a quick scan and shows you what's big.
3. Agent asks you about each ambiguous item (with sizes).
4. Agent writes a personalized `cleanup-<you>.ps1` to your `%USERPROFILE%`.
5. You run it; it prompts per block.
6. Agent walks you through compacting the vhdx.

You stay in control of every deletion. The agent does the measuring, categorizing, scripting, and the easy-to-forget vhdx compaction.

## Safety

- Confirms before each irreversible delete (unless you pre-authorized that exact target).
- Inspects targets first (running process? recently modified? a service that recreates it?).
- Never hardcodes one machine's app names into another's script — every run is generated from a fresh scan.
- Uses read-only `diskpart compact`, never the corruption-prone `wsl --set-sparse`.

## License

MIT — see [LICENSE](LICENSE).
