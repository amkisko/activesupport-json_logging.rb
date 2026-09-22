# Native interface

Run this companion when the audited tree has native, unsafe, or foreign-function code. Skip when it does not, and state that reason. Keep the same finding fields and the kinds in `security.md`.

Scan for: memory unsafety at a trust boundary; ABI mismatch; loader or plugin path from caller input; kernel or driver call without a named allowlist.

A shrinker or strip step is not binary protection. Host-equivalent privilege through a container-runtime socket stays in `security.md`.

## Skip

No native, unsafe, or foreign-function tree: skip and say so.
