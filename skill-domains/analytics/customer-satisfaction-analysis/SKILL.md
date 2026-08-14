---
name: customer-satisfaction-analysis
title: Customer Satisfaction Analysis
description: 'Analyze customer satisfaction metrics, trends, and drivers using Teradata data. Calculates NPS, CSAT scores, sentiment analysis, satisfaction trends over time, and segment-level insights. Use when analyzing customer feedback, satisfaction surveys, NPS trends, CSAT drivers, churn risk, or loyalty patterns.'
domain: analytics
metadata:
  author: demouser4@workshop-keycloak.com
  version: 1.0.0
trigger:
  mode: AUTO
  slash_commands: ['/csat-analysis']
  keywords:
    - 'customer satisfaction'
    - 'CSAT'
    - 'NPS'
    - 'customer feedback'
    - 'satisfaction score'
    - 'satisfaction trend'
    - 'customer sentiment'
    - 'satisfaction by segment'
    - 'satisfaction drivers'
    - 'customer loyalty'
    - 'customer churn risk'
    - 'satisfaction analysis'
  intent_categories:
    - 'customer_analytics'
    - 'satisfaction_metrics'
    - 'trend_analysis'
  min_confidence: 0.72
prompt:
  constraints:
    - 'Always validate that customer satisfaction tables exist before querying; use schema discovery to locate the correct table names.'
    - 'Calculate CSAT as average satisfaction score (1-5 or 1-10 scale); interpret automatically based on data range.'
    - 'Calculate NPS as (% Promoters − % Detractors) × 100, where Promoters ≥ 9, Detractors ≤ 6 on a 0-10 scale.'
    - 'Always filter for data quality: exclude NULL satisfaction scores and records with missing customer IDs.'
    - 'Segment analysis must include temporal breakdown (e.g., month-over-month) to show trends, not just snapshots.'
    - 'Include confidence intervals or statistical significance testing when comparing segments or time periods.'
  output_format: |
    Deliver satisfaction analysis as a structured report with:
    1. **Overall Metrics**: CSAT score, NPS, response rate, sample size, date range
    2. **Trends**: Time-series visualization of satisfaction over the period (month/quarter/year)
    3. **Segment Breakdown**: Satisfaction by customer segment, product, region, or cohort
    4. **Drivers & Correlations**: Top factors influencing satisfaction (from feedback or behavioral data)
    5. **Risk & Opportunity**: Identify at-risk segments (declining satisfaction) and high-value improvements
    6. **Recommendations**: Actionable insights for improvement
    Include SQL queries used and data quality notes (e.g., missing responses, outliers excluded).
---

# Customer Satisfaction Analysis

## When to Use
- You need to calculate or analyze **CSAT**, **NPS**, or **satisfaction scores** from customer survey data
- You want to understand **satisfaction trends** over time (month-over-month, quarter-over-quarter)
- You need to identify **satisfaction drivers**: which products, features, or service aspects correlate most with high/low satisfaction
- You want to **segment satisfaction** by customer type, region, product line, or tenure
- You are investigating **churn risk** or **loyalty** correlated with satisfaction levels
- You need to **benchmark** satisfaction against internal targets or peer averages
- You want to detect **declining segments** or early warning signals

**Do NOT use for**: General customer behavior analysis (use `customer-behavior-analysis`), customer value prediction without satisfaction context, or pure transaction analytics. For text sentiment analysis of unstructured feedback, consider `teradata-text-analytics` as a supplement.

## Core Concepts

### Satisfaction Metrics
| Metric | Definition | Calculation | Interpretation |
|--------|-----------|-------------|----------------|
| **CSAT** | Customer Satisfaction Score | Average of satisfaction ratings (typically 1-5 or 1-10) | Higher is better; typically ≥4.0/5.0 is healthy |
| **NPS** | Net Promoter Score | (% Promoters − % Detractors) × 100 | Measures loyalty; ranges −100 to +100; >0 is positive |
| **Response Rate** | % of invited customers who responded | (Responses ÷ Invites) × 100 | ≥30% is typical for surveys |
| **Trend** | Change in CSAT/NPS over time | Period-over-period or year-over-year | Declining trend signals dissatisfaction growth |

