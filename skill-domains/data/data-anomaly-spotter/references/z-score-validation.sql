-- Z-Score Validation Query for Teradata
-- Use this to validate anomalies using standard deviation method.
-- Confirms or contradicts IQR-based findings.

WITH stats AS (
  SELECT
    AVG(<column>) as mean_val,
    STDDEV_POP(<column>) as stddev_val,
    COUNT(*) as total_count
  FROM <table>
  WHERE <column> IS NOT NULL
),
scored AS (
  SELECT
    source.*,
    stats.mean_val,
    stats.stddev_val,
    ROUND(ABS(source.<column> - stats.mean_val) / NULLIF(stats.stddev_val, 0), 2) as z_score,
    CASE
      WHEN ABS(source.<column> - stats.mean_val) / NULLIF(stats.stddev_val, 0) > 3 THEN 'EXTREME'
      WHEN ABS(source.<column> - stats.mean_val) / NULLIF(stats.stddev_val, 0) > 2 THEN 'MODERATE'
      ELSE 'NORMAL'
    END as severity
  FROM <table> source
  CROSS JOIN stats
  WHERE source.<column> IS NOT NULL
)
SELECT
  *
FROM scored
WHERE severity IN ('EXTREME', 'MODERATE')
ORDER BY z_score DESC
LIMIT 20;
