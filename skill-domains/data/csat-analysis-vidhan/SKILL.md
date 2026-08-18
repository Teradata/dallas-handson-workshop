---
name: csat-analysis-vidhan
title: Customer Satisfaction Analysis
description: 'Analyze customer satisfaction (CSAT) data in Teradata to identify main drivers of satisfaction and dissatisfaction. Use when a user asks to analyze CSAT scores, find reasons for low satisfaction, understand what makes customers happy or unhappy, segment satisfaction by product/channel/demographic, extract themes from customer feedback, or produce a satisfaction driver report.'
domain: data
metadata:
  author: Vidhan Bhonsle
  version: 1.0.0
trigger:
  mode: HYBRID
  slash_commands: ['/csat-analysis']
  keywords:
    - 'analyze customer satisfaction'
    - 'CSAT analysis'
    - 'reasons for dissatisfaction'
    - 'why are customers unhappy'
    - 'satisfaction drivers'
    - 'customer feedback analysis'
    - 'NPS drivers'
    - 'what makes customers satisfied'
    - 'low satisfaction reasons'
    - 'customer sentiment analysis'
  intent_categories:
    - 'customer analytics'
    - 'satisfaction analysis'
    - 'feedback analysis'
  min_confidence: 0.70
prompt:
  constraints:
    - Never fabricate satisfaction scores or feedback text — only report what the data contains.
    - Always validate that the target table has a satisfaction/rating column before proceeding.
    - When free-text comments exist, apply text analytics to extract themes — do not skip qualitative analysis.
    - Present both satisfaction AND dissatisfaction drivers — never report only one side.
    - Include sample sizes with every segment breakdown so the user can judge statistical relevance.
  output_format: |
    Structured report with:
    1. Overall satisfaction distribution (scores, percentages, visual-ready summary)
    2. Top drivers of SATISFACTION (with evidence)
    3. Top drivers of DISSATISFACTION (with evidence)
    4. Segment breakdowns (by available dimensions)
    5. Key themes from free-text feedback (if available)
    6. Actionable recommendations
---

# Customer Satisfaction Analysis

## When to Use
- User asks to analyze customer satisfaction, CSAT, or NPS data
- User wants to understand why customers are satisfied or dissatisfied
- User asks for drivers of satisfaction/dissatisfaction
- User wants to segment satisfaction by product, channel, region, or demographic
- User asks to extract themes or sentiment from customer feedback comments
- Do NOT use for general text analytics unrelated to satisfaction — use `teradata-text-analytics` instead
- Do NOT use for building ML models to predict churn — use `td-train-eval-model-indb` instead

## Core Concepts

| Term | Definition |
|------|------------|
| CSAT Score | Customer Satisfaction score, typically 1–5 or 1–10 scale |
| NPS | Net Promoter Score — Promoters (9–10) minus Detractors (0–6) as % |
| Driver | A factor (product, service, feature, issue) that correlates with high or low satisfaction |
| Verbatim | Free-text customer comment explaining their rating |
| Segment | A grouping dimension (product line, channel, region, customer tier) |

## Procedure: Discover and Validate the Data

1. **Identify the satisfaction table.** Ask the user which table contains their CSAT data, or search the schema for tables with satisfaction-related columns (rating, score, csat, nps, satisfaction, feedback).
2. **Profile the table structure.** Confirm the presence of:
   - A numeric satisfaction/rating column (the dependent variable)
   - Optional free-text feedback/comment column (for qualitative analysis)
   - Dimensional columns for segmentation (product, channel, region, date, customer_tier)
3. **Check data volume and freshness.** Report row count, date range, and any null rates in key columns so the user understands coverage. See [data-validation reference](./references/data-validation.md) for checks.

## Procedure: Quantitative Satisfaction Analysis

1. **Overall distribution.** Compute the frequency and percentage for each satisfaction score value. Calculate mean, median, and standard deviation.
2. **Trend analysis.** If a date column exists, compute satisfaction scores over time (monthly/quarterly) to identify improving or declining trends.
3. **Segment breakdowns.** For each available dimension (product, channel, region, customer_tier), compute:
   - Mean satisfaction per segment
   - Count per segment (to assess statistical relevance)
   - Identify segments with scores significantly above or below the overall mean
4. **Driver identification via statistical contrast.** Compare the dimensional profile of high-satisfaction respondents (top quartile) vs. low-satisfaction respondents (bottom quartile). Dimensions with the largest gaps are candidate drivers. See [statistical-methods reference](./references/statistical-methods.md).

## Procedure: Qualitative Feedback Analysis

1. **Prerequisite:** Confirm a free-text column exists. If not, skip this section and note it in the report.
2. **Tokenize and extract n-grams.** Use TD_TextParser and TD_NGramSplitter to identify frequent terms and phrases in feedback, split by satisfaction tier (high vs. low).
3. **Sentiment extraction.** Apply TD_SentimentExtractor to score each comment, then cross-reference with the numeric rating for consistency.
4. **Theme identification.** Compare top n-grams in satisfied vs. dissatisfied groups to surface recurring themes (e.g., "fast delivery" in high-CSAT, "long wait time" in low-CSAT). See [text-analysis reference](./references/text-analysis.md).

## Procedure: Synthesize and Report

1. **Compile the driver summary.** Rank satisfaction drivers (positive and negative) by impact magnitude and frequency.
2. **Generate the structured report** per the output format: distribution → drivers → segments → themes → recommendations.
3. **Provide actionable recommendations.** Based on the top dissatisfaction drivers, suggest concrete areas for improvement with supporting data.

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| No satisfaction column found | Table lacks a numeric rating field | Ask user to identify the correct column or table |
| Skewed distribution (e.g., 90% score 5) | Common in opt-in surveys | Note the skew, focus analysis on the minority low-scorers |
| Too few responses per segment | Small sample sizes in breakdowns | Flag segments with n < 30 as unreliable; merge small segments |
| Text analytics returns empty | Comments column is NULL or empty for most rows | Report coverage rate; fall back to quantitative-only analysis |

## References
- [Data Validation](./references/data-validation.md) — Pre-analysis checks and data quality gates
- [Statistical Methods](./references/statistical-methods.md) — Quantitative driver identification techniques
- [Text Analysis](./references/text-analysis.md) — Teradata text analytics functions for feedback mining