### Segmentation Dimensions
- **Product/Service**: CSAT by product line or feature
- **Customer Type**: Satisfaction by tier (Premium, Standard, Free), tenure, or acquisition source
- **Geography**: Regional or country-level satisfaction
- **Cohort**: Satisfaction by purchase date, age, or engagement level

## Procedure: Calculate Overall CSAT & NPS

1. **Identify the satisfaction table.** Use `td-schema-discovery` to locate the survey or feedback table containing satisfaction ratings. Typical columns: `customer_id`, `satisfaction_score`, `survey_date`, `response_text`, `product_id`.
   - Why: Table names vary by org; schema discovery prevents errors.

2. **Validate data quality.** Check for missing values, outliers, and response rate.
   ```sql
   -- Example: check CSAT data quality
   SELECT
     COUNT(*) AS total_responses,
     COUNT(DISTINCT customer_id) AS unique_customers,
     COUNT(CASE WHEN satisfaction_score IS NULL THEN 1 END) AS missing_scores,
     MIN(satisfaction_score) AS min_score,
     MAX(satisfaction_score) AS max_score,
     AVG(satisfaction_score) AS avg_score
   FROM your_satisfaction_table
   WHERE survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12);
   ```

3. **Calculate CSAT.** Compute the mean satisfaction score across all valid responses.
   ```sql
   SELECT
     ROUND(AVG(satisfaction_score), 2) AS csat_score,
     STDDEV_POP(satisfaction_score) AS stddev,
     COUNT(*) AS sample_size,
     ROUND(100.0 * COUNT(*) / <total_invited>, 1) AS response_rate_pct
   FROM your_satisfaction_table
   WHERE satisfaction_score IS NOT NULL
     AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12);
   ```

4. **Calculate NPS** (if rating scale is 0–10).
   ```sql
   SELECT
     ROUND(
       100.0 * (
         (COUNT(CASE WHEN satisfaction_score >= 9 THEN 1 END) -
          COUNT(CASE WHEN satisfaction_score <= 6 THEN 1 END))
         / CAST(COUNT(*) AS FLOAT)
       ), 1
     ) AS nps,
     COUNT(CASE WHEN satisfaction_score >= 9 THEN 1 END) AS promoters,
     COUNT(CASE WHEN satisfaction_score >= 7 AND satisfaction_score <= 8 THEN 1 END) AS passives,
     COUNT(CASE WHEN satisfaction_score <= 6 THEN 1 END) AS detractors
   FROM your_satisfaction_table
   WHERE satisfaction_score IS NOT NULL
     AND survey_date >= ADD_MONTHS(TRUNC(TODAY()), -12);
   ```

5. **Report overall metrics** with date range, sample size, and confidence interval if applicable. See [calculation-guide](./references/calculation-guide.md) for formulae and edge cases.

## Procedure: Analyze Satisfaction Trends

1. **Aggregate satisfaction by time period.** Group by month, quarter, or year to track changes.
   ```sql
   SELECT
     TRUNC(survey_date, 'MONTH') AS survey_month,
     ROUND(AVG(satisfaction_score), 2) AS monthly_csat,
     COUNT(*) AS responses,
     STDDEV_POP(satisfaction_score) AS stddev
   FROM your_satisfaction_table
   WHERE satisfaction_score IS NOT NULL
   GROUP BY TRUNC(survey_date, 'MONTH')
   ORDER BY survey_month DESC;
   ```

