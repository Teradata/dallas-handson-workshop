# Table Discovery Guide for CSAT Analysis

This reference details how to locate, inspect, and validate customer satisfaction data tables in Teradata before running analysis.

## Step 1: Search for Candidate Tables

Use the Teradata schema discovery tools to find tables whose names or column names suggest customer satisfaction data.

### By table name
```sql
-- Search for tables with satisfaction-related names
-- Use base_searchTables via teradata_tool_call with keywords:
--   csat, satisfaction, survey, feedback, nps, rating
```

### By column name
If table-name search returns too many results, narrow by column name:
```sql
-- Use base_searchColumns via teradata_tool_call with keywords:
--   satisfaction_score, csat_score, nps_score, rating, feedback
```

## Step 2: Inspect Table Structure

Once a candidate table is identified, retrieve its DDL and column definitions:

```sql
-- Get column names, types, and nullability
SELECT ColumnName, ColumnType, Nullable, ColumnLength
FROM DBC.ColumnsV
WHERE DatabaseName = '<db>'
  AND TableName = '<table>'
ORDER BY ColumnId;
```

Look for:
- **Score column**: A numeric column (INTEGER or DECIMAL) with constrained values (1–5, 1–10, 0–100).
- **Date/time column**: DATE or TIMESTAMP indicating when the survey was completed.
- **Segment columns**: VARCHAR columns for product, region, channel, customer type.
- **Verbatim/text column**: VARCHAR or CLOB containing free-text feedback.
- **Customer identifier**: A key column linking to customer master data.

## Step 3: Validate Data Quality

Run these checks before analysis to avoid misleading results:

### Row count
```sql
SELECT COUNT(*) AS total_responses FROM <db>.<table>;
```
Flag if < 30 rows — the sample is too small for reliable segmentation.

### Null rates on key columns
```sql
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN satisfaction_score IS NULL THEN 1 ELSE 0 END) AS score_nulls,
    SUM(CASE WHEN survey_date IS NULL THEN 1 ELSE 0 END) AS date_nulls
FROM <db>.<table>;
```
Report columns with > 50 % nulls as a limitation.

### Score range validation
```sql
SELECT
    MIN(satisfaction_score) AS min_score,
    MAX(satisfaction_score) AS max_score,
    COUNT(DISTINCT satisfaction_score) AS distinct_values
FROM <db>.<table>;
```
If min and max suggest mixed scales (e.g., min=1, max=10 but most values are 1–5), investigate further before aggregating.

### Duplicate check
```sql
SELECT customer_id, survey_date, COUNT(*) AS cnt
FROM <db>.<table>
GROUP BY customer_id, survey_date
HAVING cnt > 1;
```
Duplicates inflate segment counts — decide with the user whether to deduplicate.

## Decision Checklist

Before proceeding to analysis, confirm:
- [ ] Target table identified and confirmed with user.
- [ ] Score column identified; scale understood (1–5, 1–10, 0–100).
- [ ] Row count is sufficient (≥ 30).
- [ ] Null rates on critical columns are acceptable (< 50 %).
- [ ] No unexpected duplicate responses.
- [ ] Available segmentation dimensions catalogued.
