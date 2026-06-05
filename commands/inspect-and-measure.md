# Inspect & Measure — Safety Heuristics Before Any Action

**Non-negotiable before proposing or executing on anything > few hundred MB** (even greens get basic measure; yellows get full inspect).

## Measure (Sizes — Do First, Always)
See scan-readonly.md for the commands. Key:
- Before batch or item: exact du/df / Get-ChildItem size on the target(s) + overall volume free.
- Record in your context.
- After action: same commands, compute delta, report to user (guest view + host view for hybrids).
- Use common-patterns.md before/after wrappers.

## Inspect (Recency, Locks, Recreate Risk, Contents)
**POSIX**:
```bash
# Recency (was it touched recently?)
find {{TARGET}} -type f -mtime -7 2>/dev/null | head -5 || true
# Or ls -l --time-style=long-iso {{TARGET}} | tail

# Locks / open handles
lsof +D {{TARGET}} 2>/dev/null | head -10 || fuser {{TARGET}} 2>/dev/null || echo "no lsof/fuser or nothing open"

# Rough contents for interview (top level or largest children)
du -sh {{TARGET}}/* 2>/dev/null | sort -rh | head -10

# Running processes that may care
ps aux | grep -E 'node|docker|ollama|rustc' | grep -v grep || true
```

**Windows / PowerShell**:
```powershell
# Recency
Get-ChildItem {{TARGET}} -Recurse -File -EA SilentlyContinue | Where-Object LastWriteTime -gt (Get-Date).AddDays(-7) | Select -First 5

# Open handles (built-in limited; recommend handle.exe from Sysinternals if present for deep)
Get-Process | Where-Object { $_.Modules.FileName -like "*{{something}}*" }  # rough
# For files: use handle.exe -accepteula -u {{path}} if available

# Contents
Get-ChildItem {{TARGET}} -Directory -EA SilentlyContinue | ForEach-Object { [PSCustomObject]@{GB=(Get-FolderSizeGB $_.FullName);Name=$_.Name} } | Sort GB -Desc | Select -First 8
```

**Cross-boundary note (WSL)**: paths under /mnt/c are NTFS — locks may be from Windows Explorer/apps. Deletion visible immediately to host (no compact needed). Use bridged Get-Process or ask user to close Explorer tabs.

## Recreate Risk Signals
- Path under a project with active package.json / Cargo.toml / pyproject.toml + recent .git activity or editor process → higher chance user still wants the build artifacts? Offer "artifact-only delete" partial.
- Caches with "last used" metadata (some tools keep it) → prefer tool's prune.
- Services: if docker is running, note that prune will affect current containers/images in use.

## Red Flags That Raise Caution in Interview
- Recently written (last 48h) + large.
- Inside active project tree (check for .git/HEAD recent).
- Contains "important", "backup", "final", "prod" in names (surface for user).
- Part of installed app that is still running (e.g. LM Studio folder while app open).

Surface in the AskUserQuestion: "This was modified 3 days ago and looks like active Ollama models. Still loading any of them?"

## For 0-Byte / Residual Sweeps
See empty-sweeps.md. Always show the list (or count + examples) before the batch perm. Skip known system names (Microsoft*, Packages, etc. — the lists evolve in scripts/ and here).

## Browser / App Profiles
Never propose whole "User Data". Only the Cache* subdirs after "close the browsers?" confirm. Inspect shows logins would be lost otherwise (they aren't in Cache).

## After Inspect — Decision
- All clear + green → batch OK.
- Yellow signals → per/group interview with the live data + catalog decision_guidance + safer partials offered.
- Red flag → stronger "keep for now" default or narrower scope.

Record the inspect summary in your reasoning + surface relevant bits to user for informed consent.

## Integration with Permission Protocol
The "explain first (before the ask)": include "Inspected: last mod {{date}}, no open handles from lsof/ps, size {{X}} GB from du, contents top: {{list}}. Why safe: regenerable per catalog + no recent use."

This is what makes direct execution trustworthy.

See explanations/decision-frameworks.md for the full "Inspect Before You Act" heuristics and how-to-decide tree.
