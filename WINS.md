# Wins — Space reclaimed thanks to deep-disk-cleanup / reclaim

This file is a living collection of real (anonymized) wins. If the tool helped you, please open an issue or PR adding your entry — it helps others believe, helps the project get stars, and strengthens the case for programs like Codex for OSS.

Format (copy/paste):

```
- **Setup**: WSL2 Ubuntu 24.04 + Docker Desktop + heavy local AI (Ollama + HF)
- **Freed**: 87 GB (inside) + ~65 GB host-visible after compact
- **Biggest wins**: old node toolchains, ~/.cache, 3 old local models, Epic games leftover, npm/pnpm
- **Notes**: Detection triggered full WSL virtual disk education + opt-in first. Inside direct clean (after interview/perm) + compact was the magic — host disk finally went down. Used the (refactored) agent skill with direct execution.
- **Date**: 2026-06
```

## Reported wins

(Seed entries — replace with real ones from the community)

- **Setup**: Windows 11 + WSL Ubuntu + Docker + Cursor + lots of browser profiles + Rust + nvm
- **Freed**: 112 GB total reported
- **Biggest**: Rust (1.9GB) no longer used, multiple node versions, browser Code Cache, old LM Studio, 40GB game install left behind
- **Compact**: Yes (after detection + education + opt-in + inside direct cleanup), diskpart readonly on ext4.vhdx and docker_data.vhdx. Host finally happy.
- **Date**: 2026-05 (pre-public polish)

Add yours below or via PR!
