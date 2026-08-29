# Privacy and data-flow mode

Run this mode when the audited system collects, stores, sends, or logs data about a person. Skip when it never does, and state that reason. Keep the same finding fields.

This mode asks whether the data should exist, move, or persist. Trace and identification mode asks which emissions identify a person or device. Security review asks whether an attacker can reach it. Run all three when they apply; do not collapse them.

## Inventory

Name:

- what is collected;
- where it is stored;
- where it is sent;
- which subprocessors receive it;
- retention;
- delete and export paths;
- analytics and tracking;
- logs, crash reports, and support payloads;
- mail and notification contents;
- client storage (cookies, local stores, backups).

Useful output: inventory, data-flow sketch, retention table, log-redaction checklist, third-party table.

## Inspect

Look at application logs, background-job payloads, error-reporter breadcrumbs, analytics events, client storage, hydrated payloads, and hidden fields. Quantity of traces stays in resource and budget; who they identify stays in trace and identification.

## Indicators

Prefer field counts, receiver counts, and pass/fail on delete or export paths over adjectives.

## Skip

No personal data in the tree: skip and say so.
