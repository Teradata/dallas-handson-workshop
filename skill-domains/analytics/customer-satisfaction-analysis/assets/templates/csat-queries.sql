-- ============================================================================
-- CUSTOMER SATISFACTION ANALYSIS - QUERY TEMPLATES
-- Copy and customize these templates for common satisfaction analysis tasks
-- ============================================================================

-- ============================================================================
-- 1. OVERALL CSAT AND NPS (Last 12 Months)
-- ============================================================================

-- Template 1.1: Calculate CSAT Score
SELECT
  ROUND(AVG(satisfaction_score), 2) AS csat_score,
  COUNT(*) AS total_responses,
  MIN(survey_date) AS period_start,
  MAX(survey_date) AS period_end,
  STDDEV_POP(satisfaction_score) AS population_stddev
FROM <YOUR_SATISFACTION_TABLE>
WHERE satisfaction_score IS NOT NULL
  AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12);

-- Template 1.2: Calculate NPS (0-10 scale)
WITH nps_calc AS (
  SELECT
    COUNT(CASE WHEN satisfaction_score >= 9 THEN 1 END) AS promoters,
    COUNT(CASE WHEN satisfaction_score >= 7 AND satisfaction_score <= 8 THEN 1 END) AS passives,
    COUNT(CASE WHEN satisfaction_score <= 6 THEN 1 END) AS detractors,
    COUNT(*) AS total
  FROM <YOUR_SATISFACTION_TABLE>
  WHERE satisfaction_score IS NOT NULL
    AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
)
SELECT
  ROUND(100.0 * ((CAST(promoters AS FLOAT) - CAST(detractors AS FLOAT)) / CAST(total AS FLOAT)), 1) AS nps,
  promoters,
  passives,
  detractors,
  total AS respondents
FROM nps_calc;

-- ============================================================================
-- 2. SATISFACTION TRENDS
-- ============================================================================

-- Template 2.1: Monthly CSAT Trend with MoM Change
WITH monthly_csat AS (
  SELECT
    TRUNC(survey_date, 'MONTH') AS month,
    ROUND(AVG(satisfaction_score), 2) AS csat,
    COUNT(*) AS responses
  FROM <YOUR_SATISFACTION_TABLE>
  WHERE satisfaction_score IS NOT NULL
  GROUP BY TRUNC(survey_date, 'MONTH')
)
SELECT
  month,
  csat,
  responses,
  LAG(csat) OVER (ORDER BY month) AS prior_month_csat,
  ROUND(csat - LAG(csat) OVER (ORDER BY month), 2) AS absolute_change,
  ROUND(
    100.0 * (csat - LAG(csat) OVER (ORDER BY month)) / LAG(csat) OVER (ORDER BY month),
    1
  ) AS pct_change
FROM monthly_csat
ORDER BY month DESC;

-- Template 2.2: Year-over-Year CSAT Comparison
WITH monthly AS (
  SELECT
    EXTRACT(YEAR FROM survey_date) AS year,
    EXTRACT(MONTH FROM survey_date) AS month,
    ROUND(AVG(satisfaction_score), 2) AS csat
  FROM <YOUR_SATISFACTION_TABLE>
  WHERE satisfaction_score IS NOT NULL
  GROUP BY EXTRACT(YEAR FROM survey_date), EXTRACT(MONTH FROM survey_date)
)
SELECT
  t1.year,
  t1.month,
  t1.csat AS current_year,
  t0.csat AS prior_year,
  ROUND(t1.csat - t0.csat, 2) AS yoy_change
FROM monthly t1
LEFT JOIN monthly t0 ON t1.month = t0.month AND t1.year = t0.year + 1
ORDER BY t1.year, t1.month;

-- ============================================================================
-- 3. SEGMENT ANALYSIS
-- ============================================================================

-- Template 3.1: CSAT by Product Line
SELECT
  product_line,
  ROUND(AVG(satisfaction_score), 2) AS csat,
  COUNT(*) AS responses,
  STDDEV_SAMP(satisfaction_score) AS stddev,
  ROUND(
    100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
    1
  ) AS volume_pct
FROM <YOUR_SATISFACTION_TABLE>
WHERE satisfaction_score IS NOT NULL
  AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
GROUP BY product_line
ORDER BY csat DESC;

-- Template 3.2: CSAT by Customer Tier
SELECT
  c.customer_tier,
  ROUND(AVG(s.satisfaction_score), 2) AS csat,
  COUNT(*) AS responses,
  ROUND(
    AVG(s.satisfaction_score) -
    (SELECT AVG(satisfaction_score) FROM <YOUR_SATISFACTION_TABLE> WHERE satisfaction_score IS NOT NULL),
    2
  ) AS delta_from_overall
