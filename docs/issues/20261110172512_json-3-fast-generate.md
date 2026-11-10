# json 3 fast_generate break

## Decisions

Treat missing `JSON.fast_generate` under json 3 as a library bug. Replace emit-path calls with `JSON.generate`. Keep `json (>= 2.21.2)`. Cut 1.3.3 for consumers that already resolve json 3.

## Effects

Regression example undefines `JSON.fast_generate` and requires simple-string and large structured-hash encode paths to emit parseable lines. Encoder sources use `JSON.generate` only. CHANGELOG and version move to 1.3.3.

## Next

- Push `main` and run `make release` for 1.3.3.
- Consumer apps that pinned json to 2.x only for this break can drop that pin after locking 1.3.3.

## Source

docs/dependencies/20261110172512_json-3-removed-fast-generate.md
https://github.com/ruby/json/releases/tag/v3.0.0.rc1
