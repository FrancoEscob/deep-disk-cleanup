# Reporting, Before/After, and Iteration Templates

Consistent reporting builds trust, teaches the user, and supports iteration. Agent should use structured output (not raw dumps) after every action/batch/close.

## Minimal Delta Report (After Any Authorized Action)
```
=== Action: Cleared regenerable caches (npm + uv + pnpm + browser caches) ===
Before (guest /): 78% used (112 GB used / 144 GB total)
After  (guest /): 61% used (88 GB used)
Freed inside: ~24 GB

Host-visible (WSL hybrid, after compact):
  ext4.vhdx shrank from 98 GB to 71 GB
  C: free space increased by ~27 GB (some overhead)

Items touched:
  - ~/.npm (2.1 GB) -> gone (regenerable)
  - ~/.cache/uv (1.8 GB)
  ...
Next? Re-scan big areas, look at yellows, or stop?
```

## Full Run Summary (End of Session or Major Phase)
Use after inside work + close if any.
- Context recap (from detection): "WSL2 Ubuntu 24.04 on Win11, Docker Desktop WSL backend, user-level + sudo-nopass, ... vhdx at C:\... \ext4.vhdx + docker_data.vhdx"
- Education delivered: "WSL virtual disk model + opt-in received for host reclaim"
- Scan summary: "Catalog + live top-N found 47 GB potential (X green, Y yellow reviewed)"
- Actions taken + deltas (table or bullets)
- Reds respected / skipped
- Host + guest deltas
- Remaining suggestions (from re-scan or user interview)
- "Backups reminder: always have them for precious data."

## Host-Visible Specific (for WSL close steps)
Emphasize the non-obvious win:
"Important: the 18 GB of models + caches you deleted inside are now also freed on your Windows C: drive because we did the readonly compact. Without the compact step, Windows would still show the old high-water-mark size."

Show before/after numbers for the specific vhdx files + C: free (or the drive containing the vhd x).

## Visual / Tool Recommendations
- "For a beautiful map next time on Windows: WizTree (free, scans C: in seconds by reading MFT)."
- "On mac: DaisyDisk or GrandPerspective."
- "On Linux: ncdu or dust (interactive TUI)."

## Iteration Offers (Always End With)
- "Anything else big we should look at now? (re-scan ~/src for abandoned projects, check Downloads, etc.)"
- "Want a more aggressive pass on yellows, or conservative only next time?"
- "Run with --list-only or the standalone reclaim.py for a quick preview later."

## Structured for Agent Reasoning + User
In your internal notes: record exact authorized catalog ids + resolved paths + sizes + timestamps + commands executed + results.

For user: human, reassuring, educational, actionable. Use the numbers from live measures (never guess).

See common-patterns.md for the before/after command blocks to run, SKILL.md "After any action/batch/close: re-measure, report..., offer iteration", explanations/decision-frameworks.md.

This turns a one-off cleanup into a learning experience so the user gets better at hygiene on future machines.
