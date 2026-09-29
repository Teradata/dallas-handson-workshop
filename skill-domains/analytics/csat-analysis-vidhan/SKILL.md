---
name: csat-analysis-vidhan
title: Customer Satisfaction Analysis
description: 'Analyze customer satisfaction data in Teradata to identify the main reasons customers are satisfied or dissatisfied. Profile survey responses, complaint records, and customer features to surface actionable CSAT drivers, segment satisfaction by demographics, and quantify dissatisfaction themes. Triggers on requests to analyze CSAT, survey data, satisfaction drivers, or customer feedback.'
domain: analytics
metadata:
  author: Vidhan Bhonsle
  version: 2.0.0
trigger:
  mode: MANUAL
  slash_commands: ['/csat-analysis-vidhan']
  keywords:
    - customer satisfaction analysis
    - CSAT drivers
    - survey response analysis
    - satisfaction reasons
    - dissatisfaction reasons
    - customer feedback analysis
  intent_categories:
    - customer-analytics
    - satisfaction-analysis
  min_confidence: 0.75
prompt:
  constraints:
    - Use ONLY read-only SQL (SELECT). Never execute INSERT, UPDATE, DELETE, CREATE, DROP, or ALTER.
    - Do not move data out of Teradata — all analysis runs in-database.
    - Always verify table existence and column names before querying.
    - Limit result sets to avoid excessive data transfer — use TOP, SAMPLE, or GROUP BY aggregations.
    - Do not fabricate findings — every claim must be backed by query results.
  output_format: |
    Return a structured report with three sections:
    1. **Summary of Findings** — top satisfaction and dissatisfaction drivers, key metrics.
    2. **Supporting Evidence** — the SQL queries executed and their result summaries.
    3. **Limitations** — data gaps, sample size caveats, and analytical assumptions.
tools:
  required_tools:
    - base_readQuery
    - base_getTableColumns
    - base_findTables
  preferred_order:
    - base_findTables
    - base_getTableColumns
    - base_readQuery
---

# Customer Satisfaction Analysis

## When to Use
- User asks to analyze customer satisfaction, CSAT scores, or survey data.
- User wants to understand why customers are satisfied or dissatisfied.
- User asks to segment satisfaction by customer demographics or behavior.
- User wants to identify complaint themes or feedback patterns.
- Do NOT use for predictive churn modeling — use `td-train-eval-model-indb` instead.
- Do NOT use for general table profiling — use `td-data-profile` instead.

## Core Concepts

| Term | Definition |
|------|------------|
| CSAT Score | Customer Satisfaction score, typically 1–5 or 1–10, from post-interaction surveys |
| NPS | Net Promoter Score — measures likelihood to recommend (promoters vs detractors) |
| Satisfaction Driver | A measurable factor (e.g., complaint count, resolution time) correlated with high CSAT |
| Dissatisfaction Theme | A recurring category of complaint or low-score reason |

### Recommended Starting Tables

These tables form a satisfaction-to-attrition analysis pipeline (all joined on `customer_id`):

| Table | Role |
|-------|------|
| `clv_dim_customer` | Customer demographics and attributes |
| `clv_survey_response` | Raw survey responses with satisfaction scores |
| `clv_feature_customer` | Engineered customer features (tenure, activity metrics) |
| `clv_score_attrition_v2` | Attrition risk scores for correlation analysis |
| `clv_complaint` | Complaint records with categories and resolution status |

Additional useful tables: `CSAT_SRVEY_ANLS`, `clv_feature_complaint`, `clv_fact_transaction`, `clv_fact_interaction`.

## Procedure: Analyze Customer Satisfaction

### Phase 1 — Discovery & Validation
1. **Locate the relevant tables** using `base_findTables` — search for survey, satisfaction, complaint, and customer tables in the target database because the exact table names may vary by environment.
2. **Inspect column metadata** with `base_getTableColumns` on each discovered table to confirm the presence of satisfaction score columns, customer identifiers, and join keys.
3. **Sample a few rows** from each key table (use `SELECT TOP 10`) to understand data formats, value ranges, and null patterns before writing analytical queries.

### Phase 2 — Satisfaction Landscape
4. **Compute the overall CSAT distribution** — aggregate satisfaction scores into buckets and calculate mean, median, and standard deviation. See [analysis-queries.md](./references/analysis-queries.md) for query templates.
5. **Segment satisfaction by demographics** — break down scores by age group, gender, region, or account type to identify which segments are most/least satisfied.
6. **Trend over time** — if a date column exists, compute monthly or quarterly average CSAT to detect improving or declining satisfaction.

### Phase 3 — Driver Identification
7. **Analyze complaint categories** — aggregate complaints by category/type and cross-reference with satisfaction scores to find which complaint types most strongly correlate with low CSAT.
8. **Identify satisfaction drivers** — compare feature values (tenure, transaction frequency, interaction count) between high-satisfaction and low-satisfaction cohorts to surface what differentiates them.
9. **Quantify dissatisfaction themes** — rank the top reasons for low scores by frequency and severity (average score impact).

### Phase 4 — Reporting
10. **Compile the findings** into the three-section output format: Summary, Evidence, and Limitations.
11. **Flag data quality issues** — report any columns with high null rates, skewed distributions, or insufficient sample sizes that limit confidence in the findings.

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Table not found | Wrong database context or table name | Run `base_findTables` first; verify the database |
| No satisfaction score column | Table schema differs from expected | Inspect columns with `base_getTableColumns`; adapt queries |
| Skewed results from small segments | Demographic segment has < 30 records | Note the limitation; avoid drawing conclusions from tiny groups |
| Timeout on large joins | Joining full fact tables without filters | Add date range or SAMPLE filters; aggregate before joining |

## References
- [Analysis Query Templates](./references/analysis-queries.md) — reusable SQL patterns for CSAT distribution, segmentation, and driver analysis.
