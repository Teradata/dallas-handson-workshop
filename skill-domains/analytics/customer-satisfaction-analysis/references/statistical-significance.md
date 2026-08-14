# Statistical Significance Testing for Satisfaction Segments

This reference covers hypothesis testing to determine whether satisfaction differences between segments are statistically significant.

## T-Test: Comparing Two Segments

### Scenario
Compare CSAT between two customer segments (e.g., Premium vs. Standard).

### Hypothesis
- **H0 (Null)**: Mean CSAT for Segment A = Mean CSAT for Segment B
- **H1 (Alternative)**: Means are different
- **Significance Level**: α = 0.05 (95% confidence)

### Implementation in Teradata
```sql
WITH segment_data AS (
  SELECT
    customer_tier,
    satisfaction_score
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
    AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
),
segment_stats AS (
  SELECT
    customer_tier,
    COUNT(*) AS n,
    AVG(satisfaction_score) AS mean_csat,
    STDDEV_SAMP(satisfaction_score) AS sample_stddev,
    SQRT(CAST(COUNT(*) AS FLOAT)) AS sqrt_n
  FROM segment_data
  GROUP BY customer_tier
)
SELECT
  s1.customer_tier AS segment_1,
  s2.customer_tier AS segment_2,
  ROUND(s1.mean_csat, 2) AS mean_1,
  ROUND(s2.mean_csat, 2) AS mean_2,
  ROUND(s1.mean_csat - s2.mean_csat, 2) AS difference,
  -- Standard error of difference
  ROUND(
    SQRT(
      (POWER(s1.sample_stddev, 2) / s1.n) +
      (POWER(s2.sample_stddev, 2) / s2.n)
    ),
    4
  ) AS se_difference,
  -- T-statistic
  ROUND(
    (s1.mean_csat - s2.mean_csat) /
    SQRT(
      (POWER(s1.sample_stddev, 2) / s1.n) +
      (POWER(s2.sample_stddev, 2) / s2.n)
    ),
    4
  ) AS t_statistic,
  -- Degrees of freedom (approximation)
  CAST(
    POWER(
      (POWER(s1.sample_stddev, 2) / s1.n) +
      (POWER(s2.sample_stddev, 2) / s2.n),
      2
    ) /
    (
      POWER(POWER(s1.sample_stddev, 2) / s1.n, 2) / (s1.n - 1) +
      POWER(POWER(s2.sample_stddev, 2) / s2.n, 2) / (s2.n - 1)
    )
    AS INTEGER
  ) AS df,
  CASE
    WHEN ABS(
      (s1.mean_csat - s2.mean_csat) /
      SQRT(
        (POWER(s1.sample_stddev, 2) / s1.n) +
        (POWER(s2.sample_stddev, 2) / s2.n)
      )
    ) > 1.96 THEN 'Significant (p < 0.05)'
    ELSE 'Not Significant (p >= 0.05)'
  END AS significance_result
FROM segment_stats s1, segment_stats s2
WHERE s1.customer_tier < s2.customer_tier;
```

**Interpretation**:
- If `t_statistic` > 1.96 (or < -1.96 for large samples), reject H0: difference is **significant**.
- Otherwise, fail to reject H0: difference is **not significant** (could be due to random variation).

## ANOVA: Comparing Multiple Segments

### Scenario
Compare CSAT across 3+ segments (e.g., by region: North, South, East, West).

### Hypothesis
- **H0 (Null)**: All segment means are equal
- **H1 (Alternative)**: At least one segment mean differs

