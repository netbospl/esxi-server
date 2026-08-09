# Nemotron 3 Ultra runtime profile

Use for `nvidia/nemotron-3-ultra-550b-a55b` or a verified provider equivalent.

- Treat the active Hermes/provider context limit as authoritative.
- Use progressive disclosure; never preload references or fallback paths.
- Preserve room for tool results.
- Keep a compact ledger of fresh facts, IDs, uncertainties, and approval state.
- Summarize bulky output; refresh volatile state after compaction, interruption, recovery, approval expiry, or state change.
- Do not restate parent safety policy.

Model background: [NVIDIA model card](https://build.nvidia.com/nvidia/nemotron-3-ultra-550b-a55b/modelcard).
