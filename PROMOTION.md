# Promotion & Star-Gathering Playbook (for Codex for OSS and real adoption)

Goal: Get genuine stars + usage reports from people who find the tool *useful*, not just pity stars. This builds real signals for the OpenAI form ("meaningful usage", "ecosystem importance") while actually helping the community.

## Core narrative (use everywhere)
"WSL + Docker + AI tools (and normal dev bloat on any OS) eat your disk and usual 'just delete' advice often doesn't give space back (especially host-visible on Windows). This educational wizard (agent skill with direct execution primary, or standalone) does mandatory detection first, teaches the non-obvious (virtual disks etc.), interviews you with live sizes + tradeoffs, gets explicit permission, executes directly (or falls back to reference scripts), and for hybrids finishes with the safe readonly vhdx compact. Most tutorials skip or get the compact dangerously wrong."

Emphasize: safety, education, finishing the job (host-visible space), works with or without fancy agents.

## Immediate actions (do these today)

1. **Reply in the original thread**
   - Link: the one from nicos_ai (https://x.com/nicos_ai/status/2062476098840019079)
   - Text example (adapt, be authentic):
     "Gracias por el tip! Armé una herramienta real para un dolor muy común de devs que usan WSL + Docker + herramientas AI: libera espacio de verdad (incluyendo el compact del vhdx que casi nadie hace bien) de forma segura, con wizard que pregunta antes de borrar nada riesgoso.
     Repo: https://github.com/FrancoEscob/deep-disk-cleanup
     Funciona como skill de Claude/Grok/Cursor o standalone con scripts + reclaim.py temprano.
     Si te ayuda a recuperar 50GB+, dale star y contame en issues tu setup + GBs liberados. Entre todos hacemos que proyectos útiles lleguen a más gente."

2. **Post standalone threads / updates**
   - Short demo video or asciinema of `reclaim.py --list-only` + one agent run if possible.
   - "How I safely reclaimed 80GB+ from WSL without losing my mind (and why deleting inside Linux doesn't free Windows space)"
   - Include before/after (df + Windows disk usage), the compact proof.
   - Tag relevant: #WSL #Docker #DevTools #OpenSource

3. **Communities (high signal, not spam)**
   - Reddit: r/WSL, r/docker, r/bash, r/linux4noobs (careful), r/selfhosted, r/LocalLLaMA (they bloat disks with models), r/cursor (agent users).
     Post the problem + solution + link. "Not asking for stars, but if it helps you, a star makes the tool discoverable for others in the same pain."
   - Spanish communities: foros de Linux en español, Discord de devs hispanos, grupos de WSL en FB/Telegram, HN en español si existe.
   - X / LinkedIn: devs complaining "se me llenó el disco C con WSL".
   - Relevant GitHub discussions in microsoft/WSL, docker/roadmap, etc. (respectful).

4. **The form itself**
   - Apply now (even with current stars) — explain the *problem it solves for OSS maintainers*.
   - "Primary maintainer. This tool keeps the workstations of developers who contribute to OSS (very common WSL/Docker/AI-tool stack) healthy. We already have evidence of 50-100+ GB reclaimed per user with strong safety guarantees. Will use credits to accelerate the standalone CLI, catalog contributions, and run Codex Security on the project itself."
   - Update the "why it qualifies" and "how will you use" as you add real usage data.

## Content ideas that convert

- Before/after screenshots (Windows storage + WSL df + after compact).
- "The one command most WSL cleanup guides forget (and the bug it can cause)".
- "I turned my agent into a sysadmin that actually asks before deleting my Rust toolchain".
- Short loom or phone video of the flow.
- "Reclaim equivalent": "Freed enough space for 3 more 7B models" or "equivalent to X hours of local builds".

## Measuring progress (beyond stars)

- GitHub traffic / clones.
- Issues with "freed X GB".
- Forks or "used your script as base for my distro".
- Mentions in other threads ("use deep-disk-cleanup instead of the one-liner").

## Long-term (after initial push)

- When you have 5-10 real wins, add a "Featured wins" section or embed WINS.md highlights in README.
- Reach out to popular WSL / dev productivity creators for a mention (value first: "this actually solves the compact part correctly").
- Consider a small website or GitHub Pages with the flow explained + install buttons.

Remember: the best promotion is a tool that delivers a "holy shit it actually worked and my host disk went down" moment. Focus on making the experience that good, and the shares will come.

Good luck with the application — this is already one of the more substantive repos people are submitting.
