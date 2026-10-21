# Supply chain and release

Run this companion when the tree builds, downloads, generates, signs, packages, or releases executable artifacts. Skip when it does none of those, and state that reason. Keep the finding contract in `security.md`.

Trace source and dependency introduction through build, generated code, CI, artifact store, signing, publication, and installation. Name which identity can turn untrusted input into a trusted artifact.

Scan for: untrusted checkout with write credentials; event or branch text interpolated into a command; mutable third-party steps or downloads; build output accepted without provenance; signing material exposed to pull-request code; release approval that defaults off; generated artifacts not tied to reviewed source; package-name confusion; installer or update channel without authenticity and rollback rules.

Validate using the workflow's effective permissions and triggers, immutable references, digest or signature verification, clean-build comparison, artifact promotion path, and a release attempt from a lower-trust event. A lockfile does not authenticate a registry or build worker.

Known advisories, package reachability, and freshness belong to `dependency-audit`. Link that assessment instead of duplicating it here.

## Skip

No build, download, generated artifact, package, or release path: skip and say so.
