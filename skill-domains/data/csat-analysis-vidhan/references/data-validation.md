# Data Validation for CSAT Analysis

Run these checks before any satisfaction analysis to ensure data quality and coverage.

## Required Column Identification

Search for a numeric satisfaction column. Common names and patterns:

```sql
-- Find candidate satisfaction columns
SELECT ColumnName, ColumnType, CommentString
FROM DBC.ColumnsV
WHERE DatabaseName = '<db>'
  AND TableName = '<table>'
  AND (ColumnName LIKE '%sat%'
    OR ColumnName LIKE '%score%'
    OR ColumnName LIKE '%rating%'
    OR ColumnName LIKE '%nps%'
    OR ColumnName LIKE '%csat%');
```

## Data Quality Checks

### 1. Volume and Date Range

```sql
SELECT
  COUNT(*) AS total_responses,
  MIN(survey_date) AS earliest,
  MAX(survey_date) AS latest,
  COUNT(DISTINCT survey_date) AS distinct_dates
FROM <db>.<table>;
```

### 2. Null Rate in Key Columns

```sql
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN satisfaction_score IS NULL THEN 1 ELSE 0 END) AS null_scores,
  SUM(CASE WHEN feedback_text IS NULL THEN 1 ELSE 0 END) AS null_feedback,
  CAST(SUM(CASE WHEN satisfaction_score IS NULL THEN 1 ELSE 0 END) AS FLOAT)
    / COUNT(*) * 100 AS pct_null_scores,
  CAST(SUM(CASE WHEN feedback_text IS NULL THEN 1 ELSE 0 END) AS FLOAT)
    / COUNT(*) * 100 AS pct_null_feedback
FROM <db>.<table>;
```

### 3. Score Range Validation

Confirm the rating scale — reject rows outside the expected range:

```sql
SELECT
  MIN(satisfaction_score) AS min_score,
  MAX(satisfaction_score) AS max_score,
  COUNT(DISTINCT satisfaction_score) AS distinct_values
FROM <db>.<table>
WHERE satisfaction_score IS NOT NULL;
```

If `min_score` < 1 or `max_score` > expected maximum (5 or 10), flag as data quality issue.

### 4. Dimensional Coverage

For each segmentation dimension, check cardinality and null rate:

```sql
SELECT
  '<dimension_col>' AS dimension,
  COUNT(DISTINCT <dimension_col>) AS distinct_values,
  SUM(CASE WHEN <dimension_col> IS NULL THEN 1 ELSE 0 END) AS null_count
FROM <db>.<table>;
```

## Minimum Thresholds

| Check | Minimum | Action if below |
|-------|---------|------------------|
| Total responses | 100 | Warn user — results may not be statistically meaningful |
| Null rate on score | < 10% | Proceed; note the gap |
| Null rate on score | ≥ 10% | Investigate cause; exclude nulls explicitly |
| Feedback text coverage | ≥ 30% non-null | Proceed with text analysis |
| Feedback text coverage | < 30% non-null | Skip text analysis; note in report |
| Segment size | ≥ 30 per group | Include in breakdown |
| Segment size | < 30 per group | Merge with adjacent group or flag as unreliable |
