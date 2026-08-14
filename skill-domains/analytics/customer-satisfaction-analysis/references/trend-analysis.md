# Satisfaction Trend Analysis

This reference covers time-series techniques for understanding satisfaction evolution.

## Month-over-Month (MoM) Trend

### Basic MoM Change
```sql
WITH monthly AS (
  SELECT
    TRUNC(survey_date, 'MONTH') AS month,
    ROUND(AVG(satisfaction_score), 2) AS csat
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
  GROUP BY TRUNC(survey_date, 'MONTH')
)
SELECT
  month,
  csat,
  LAG(csat) OVER (ORDER BY month) AS prior_month,
  ROUND(csat - LAG(csat) OVER (ORDER BY month), 2) AS absolute_change,
  ROUND(
    100.0 * (csat - LAG(csat) OVER (ORDER BY month)) / LAG(csat) OVER (ORDER BY month),
    1
  ) AS pct_change
FROM monthly
ORDER BY month;
```

## Year-over-Year (YoY) Trend

### Compare current month to same month prior year
```sql
WITH monthly AS (
  SELECT
    EXTRACT(YEAR FROM survey_date) AS year,
    EXTRACT(MONTH FROM survey_date) AS month,
    ROUND(AVG(satisfaction_score), 2) AS csat,
    COUNT(*) AS responses
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
  GROUP BY EXTRACT(YEAR FROM survey_date), EXTRACT(MONTH FROM survey_date)
)
SELECT
  t1.year,
  t1.month,
  t1.csat AS current_year_csat,
  t0.csat AS prior_year_csat,
  ROUND(t1.csat - t0.csat, 2) AS yoy_change,
  ROUND(
    100.0 * (t1.csat - t0.csat) / t0.csat,
    1
  ) AS yoy_pct_change
FROM monthly t1
LEFT JOIN monthly t0 ON t1.month = t0.month AND t1.year = t0.year + 1
WHERE t1.year >= EXTRACT(YEAR FROM ADD_MONTHS(TODAY(), -24))
ORDER BY t1.year, t1.month;
```

## Rolling Average (Smoothing)

### 3-Month Rolling Average
Use a rolling window to smooth month-to-month volatility:
```sql
WITH monthly AS (
  SELECT
    TRUNC(survey_date, 'MONTH') AS month,
    ROUND(AVG(satisfaction_score), 2) AS csat
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
  GROUP BY TRUNC(survey_date, 'MONTH')
)
SELECT
  month,
  csat,
  ROUND(
    AVG(csat) OVER (
      ORDER BY month
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ),
    2
  ) AS rolling_3m_avg,
  ROUND(
    AVG(csat) OVER (
      ORDER BY month
      ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
    ),
    2
  ) AS rolling_12m_avg
FROM monthly
ORDER BY month;
```

## Trend Detection: Improving vs. Declining

### Classify Trend Direction
```sql
WITH monthly AS (
  SELECT
    TRUNC(survey_date, 'MONTH') AS month,
    ROUND(AVG(satisfaction_score), 2) AS csat
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
  GROUP BY TRUNC(survey_date, 'MONTH')
),
trend_stats AS (
  SELECT
    month,
    csat,
    ROW_NUMBER() OVER (ORDER BY month) AS month_num,
    AVG(csat) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_avg
  FROM monthly
)
SELECT
  month,
  csat,
  CASE
    WHEN csat > cumulative_avg THEN 'Improving'
    WHEN csat < cumulative_avg THEN 'Declining'
    ELSE 'Stable'
  END AS trend_direction,
  ROUND(csat - cumulative_avg, 2) AS deviation_from_avg
FROM trend_stats
WHERE month >= ADD_MONTHS(TRUNC(TODAY()), -12)
ORDER BY month DESC;
```

## Segment Trend Comparison

### CSAT Trend by Product Line
```sql
WITH segment_monthly AS (
  SELECT
    TRUNC(survey_date, 'MONTH') AS month,
    product_line,
    ROUND(AVG(satisfaction_score), 2) AS csat,
    COUNT(*) AS responses
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
  GROUP BY TRUNC(survey_date, 'MONTH'), product_line
)
SELECT
  month,
  product_line,
  csat,
  responses,
  LAG(csat) OVER (PARTITION BY product_line ORDER BY month) AS prior_month_csat,
  ROUND(
    csat - LAG(csat) OVER (PARTITION BY product_line ORDER BY month),
    2
  ) AS mom_change
FROM segment_monthly
ORDER BY product_line, month DESC;
```

## Seasonal Decomposition (Simple)

### Identify Seasonal Pattern
```sql
WITH monthly AS (
  SELECT
    TRUNC(survey_date, 'MONTH') AS month,
    EXTRACT(MONTH FROM survey_date) AS month_of_year,
    ROUND(AVG(satisfaction_score), 2) AS csat
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
    AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -24)  -- 2 years minimum
  GROUP BY TRUNC(survey_date, 'MONTH'), EXTRACT(MONTH FROM survey_date)
),
seasonality AS (
  SELECT
    month_of_year,
    ROUND(AVG(csat), 2) AS seasonal_avg,
    COUNT(*) AS occurrences
  FROM monthly
  GROUP BY month_of_year
)
SELECT
  month_of_year,
  TO_CHAR(TO_DATE('2000-' || LPAD(month_of_year, 2, '0') || '-01', 'YYYY-MM-DD'), 'Month') AS month_name,
  seasonal_avg,
  ROUND(seasonal_avg - (SELECT AVG(seasonal_avg) FROM seasonality), 2) AS seasonal_component
FROM seasonality
ORDER BY month_of_year;
```

## Acceleration/Deceleration Detection

### Identify when satisfaction change accelerates or slows
```sql
WITH monthly AS (
  SELECT
    TRUNC(survey_date, 'MONTH') AS month,
    ROUND(AVG(satisfaction_score), 2) AS csat
  FROM satisfaction_surveys
  WHERE satisfaction_score IS NOT NULL
  GROUP BY TRUNC(survey_date, 'MONTH')
)
SELECT
  month,
  csat,
  LAG(csat) OVER (ORDER BY month) AS prior_csat,
  LAG(LAG(csat)) OVER (ORDER BY month) AS prior_prior_csat,
  ROUND(csat - LAG(csat) OVER (ORDER BY month), 2) AS current_change,
  ROUND(
    LAG(csat) OVER (ORDER BY month) - LAG(LAG(csat)) OVER (ORDER BY month),
    2
  ) AS prior_change,
  ROUND(
    (csat - LAG(csat) OVER (ORDER BY month))
    - (LAG(csat) OVER (ORDER BY month) - LAG(LAG(csat)) OVER (ORDER BY month)),
    2
  ) AS acceleration,
  CASE
    WHEN (csat - LAG(csat) OVER (ORDER BY month))
         - (LAG(csat) OVER (ORDER BY month) - LAG(LAG(csat)) OVER (ORDER BY month)) > 0.1
      THEN 'Accelerating Improvement'
    WHEN (csat - LAG(csat) OVER (ORDER BY month))
         - (LAG(csat) OVER (ORDER BY month) - LAG(LAG(csat)) OVER (ORDER BY month)) < -0.1
      THEN 'Accelerating Decline'
    ELSE 'Stable Pace'
  END AS acceleration_status
FROM monthly
ORDER BY month DESC;
```
