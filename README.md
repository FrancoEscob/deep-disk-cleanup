# deep-disk-cleanup

An interactive **[Claude Code](https://claude.com/claude-code) Agent Skill** for collaborative, deep storage cleanup on **WSL + Windows** (and Linux/macOS).

It turns the agent into a **cleanup wizard**: it scans your disk, categorizes what it finds by risk, asks you about anything ambiguous, **generates a cleanup script tailored to your machine**, reclaims the space, and **compacts the WSL/Docker `.vhdx`** so the host OS actually sees it freed.

## It's a wizard, not a fixed script

The bundled `.ps1` files are **templates** — the agent never deletes from a hardcoded list. Instead it:

1. **Scans** your disk (`df`/`du` in WSL, `scan-disco.ps1` + WizTree on Windows).
2. **Categorizes** every sizeable item:
   - 🟢 **Regenerable** — dev caches, browser cache, build caches, headless browsers, IDE remote servers → safe.
   - 🟡 **Data / history** — sessions, profiles, logins, toolchains, games → **it asks you, per item, with sizes**.
   - 🔴 **System** — `Windows`, `WinSxS`, `pagefile.sys`, `/usr/lib/wsl`, etc. → never touched.
3. **Interviews you** so you decide each ambiguous item.
4. **Generates a personalized script** with only your confirmed targets, written to disk so commands never mangle on paste.
5. **You run it** — it prompts before each block and reports GB freed.
6. **Compacts the vhdx** so the host OS sees the space.

## The non-obvious part

Deleting files inside WSL **does not** free space in Windows. The whole Linux filesystem lives in a single virtual disk (`ext4.vhdx`) that grows but **never shrinks on its own** — you must compact it. This skill handles that final step, using read-only `diskpart compact` (never the corruption-prone `--set-sparse`).

## Files

| File | Role |
|---|---|
| `SKILL.md` | The wizard flow + rules the agent follows |
| `REFERENCE.md` | Categorized target catalog, diskpart steps, Docker tips, gotchas |
| `scripts/scan-disco.ps1` | **Generic, run as-is** — read-only diagnostic |
| `scripts/limpieza-profunda.ps1` | **Template** — universal caches + a block the agent fills with your targets |
| `scripts/limpiar-residuales.ps1` | **Template** — dead-app list to fill + a generic empty-folder sweep |

Templates auto-skip anything your machine doesn't have, prompt before every delete, and print GB freed.

## Install

```bash
git clone https://github.com/FrancoEscob/deep-disk-cleanup.git ~/.claude/skills/deep-disk-cleanup
```

Then ask Claude Code to *"do a deep disk cleanup"* and it walks you through it.

## Safety

- Confirms before each irreversible delete.
- Inspects targets first (running process? recently modified?).
- Generated fresh from each scan — no machine's app names baked into another's script.
- Uses read-only `diskpart compact`, never `wsl --set-sparse`.

## License

MIT — see [LICENSE](LICENSE).