### Implementation in Teradata
```sql
WITH segment_data AS (
  SELECT
    region,
    satisfaction_score
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
    AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
),
segment_stats AS (
  SELECT
    region,
    COUNT(*) AS n,
    AVG(satisfaction_score) AS segment_mean,
    STDDEV_SAMP(satisfaction_score) AS sample_stddev
  FROM segment_data
  GROUP BY region
),
grand_stats AS (
  SELECT
    AVG(satisfaction_score) AS grand_mean,
    COUNT(*) AS total_n,
    STDDEV_SAMP(satisfaction_score) AS total_stddev,
    COUNT(DISTINCT region) AS k_groups
  FROM segment_data
),
anova_components AS (
  SELECT
    g.total_n,
    g.k_groups,
    g.total_n - g.k_groups AS df_within,
    g.k_groups - 1 AS df_between,
    g.grand_mean,
    -- Between-group sum of squares (BSS)
    SUM(s.n * POWER(s.segment_mean - g.grand_mean, 2)) AS bss,
    -- Within-group sum of squares (WSS)
    SUM((s.n - 1) * POWER(s.sample_stddev, 2)) AS wss
  FROM segment_stats s, grand_stats g
  GROUP BY g.total_n, g.k_groups, g.df_within, g.df_between, g.grand_mean
)
SELECT
  total_n,
  k_groups,
  df_between,
  df_within,
  ROUND(bss / df_between, 4) AS mss_between,  -- Mean sum of squares (between)
  ROUND(wss / df_within, 4) AS mss_within,    -- Mean sum of squares (within)
  ROUND((bss / df_between) / (wss / df_within), 4) AS f_statistic,
  CASE
    WHEN (bss / df_between) / (wss / df_within) > 2.5 THEN 'Likely Significant (p < 0.05)'
    ELSE 'Not Significant (p >= 0.05)'
  END AS significance_result
FROM anova_components;
```

**Interpretation**:
- F-statistic > 2.5 (rough threshold for 3–4 groups): at least one segment mean significantly differs.
- F-statistic ≤ 2.5: no significant difference detected (could be random variation).

## Effect Size: Cohen's d

### Scenario
Measure the practical magnitude of difference between two segments.

### Formula
```
Cohen's d = (Mean 1 − Mean 2) / Pooled StdDev
```
Interpretation:
- d < 0.2: Negligible
- 0.2 ≤ d < 0.5: Small
- 0.5 ≤ d < 0.8: Medium
- d ≥ 0.8: Large

### Implementation
```sql
WITH segment_stats AS (
  SELECT
    customer_tier,
    COUNT(*) AS n,
    AVG(satisfaction_score) AS mean_csat,
    STDDEV_SAMP(satisfaction_score) AS sample_stddev
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
    AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
  GROUP BY customer_tier
)
SELECT
  s1.customer_tier,
  s2.customer_tier,
  ROUND(s1.mean_csat - s2.mean_csat, 2) AS difference,
  -- Pooled standard deviation
  ROUND(
    SQRT(
      (
        (s1.n - 1) * POWER(s1.sample_stddev, 2) +
        (s2.n - 1) * POWER(s2.sample_stddev, 2)
      ) / (s1.n + s2.n - 2)
    ),
    2
  ) AS pooled_stddev,
  -- Cohen's d
  ROUND(
    (s1.mean_csat - s2.mean_csat) /
    SQRT(
      (
        (s1.n - 1) * POWER(s1.sample_stddev, 2) +
        (s2.n - 1) * POWER(s2.sample_stddev, 2)
      ) / (s1.n + s2.n - 2)
    ),
    2
  ) AS cohens_d,
  CASE
    WHEN ABS(
      (s1.mean_csat - s2.mean_csat) /
      SQRT(
        (
          (s1.n - 1) * POWER(s1.sample_stddev, 2) +
          (s2.n - 1) * POWER(s2.sample_stddev, 2)
        ) / (s1.n + s2.n - 2)
      )
    ) >= 0.8 THEN 'Large'
    WHEN ABS(
      (s1.mean_csat - s2.mean_csat) /
      SQRT(
        (
          (s1.n - 1) * POWER(s1.sample_stddev, 2) +
          (s2.n - 1) * POWER(s2.sample_stddev, 2)
        ) / (s1.n + s2.n - 2)
      )
    ) >= 0.5 THEN 'Medium'
    WHEN ABS(
      (s1.mean_csat - s2.mean_csat) /
      SQRT(
        (
          (s1.n - 1) * POWER(s1.sample_stddev, 2) +
          (s2.n - 1) * POWER(s2.sample_stddev, 2)
        ) / (s1.n + s2.n - 2)
      )
    ) >= 0.2 THEN 'Small'
    ELSE 'Negligible'
  END AS effect_size
FROM segment_stats s1, segment_stats s2
WHERE s1.customer_tier < s2.customer_tier;
```
