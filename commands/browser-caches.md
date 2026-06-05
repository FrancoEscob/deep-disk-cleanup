# Browser Cache-Only Clears (Never Whole Profiles)

**Critical safety rule**: Browser "User Data" / profiles contain logins, cookies, passwords, history, bookmarks, extensions, autofill. **Only ever target the Cache subfolders**.

Catalog entry "browser-caches-chromium" encodes this + the exact subdir list.

Close browsers first (user action; agent reminds + confirms).

## Chromium Family (Chrome, Edge, Brave, Vivaldi, Arc, Comet/Perplexity, etc.)
Common cache subdirs (per profile):
- Cache
- Code Cache
- GPUCache
- ShaderCache
- DawnGraphiteCache / DawnWebGPUCache
- GrShaderCache
- Service Worker\CacheStorage (or CacheStorage)

**POSIX example** (mac / Linux / WSL):
```bash
# For a specific profile (Default or Profile 1 etc.)
PROFILE="~/Library/Application Support/Google/Chrome/Default"   # adapt
for c in Cache "Code Cache" GPUCache ShaderCache Service\ Worker/CacheStorage; do
  p="$PROFILE/$c"
  if [ -d "$p" ]; then
    sz=$(du -sh "$p" 2>/dev/null | cut -f1)
    echo "Clearing $p ($sz)..."
    rm -rf "$p"/* 2>/dev/null || true
  fi
done
```

Windows (PowerShell reference in scripts/limpieza-profunda.ps1 ClearChromiumCache function):
```powershell
function ClearChromiumCache($userDataPath, $name) {
  if (-not (Test-Path $userDataPath)) { return }
  $profiles = Get-ChildItem $userDataPath -Directory -EA SilentlyContinue |
              Where-Object { $_.Name -eq 'Default' -or $_.Name -like 'Profile*' -or $_.Name -eq 'Guest Profile' }
  $total = 0
  foreach ($p in $profiles) {
    foreach ($c in @('Cache','Code Cache','GPUCache','ShaderCache','DawnGraphiteCache','DawnWebGPUCache','GrShaderCache','Service Worker\CacheStorage')) {
      $cp = Join-Path $p.FullName $c
      if (Test-Path $cp) {
        $total += (Get-FolderSizeGB $cp)   # or just rm
        Remove-Item "$cp\*" -Recurse -Force -EA SilentlyContinue
      }
    }
  }
  Write-Host "$name caches cleared (~$total GB)"
}
# Call for each:
ClearChromiumCache "$env:LOCALAPPDATA\Google\Chrome\User Data" "Chrome"
ClearChromiumCache "$env:LOCALAPPDATA\Microsoft\Edge\User Data" "Edge"
# ... BraveSoftware\Brave-Browser , Vivaldi , Perplexity\Comet etc.
```

## Firefox Family
Less cache-heavy usually, but:
- `~/.cache/mozilla/firefox/.../cache2` or `startupCache`
- Windows: `%LOCALAPPDATA%\Mozilla\Firefox\Profiles\...\cache2` etc.

Prefer browser UI clear for Firefox ("Cached Web Content").

## Permission / Flow
- In scan: only report size of the Cache* subdirs (not parent).
- In interview/perm: "These are pure web caches (images, JS, shaders). Logins, history, passwords stay. Close browsers first. 4.7 GB across Chrome/Edge. OK?"
- Confirm "Browsers closed?"
- Execute the targeted rm of *contents* inside the cache dirs (leave the dir itself so browser is happy).
- Re-measure.

## Safer Partials / Alts
- Browser's own "Clear browsing data → Cached images and files" (sometimes smarter, respects more).
- Only specific profiles you rarely use.
- Extensions or sites can have their own caches.

## Gotchas
- Some "Cache" dirs may be in use while browser running → locks; user must close.
- Service Worker caches can hold offline app data.
- After clear: first load of heavy sites will be slower (re-download) — tradeoff noted.
- Chromium-based Electron apps (some AI tools, VS Code webviews, etc.) may have similar; treat case-by-case (often safe).

See catalog "browser-caches-chromium", scripts/limpieza-profunda.ps1 for the full function, green-prune.md, explanations/decision-frameworks.md (partials).