FROM <YOUR_SATISFACTION_TABLE> s
JOIN <YOUR_CUSTOMERS_TABLE> c ON s.customer_id = c.customer_id
WHERE s.satisfaction_score IS NOT NULL
  AND s.survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
GROUP BY c.customer_tier
ORDER BY csat DESC;

-- Template 3.3: CSAT by Region
SELECT
  c.region,
  ROUND(AVG(s.satisfaction_score), 2) AS csat,
  COUNT(*) AS responses,
  MIN(s.survey_date) AS earliest_survey,
  MAX(s.survey_date) AS latest_survey
FROM <YOUR_SATISFACTION_TABLE> s
JOIN <YOUR_CUSTOMERS_TABLE> c ON s.customer_id = c.customer_id
WHERE s.satisfaction_score IS NOT NULL
  AND s.survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
GROUP BY c.region
ORDER BY csat DESC;

-- ============================================================================
-- 4. DATA QUALITY CHECKS
-- ============================================================================

-- Template 4.1: Data Quality Summary
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(CASE WHEN satisfaction_score IS NULL THEN 1 END) AS null_scores,
  COUNT(CASE WHEN satisfaction_score IS NOT NULL THEN 1 END) AS valid_scores,
  MIN(satisfaction_score) AS min_score,
  MAX(satisfaction_score) AS max_score,
  MODE(satisfaction_score) AS mode_score,
  ROUND(AVG(satisfaction_score), 2) AS mean_score,
  MIN(survey_date) AS earliest_date,
  MAX(survey_date) AS latest_date
FROM <YOUR_SATISFACTION_TABLE>;

-- Template 4.2: Outlier Detection
WITH stats AS (
  SELECT
    AVG(satisfaction_score) AS mean,
    STDDEV_POP(satisfaction_score) AS stddev
  FROM <YOUR_SATISFACTION_TABLE>
  WHERE satisfaction_score IS NOT NULL
)
SELECT
  satisfaction_score,
  COUNT(*) AS frequency,
  CASE
    WHEN ABS(satisfaction_score - mean) > 3 * stddev THEN 'Outlier (3σ)'
    WHEN ABS(satisfaction_score - mean) > 2 * stddev THEN 'Potential Outlier (2σ)'
    ELSE 'Normal'
  END AS classification
FROM <YOUR_SATISFACTION_TABLE>, stats
WHERE satisfaction_score IS NOT NULL
GROUP BY satisfaction_score, mean, stddev
ORDER BY frequency DESC;

-- ============================================================================
-- 5. ADVANCED: ROLLING AVERAGES & SMOOTHING
-- ============================================================================

-- Template 5.1: 3-Month Rolling Average
WITH monthly_csat AS (
  SELECT
    TRUNC(survey_date, 'MONTH') AS month,
    ROUND(AVG(satisfaction_score), 2) AS csat
  FROM <YOUR_SATISFACTION_TABLE>
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
  ) AS rolling_3m_avg
FROM monthly_csat
ORDER BY month DESC;

-- ============================================================================
-- 6. CHURN RISK & LOYALTY
-- ============================================================================

-- Template 6.1: At-Risk Segments (Declining Satisfaction)
WITH segment_monthly AS (
  SELECT
    product_line,
    TRUNC(survey_date, 'MONTH') AS month,
    ROUND(AVG(satisfaction_score), 2) AS csat
  FROM <YOUR_SATISFACTION_TABLE>
  WHERE satisfaction_score IS NOT NULL
  GROUP BY product_line, TRUNC(survey_date, 'MONTH')
),
latest_trend AS (
  SELECT
    product_line,
    csat AS latest_csat,
    LAG(csat) OVER (PARTITION BY product_line ORDER BY month) AS prior_csat,
    ROUND(csat - LAG(csat) OVER (PARTITION BY product_line ORDER BY month), 2) AS change
  FROM segment_monthly
  WHERE month >= ADD_MONTHS(TRUNC(TODAY()), -3)
)
SELECT
  product_line,
  latest_csat,
  change,
  CASE
    WHEN change < -0.2 THEN 'High Risk - Declining'
    WHEN change < 0 THEN 'At Risk - Slight Decline'
    WHEN change >= 0.2 THEN 'Improving'
    ELSE 'Stable'
  END AS risk_status
FROM latest_trend
WHERE prior_csat IS NOT NULL
ORDER BY change ASC;

-- ============================================================================
-- CUSTOMIZATION NOTES:
-- Replace <YOUR_SATISFACTION_TABLE> with actual table name
-- Replace <YOUR_CUSTOMERS_TABLE> with actual customer dimension table
-- Adjust date filters (e.g., -12 months) as needed
-- Modify segment fields (product_line, customer_tier, region) to match your schema
-- ============================================================================
