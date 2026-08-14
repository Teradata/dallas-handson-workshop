# Satisfaction Drivers Analysis

This reference covers techniques to identify which factors or behaviors correlate most strongly with satisfaction.

## Correlation: Satisfaction vs. Single Factor

### Scenario
Identify whether customer tenure correlates with satisfaction.

### Implementation in Teradata
```sql
WITH corr_data AS (
  SELECT
    s.satisfaction_score,
    EXTRACT(YEAR FROM AGE(TODAY(), c.customer_since)) AS tenure_years
  FROM satisfaction_surveys s
  JOIN customers c ON s.customer_id = c.customer_id
  WHERE s.satisfaction_score IS NOT NULL
    AND s.survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
)
SELECT
  COUNT(*) AS n,
  ROUND(
    (
      SUM(satisfaction_score * tenure_years) -
      (SUM(satisfaction_score) * SUM(tenure_years) / COUNT(*))
    ) /
    SQRT(
      (
        SUM(POWER(satisfaction_score, 2)) -
        POWER(SUM(satisfaction_score), 2) / COUNT(*)
      ) *
      (
        SUM(POWER(tenure_years, 2)) -
        POWER(SUM(tenure_years), 2) / COUNT(*)
      )
    ),
    3
  ) AS pearson_correlation,
  CASE
    WHEN ABS(
      (
        SUM(satisfaction_score * tenure_years) -
        (SUM(satisfaction_score) * SUM(tenure_years) / COUNT(*))
      ) /
      SQRT(
        (
          SUM(POWER(satisfaction_score, 2)) -
          POWER(SUM(satisfaction_score), 2) / COUNT(*)
        ) *
        (
          SUM(POWER(tenure_years, 2)) -
          POWER(SUM(tenure_years), 2) / COUNT(*)
        )
      )
    ) > 0.3 THEN 'Moderate-to-Strong Correlation'
    WHEN ABS(
      (
        SUM(satisfaction_score * tenure_years) -
        (SUM(satisfaction_score) * SUM(tenure_years) / COUNT(*))
      ) /
      SQRT(
        (
          SUM(POWER(satisfaction_score, 2)) -
          POWER(SUM(satisfaction_score), 2) / COUNT(*)
        ) *
        (
          SUM(POWER(tenure_years, 2)) -
          POWER(SUM(tenure_years), 2) / COUNT(*)
        )
      )
    ) > 0.1 THEN 'Weak Correlation'
    ELSE 'No Significant Correlation'
  END AS correlation_strength
FROM corr_data;
```

**Interpretation**:
- Pearson r > 0.3 (or < −0.3): Moderate-to-strong relationship
- 0.1 < r ≤ 0.3: Weak relationship
- r ≤ 0.1: No meaningful correlation

## Categorical Driver: Satisfaction by Product/Feature

### Scenario
Identify which product line drives highest satisfaction.

### Implementation
```sql
SELECT
  product_line,
  COUNT(*) AS responses,
  ROUND(AVG(satisfaction_score), 2) AS avg_csat,
  ROUND(STDDEV_SAMP(satisfaction_score), 2) AS stddev,
  ROUND(
    AVG(satisfaction_score) -
    (SELECT AVG(satisfaction_score) FROM satisfaction_surveys WHERE satisfaction_score IS NOT NULL),
    2
  ) AS deviation_from_overall_mean,
  ROUND(
    100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
    1
  ) AS volume_pct
FROM satisfaction_surveys
WHERE satisfaction_score IS NOT NULL
  AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
GROUP BY product_line
ORDER BY avg_csat DESC;
```

## Behavioral Driver: Feature Usage vs. Satisfaction

### Scenario
Determine if using advanced features correlates with higher satisfaction.

### Implementation
```sql
WITH feature_usage AS (
  SELECT
    s.customer_id,
    s.satisfaction_score,
    COUNT(DISTINCT f.feature_id) AS num_features_used,
    SUM(CASE WHEN f.feature_flag = 'Premium' THEN 1 ELSE 0 END) AS premium_features_used
  FROM satisfaction_surveys s
  LEFT JOIN customer_feature_usage f ON s.customer_id = f.customer_id
    AND f.month = EXTRACT(MONTH FROM s.survey_date)
    AND f.year = EXTRACT(YEAR FROM s.survey_date)
  WHERE s.satisfaction_score IS NOT NULL
    AND s.survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
  GROUP BY s.customer_id, s.satisfaction_score
)
SELECT
  num_features_used,
  COUNT(*) AS customers,
  ROUND(AVG(satisfaction_score), 2) AS avg_csat,
  ROUND(AVG(premium_features_used), 2) AS avg_premium_features
FROM feature_usage
GROUP BY num_features_used
ORDER BY num_features_used;
```

## Support Engagement vs. Satisfaction

