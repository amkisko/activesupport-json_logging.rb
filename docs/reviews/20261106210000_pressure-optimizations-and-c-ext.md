# Pressure optimizations and C-extension probe

## Participants

Andrei Makarov (@amkisko)

## Scope

`activesupport-json_logging.rb` after the pressure-cooker episode: remove `JSON_LOGGING_OPT_LEVEL` flags from `lib/`, keep permanent logging/sanitize optimizations, throwaway C key-walk probe (not shipped).

Host for cited numbers: Ruby 4.0.x, arm64-darwin. Host-relative, not SLOs.

## Decision: C extension

**Ship custom C extension: no.**

| Probe | Ruby median | C median | Ratio | Why not ship |
| --- | ---: | ---: | ---: | --- |
| nested `sanitize_without_filter` / call | **837 µs** | deep `to_s` keys only **25 µs** | ~34× | C stub skips ParameterFilter / string policy. |
| `JsonLogger#info` simple message | ~**3.4 µs**/call | — | — | Baseline; production path is broader than key walk. |

Throwaway tree: `benchmarks/tmp_c_ext_probe/` (removed after measurement).

## When to try C extensions again

Retry custom C only when measurement shows the hot path is (1) a large enough share of total time and (2) a tight loop over primitives with full sanitize/log semantics.

### Try again when

- Work is linear over a blob with a rare boundary (whole payload in, JSON line out), and C implements the full sanitize + encode policy.
- End-to-end logger/sanitize improvement is clearly above ~20% median wall (n ≥ 3). A key-`to_s` stub that is ~34× faster is not enough.
- Profile shows roughly ≥30–40% of time in one tight function before writing `ext/`.

### Do not retry when

- The win is only a partial hash walk without ParameterFilter / string limits.
- Encode already uses `JSON.fast_generate` / `json` C.
- The bottleneck is I/O to the log sink, not CPU sanitize.
- Platform/ABI/maintenance cost exceeds the measured gain.

### Gate before shipping

1. Load measure: named primary series dominates at L1.
2. Profile: one tight function owns a large fraction of log emit time.
3. Throwaway C probe with the same semantics → only then add `ext/` if the full probe improves enough and tests stay green.

Short form: retry C for “full sanitize/encode byte loops”; skip C for “partial walks and I/O-bound logging.”

## Permanent Ruby optimizations (flags removed)

| Optimization | Before → after (cited runs) | Diff |
| --- | --- | --- |
| `JSON.fast_generate` on line / structured hash encode paths | simple logger ~**326k** → ~**347k** ops/s | ~**+6%** throughput |
| Per-second timestamp cache | cooker opt | fewer `iso8601` calls |
| `json_string?` length &lt; 2 early out | cooker | less parse probing |
| Empty context / hash / array sanitize early returns | cooker | skip walks |
| Skip `SanitizerHashLimit` when no Rails filter and small hash | cooker | less copy |
| `merge_context` skip `transform_keys` when keys already strings | cooker | less alloc |
| Primitive structured hash → `sanitize_primitive_hash` | cooker | shallow path |
| One `Severity.name_for` per emitted line | cooker | less severity work |
| Thread-local clean tag-list cache | cooker | reuse tag arrays |

`JSON_LOGGING_OPT_LEVEL` / `JsonLogging.opt?` removed; wins are default. Specs: **285** examples green (3 pending).

## Documentation cleanup

Removed cooker episode docs, opt-level harnesses, and joint multi-gem review content from this repository. Retained light `benchmarks/load.rb`.

## Source

- `lib/json_logging/` permanent paths
- Throwaway C key-walk probe numbers above (trees deleted)
