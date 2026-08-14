-- IQR-Based Anomaly Detection Query for Teradata
-- Use this template to detect outliers using the Interquartile Range method.
-- Replace <table>, <column>, <date_column> (optional) with your values.

-- Step 1: Compute quartiles and IQR
WITH stats AS (
  SELECT
    COUNT(*) as total_count,
    MIN(<column>) as min_val,
    MAX(<column>) as max_val,
    AVG(<column>) as mean_val,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY <column>) as q1,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY <column>) as q2_median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY <column>) as q3
  FROM <table>
  WHERE <column> IS NOT NULL
)
-- Step 2: Identify anomalies
SELECT
  source.*,
  ROUND((source.<column> - stats.q2_median) / NULLIF(ABS(stats.q3 - stats.q1), 0), 2) as deviation_ratio,
  CASE
    WHEN source.<column> < stats.q1 - 1.5 * (stats.q3 - stats.q1) THEN 'LOW_OUTLIER'
    WHEN source.<column> > stats.q3 + 1.5 * (stats.q3 - stats.q1) THEN 'HIGH_OUTLIER'
  END as anomaly_type
FROM <table> source
CROSS JOIN stats
WHERE source.<column> IS NOT NULL
  AND (
    source.<column> < stats.q1 - 1.5 * (stats.q3 - stats.q1)
    OR source.<column> > stats.q3 + 1.5 * (stats.q3 - stats.q1)
  )
ORDER BY ABS(source.<column> - stats.q2_median) DESC
LIMIT 20;

-- Optional: Filter by date range for recent anomalies
-- Add this WHERE clause if you have a <date_column>:
-- AND <date_column> >= CURRENT_DATE - INTERVAL '30' DAY
