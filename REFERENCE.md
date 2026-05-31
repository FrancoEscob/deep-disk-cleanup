# Deep Disk Cleanup — Reference

## Why deleting in WSL doesn't free Windows space

WSL2 keeps the entire Linux filesystem inside one virtual disk file:
- **Ubuntu:** find the path via the registry — `Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | ForEach-Object { $_.GetValue('DistributionName'); $_.GetValue('BasePath') }`. The vhdx is `<BasePath>\ext4.vhdx` (strip any `\\?\` prefix). It is NOT always under AppData — users relocate it (e.g. `C:\WSL\Ubuntu\ext4.vhdx`).
- **Docker:** `C:\Users\<user>\AppData\Local\Docker\wsl\disk\docker_data.vhdx`.

The file grows to its high-water mark and stays there. Reclaim with a **read-only compact** (safe):

```
wsl --shutdown
diskpart
```
then, one line at a time:
```
select vdisk file="C:\WSL\Ubuntu\ext4.vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
exit
```

After compact, the freed space returns to the host drive. Confirm with `(Get-Item <path>).Length / 1GB` — it should drop to roughly the real internal usage (`df -h /` inside WSL).

### Do NOT use `--set-sparse`
`wsl --manage <distro> --set-sparse true` is the "auto-shrink" option but Microsoft **disabled it by default due to a data-corruption bug**. It errors with `E_INVALIDARG` unless forced with `--allow-unsafe`. Don't force it — use `diskpart compact` instead.

## Categorized targets

### 🟢 Regenerable — delete freely (re-downloads / re-creates)
| Area | Paths |
|---|---|
| Node/Python caches (Win) | `%LOCALAPPDATA%\npm-cache`, `\uv`, `\pip`, `\pnpm`, `\pnpm-cache`, `\node-gyp` |
| Node/Python caches (WSL) | `~/.npm` (`npm cache clean --force`), `~/.cache/uv`, `~/.cache/pip`, pnpm store (`pnpm store prune`) |
| Build caches | `~/.cache/node-gyp`, `next-swc`, `typescript`, `prisma`, `.cache/pip` |
| Headless browsers | `~/.cache/camoufox`, `~/.cache/ms-playwright`, `%LOCALAPPDATA%\ms-playwright` (Playwright/browser-harness re-downloads) |
| IDE remote servers | `~/.cursor-server`, `~/.vscode-server`, `~/.zed_server` (re-install on reconnect) |
| Browser cache (per profile) | `<Chromium>\User Data\<Profile>\{Cache,Code Cache,GPUCache,ShaderCache}` — keeps logins/history |
| Test tools | `%LOCALAPPDATA%\Cypress\Cache`, `\NuGet\v3-cache` |
| /tmp leftovers | stale `cargo-install*`, tool extension dirs, font zips, bundles |
| System (Linux, needs sudo) | `apt-get autoremove --purge`, `apt-get clean`, `journalctl --vacuum-size=50M` |

### 🟡 Ask the user (data / history / preference)
- AI-tool data: Grok sessions, `.factory`, `.pi`, `.codex`, OpenAI, Perplexity/Comet **profile** (cache OK to clear, profile not).
- Old AI apps that may still be wanted: GPT4All (`nomic.ai`), LM Studio.
- Rust toolchains (`~/.rustup` + `~/.cargo`, ~1.9 GB) — only if they don't use Rust. **Then remove `.cargo/env` lines from `.zshrc/.bashrc/.zshenv/.profile`** or shells error.
- Games (Epic/Steam) — often the single biggest win (tens of GB). Uninstall via the launcher, never by deleting folders.
- Duplicate toolchains: nvm vs fnm, multiple Node versions.
- `Downloads` — old installers (.exe/.iso/.zip).

### 🔴 Never touch
`Windows`, `WinSxS`, `Program Files`, `Program Files (x86)`, `System32`, `pagefile.sys`, `hiberfil.sys`, `System Volume Information`, `/usr/lib/wsl` (WSL/GPU drivers injected by Windows), `/usr/lib/x86_64-linux-gnu`, loose system `.dll`s, `ProgramData` of apps in use.

## Empty Docker without uninstalling
Keeps Docker installed and functional, just reclaims the data:
```
# Docker Desktop running:
docker system prune -a --volumes -f
```
Then `wsl --shutdown` and `compact vdisk` on `docker_data.vhdx` (see above). To fully remove instead: uninstall Docker Desktop, then `wsl --unregister docker-desktop`.

## Reading WizTree
- **Tree view** is pre-sorted by size; expand the big nodes (`Users → <user> → AppData → Local`).
- **Extension panel** (right) reveals patterns: many `.vhdx` = stray virtual disks; huge `.ucas/.pak` = game data.
- **File view** tab = biggest individual files on the whole disk (ISOs, old vhdx, dumps, logs).
- Run **as Administrator** for full visibility.

## Uninstalling apps cleanly
- Windows apps: Settings → Apps → uninstall (don't delete the folder — leaves registry cruft).
- Microsoft Store / packaged apps (e.g. Claude Desktop): same; uninstalling removes its whole `Packages\<App>_<hash>` tree including any bundled VM (`vm_bundles\*.vhdx`).

## Gotchas
- Don't `du` over `/mnt/c` from WSL — use WizTree natively.
- `sudo` in a piped/non-tty context needs `-S` (password on stdin) or a tty; otherwise it errors "a terminal is required".
- Write `.ps1` files to disk for the user (via `/mnt/c/Users/<user>/`) instead of pasting multi-line commands — pasted newlines break PowerShell parsing. Keep scripts ASCII-only to avoid PS 5.1 encoding issues with accents.
- Every `.ps1` should prompt before deleting and print GB-before/after.
- Inspect recently-modified targets and running processes before deleting (a service may recreate the dir, or it may be in active use).
