# Follow-up Small Edits (RC Files, Config Cleanup After Toolchain Removal)

When a user confirms a 🟡 toolchain / manager is dead (Rust, nvm, pyenv, etc.) and we delete the dirs, the shell will complain on next login if `.zshrc`/`.bashrc`/`.profile`/`.zprofile`/etc still source the now-missing env.

This is a small, low-risk, high-value follow-up step. Separate permission (tiny scope).

## Detection of Sourcing Lines (after delete confirmed)
```bash
# POSIX shells
grep -E 'cargo|rustup|\.cargo/env|nvm|fnm|asdf|pyenv|conda|volta' ~/.zshrc ~/.bashrc ~/.profile ~/.zprofile 2>/dev/null || true

# Or broader
grep -iE 'source .*cargo|export PATH.*cargo|rustup|NVM_DIR' ~/{.zshrc,.bashrc,.profile,.zprofile,.bash_profile} 2>/dev/null || true
```

Windows (less common for sourcing, more env vars or profile.ps1):
```powershell
# Check PowerShell profiles
$PROFILE | ForEach-Object { if (Test-Path $_) { Select-String -Path $_ -Pattern 'cargo|rustup|nvm' } }
# User profile: ~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 etc.
```

## Safe Edit Pattern (comment out, with backup)
**POSIX** (after small perm "comment the dead sourcing lines so your shell doesn't error?"):
```bash
# Create backup
cp ~/.zshrc ~/.zshrc.ddc-backup-$(date +%s) || true

# Example: comment lines containing the dead thing
sed -i.bak '/\.cargo\/env/s/^/# DDC-REMOVED: /' ~/.zshrc
sed -i.bak '/NVM_DIR/s/^/# DDC-REMOVED: /' ~/.zshrc
# etc. for the exact lines found

# Or manual: open in editor, but since agent direct: use sed or echo new content.
```

Better robust (agent can read the file, propose the diff, then apply after confirm):
```bash
# Agent reads full rc, shows the 2-3 lines, asks "comment these?"
# Then:
sed -i 's|^.*cargo/env.*$|# &   # removed by deep-disk-cleanup after toolchain delete|' ~/.zshrc
```

**Verify**:
```bash
tail -5 ~/.zshrc
# new shell: source ~/.zshrc  (should be quiet)
```

## PowerShell / Windows Profile Edits
Similar: read the profile file(s), comment the lines, backup first.

## Permission Ask (tiny, specific)
"After removing the dead Rust toolchains we also found these 3 lines in your .zshrc that source the old env. If left they will print errors on every shell start. Comment them out safely (backup made)? (Yes / No / Show exact lines first)"

Only the lines related to what was just removed in *this conversation*.

## Scope
- Only after a confirmed delete of the related toolchain in the same run.
- Small edit only (comment, never delete user custom).
- Reversible via the .ddc-backup timestamped copy.
- If multiple shells (zsh + bash + fish), check common rc files.
- For nvm/fnm etc., the sourcing is usually `export NVM_DIR=...` + `[ -s ... ] && source ...`

## Agent Direct Execution
Use your tools to:
- Read the rc file(s) (read_file or cat via terminal).
- Identify exact lines.
- In the small AskUserQuestion, show them.
- After yes: use sed/echo/printf or PowerShell -replace to edit in place (with backup).
- Confirm the edit succeeded (re-grep or tail).
- Tell user "backup at ~/.zshrc.ddc-backup-..."

This is the "Special follow-ups: toolchain yellow confirmed dead → after delete, offer small rc-file sourcing cleanup (separate small perm + direct edit)" from SKILL.md.

See yellow entries in catalog (rust-toolchains, node-version-managers, python-envs-managers), explanations/decision-frameworks.md.
