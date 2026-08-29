# Trace and identification mode

Run this mode for every audited tree that can execute. Skip only when the tree never becomes executed bytes, and state that reason. Local disk, logs, and SDK init are in even when there is no network. Keep the same finding fields as the rest of the skill.

## Quantity versus identification

Resource and budget mode counts network bytes, storage, CPU, and energy. This mode asks which emissions identify a person or device, which observers see them, and whether they appear in what this product showed the person for this run. A small crash ping can pass a byte budget and still mint a user id they were not shown. One extra call can be two findings: bytes over the ceiling, and a mark not shown to the person. Quantity and identity are separate passes.

## What the person was shown

The contract is the in-app notice, install prompt, CLI README, or privacy page linked from the product. A buried legal PDF they never opened is not the contract. Emit only what the feature they asked for this session needs, and what they were shown. Extra telemetry is allowed when the requirement names it.

## Measure first

Until HAR, packet capture, disk, logs, crash payload, or SDK init is measured, who is identified is inference. Name the bench and the fixture. Fixtures: idle, first launch, after logout, request logs. After uninstall or delete-my-data when the product claims deletion. A server-only API uses request logs and retained fields as the fixture set.

## Catch questions

RFC 6973 section 7.1 is the list:

- which identifiers this tree mints, and which of those the person was shown for this product;
- what else is exposed about the person or device, and whether fields not named as identity combine into a device fingerprint;
- which observers see them, including first parties and third parties;
- how long those identifiers last, and whether they can be deleted;
- whether they correlate with data outside this protocol;
- how long recipients, intermediaries, or logs retain identifiers and other fields, including IP addresses;
- whether traces remain after logout, uninstall, or delete-my-data;
- whether telemetry is on by default and not required for the feature they asked for this session;
- marks at idle, first launch, after logout, and in logs, not only on the network.

Name the surface in the finding (web, desktop, console, mobile, embedded, server logs). TLS handshake, SNI, and certificate exchange are the channel unless this tree adds extra marks there. Hand spoofable identity keys and missing TLS verify to security review. House security.md names both: a redacted hash of a secret, and a device fingerprint that can unmask a person or a session secret.

Related: resource-and-budget.md counts the bytes. W3C Privacy Principles, W3C fingerprinting-guidance, EDPB Guidelines 2/2023, and WSG energy-metric fingerprinting stay related reading.
