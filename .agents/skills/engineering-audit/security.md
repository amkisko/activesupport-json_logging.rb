# Security review mode

Run this mode when trust, authentication, authorization, or an attacker path is in scope. Skip for a calculation-only library with no IO and no secrets, and state that reason. Keep the same finding fields. Extra fields when they help: attack path; blast radius; regression guard.

Credential handling for agents lives in the `security` fragment. Advisory scanning and lag metrics live in `dependency-audit`. This mode reviews the product.

## Two maps

1. Request pipeline: ingress → routing → authentication → authorization → validation → app logic → cache → store → queue → worker → external API → response.
2. Attacker path: entry → trust boundary → privilege gain → data access → persistence → lateral movement → exfiltration → cover-up.

Never collapse authentication and authorization into one vague check.

## Dimensions

Scan for: missing or weak authentication; object- or tenant-level authorization gaps; injection and unsafe parsing; data exposure; secrets in tree, logs, or artifacts; session and browser-boundary flaws; infrastructure exposure; jobs that skip policy; missing audit of sensitive actions; abuse paths (rate limit, enumeration, flooding); weak or homemade cryptography.

Manual checklist frame: a published application-security verification standard (OWASP ASVS is the usual web frame). Start at the lowest level; raise selected controls for auth, sessions, access, upload, and APIs.

## Auth changes

Before suggesting an auth change, name the trust boundary, the policy owner, and whether the path runs as user, operator, service, or worker. Show whether the bug is missing authentication, missing authorization, wrong object scope, wrong tenant scope, or unsafe privilege inheritance.

Ask whether a request parameter establishes access, or only chooses a row inside an already-authorized set. Ask whether a worker reads request-local context that was not captured at enqueue. HTTP-cached form pages that leave a stale mutating token are a session-boundary flaw.

## Tests

Separate missing security coverage, futile coverage (happy path only, boundary mocked away), and dangerous helpers that bypass real policy.

## Threat-model steps

When asked to threat-model: assets, actors, trust boundaries, entry points, privilege transitions, sensitive flows, abuse cases; then rank by impact and ease. End in concrete fixes.

## Secrets review

Search committed files, config, examples, CI, logs, images, scripts, and docs. Classify: credential, token, key, webhook secret, internal URL, customer data, harmless placeholder. For real exposure: rotate, revoke, and audit access since exposure. History purge only when needed.

## Dependency security

Reachability and known advisories: `dependency-audit`. Do not claim a CVE applies unless version and reachability are clear.

## Ranking

Order by exploitability, blast radius, privilege gained, data sensitivity, certainty, then fix cost. Smallest real fix first.

## Skip

No trust boundary, secrets, or attacker path: skip and say so.
