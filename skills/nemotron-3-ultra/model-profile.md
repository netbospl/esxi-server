# Nemotron 3 Ultra runtime profile

Use this profile for every Nemotron-specific sub-skill in this repository.

| Property | Value |
|---|---|
| Model ID | `nvidia/nemotron-3-ultra-550b-a55b` or a verified provider equivalent |
| Architecture | LatentMoE hybrid, 550B total / 55B active |
| Published model ceiling | Up to 1M tokens |
| Current Hermes deployment target | 64K tokens; re-read the active profile before relying on it |
| Strengths used here | Multi-step reasoning, coding, instruction following, tool use |

The model ceiling is not the active context window. Provider, endpoint,
quantization, runtime, memory, and Hermes configuration may impose a lower
limit. Treat the observed Hermes value as authoritative, keep room for tool
results, and use progressive disclosure instead of filling the window.

Do not repeat this model table in child skills. Child skills add only
task-specific decision and validation patterns after their model-agnostic
parents.

Primary source: [NVIDIA Nemotron 3 Ultra model card](https://build.nvidia.com/nvidia/nemotron-3-ultra-550b-a55b/modelcard).
