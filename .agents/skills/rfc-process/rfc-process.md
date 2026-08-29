# RFC process

Use when writing, numbering, or advancing an RFC, or when aligning a repository to this house shape.

## Read first

Open the current repository's `rfcs/README.md` and the process RFC it names. That file owns numbering bands, isolation, and extra product tests. This skill owns the shared shape.

When `0001` is free, the process RFC is `0001`. When `0001` already names another document, claim the next free id in the process band and name it in `rfcs/README.md`.

## When to write

Write an RFC for a user-facing API, CLI, file, protocol, or storage contract. Skip a bugfix that restores documented behavior, a typo, or a refactor that leaves observable bytes unchanged.

## Claim an id

Add `rfcs/ids/NNNN` before `rfcs/NNNN-slug.md`. The file holds one line: the kebab slug, or `reserved` then the slug. Two pull requests that add the same `ids/NNNN` path conflict in git. After a conflict, take a free id and rename the draft.

Keep each number on the document that claimed it. A retired id stays retired.

## Copy the template

Copy `rfcs/0000-template.md` from `references/template.md` when the repo has no template, or when aligning to this process. Delete the optional-header instruction. Fill sections that apply. Omit unused header fields and empty sections.

Required header: Type, Status, Created, Author. The title is the H1.

Optional, omit unused: Feature Name, Stakeholders, Feedback until, Relates, Requires, Supersedes. Describes is historical; new RFCs omit it. Version numbers belong in changelogs.

Required sections: Summary, Motivation, Guide-level explanation, Unresolved questions. Summary is the suggestion. Product RFCs also fill Reference-level explanation (the specification), Drawbacks (effects), Rationale and alternatives, and Prior art. Implementation notes are optional evidence.

Prefer under 150 lines. Split a second RFC when a file grows past that because it has two concerns.

## Types

- Standards Track: a public API, CLI, file, or protocol contract implementations MUST follow
- Informational: description or analysis that does not by itself change the contract
- Historical: a shape that shipped before this process
- Procedural: how this project decides, numbers, and advances RFCs

## Statuses

- Draft: authoring; not yet listed as published
- Experimental: published design that is not yet the product contract
- Proposed: a change open for review toward Stable
- Stable: accepted. Behavior that already shipped is Stable when the RFC specifies it; writing the RFC later does not reopen the feature
- Final: deployed long enough that breaking changes need a new RFC
- Deferred, Rejected, Superseded, Obsolete

Accepted maps to Stable when aligning an older tree. The two-week lazy-consensus clock applies to Proposed changes.

## Isolation

Default: RFCs MAY name repository paths a reviewer can open. Prefer another RFC for design cross-references.

Isolation on is opt-in in `rfcs/README.md`: RFCs MUST NOT cite markdown outside `rfcs/`. Implementation notes MAY still name crates, modules, schemas, and fixtures.

## Lifecycle

1. Claim `ids/NNNN`.
2. Copy the template. Omit unused fields and empty sections.
3. Open `rfc: NNNN short title` from `plan/` or `feature/`.
4. Discuss until Summary, Motivation, and Unresolved questions are honest.
5. If the RFC specifies already-shipped design, mark Stable in the same PR. Otherwise mark Experimental, Proposed, Stable, Rejected, or Deferred.
6. Implementation PRs cite `RFC-NNNN`.

## Aligning an existing tree

Flatten band folders to `rfcs/NNNN-slug.md`. Keep existing numbers. Add `ids/` claims for every existing RFC. Replace `0000-template.md` with the shared template. Write or update the process RFC. Update headers (Type, Status) without restyling bodies unless asked. Fold band indexes into `rfcs/README.md`. Leave ADRs where the README already points.

## Prose

State the fact, open with the claim, and keep agency on the person who acts. Prefer commas and full stops over em dashes. Refuse sales language.

Titles, registrar names, paths, CLI verbs, and identifiers use instrument and protocol words: check-in, last-seen, probe, monitor, expected tick. Body and organism metaphors such as heartbeat, pulse, and organ stay out of the contract. HTTP `/health` remains the liveness probe until a later RFC. Follow writing-prose for the rest of the house vocabulary.

A checkable statement MUST name a command, field, fail mode, fixture, schema, or test a reviewer can open. Mark inference. The RFC subject is the design. Version numbers belong in changelogs. Implementation paths are optional evidence.
