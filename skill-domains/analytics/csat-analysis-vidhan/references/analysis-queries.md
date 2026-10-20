# CSAT Analysis Query Templates

Reusable SQL patterns for customer satisfaction analysis. Adapt table and
column names to the actual schema discovered in Phase 1.

---

## 1. Overall CSAT Distribution

Compute the distribution of satisfaction scores to understand the overall
landscape before drilling into segments.

```sql
-- Satisfaction score distribution with descriptive statistics
SELECT
    satisfaction_score,
    COUNT(*)                          AS response_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS pct_of_total
FROM clv_survey_response
GROUP BY satisfaction_score
ORDER BY satisfaction_score;
```

```sql
-- Descriptive statistics for satisfaction scores
SELECT
    COUNT(*)          AS total_responses,
    AVG(satisfaction_score * 1.0)  AS mean_score,
    MEDIAN(satisfaction_score)     AS median_score,
    STDDEV_POP(satisfaction_score) AS stddev_score,
    MIN(satisfaction_score)        AS min_score,
    MAX(satisfaction_score)        AS max_score
FROM clv_survey_response;
```

## 2. Satisfaction by Demographic Segment

Break down CSAT by customer attributes to identify which groups are
most and least satisfied.

```sql
-- Average satisfaction by age group
SELECT
    CASE
        WHEN c.age < 25  THEN '18-24'
        WHEN c.age < 35  THEN '25-34'
        WHEN c.age < 45  THEN '35-44'
        WHEN c.age < 55  THEN '45-54'
        WHEN c.age < 65  THEN '55-64'
        ELSE '65+'
    END                        AS age_group,
    COUNT(*)                   AS responses,
    AVG(s.satisfaction_score * 1.0)  AS avg_satisfaction
FROM clv_survey_response s
JOIN clv_dim_customer c ON s.customer_id = c.customer_id
GROUP BY age_group
HAVING COUNT(*) >= 30   -- exclude tiny groups
ORDER BY avg_satisfaction DESC;
```

```sql
-- Average satisfaction by region
SELECT
    c.region,
    COUNT(*)                   AS responses,
    AVG(s.satisfaction_score * 1.0)  AS avg_satisfaction
FROM clv_survey_response s
JOIN clv_dim_customer c ON s.customer_id = c.customer_id
GROUP BY c.region
ORDER BY avg_satisfaction DESC;
```

## 3. Complaint Category Impact on Satisfaction

Identify which complaint types are most damaging to satisfaction.

```sql
-- Average satisfaction score by complaint category
SELECT
    cmp.complaint_category,
    COUNT(DISTINCT cmp.customer_id) AS affected_customers,
    AVG(s.satisfaction_score * 1.0)      AS avg_satisfaction,
    COUNT(cmp.complaint_id)         AS complaint_count
FROM clv_complaint cmp
JOIN clv_survey_response s ON cmp.customer_id = s.customer_id
GROUP BY cmp.complaint_category
ORDER BY avg_satisfaction ASC;
```

## 4. High vs Low Satisfaction Cohort Comparison

Compare behavioral features between satisfied and dissatisfied customers
to surface drivers.

```sql
-- Feature comparison: satisfied (score >= 4) vs dissatisfied (score <= 2)
SELECT
    CASE
        WHEN s.satisfaction_score >= 4 THEN 'Satisfied'
        WHEN s.satisfaction_score <= 2 THEN 'Dissatisfied'
    END                                  AS cohort,
    COUNT(*)                             AS customer_count,
    AVG(f.tenure_months * 1.0)           AS avg_tenure,
    AVG(f.total_transactions * 1.0)      AS avg_transactions,
    AVG(f.total_complaints * 1.0)        AS avg_complaints,
    AVG(f.interaction_count * 1.0)       AS avg_interactions
FROM clv_survey_response s
JOIN clv_feature_customer f ON s.customer_id = f.customer_id
WHERE s.satisfaction_score >= 4 OR s.satisfaction_score <= 2
GROUP BY cohort;
```

## 5. Dissatisfaction Theme Ranking

Rank the most common reasons for low satisfaction by frequency and
score impact.

```sql
-- Top dissatisfaction themes (among low-score respondents)
SELECT
    cmp.complaint_category        AS dissatisfaction_theme,
    COUNT(*)                      AS occurrence_count,
    AVG(s.satisfaction_score * 1.0)    AS avg_score_when_present,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS pct_of_complaints
FROM clv_complaint cmp
JOIN clv_survey_response s ON cmp.customer_id = s.customer_id
WHERE s.satisfaction_score <= 2
GROUP BY cmp.complaint_category
ORDER BY occurrence_count DESC;
```

## 6. Satisfaction Trend Over Time

Track how satisfaction evolves — useful for detecting the impact of
service changes or campaigns.

```sql
-- Monthly average satisfaction trend
SELECT
    EXTRACT(YEAR FROM s.survey_date)  AS survey_year,
    EXTRACT(MONTH FROM s.survey_date) AS survey_month,
    COUNT(*)                          AS responses,
    AVG(s.satisfaction_score * 1.0)        AS avg_satisfaction
FROM clv_survey_response s
GROUP BY survey_year, survey_month
ORDER BY survey_year, survey_month;
```

## 7. Correlation with Attrition Risk

Cross-reference satisfaction with attrition scores to validate that
low CSAT predicts churn.

```sql
-- Average attrition score by satisfaction level
SELECT
    s.satisfaction_score,
    COUNT(*)                         AS customers,
    AVG(a.attrition_score * 1.0)     AS avg_attrition_risk
FROM clv_survey_response s
JOIN clv_score_attrition_v2 a ON s.customer_id = a.customer_id
GROUP BY s.satisfaction_score
ORDER BY s.satisfaction_score;
```

---

> **Note:** All queries are read-only SELECT statements. Adapt column and
> table names based on what `base_getTableColumns` discovers in Phase 1.
> Always include a `HAVING COUNT(*) >= 30` or equivalent filter when
> drawing conclusions from segments to avoid small-sample bias.
