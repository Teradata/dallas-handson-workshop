---
name: data-anomaly-spotter
title: Data Anomaly Spotter
description: 'Detect statistical anomalies, outliers, and unusual patterns in Teradata data. Identify spikes, drops, duplicates, missing values, and distribution shifts using quantile analysis, standard deviation thresholds, and time-series trend detection.'
domain: data
metadata:
  author: Tera Workshop Team
  version: 1.0.0
trigger:
  mode: HYBRID
  slash_commands: ['/anomaly-spotter']
  keywords: ['detect anomalies', 'find outliers', 'spot unusual patterns', 'identify spikes', 'data quality issues', 'unusual distribution', 'anomaly detection']
  intent_categories: ['data-exploration', 'quality-check', 'diagnostics']
  min_confidence: 0.65
prompt:
  constraints:
    - Always validate the table exists and the column is numeric before running statistical queries.
    - Use quantile-based detection (IQR method) as the primary technique; supplement with z-score for confirmation.
    - For time-series anomalies, establish baseline from historical data before flagging recent records.
    - Never modify user data; all queries are read-only exploration and analysis.
    - Explain the statistical method used and the threshold rationale to the user.
  output_format: |
    1. Anomaly detection result summary (count, % of data flagged)
    2. Top anomalies (5–10 examples with values and deviation from baseline)
    3. Statistical method and threshold explanation
    4. Recommendation (e.g., "investigate these records", "check data entry process", "legitimate business spike")
---

# Data Anomaly Spotter

## When to Use
- You suspect unusual values in a numeric column (spikes, drops, extreme outliers).
- You need to identify data quality issues like duplicates, gaps, or distribution shifts.
- You want to validate data before loading into a model or report.
- You're investigating a sudden change in KPIs or metrics.
- **Do NOT use for:** generating synthetic data, modifying existing records, or business rule enforcement — use `row-level-security` or data-governance skills instead.

## Core Concepts

### Statistical Methods

| Method | Use Case | Threshold |
|--------|----------|----------|
| **Interquartile Range (IQR)** | General outlier detection | Values < Q1 - 1.5×IQR or > Q3 + 1.5×IQR |
| **Z-Score** | Normally distributed data | \|z-score\| > 3 (extreme) or > 2 (moderate) |
| **Median Absolute Deviation (MAD)** | Robust for skewed data | Modified z-score > 3.5 |
| **Time-Series Trend** | Seasonal or sequential data | % deviation from moving average > threshold |

### Key Terms
- **Outlier**: A value that deviates significantly from the typical range.
- **Anomaly**: An unexpected or irregular occurrence (may be legitimate business event or data error).
- **Baseline**: Historical normal range used to detect deviations.
- **False Positive**: Flagged anomaly that is actually valid (e.g., legitimate sales spike).

## Procedure: Detect Anomalies in a Column

1. **Profile the column** — collect count, mean, median, std dev, min, max, and quartiles.
   - This establishes the baseline and determines which method to use.
   - Skewed data → use IQR or MAD; normally distributed → z-score is acceptable.

2. **Apply IQR-based detection** — identify records outside the whiskers.
   - Compute Q1 (25th percentile), Q3 (75th percentile), IQR = Q3 - Q1.
   - Flag values where `value < Q1 - 1.5 * IQR` or `value > Q3 + 1.5 * IQR`.
   - See [iqr-detection.sql](./references/iqr-detection.sql) for the query template.

3. **Investigate top anomalies** — extract and sort by deviation magnitude.
   - Retrieve the most extreme 10 anomalies and context (timestamp, related fields).
   - Calculate deviation ratio or z-score to rank severity.

4. **Validate with secondary method** — if results seem unexpected, confirm with z-score or MAD.
   - Reconcile false positives; confirm legitimate business events.
   - See [z-score-validation.sql](./references/z-score-validation.sql).

5. **Report findings** — summarize count, severity distribution, and recommendation.
   - State the method, threshold, and justification.
   - Suggest next steps: data cleaning, investigation, or accept as legitimate variance.

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Too many false positives | Threshold too strict (z > 2 is moderate, not extreme) | Use z > 3 for extreme only; pair IQR with domain knowledge |
| Method choice unclear | Applied z-score to highly skewed data | Check distribution first; use IQR or MAD for skew |
| Seasonal spikes missed | Baseline includes high/low seasons | Split by season or use trailing moving average as baseline |
| No anomalies detected | Threshold too lenient | Lower threshold; check if data is truly uniform |
| Performance degradation | Large table scanned multiple times | Materialize intermediate stats; use SAMPLE for exploration |

## References
- [IQR Detection Query](./references/iqr-detection.sql) — Teradata SQL template for quantile-based anomaly detection.
- [Z-Score Validation](./references/z-score-validation.sql) — Secondary confirmation using z-score method.
- [Statistical Foundations](./references/statistical-foundations.md) — In-depth explanation of methods, trade-offs, and when each applies.
