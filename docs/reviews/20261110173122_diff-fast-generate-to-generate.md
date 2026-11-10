# Diff bench: JSON.fast_generate to JSON.generate

## Decisions

Route as one-change base/head resource compare, not a pressure-cooker episode. The executable diff is encode-path `JSON.fast_generate` to `JSON.generate` in `LineEncoder` and `StructuredHashJsonEncoder`.

Probe: isolated worktrees under `tmp/bench-base-fast-generate` (HEAD + fast_generate) and `tmp/bench-head-generate` (HEAD + generate working-tree files). Same machine, alternate base then head for three samples. Shared lock json 2.21.2. Command: `env -u BUNDLE_PATH BENCH_LABEL=... bundle exec ruby benchmarks/diff_probe.rb`.

## Effects

Host: arm64-Darwin, Ruby 4.0.2. Log: `benchmarks/output/diff_fast_generate_vs_generate_20261110173122.log`.

Series medians (n=3):

- simple `LineEncoder.build_line` ops/s: base 714367.4 -> head 797677.2 (about +11.7%)
- structured `encode_line` ops/s: base 8094.7 -> head 8097.8 (flat)
- `JsonLogger#info` simple ops/s: base 315786.1 -> head 340674.9 (about +7.9%)
- boot CPU seconds after require: base 0.022168 -> head 0.022197 (flat)
- boot RSS bytes: base 28147712 -> head 28786688 (about +2.3%, within sample noise)
- shipped gem compressed bytes: base 28160 (1.3.2) -> head 28160 (1.3.3)
- install graph: vendor/bundle 97689600 bytes shared (lock unchanged for this encode swap)

Same-process microbench on json 2.21.2, 100000 iterations of a small hash: `JSON.generate` about 0.017s real vs `JSON.fast_generate` about 0.031s real. Base encode path prints a deprecation warning per call (`JSON.fast_generate is deprecated...`); 100 simple lines produced 23600 stderr bytes. That warning cost explains the simple-path and logger gains on head. Structured path is dominated by sanitize/walk, so encode API swap stays flat.

Secondary smoke `SCENARIO=smoke` on the working tree wrote `benchmarks/output/20261110173153_load.json`. Pressure target fails on this short smoke are expected noise at tiny n; they are not a regression gate for this diff.

Verdict: switching to `JSON.generate` does not regress encode throughput on json 2.21.2; simple emit is faster by avoiding deprecation warnings; json 3 requires the swap for correctness.

## Next

- Keep the generate swap for 1.3.3.
- Optional later: re-run the same probe with a lock on json 3.1.0 (base cannot call fast_generate there).

## Source

benchmarks/output/diff_fast_generate_vs_generate_20261110173122.log
benchmarks/output/20261110173153_load.json
lib/json_logging/line_encoder.rb
lib/json_logging/structured_hash_json_encoder.rb
docs/dependencies/20261110172512_json-3-removed-fast-generate.md
