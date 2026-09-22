# Client surface

Run this companion when the audited tree has a browser, embedded browser, or other client that executes untrusted markup or script. Skip when it does not, and state that reason. Keep the same finding fields and the kinds in `security.md`.

Scan for: document-object mutation from untrusted HTML; `postMessage` without origin check; prototype-chain write; UI redress that covers a trusted control; storage that a less-trusted origin can read.

The distinction between unlabeled controls and explicitly decorative elements stays in `product-surface.md`. Secrets in local stores versus a platform keystore stay in `security.md` packaged-client.

## Skip

No browser or embedded-browser surface: skip and say so.