2. **Calculate month-over-month (MoM) change.** Use window functions to compute deltas.
   ```sql
   SELECT
     survey_month,
     monthly_csat,
     LAG(monthly_csat) OVER (ORDER BY survey_month) AS prev_month_csat,
     ROUND(monthly_csat - LAG(monthly_csat) OVER (ORDER BY survey_month), 2) AS mom_change,
     ROUND(
       100.0 * (monthly_csat - LAG(monthly_csat) OVER (ORDER BY survey_month))
       / LAG(monthly_csat) OVER (ORDER BY survey_month), 1
     ) AS mom_pct_change
   FROM (
     SELECT
       TRUNC(survey_date, 'MONTH') AS survey_month,
       ROUND(AVG(satisfaction_score), 2) AS monthly_csat
     FROM your_satisfaction_table
     WHERE satisfaction_score IS NOT NULL
     GROUP BY TRUNC(survey_date, 'MONTH')
   ) t
   ORDER BY survey_month DESC;
   ```

3. **Visualize trends** using a line chart (month on x-axis, CSAT on y-axis). Flag periods with declining satisfaction for investigation.

4. See [trend-analysis](./references/trend-analysis.md) for advanced techniques (e.g., seasonal decomposition, exponential smoothing).

## Procedure: Segment Satisfaction Analysis

1. **Identify segmentation dimensions.** Decide whether to segment by product, customer tier, region, or cohort.

2. **Compute CSAT per segment.**
   ```sql
   SELECT
     product_line,
     ROUND(AVG(satisfaction_score), 2) AS segment_csat,
     COUNT(*) AS responses,
     STDDEV_POP(satisfaction_score) AS stddev
   FROM your_satisfaction_table
   WHERE satisfaction_score IS NOT NULL
   GROUP BY product_line
   ORDER BY segment_csat DESC;
   ```

3. **Compare segments statistically.** Use ANOVA or t-tests to determine if differences are significant. See [statistical-significance](./references/statistical-significance.md).

4. **Identify underperforming segments** (CSAT < organizational target) and high-value segments (high volume + high satisfaction).

## Procedure: Identify Satisfaction Drivers

1. **Correlate satisfaction with behavioral or demographic factors.**
   ```sql
   SELECT
     feature_usage,
     ROUND(AVG(satisfaction_score), 2) AS avg_csat,
     COUNT(*) AS count
   FROM your_satisfaction_table t
   JOIN customer_features f ON t.customer_id = f.customer_id
   WHERE t.satisfaction_score IS NOT NULL
   GROUP BY feature_usage
   ORDER BY avg_csat DESC;
   ```

2. **Extract themes from text feedback** (if available). Use `teradata-text-analytics` for sentiment or keyword extraction.

3. **Build correlation matrix** between satisfaction and attributes (tenure, purchase frequency, support tickets, etc.).

4. See [drivers-analysis](./references/drivers-analysis.md) for advanced correlation and regression techniques.

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| CSAT appears artificially high | Survey bias (only happy customers respond) | Weight results by response rate; perform non-response analysis |
| NPS calculation yields >100 or <−100 | Scale assumption error (e.g., using 1–5 instead of 0–10) | Verify rating scale in source table; adjust formula accordingly |
| Trend shows no change | Aggregation period too short | Increase period granularity (e.g., quarter instead of week) or expand lookback window |
| Segment CSAT differs drastically from overall | Unequal segment sizes | Weight segments by volume or review segment definitions |
| Missing recent months in trend | Data lag in survey pipeline | Confirm ETL schedule; document cutoff date |

## References
- [Calculation Guide](./references/calculation-guide.md) — CSAT, NPS, response rate, and confidence intervals
- [Trend Analysis](./references/trend-analysis.md) — Time-series decomposition, MoM/YoY, smoothing
- [Statistical Significance](./references/statistical-significance.md) — ANOVA, t-tests for segment comparison
- [Drivers Analysis](./references/drivers-analysis.md) — Correlation, regression, and feature importance
- [SQL Templates](./assets/templates/csat-queries.sql) — Copy-paste query patterns
