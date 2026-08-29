---
name: rfc-process
description: >-
  Write, number, and advance RFCs in the house shape used across amkisko
  libraries. Use when adding an RFC, claiming an id, copying the template,
  mapping status, flattening an RFC tree, or aligning a repo to this process.
---

# RFC process

Read `rfc-process.md` in this skill directory for claim, template, types, statuses, length, and isolation. Read `references/template.md` when copying or replacing `rfcs/0000-template.md`.

## Quick reference

```text
read rfcs/README.md → claim ids/NNNN → copy template → omit empty sections → PR rfc: NNNN title → implementation cites RFC-NNNN
```

Keep existing RFC numbers. Project bands and extra tests stay in that repo's `rfcs/README.md`. Product RFCs specify a design (suggestion, motivation, specification, effects, alternatives, prior art). Version numbers belong in changelogs.
