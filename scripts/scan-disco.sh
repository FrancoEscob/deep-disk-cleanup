#!/usr/bin/env bash
# ============================================================
#  scan-disco.sh  -  Disk space diagnostic (READ ONLY) — REFERENCE / FALLBACK
#  Deletes nothing. Shows what is taking up space.
#  For Linux, WSL, macOS.
#
#  ROLE IN THE SKILL (scripts = strictly secondary; direct exec primary): Safe reference impl + standalone helper.
#  See SKILL.md (minimal powerful principles + adaptive decision tree; **direct execution via agent tools after perm is the normal path**).
#  Primary agent: detection first (detection-commands.md), load catalog/targets.json (master portable targets + rich edu/decision metadata),
#  **then direct execution** after explicit permission. Use this script ONLY for:
#  - Manual/standalone diagnostics (illustrative lists).
#  - Rare audit/fallback artifact (populate *only* this-run user-confirmed targets from catalog + live).
#  Never default to "generate script".
#
#  Catalog = single source of truth for targets, categories, prune, rich decision/education text.
#  Full agent uses catalog directly + drives actions per the SKILL contract. This shows patterns.
#
#  Run: bash scripts/scan-disco.sh   or   chmod +x && ./scan-disco.sh
#  Full context: SKILL.md + catalog/ + REFERENCE.md + explanations/ + detection-commands.md + commands/ (the granular portable safe command snippets & patterns for direct agent execution)
#  This script demonstrates high-level patterns; prefer commands/*.md snippets (read + adapt + run via terminal after perm) for agent direct work.
# ============================================================

set -euo pipefail

echo ""
echo "=== DISK SPACE (df -h) ==="
df -h / 2>/dev/null || df -h

echo ""
echo "=== TOP 20 largest directories under ~ (user home) ==="
# Safe: don't cross filesystems excessively, limit depth somewhat for speed
du -ah ~ 2>/dev/null | sort -rh | head -20 || true

echo ""
echo "=== TOP candidates outside home (common bloat locations) ==="
for p in /usr /var /tmp /opt /Library /System/Volumes; do
  if [ -d "$p" ]; then
    echo "--- $p ---"
    du -sh "$p"/* 2>/dev/null | sort -rh | head -10 || true
  fi
done

echo ""
echo "=== Common cache / dev junk spots (if present) — illustrative subset ==="
echo "    (Master list + rich metadata lives in catalog/targets.json; see catalog/README.md."
echo "     The full agent skill loads the catalog for scan targets + education.)"
CANDIDATES=(
  "$HOME/.npm"
  "$HOME/.cache"
  "$HOME/.cargo"
  "$HOME/.rustup"
  "$HOME/.local/share/pnpm"
  "$HOME/.cache/pip"
  "$HOME/.cache/uv"
  "$HOME/Library/Caches"
  "$HOME/.cursor-server"
  "$HOME/.vscode-server"
  "$HOME/.ollama"
  "$HOME/.cache/huggingface"
)
# NOTE: These are examples drawn from the catalog. In agent-generated fallback scripts,
# only include paths the user explicitly confirmed in this conversation (from catalog or live scan).

for c in "${CANDIDATES[@]}"; do
  if [ -e "$c" ]; then
    size=$(du -sh "$c" 2>/dev/null | cut -f1)
    echo "$size  $c"
  fi
done

echo ""
echo "=== Docker / container usage (if docker available) ==="
if command -v docker >/dev/null 2>&1; then
  docker system df 2>/dev/null || echo "docker present but 'docker system df' failed (permissions?)"
  echo "Tip: docker system prune -a --volumes (interactive caution)"
else
  echo "(docker not in PATH or not installed)"
fi

echo ""
echo "Done. Paste or screenshot this output for the agent / review."
echo "TIP: On macOS, consider DaisyDisk or GrandPerspective for visual maps."
echo "TIP: For WSL, after cleaning inside, remember the vhdx compact step on the Windows side (see explanations/wsl-virtual-disks.md + REFERENCE.md)."
echo "For the full catalog-driven experience and education: use the agent skill (SKILL.md + catalog/targets.json)."
