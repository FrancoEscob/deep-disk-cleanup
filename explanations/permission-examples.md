# Permission Protocol — Concrete Examples & Phrasing

See SKILL.md "Permission Protocol" for the binding rules. This file gives ready-to-adapt examples for AskUserQuestion (or platform equiv) so every destructive or cross-boundary step is explicit, informed, and logged.

**Always**:
- Explain **first** (impact, why safe, size, alts, tradeoffs, edu points).
- Structured options: Yes (full), Partial / only these, Keep for now, Tell me top files / more info, Cancel.
- Record the exact choice.
- Re-confirm if scope changes or doubt.

## Example 1: Green Batch (Low-Regret, One Ask)
**Pre-ask education (brief)**: "These are all pure regenerable caches from the catalog (npm, pnpm, uv, browser Code Cache etc.). The tools recreate what they need on next use. Low risk."

**Ask**:
"Ready to clear the following regenerable caches (total measured 6.8 GB)?
- ~/.npm (2.3 GB, last mod 3w ago)
- ~/.cache/uv (1.9 GB)
- ~/Library/Caches/Google/Chrome/Default/Cache* (1.4 GB across profiles)
- ... (list 4-6 top)

This is safe; they will come back gradually. We can also run the official prune commands instead of raw delete for some.

Options:
1. Yes, clear all of them now (direct execution).
2. Only the dev caches (npm/uv/pnpm), skip browser for now.
3. Tell me the 5 largest files inside the biggest one first.
4. Keep for now / review individually.
5. Cancel this batch."

(Use AskUserQuestion with multiSelect false or appropriate.)

## Example 2: Yellow Item / Group (Interview-Heavy)
**Live data first**: "Found ~/.ollama/models at 47 GB, last written 4 months ago. Contains 3 large models (llama3.1-70b.gguf 38 GB, phi3 4 GB, old-experiment 5 GB)."

**Catalog decision + alts**: "These are user-pulled expensive artifacts (bandwidth + time to re-get). Safer partials: use `ollama rm` for specific, or delete only the ones not loaded recently."

**Ask**:
"Which (if any) of these local AI models do you still actively use or want to keep?
A. Keep all (do nothing).
B. Delete only the old-experiment 5 GB one (re-pull if needed later).
C. Delete the two you haven't loaded in 6+ months (llama 70b + phi3?).
D. Delete all three — I can always ollama pull again.
E. Show me manifest / last-used info or top files inside first.
F. Keep for now.

(Exact authorized scope will be executed directly after this confirm.)"

If user picks C: re-ask "Confirm delete the 70b and phi3 (42 GB total)? This is permanent inside the guest; host reclaim will require the later compact step you opted into."

## Example 3: Close-the-Loop WSL Compact (Dedicated, High-Impact)
**Pre (after inside done + separate from green ask)**: "We have cleaned inside (guest now reports real free). For host C: to actually shrink, we need wsl --shutdown (pauses all your WSL terminals/servers for a few minutes) + readonly diskpart compact on the two discovered vhd x (your Ubuntu + docker_data). This is the safe Microsoft-recommended way. No data loss. Vhdx files will shrink to match real usage."

**Ask**:
"Include the host-visible reclamation now?
- Shutdown WSL + compact ext4.vhdx (currently ~95 GB file, will drop ~XX GB)
- Same for docker_data.vhdx (~12 GB → smaller)
This requires a few minutes of downtime for WSL processes. Your C: drive free space will increase by roughly the amount we freed inside.

Options:
1. Yes, do both compacts (I'll drive wsl --shutdown + the diskpart scripts directly).
2. Only the main Ubuntu ext4.vhdx, skip Docker one for now.
3. Not now — remind me the steps later (or emit a tiny script).
4. Tell me the exact diskpart commands you'll run first.
5. No thanks (space freed inside only)."

After yes: one more lightweight "Proceed with wsl --shutdown now? (current terminals will close)" then execute.

## Example 4: Privileged or Cross-Boundary (journal, fstrim, sudo)
"Next small win: vacuum the systemd journal (currently ~180 MB of old logs) + apt clean. This uses sudo.

`sudo journalctl --vacuum-size=50M --vacuum-time=14days`
`sudo apt-get autoremove --purge && sudo apt-get clean`

Impact: loses old boot logs (rarely needed), frees ~120 MB. Safe, standard maintenance. Agent can run with sudo -n (no password prompt since detected available).

OK to run these two? (Yes / Run only journal / I'll run them myself / No)"

## Example 5: Partial Safer for Risky Yellow (Games / Large Downloads)
"38 GB under SteamLibrary for titles last launched 11 months ago (list top 3). Prefer official uninstall via Steam UI (cleans registry/metadata better, respects licenses).

Options:
1. Launch Steam and uninstall the 2 you don't play via the launcher (I can wait / you report back).
2. Raw delete the specific game folders (faster but leaves launcher metadata; may need verify later).
3. Only delete the shader caches / compatdata inside (smaller win, safer).
4. Keep everything.
5. Show full list of games + sizes first."

Strongly steer to 1.

## General Phrasing Principles
- Lead with real measured size + recency + contents sample.
- Name the category (🟢 or 🟡) + why (quote catalog where possible).
- Always surface 1-2 safer partials or alts.
- State risks + mitigations ("permanent inside guest; backup reminder for anything precious").
- "Direct execution by me after your yes" vs "I'll prepare a script".
- End with clear, numbered or labeled options including "more info" and "keep".
- For batches: "all of the following (total X GB)?" + "or pick subset".

See SKILL.md Permission Protocol (explain first, scope clarity, structured tool, granularity for cross-boundary), explanations/decision-frameworks.md (batch vs per-item, "how to decide" tree), and the AskUserQuestion usage in agent instructions.

Use these patterns consistently so users learn the decision process and trust the direct execution.
