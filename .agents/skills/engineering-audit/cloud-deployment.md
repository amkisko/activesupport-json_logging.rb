# Cloud and deployment boundary

Run this companion when the tree declares or configures hosted compute, storage, network, identity, or orchestration. Skip when deployment is wholly outside the audit scope, and state that reason. Keep the finding contract in `security.md`.

Trace public ingress, workload identity, control-plane authority, east-west access, data stores, secrets, metadata services, and operator paths. Review the deployed-effective policy when available; a template alone may not describe reality.

Scan for: public exposure by default; wildcard identity or resource grants; one workload identity shared across trust zones; caller-controlled role or resource selection; metadata credential access; secret values in state or user data; management port exposure; network policy treated as identity; privileged runtime sockets; mutable images; drift that widens access; logs or snapshots with weaker policy than the primary store.

Validate with policy simulation or read-only effective-state inspection, denied cross-role calls, private-path reachability, credential scope and lifetime, image digest, and drift comparison. Do not mutate a live environment without explicit authorization.

## Skip

No hosted infrastructure or deployment configuration in scope: skip and say so.
