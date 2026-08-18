# Statistical Methods for Satisfaction Driver Identification

These techniques identify which factors most strongly associate with high or low satisfaction.

## 1. Distribution Analysis

Compute the full satisfaction distribution:

```sql
SELECT
  satisfaction_score,
  COUNT(*) AS cnt,
  CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER () * 100 AS pct
FROM <db>.<table>
WHERE satisfaction_score IS NOT NULL
GROUP BY satisfaction_score
ORDER BY satisfaction_score;
```

Calculate summary statistics:

```sql
SELECT
  AVG(satisfaction_score) AS mean_score,
  MEDIAN(satisfaction_score) AS median_score,
  STDDEV_POP(satisfaction_score) AS stddev_score,
  COUNT(*) AS n
FROM <db>.<table>
WHERE satisfaction_score IS NOT NULL;
```

## 2. Segment Comparison (Mean Difference)

For each dimension, compute mean satisfaction and compare to the global mean:

```sql
SELECT
  <segment_col> AS segment_value,
  COUNT(*) AS n,
  AVG(satisfaction_score) AS segment_mean,
  AVG(satisfaction_score) - (SELECT AVG(satisfaction_score) FROM <db>.<table>) AS diff_from_global
FROM <db>.<table>
WHERE <segment_col> IS NOT NULL
  AND satisfaction_score IS NOT NULL
GROUP BY <segment_col>
HAVING COUNT(*) >= 30
ORDER BY diff_from_global;
```

Segments with the largest negative `diff_from_global` are dissatisfaction hotspots. Largest positive values are satisfaction strengths.

## 3. Top-vs-Bottom Quartile Contrast

Identify what distinguishes the happiest from the unhappiest customers:

```sql
-- Define quartile boundaries
SELECT
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY satisfaction_score) AS q1,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY satisfaction_score) AS q3
FROM <db>.<table>;
```

Then compare dimensional distributions between top quartile (score ≥ Q3) and bottom quartile (score ≤ Q1):

```sql
SELECT
  <segment_col>,
  SUM(CASE WHEN satisfaction_score >= <q3> THEN 1 ELSE 0 END) AS high_sat_count,
  SUM(CASE WHEN satisfaction_score <= <q1> THEN 1 ELSE 0 END) AS low_sat_count,
  CAST(SUM(CASE WHEN satisfaction_score >= <q3> THEN 1 ELSE 0 END) AS FLOAT)
    / NULLIFZERO(SUM(CASE WHEN satisfaction_score <= <q1> THEN 1 ELSE 0 END)) AS ratio
FROM <db>.<table>
WHERE satisfaction_score IS NOT NULL
GROUP BY <segment_col>
ORDER BY ratio DESC;
```

A high ratio means that segment is over-represented among satisfied customers (positive driver). A low ratio (< 1) means over-represented among dissatisfied (negative driver).

## 4. Trend Analysis

Track satisfaction movement over time:

```sql
SELECT
  TRUNC(survey_date, 'MM') AS month,
  COUNT(*) AS responses,
  AVG(satisfaction_score) AS avg_score,
  AVG(satisfaction_score) - LAG(AVG(satisfaction_score)) OVER (ORDER BY TRUNC(survey_date, 'MM')) AS mom_change
FROM <db>.<table>
WHERE survey_date IS NOT NULL
GROUP BY TRUNC(survey_date, 'MM')
ORDER BY month;
```

## 5. Correlation Screening (Numeric Dimensions)

For numeric attributes (e.g., wait_time, order_value, tenure_months), compute Pearson correlation with satisfaction:

```sql
SELECT
  '<numeric_col>' AS factor,
  (COUNT(*) * SUM(satisfaction_score * <numeric_col>)
    - SUM(satisfaction_score) * SUM(<numeric_col>))
  / (SQRT(COUNT(*) * SUM(satisfaction_score * satisfaction_score)
    - SUM(satisfaction_score) * SUM(satisfaction_score))
  *  SQRT(COUNT(*) * SUM(<numeric_col> * <numeric_col>)
    - SUM(<numeric_col>) * SUM(<numeric_col>))) AS pearson_r
FROM <db>.<table>
WHERE satisfaction_score IS NOT NULL
  AND <numeric_col> IS NOT NULL;
```

Rank factors by absolute value of `pearson_r`. Values > 0.3 indicate meaningful association.
