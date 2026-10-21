# Data isolation and lifecycle

Run this companion when the system stores, derives, exports, restores, or deletes data across principals or tenants. Skip when it has no such data, and state that reason. Keep the finding contract in `security.md`.

A tenant field on the primary row is not isolation. Trace authorization and lifecycle through cache, search, queue payload, export, analytics, logs, snapshots, backups, restore, and deletion. Privacy mode asks whether the data should exist; this companion asks which other principal can reach any copy.

Scan for: derived copy with weaker access; shared cache key without tenant binding; export or search outside the ownership set; soft-deleted data still readable; restore that changes ownership; queued work that recreates deleted data; backup or log access wider than production data; test or support tooling that bypasses ordinary policy; deletion marker lost during replication.

Validate read, write, delete, export, restore, and asynchronous replay with two principals. Include secondary indexes and derived stores. When process state and local caches are cleared, name the durable source from which isolation and deletion state rebuild.

## Skip

No principal- or tenant-scoped stored data: skip and say so.
