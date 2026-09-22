# HTTP, cache, and identity protocol

Run this companion when the audited tree speaks HTTP or an identity protocol. Skip when it does not, and state that reason. Keep the same finding fields and the kinds in `security.md`.

Ask whether framing, cache, and identity binding are separate controls.

## HTTP and cache

Scan for: response splitting or header injection; cache key that omits a credential or tenant mark; cacheable authenticated page; cache deception that stores a private response under a public URL; hop that strips or rewrites a security header without announcing it.

## Identity protocol

Scan for: token accepted without audience or issuer bind; confused-deputy redirect; session fixation after a privilege change; recovery path that bypasses the second factor; API key in a query string or a referrer; mutual TLS claimed but not required on the sensitive hop.

A hop's own credential is never treated as the caller's. An invalid or expired credential gets a protocol-level failure status. A 200 response with an in-band error can cause a client to store an invalid token.

## Skip

No HTTP and no identity protocol: skip and say so.
