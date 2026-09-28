# Driver Analysis Queries for CSAT

Reusable SQL templates for ranking satisfaction drivers and segmenting results. Replace `<db>`, `<table>`, `<score_col>`, and dimension column names with actual values discovered during the table validation step.

## 1. Overall Satisfaction Distribution

Establishes the baseline — how responses spread across score values.

```sql
SELECT
    <score_col>,
    COUNT(*) AS response_count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct
FROM <db>.<table>
GROUP BY <score_col>
ORDER BY <score_col>;
```

**Interpretation**: A left-skewed distribution (most scores high) is typical for voluntary surveys. A bimodal pattern (peaks at low and high ends) may indicate two distinct customer populations.

## 2. Average Satisfaction by Segment

Compute mean score per dimension and compare to the overall average.

```sql
SELECT
    <segment_col> AS segment,
    COUNT(*) AS n,
    CAST(AVG(<score_col>) AS DECIMAL(5,2)) AS avg_score,
    CAST(AVG(<score_col>) - (
        SELECT AVG(<score_col>) FROM <db>.<table>
    ) AS DECIMAL(5,2)) AS gap_from_overall
FROM <db>.<table>
WHERE <score_col> IS NOT NULL
GROUP BY <segment_col>
HAVING n >= 30
ORDER BY gap_from_overall ASC;
```

**Interpretation**: Segments with the largest negative gap are the primary dissatisfaction drivers. Segments with fewer than 30 responses are excluded (low confidence).

## 3. Top Positive and Negative Drivers

Rank all segments across all dimensions in one view.

```sql
WITH overall AS (
    SELECT CAST(AVG(<score_col>) AS DECIMAL(5,2)) AS overall_avg
    FROM <db>.<table>
    WHERE <score_col> IS NOT NULL
),
by_dimension AS (
    SELECT
        '<dim1_name>' AS dimension,
        <dim1_col> AS value,
        COUNT(*) AS n,
        CAST(AVG(<score_col>) AS DECIMAL(5,2)) AS avg_score
    FROM <db>.<table>
    WHERE <score_col> IS NOT NULL
    GROUP BY <dim1_col>
    HAVING n >= 30

    UNION ALL

    SELECT
        '<dim2_name>' AS dimension,
        <dim2_col> AS value,
        COUNT(*) AS n,
        CAST(AVG(<score_col>) AS DECIMAL(5,2)) AS avg_score
    FROM <db>.<table>
    WHERE <score_col> IS NOT NULL
    GROUP BY <dim2_col>
    HAVING n >= 30
    -- Add more UNION ALL blocks for additional dimensions
)
SELECT
    d.dimension,
    d.value,
    d.n,
    d.avg_score,
    d.avg_score - o.overall_avg AS gap
FROM by_dimension d
CROSS JOIN overall o
ORDER BY gap ASC;
```

**Interpretation**: The top rows (most negative gap) are the strongest dissatisfaction drivers. The bottom rows (most positive gap) are satisfaction drivers. Present the top 3–5 from each end.

## 4. Monthly Trend Analysis

```sql
SELECT
    EXTRACT(YEAR FROM <date_col>) AS yr,
    EXTRACT(MONTH FROM <date_col>) AS mo,
    COUNT(*) AS n,
    CAST(AVG(<score_col>) AS DECIMAL(5,2)) AS avg_score
FROM <db>.<table>
WHERE <score_col> IS NOT NULL
  AND <date_col> IS NOT NULL
GROUP BY yr, mo
HAVING n >= 10
ORDER BY yr, mo;
```

**Interpretation**: Look for sustained upward or downward trends (3+ consecutive months moving in the same direction). A single-month spike or dip may be noise unless the volume is high.

## 5. Low-Score Deep Dive

Isolate the most dissatisfied respondents and cross-tabulate against dimensions.

```sql
-- Determine the bottom-quartile threshold
SELECT PERCENTILE_CONT(0.25)
    WITHIN GROUP (ORDER BY <score_col>)
    AS p25_score
FROM <db>.<table>
WHERE <score_col> IS NOT NULL;

-- Then filter and cross-tabulate
SELECT
    <segment_col>,
    COUNT(*) AS low_score_count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct_of_low_scores
FROM <db>.<table>
WHERE <score_col> <= <p25_value>   -- substitute the threshold from the previous query
GROUP BY <segment_col>
ORDER BY low_score_count DESC;
```

## 6. Verbatim Sampling (if text feedback exists)

```sql
SELECT TOP 20
    <score_col>,
    <text_col>,
    <segment_col>
FROM <db>.<table>
WHERE <score_col> <= <p25_value>
ORDER BY <score_col> ASC;
```

Surface these as illustrative quotes in the report. Do not claim they are statistically representative — note the sample size.

## Combining Results into the Final Report

After running the queries above, assemble the output as:

1. **Summary of Findings**: State the overall average CSAT score, the top 3–5 positive drivers, and the top 3–5 negative drivers. Include the trend direction if available.
2. **Supporting Evidence**: For each finding, include the query that produced it, the result count, and key numbers (averages, gaps, percentages).
3. **Limitations**: Note the total sample size, any segments excluded due to low n, columns with high null rates, whether the survey was voluntary (self-selection bias), and that correlations do not prove causation.
