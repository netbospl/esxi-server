# Upstream sources and provenance

Reviewed 2026-08-03. The bundled helpers are independently written from
documented OpenSSH/tmux interfaces; no upstream helper code is copied.

| Source | Reviewed identifier | License/reuse |
|---|---|---|
| [Yale SOM staying-connected](https://github.com/yale-som-hpc/claude-code-marketplace/blob/0a8f62dafb0e9ededa9efc3e4a47edf086f2ad87/plugins/hpc/skills/staying-connected/SKILL.md) | Commit `0a8f62dafb0e9ededa9efc3e4a47edf086f2ad87`; blob `a7845d5d809d0ea78c71c3e82cac3625d41c6263` | Unlicense; architecture concepts only. Yale/HPC details removed. |
| [OpenClaw tmux](https://github.com/openclaw/openclaw/blob/main/skills/tmux/SKILL.md) | Blob `6daf7358173026b1afcd4ebc8b818e360438d325`; wait helper `56354be835459c7614bfc96b5526e92dc1dbde5d` | MIT, OpenClaw Foundation 2026; concepts only, independent helper. |
| [Superpowers Lab](https://github.com/obra/superpowers-lab/blob/main/skills/using-tmux-for-interactive-commands/SKILL.md) | Blob `b8805d846d01c9ed2bfa1d6985fbfadeb663f5fa` | MIT, Jesse Vincent 2025; PTY concepts only. Fixed sleeps and absolute paths rejected. |
| [claude-code-tools tmux-cli](https://github.com/pchalasani/claude-code-tools/blob/main/plugins/tmux-cli/skills/tmux-cli/SKILL.md) | Blob `8e9da3a8c3912c9270268eb5b8302f21d8ae4bbf` | MIT, Prasad Chalasani 2025; structured-result concepts only; no dependency. |
| [claude-session](https://github.com/mmmontov/claude-session/blob/c8a0944ec7a0d7415126e5183a378dd1be0ac579/SKILL.md) | Commit `c8a0944ec7a0d7415126e5183a378dd1be0ac579`; blob `a70ec31252c213934aecc3ba218e7ff937de1955` | No license found during review; concept-only, no code or wording copied. |
| [Hermes Agent](https://github.com/NousResearch/hermes-agent/tree/34d6095e41c1c595fe2f458923f3a85e9081a414) | Commit `34d6095e41c1c595fe2f458923f3a85e9081a414` | Compatibility review only; no code copied. |

Canonical behavior references:

- [OpenBSD `ssh_config(5)`](https://man.openbsd.org/ssh_config)
- [OpenBSD `tmux(1)`](https://man.openbsd.org/tmux.1)
- [Mosh](https://mosh.org/)
- [Eternal Terminal](https://eternalterminal.dev/)
- [zmx](https://zmx.sh/)

Alternative tools are optional and version-sensitive. Check live `--help`
before generating commands. No alternative is installed automatically or
assumed available on ESXi.
