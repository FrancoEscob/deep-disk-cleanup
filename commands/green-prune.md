# Green Regenerable Prune Commands (🟢)

**Use only after catalog load + scan showed size + batch permission** (one Ask for the group of safe regenerables is fine; low-regret).

**Rule**: Prefer the ecosystem's official `prune_commands` from `catalog/targets.json` when present. These wrappers add safety (list/measure first, auto-skip, reporting, dry options), bridging, and education echo.

Cross-ref catalog entries for exact `why_this_bucket` etc. to quote in permission ask.

## Node / JS Ecosystem
```bash
# npm
npm cache clean --force   # official, often smarter than rm

# pnpm (preferred over rm)
pnpm store prune

# yarn
yarn cache clean

# node-gyp (usually just rm the dir after)
rm -rf ~/.cache/node-gyp 2>/dev/null || true
```

Windows variants (run where npm in PATH, or full path):
```powershell
npm cache clean --force
# etc.
```

## Python
```bash
# pip
pip cache purge || rm -rf ~/.cache/pip 2>/dev/null || true

# uv (modern, fast)
uv cache clean

# Older pyenv/conda handled as yellow usually.
```

## Go
```bash
go clean -cache -modcache
```

## .NET
```bash
dotnet nuget locals all --clear
```

## Rust (toolchain parts are often yellow; pure build cache green)
```bash
# If only build cache confirmed safe
cargo clean --package some  # per project better
# global build often under target dirs in projects (see yellow abandoned)
```

## Docker (primary reclaim path for container bloat — see docker-specific.md for full)
```bash
# Show first (always)
docker system df -v

# After permission on scope (dangling vs -a --volumes)
docker system prune -a --volumes -f   # aggressive; confirm volumes first
# or safer: docker system prune -f
docker builder prune -f
docker volume prune -f   # list first if named volumes matter
```

## Browser Caches — CRITICAL: ONLY sub Cache dirs, never whole User Data (see browser-caches.md)
```bash
# Example Chromium Default profile cache (POSIX)
rm -rf ~/Library/Caches/Google/Chrome/Default/Cache/* 2>/dev/null || true
# ... Code Cache etc. See full list in browser-caches.md or catalog "browser-caches-chromium"
```

## IDE Remote Servers (re-download on next attach)
```bash
rm -rf ~/.cursor-server ~/.vscode-server ~/.zed_server 2>/dev/null || true
# Windows: $env:LOCALAPPDATA\cursor-server etc.
```

## Linux / WSL System (apt, journal — often needs sudo -n or guide user)
```bash
# After priv detection
sudo -n apt-get autoremove --purge && sudo -n apt-get clean && sudo -n apt-get autoclean || echo "apt needs pass or no sudo"

sudo -n journalctl --vacuum-size=50M --vacuum-time=14days || echo "journalctl vacuum needs root"
```

dnf/pacman equivalents in catalog.

## Brew (macOS / linuxbrew)
```bash
brew cleanup -s && brew autoremove
```

## Cypress / Playwright / Headless Browser Caches
```bash
rm -rf ~/.cache/Cypress ~/.cache/ms-playwright 2>/dev/null || true
# Windows %LOCALAPPDATA%\Cypress\Cache etc.
```

## General Pattern for a Catalog Green Entry with prune_command
1. Measure the path(s).
2. In permission: "Running the official `npm cache clean --force` (or rm of the cache dir) on the 1.8 GB npm cache. It will be repopulated on next use. Safe?"
3. Execute the prune_command or rm -rf on resolved existing.
4. Re-measure, add to freed total.

## Windows Host Notes
Many of the above work in pwsh if the CLIs are in PATH. For packaged apps, use the resolved %LOCALAPPDATA% paths.

## Agent Execution Tip
Wrap in the common-patterns "for each if exists + size + (after perm) execute + report delta".

Never run these without prior batch permission + the "why regenerable" education from catalog.

For items that are borderline (some global installs inside cache dirs), surface in interview even if catalog green.
