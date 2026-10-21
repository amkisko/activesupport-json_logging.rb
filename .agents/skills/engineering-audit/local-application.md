# Local application boundaries

Run this companion when the tree ships a desktop, mobile, command-line, extension, plugin, or other installed client with local authority. Skip for server-only and calculation-only trees, and state that reason. Keep the finding contract in `security.md`.

Trace platform manifest and exported entry points, deep links, file handlers, IPC, plugins, updates, embedded browsers, local storage, credential stores, logs, clipboard, notifications, and operating-system permissions. A local process or file is not trusted merely because it is on the same device.

Scan for: exported component without a bound permission; deep link or file path that triggers a sensitive action; unauthenticated IPC; broad file or device permission; credential outside the platform store; cleartext transport; TLS failure ignored; embedded browser bridge exposed to untrusted content; plugin or update loaded without authenticity; logout that leaves a reusable local identifier or token.

Validate from the least-privileged local principal with malformed deep links, foreign files, wrong-origin browser messages, concurrent IPC, locked credential store, offline or stale state, TLS failure, logout, and upgrade or downgrade. Binary shrinking or symbol stripping is not an access control.

## Skip

No installed application or local authority boundary: skip and say so.
