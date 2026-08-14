# Customer Satisfaction Calculation Guide

This reference details the formulas and implementation patterns for CSAT, NPS, and related metrics.

## CSAT (Customer Satisfaction Score)

### Definition
CCSAT is the average of customer satisfaction ratings over a time period.

### Formula
```
CSAT = (Sum of satisfaction ratings) / (Number of valid responses)
```

### Implementation in Teradata
```sql
SELECT
  ROUND(AVG(satisfaction_score), 2) AS csat,
  COUNT(*) AS responses,
  MIN(survey_date) AS period_start,
  MAX(survey_date) AS period_end,
  STDDEV_POP(satisfaction_score) AS population_stddev,
  STDDEV_SAMP(satisfaction_score) AS sample_stddev
FROM satisfaction_surveys
WHERE satisfaction_score IS NOT NULL
  AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12);
```

### Interpretation
- **Scale 1–5**: CSAT ≥ 4.0 is considered healthy; < 3.0 signals concern
- **Scale 1–10**: CSAT ≥ 7.5 is strong; < 6.0 indicates dissatisfaction
- **Scale 0–100**: CSAT ≥ 70 is acceptable; < 50 is poor

## NPS (Net Promoter Score)

### Definition
NPS measures customer loyalty by subtracting the percentage of Detractors from the percentage of Promoters.

### Formula
```
NPS = (Promoters % − Detractors %) × 100
```
Where on a 0–10 scale:
- **Promoters** = scores 9–10
- **Passives** = scores 7–8
- **Detractors** = scores 0–6

### Implementation in Teradata
```sql
WITH categories AS (
  SELECT
    COUNT(CASE WHEN satisfaction_score >= 9 THEN 1 END) AS promoters,
    COUNT(CASE WHEN satisfaction_score BETWEEN 7 AND 8 THEN 1 END) AS passives,
    COUNT(CASE WHEN satisfaction_score <= 6 THEN 1 END) AS detractors,
    COUNT(*) AS total
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
    AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
)
SELECT
  ROUND(
    100.0 * ((CAST(promoters AS FLOAT) - CAST(detractors AS FLOAT)) / CAST(total AS FLOAT)),
    1
  ) AS nps,
  promoters,
  passives,
  detractors,
  total
FROM categories;
```

### Interpretation
- **NPS > 50**: Excellent (world-class)
- **NPS 20–50**: Good
- **NPS 0–20**: Acceptable
- **NPS < 0**: Problem (detractors > promoters)

## Response Rate

### Definition
The percentage of surveyed customers who responded.

### Formula
```
Response Rate = (Responses / Invitations) × 100
```

### Implementation in Teradata
```sql
SELECT
  COUNT(DISTINCT customer_id) AS respondents,
  (SELECT COUNT(DISTINCT customer_id) FROM customer_universe WHERE survey_eligible = 1) AS eligible,
  ROUND(
    100.0 * COUNT(DISTINCT customer_id) /
    (SELECT CAST(COUNT(DISTINCT customer_id) AS FLOAT) FROM customer_universe WHERE survey_eligible = 1),
    1
  ) AS response_rate_pct
FROM satisfaction_surveys
WHERE survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12);
```

### Benchmarks
- Online surveys: 20–35% typical
- Email surveys: 5–15%
- Phone surveys: 40–60%

## Confidence Interval (95%)

### Definition
Range around CSAT that accounts for sampling variability.

### Formula
```
CI = CSAT ± 1.96 × (StdDev / √N)
```

### Implementation in Teradata
```sql
WITH stats AS (
  SELECT
    AVG(satisfaction_score) AS mean_csat,
    STDDEV_SAMP(satisfaction_score) AS sample_stddev,
    COUNT(*) AS n
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
    AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
)
SELECT
  ROUND(mean_csat, 2) AS csat,
  ROUND(mean_csat - 1.96 * (sample_stddev / SQRT(CAST(n AS FLOAT))), 2) AS ci_lower,
  ROUND(mean_csat + 1.96 * (sample_stddev / SQRT(CAST(n AS FLOAT))), 2) AS ci_upper,
  n AS sample_size
FROM stats;
```

## CSAT by Segment with Confidence Intervals

```sql
WITH segment_stats AS (
  SELECT
    product_line,
    AVG(satisfaction_score) AS mean_csat,
    STDDEV_SAMP(satisfaction_score) AS sample_stddev,
    COUNT(*) AS n
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
    AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
  GROUP BY product_line
)
SELECT
  product_line,
  ROUND(mean_csat, 2) AS csat,
  ROUND(mean_csat - 1.96 * (sample_stddev / SQRT(CAST(n AS FLOAT))), 2) AS ci_lower,
  ROUND(mean_csat + 1.96 * (sample_stddev / SQRT(CAST(n AS FLOAT))), 2) AS ci_upper,
  n AS responses
FROM segment_stats
ORDER BY mean_csat DESC;
```

## Month-over-Month CSAT Change

```sql
WITH monthly_csat AS (
  SELECT
    TRUNC(survey_date, 'MONTH') AS month,
    ROUND(AVG(satisfaction_score), 2) AS csat,
    COUNT(*) AS responses
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
  GROUP BY TRUNC(survey_date, 'MONTH')
)
SELECT
  month,
  csat,
  responses,
  LAG(csat) OVER (ORDER BY month) AS prev_month_csat,
  ROUND(csat - LAG(csat) OVER (ORDER BY month), 2) AS mom_change,
  ROUND(
    100.0 * (csat - LAG(csat) OVER (ORDER BY month))
    / LAG(csat) OVER (ORDER BY month),
    1
  ) AS mom_pct_change
FROM monthly_csat
ORDER BY month DESC;
```

## Edge Cases & Data Quality

### Null Handling
Always filter out NULL satisfaction scores:
```sql
WHERE satisfaction_score IS NOT NULL
```

### Outlier Detection
Identify and optionally exclude extreme values:
```sql
WITH stats AS (
  SELECT
    AVG(satisfaction_score) AS mean,
    STDDEV_POP(satisfaction_score) AS stddev
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
)
SELECT
  satisfaction_score,
  CASE
    WHEN ABS(satisfaction_score - mean) > 3 * stddev THEN 'Outlier'
    ELSE 'Normal'
  END AS classification
FROM satisfaction_surveys, stats
WHERE satisfaction_score IS NOT NULL;
```

### Duplicate Responses
Handle cases where a customer rated multiple times:
```sql
-- Keep only the most recent response per customer
WITH ranked_responses AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY survey_date DESC) AS rn
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
)
SELECT
  ROUND(AVG(satisfaction_score), 2) AS deduplicated_csat,
  COUNT(*) AS unique_customers
FROM ranked_responses
WHERE rn = 1;
```
