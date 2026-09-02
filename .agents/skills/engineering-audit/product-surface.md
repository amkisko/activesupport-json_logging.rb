# Product surface mode

Run this mode when the audited system presents a screen, document, terminal, or other surface a person uses. Skip it for a library or service with no person-facing presentation, and state that reason. Keep the same finding fields.

Names of frameworks, component catalogues, linters, and browser drivers stay out of this mode. Use whatever the tree already runs.

## Accessibility

Automated checks on the rendered tree catch many common problems. They do not prove the surface is accessible. Treat an automated pass as one layer, not a certificate.

Layer the work:

- static rules on markup and client code;
- checks on the rendered tree against a published accessibility standard (WCAG is the usual web frame);
- keyboard-only (or equivalent non-pointer) contracts for forms, menus, dialogs, and focus order;
- contrast, text resize, and reduced-motion where the platform exposes them;
- human review of meaning, labels, and whether the person can complete the task.

Do not quote a tool pass as fully accessible. Separate automated findings from human judgement.

## Presentation quality

Ask whether the person can complete the task on a narrow surface, a short surface, a high-density display, and with pointer or keyboard only. Check empty, loading, error, and long-text states. Check that destructive actions have friction and that error text tells the person what to do next. Ask whether a live refresh or reconnect wipes the work still on the place.

Related: `keep-the-work` keeps the place and in-progress answers after a refusal. This mode asks whether the surface is usable before that refusal.

## Component states

When the tree has reusable presentation units, audit each unit for default, disabled, loading, error, empty, long text, translated text, and the platform's contrast or color-scheme variants. A catalogue or preview surface that exposes those states is the laboratory; full-application flows come after the units are covered.

Record coverage as states scanned versus states defined.

## Optional visual critic

A person or model may comment on hierarchy, clutter, or weak affordance from a screenshot. Bind comments to coordinates or an element identity. This layer is not a release gate.

## Indicators

Prefer counts of rule violations by impact, pass/fail matrices per flow and state, and coverage ratios over adjectives.

## Skip

No person-facing presentation: skip and say so.
