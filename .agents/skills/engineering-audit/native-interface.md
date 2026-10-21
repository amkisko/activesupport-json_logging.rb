# Native interface

Run this companion when the audited tree has native, unsafe, or foreign-function code. Skip when it does not, and state that reason. Keep the same finding fields and the kinds in `security.md`.

Scan for: memory unsafety at a trust boundary; ABI mismatch; loader or plugin path from caller input; kernel or driver call without a named allowlist.

Trace sizes, ownership, lifetimes, encodings, and error values across each native or foreign-function boundary. Distinguish a language-safe wrapper from the unchecked code and operating-system authority beneath it.

Validate with boundary lengths, truncated and oversized values, invalid encodings, concurrent teardown, partial initialization, loader search order, and denied system calls. A crash proves availability impact; stronger integrity or code-execution impact needs separate evidence.

A shrinker or strip step is not binary protection. Host-equivalent privilege through a container-runtime socket stays in `security.md`.

## Skip

No native, unsafe, or foreign-function tree: skip and say so.
