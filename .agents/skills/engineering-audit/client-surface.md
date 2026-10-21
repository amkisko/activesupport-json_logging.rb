# Client surface

Run this companion when the audited tree has a browser, embedded browser, or other client that executes untrusted markup or script. Skip when it does not, and state that reason. Keep the same finding fields and the kinds in `security.md`.

Scan for: document-object mutation from untrusted HTML; `postMessage` without origin check; prototype-chain write; UI redress that covers a trusted control; storage that a less-trusted origin can read.

Trace untrusted markup, URL, message, storage value, and server response through parsing and rendering to script, navigation, credential, clipboard, download, or trusted-control sinks. Keep browser origin, application identity, and displayed identity distinct.

Validate with hostile origins, nested frames, encoded URLs, stale storage, navigation during an in-progress write, and content-security controls at the actual response. A client-side sanitizer or visual confirmation is not authorization for the server-side action.

The distinction between unlabeled controls and explicitly decorative elements stays in `product-surface.md`. Secrets in local stores versus a platform keystore stay in `security.md` packaged-client.

## Skip

No browser or embedded-browser surface: skip and say so.
