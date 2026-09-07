# Changelog update

## Two layers

1. `usr/docs/changelogs/` — engineering draft: intent, reproduction steps, implementation notes, pull request links.
2. `CHANGELOG.md` — product-facing release notes: describe what people see and can do, not how it is built.

File name for new engineering notes: `usr/docs/changelogs/#{YYYYMMDDHHMMSS}_<title>.md` with kebab-case title.

## Audience split

| Layer | Reader | Voice |
|-------|--------|-------|
| `CHANGELOG.md` | users, operators, product owners | outcome, screen, workflow; plain language |
| `usr/docs/changelogs/` | engineers and reviewers | classes, files, trade-offs, links |

`CHANGELOG.md` may name an operator surface when that is the user-visible place, but still describe the workflow benefit, not internal adapter or job names.

## When to write

- user-visible features, fixes, and breaking behavior: yes;
- library upgrades, internal refactors, dev-only tooling: no unless they change a public contract or operator workflow users rely on;
- do not invent behavior; gather facts from `usr/docs/changelogs/`, git diff, or commits since the last release tag.

## CHANGELOG.md shape

```markdown
# CHANGELOG

## X.Y.Z (YYYY-MM-DD)

- Add ...
- Fix ...
```

Rules:

- title line is `# CHANGELOG` only;
- use ISO date in parentheses on version headings when the repository follows that convention;
- unordered list with `- ` only;
- bullets stay imperative, concrete, and short;
- no marketing language;
- state the finding directly; preserve necessary negation.

## Workflow

1. capture engineering detail in `usr/docs/changelogs/` when the change is significant enough to mention;
2. distill user-visible outcomes into `CHANGELOG.md` when cutting a release;
3. review for marketing language, invented objections, empty contrasts, and stray em dashes; preserve meaning, necessary negation, scope, and uncertainty;
4. keep version headings and release tags aligned when the repository uses tagged releases.

## Relationship to pull requests

Pull request descriptions answer what problem is solved, why it matters, how the solution works, and relevant context. Changelog bullets are slightly more user-facing than commit titles but still concrete, not promotional.
