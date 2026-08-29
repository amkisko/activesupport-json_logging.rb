# Freshness metrics (libyears and related)

Use with Pass 2 of the dependency-audit skill. Concepts apply across ecosystems. Tool names vary; the metric does not.

Libyears (or an equivalent lag measure) is the age of locked versions versus current releases, summed across the graph. It is one freshness signal. It is not effort, risk, or a schedule.

## Estimation

Prefer team knowledge of this graph. Prefer a spike: upgrade the outliers and see whether the tree still works. Record spike results in the risk write-up.

There is no established correlation between libyears and work hours. Do not quote hour estimates from libyears alone.

## Metrics to combine

Use more than one signal.

| Metric | Role |
|--------|------|
| Total libyears (or equivalent) | stack-wide lag versus current releases |
| Average per package | total divided by package count; flags concentrated drift |
| Major-version distance | how many major versions behind; include in risk |
| Test coverage | safety net for upgrades |

Lag does not show compatibility of newer versions. A low total does not guarantee an easy upgrade.

## Bands

Bands differ by ecosystem. State which band table you used. The numbers below are starting guidance, not house law.

Compact application graphs (few direct packages, slow release cadence) often treat total lag of about 10 as low, about 100 as medium, and above 100 as high.

High-churn graphs with many small libraries often show totals around 1000 even when maintainers are active. Recalibrate before calling that high.

If average lag per package is more than a few years, treat that as definite risk even when the total looks acceptable for the ecosystem.

## Stakeholder copy

State risk from combined metrics, not lag alone. Separate observed facts (measured lag, coverage, spike result) from inference (effort, schedule). Do not sell upgrades from lag math. Cite spike results, coverage gaps, and major-version jumps.

Non-engineer copy: reliability and maintenance risk in plain language. Package names and metric jargon only when that audience asked.

## Checklist

- total and average lag recorded;
- major-version distance noted for the worst offenders;
- test coverage included;
- spike or compatibility check attempted when feasible;
- ecosystem context applied and named;
- no hour estimate derived only from lag.
