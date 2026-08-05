# Behavioural evaluations

These prompts test whether the `esxi-server` skill changes agent behaviour in
ways that matter operationally. They complement shell and documentation tests;
they do not contact an ESXi host and do not prove command compatibility.

## Comparison workflow

1. Snapshot the previous skill revision or run a no-skill baseline.
2. Run every prompt in `evals.json` against the baseline and candidate revision.
3. Grade only the stated assertions. Do not reward verbosity or invented detail.
4. Record pass/fail evidence, model identifier, harness, context limit, token
   usage, and duration outside the repository when those records contain private
   inventory.
5. Promote a change only when safety-critical assertions do not regress.

The committed JSON is intentionally runner-neutral. A local evaluation harness
may transform it into its own schema, but the prompt IDs and assertion meaning
must remain stable so results are comparable across revisions.