### Scenario
Analyze how support interactions correlate with customer satisfaction.

### Implementation
```sql
WITH support_metrics AS (
  SELECT
    s.customer_id,
    s.satisfaction_score,
    COUNT(sup.ticket_id) AS support_tickets,
    ROUND(AVG(CASE WHEN sup.resolution_time_days IS NOT NULL THEN sup.resolution_time_days ELSE NULL END), 1) AS avg_resolution_days,
    COUNT(CASE WHEN sup.satisfaction_rating >= 4 THEN 1 END) AS positive_support_ratings
  FROM satisfaction_surveys s
  LEFT JOIN support_tickets sup ON s.customer_id = sup.customer_id
    AND sup.created_date >= ADD_MONTHS(s.survey_date, -3)
    AND sup.created_date <= s.survey_date
  WHERE s.satisfaction_score IS NOT NULL
    AND s.survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
  GROUP BY s.customer_id, s.satisfaction_score
)
SELECT
  CASE
    WHEN support_tickets = 0 THEN 'No Tickets'
    WHEN support_tickets BETWEEN 1 AND 2 THEN '1-2 Tickets'
    WHEN support_tickets BETWEEN 3 AND 5 THEN '3-5 Tickets'
    ELSE '6+ Tickets'
  END AS support_tier,
  COUNT(*) AS customers,
  ROUND(AVG(satisfaction_score), 2) AS avg_csat,
  ROUND(AVG(avg_resolution_days), 1) AS avg_resolution_days
FROM support_metrics
GROUP BY support_tier
ORDER BY customers DESC;
```

## Regression: Multi-Factor Driver Model

### Scenario
Build a simple linear regression to explain satisfaction based on multiple factors.

### Implementation (Simplified OLS)
```sql
WITH regression_data AS (
  SELECT
    s.satisfaction_score AS y,
    EXTRACT(YEAR FROM AGE(TODAY(), c.customer_since)) AS x1_tenure,
    c.annual_spend AS x2_spend,
    COUNT(sup.ticket_id) AS x3_support_tickets
  FROM satisfaction_surveys s
  JOIN customers c ON s.customer_id = c.customer_id
  LEFT JOIN support_tickets sup ON s.customer_id = sup.customer_id
    AND sup.created_date >= ADD_MONTHS(s.survey_date, -12)
  WHERE s.satisfaction_score IS NOT NULL
    AND s.survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
  GROUP BY s.customer_id, s.satisfaction_score, c.customer_since, c.annual_spend
),
stats AS (
  SELECT
    COUNT(*) AS n,
    AVG(y) AS mean_y,
    AVG(x1_tenure) AS mean_x1,
    AVG(x2_spend) AS mean_x2,
    AVG(x3_support_tickets) AS mean_x3,
    STDDEV_SAMP(y) AS std_y,
    STDDEV_SAMP(x1_tenure) AS std_x1
  FROM regression_data
)
SELECT
  'Tenure' AS factor,
  'years' AS unit,
  ROUND(
    (
      SUM(rd.x1_tenure * rd.y) - s.n * s.mean_x1 * s.mean_y
    ) / (
      SUM(POWER(rd.x1_tenure, 2)) - s.n * POWER(s.mean_x1, 2)
    ),
    4
  ) AS coefficient,
  ROUND(
    (
      SUM(rd.x1_tenure * rd.y) - s.n * s.mean_x1 * s.mean_y
    ) / (s.n * s.std_x1 * s.std_y),
    3
  ) AS correlation
FROM regression_data rd, stats s
GROUP BY s.n, s.mean_y, s.mean_x1, s.std_y, s.std_x1;
```

## Text Sentiment: Extract Satisfaction Themes

### Scenario
Identify common keywords or themes in customer feedback tied to satisfaction.

### Implementation (Simple Keyword Extraction)
```sql
SELECT
  CASE
    WHEN LOWER(feedback_text) LIKE '%easy%' OR LOWER(feedback_text) LIKE '%simple%' THEN 'Ease of Use'
    WHEN LOWER(feedback_text) LIKE '%support%' OR LOWER(feedback_text) LIKE '%help%' THEN 'Customer Support'
    WHEN LOWER(feedback_text) LIKE '%price%' OR LOWER(feedback_text) LIKE '%cost%' THEN 'Pricing'
    WHEN LOWER(feedback_text) LIKE '%reliable%' OR LOWER(feedback_text) LIKE '%stable%' THEN 'Reliability'
    ELSE 'Other'
  END AS theme,
  COUNT(*) AS mentions,
  ROUND(AVG(satisfaction_score), 2) AS avg_csat_for_theme
FROM satisfaction_surveys
WHERE satisfaction_score IS NOT NULL
  AND feedback_text IS NOT NULL
  AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12)
GROUP BY theme
ORDER BY mentions DESC;
```
