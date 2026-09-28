---
name: csat-analysis-vidhan
title: Customer Satisfaction (CSAT) Analysis
description: 'Analyze customer satisfaction survey data stored in Teradata to identify the main drivers of customer satisfaction and dissatisfaction. Use when a user asks to analyze CSAT scores, find reasons customers are happy or unhappy, explore satisfaction trends, or diagnose drivers of low NPS or CSAT ratings. Performs read-only queries against survey and feedback tables.'
domain: analytics
metadata:
  author: Vidhan Bhonsle
  version: 1.0.0
trigger:
  mode: MANUAL
  slash_commands: ['/csat-analysis-vidhan']
  keywords:
    - 'customer satisfaction analysis'
    - 'CSAT analysis'
    - 'why are customers dissatisfied'
    - 'satisfaction drivers'
    - 'customer feedback analysis'
    - 'NPS drivers'
  intent_categories:
    - 'customer-analytics'
    - 'satisfaction-analysis'
  min_confidence: 0.70
prompt:
  constraints:
    - 'NEVER execute INSERT, UPDATE, DELETE, DROP, CREATE, ALTER, or any DDL/DML that modifies data. Use only SELECT statements.'
    - 'Always confirm the target database and table with the user before running analysis queries.'
    - 'Do not fabricate data — only report findings that the queries actually return.'
    - 'When row counts are large, use aggregations and sampling rather than selecting all rows.'
    - 'Clearly state limitations of the analysis (sample size, missing data, correlation vs causation).'
  output_format: |
    Return a structured report with three sections:
    1. **Summary of Findings** — Key drivers of satisfaction and dissatisfaction, ranked by impact or frequency.
    2. **Supporting Evidence** — The SQL queries executed, result counts, and representative data points that back each finding.
    3. **Limitations** — Sample size caveats, columns with high null rates, potential biases, and any assumptions made.
tools:
  required_tools:
    - teradata_tool_call
    - teradata_list_patterns
  preferred_order:
    - teradata_tool_call
---

# Customer Satisfaction (CSAT) Analysis

## When to Use
- User asks to analyze customer satisfaction or CSAT data in Teradata.
- User wants to find the main reasons customers are satisfied or dissatisfied.
- User asks about satisfaction trends, NPS drivers, or feedback patterns.
- User has survey or feedback data in Teradata and wants actionable insights.
- Do NOT use for building ML models on CSAT data — use `td-train-eval-model-indb` instead.
- Do NOT use for data profiling only (column stats, nulls, distributions without a CSAT context) — use `td-data-profile` instead.

## Core Concepts

| Term | Definition |
|------|------------|
| CSAT Score | A numeric rating (typically 1–5 or 1–10) capturing overall customer satisfaction. |
| NPS | Net Promoter Score — derived from "likelihood to recommend" responses (Promoters 9–10, Passives 7–8, Detractors 0–6). |
| Driver | A factor (product quality, support response time, price, etc.) that correlates with high or low satisfaction. |
| Verbatim | Free-text feedback from customers, often paired with a numeric score. |
| Segment | A customer grouping (by region, product, tenure, channel) used to slice satisfaction results. |

## Procedure: Discover and Validate CSAT Data

1. **Ask the user** for the database and table (or tables) that hold customer satisfaction data. If not provided, use schema discovery tools to search for likely candidates.
   ```
   teradata_tool_call → base_searchTables with keyword "csat" or "satisfaction" or "survey" or "feedback"
   ```
2. **Inspect the table structure** to identify the satisfaction score column, any categorical driver columns, date/time columns, and customer segment columns. See [Table Discovery Guide](./references/table-discovery-guide.md) for detailed steps.
3. **Validate data quality** — check row counts, null rates on key columns, and score distributions. Flag tables with fewer than 30 responses or columns with >50 % nulls because these weaken the analysis.

## Procedure: Analyze Satisfaction Drivers

1. **Compute overall satisfaction distribution** — count and percentage of responses by score value. This establishes the baseline.
2. **Segment analysis** — break satisfaction scores by available dimensions (product, region, channel, customer tenure). Identify segments with statistically meaningful differences from the overall average.
3. **Driver ranking** — for each categorical factor, compute the average satisfaction score and response count. Rank factors by their gap from the overall mean to surface the strongest positive and negative drivers. See [Driver Analysis Queries](./references/driver-analysis-queries.md) for SQL templates.
4. **Trend analysis** (if date column exists) — compute monthly or quarterly average satisfaction scores to detect improving or declining trends.
5. **Compile the report** using the output format specified in the frontmatter: Summary of Findings → Supporting Evidence → Limitations.

## Procedure: Deep-Dive on Dissatisfaction

1. **Isolate low-score responses** — filter to scores in the bottom 25th percentile (or ≤ 2 on a 1–5 scale, ≤ 6 on a 1–10 scale).
2. **Cross-tabulate** low scores against every available dimension to find which segments concentrate the most dissatisfaction.
3. **If verbatim/text feedback exists**, sample representative comments from the lowest-scoring responses and surface common themes.
4. **Report the top 3–5 dissatisfaction drivers** with counts, percentages, and example evidence.

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| No CSAT table found | User didn't specify a table and search returned nothing | Ask the user for the exact database.table name |
| Score column has mixed scales | Some rows 1–5, others 1–10 | Detect distinct value ranges and normalize or analyze each scale separately |
| Too few responses in a segment | Segment has < 30 rows | Merge small segments or caveat the finding as low-confidence |
| High null rate on driver column | Data collection gap | Report the null rate and exclude nulls from that driver's analysis |

## References
- [Table Discovery Guide](./references/table-discovery-guide.md) — How to locate and validate CSAT tables in Teradata.
- [Driver Analysis Queries](./references/driver-analysis-queries.md) — Reusable SQL templates for satisfaction driver ranking and segmentation.
