---
name: csat-analysis-skill
title: Customer Satisfaction Analysis
description: Analyze customer satisfaction survey data end to end using schema discovery, profiling, statistics, text analytics, and semantic search to identify satisfaction patterns, detractor and promoter topics, and actionable customer experience insights.
domain: analytics
version: 1.0.0
status: active

metadata:
  author: Vidhan Bhonsle

trigger:
  slash_commands:
    - /csat-analysis
    - /csat
  keywords:
    - csat analysis
    - customer satisfaction
    - survey analysis
    - customer feedback
    - detractor analysis
    - promoter analysis
    - satisfaction drivers
  intent_categories:
    - analytics
  mode: HYBRID
  min_confidence: 0.7

prompt:
  constraints:
    - Resolve material ambiguity before starting the analysis.
    - Ask which database to use when it cannot be reliably determined from the request or conversation context.
    - Reuse discoveries and analytical context across workflow stages.
    - Use the preferred subskills defined below when available and appropriate.
    - Base findings only on actual metadata, query results, and successfully executed analytics.
    - Never fabricate analytical results, topics, counts, vector distances, or similarity scores.
    - Prefer existing classifications, sentiment fields, and embeddings before creating new ones.
    - Ask before creating persistent objects, models, embeddings, or indexes.
    - Attempt a supported recovery or fallback when an operation fails and disclose it.
    - Distinguish measured findings from interpretations and recommendations.
    - Do not estimate NPS uplift, conversions, churn reduction, or other business impact unless requested.

  output_format: |
    Produce a consolidated CSAT analysis covering:
    1. Data analyzed
    2. Satisfaction score and segment overview
    3. Detractor drivers and topics
    4. Promoter topics
    5. Semantic topic insights
    6. Sentiment and rating alignment
    7. Most interesting findings
    8. Evidence-based recommendations
    9. Execution notes for any recovery, fallback, or limitation

tools:
  required_tools: []
  preferred_order: []
---

# Customer Satisfaction Analysis

An end-to-end orchestration skill for analyzing customer satisfaction survey
data using structured analytics, free-form feedback, and semantic search.

After required inputs are resolved, execute the analysis autonomously. The
user should not need to issue a separate prompt for every analytical step.

## When to Use

Use this skill when the user wants to:

- Run a CSAT or customer satisfaction analysis.
- Analyze customer survey scores and satisfaction segments.
- Identify drivers of dissatisfaction.
- Understand detractor and promoter feedback.
- Discover recurring topics in free-form survey responses.
- Find semantically related customer feedback.
- Compare sentiment with survey ratings.
- Identify actionable customer experience insights.

---

## Preferred Subskills

Use these specialized skills when available and appropriate:

| Task | Preferred Subskill |
|---|---|
| Discover survey data | `td-schema-discovery` |
| Profile survey data | `td-data-profile` |
| Score distributions and statistics | `td-data-stats` |
| Segment and driver analysis | `teradata-analytics` |
| Free-form feedback analysis | `teradata-text-analytics` |
| Semantic similarity and topic drill-down | `teradata-vector-embeddings` |

Visualization may be generated directly by Tera and does not require a
dedicated subskill.

Subskills are preferred capabilities, not rigid dependencies. If a preferred
skill or operation fails, attempt a supported recovery or fallback and record
it in the final execution notes.

---

# Required Inputs

## Database

Determine the database before beginning the full analysis.

1. Use a database explicitly provided by the user.
2. Otherwise reuse the database established in the conversation.
3. If exactly one relevant database can be reliably identified, use it.
4. Otherwise ask:

**"Which database would you like me to use for the CSAT analysis?"**

Retain the selected database throughout the workflow.

## Survey Source

Use `td-schema-discovery` to identify the primary survey-response table and
relevant supporting objects.

If one table is clearly the primary response table, select it and continue.
If multiple tables are equally plausible, present the candidates and ask the
user which one to use.

## Satisfaction Definition

Prefer an existing satisfaction classification or documented definition.

If only a numeric score exists and no reliable promoter/passive/detractor or
equivalent mapping can be determined, ask the user how the scores should be
classified.

Do not silently impose an NPS or satisfaction definition.

---

# Workflow

## 1. Discover and Profile Survey Data

Use `td-schema-discovery` to identify:

- the primary survey-response table
- supporting survey objects
- identifiers
- rating or satisfaction fields
- free-form feedback
- sentiment data
- existing survey embeddings

Then use `td-data-profile` on the selected survey table to understand:

- columns and data types
- identifiers and keys
- rating and segment fields
- response indicators
- feedback and sentiment fields
- relevant business dimensions
- missing values and useful metadata

Carry this context through all subsequent stages. Do not repeatedly rediscover
information already established.

---

## 2. Analyze and Visualize Satisfaction Scores

Use `td-data-stats` to analyze the appropriate survey score for valid
respondents.

Calculate where appropriate:

- count and percentage by score
- mean
- median
- mode
- standard deviation
- satisfaction segment counts and percentages

Generate an appropriate visualization of the score distribution with useful
summary KPIs.

Do not include non-respondents in score statistics unless required.

---

## 3. Identify Satisfaction Segments and Detractor Drivers

Use `teradata-analytics` to compare promoters, passives, detractors, or
equivalent satisfaction groups.

Report segment counts and percentages.

For detractors, analyze relevant dimensions such as:

- banking or service task
- product
- channel
- interaction type
- customer segment
- journey
- sentiment

Where useful, compare both detractor count and detractor rate. Rank the
strongest observed drivers without implying causation.

---

## 4. Analyze Detractor Feedback

Use `teradata-text-analytics` to identify recurring language and dominant
themes in detractor feedback.

Prefer appropriate native text functions such as `TD_NgramSplitter`,
`TD_TFIDF`, `TD_TextMorph`, or `TD_SentimentExtractor` when applicable.

When using n-grams:

1. Extract meaningful recurring terms and phrases.
2. De-emphasize common conversational terms where appropriate.
3. Group related textual patterns into business-relevant topics.
4. Validate topics using representative survey responses.

Treat n-grams as evidence for topics, not automatically as the final topics.

---

## 5. Semantically Explore Detractor Topics

Use `teradata-vector-embeddings` when suitable survey embeddings already
exist.

For important detractor topics:

1. Select representative responses.
2. Retrieve their existing embeddings.
3. Perform semantic nearest-neighbor search using an appropriate native
   vector function such as `TD_VectorDistance`.
4. Join neighbors back to the survey-response data.
5. Review the actual feedback.
6. Identify meaningful subtopics.

Return actual response identifiers and distance or similarity values when
available.

Do not use keyword filtering and describe it as semantic search.

Do not treat a table containing embedding columns as a managed vector
collection unless it actually is one.

---

## 6. Analyze Promoter Feedback

Use `teradata-text-analytics` to identify what highly satisfied customers
value.

Determine:

- recurring positive terms and phrases
- dominant positive themes
- praised services or experiences
- representative customer feedback

Where useful, use `teradata-vector-embeddings` to find semantically related
promoter responses and identify deeper positive subtopics.

Apply the same evidence requirements used for detractor analysis.

---

## 7. Explore an Important Topic

Select an analytically important topic from the preceding findings and
investigate it more deeply.

If one topic is clearly dominant, select it automatically and state the
selection.

If several topics are similarly important and the choice would materially
change the analysis, ask the user which topic to explore.

Use `teradata-analytics`, `teradata-text-analytics`, and
`teradata-vector-embeddings` as appropriate to identify related patterns and
subtopics.

---

## 8. Compare Sentiment with Survey Ratings

Prefer existing sentiment data when suitable.

Use `td-data-stats` and `teradata-analytics` to compare sentiment with survey
ratings and identify:

- low rating + negative sentiment
- high rating + positive sentiment
- low rating + positive sentiment
- high rating + negative sentiment

Investigate meaningful mismatches for possible mixed experiences, rating
ambiguity, contextual differences, or sentiment-model limitations.

Use `teradata-text-analytics` only when sentiment must be derived from text.

---

## 9. Identify the Most Interesting Findings

Synthesize results across the complete analysis.

Look for relationships across:

- satisfaction distribution
- satisfaction segments
- detractor drivers
- detractor topics and semantic subtopics
- promoter topics and semantic subtopics
- sentiment-rating alignment

Prioritize findings based on evidence, prevalence, magnitude, unusual
behavior, and business relevance.

Do not simply repeat earlier results.

---

## 10. Produce the Final CSAT Analysis

Create one consolidated analysis containing:

### Data Analyzed
Database, primary survey table, supporting data, and respondent population.

### Satisfaction Overview
Score distribution, descriptive statistics, and satisfaction segments.

### Detractor Analysis
Key drivers, dominant topics, semantic subtopics, and supporting evidence.

### Promoter Analysis
Dominant positive themes, semantic subtopics, and supporting evidence.

### Sentiment Alignment
Overall alignment and meaningful rating/sentiment mismatches.

### Key Findings
The strongest cross-analysis insights.

### Recommendations
Evidence-based actions derived from the findings.

### Execution Notes
Any failed operation, recovery, fallback, skipped analysis, or limitation.

---

# Recovery and Fallback

## Text Analytics

If a native text analytics operation fails:

1. Inspect the actual error.
2. Determine whether the invocation path caused the failure.
3. Attempt supported direct SQL execution when appropriate.
4. Correct syntax or parameter issues and retry.
5. Use a data-backed fallback only if native execution remains unavailable.
6. Report the recovery or fallback.

For example, if `TD_NgramSplitter` fails through an SQLE fastpath but is
available through direct SQL, retry it through the supported SQL execution
path.

## Vector Analysis

If semantic search fails:

1. Confirm that embeddings exist.
2. Inspect their structure, identifiers, and dimensions.
3. Retry using a supported vector execution path.
4. Confirm that actual neighbors were returned.

Do not present proposed SQL, expected neighbors, or invented distance scores
as successful semantic-search results.

If vector analysis remains unavailable, report the limitation and continue
with the remaining CSAT workflow.

---

# Guardrails

- Never guess database schema.
- Preserve context between workflow stages and subskills.
- Never fabricate analytical results.
- Do not present expected results as executed results.
- Prefer existing sentiment, classifications, and embeddings.
- Treat n-grams as textual evidence rather than final topics.
- Use actual vector analysis for semantic-search claims.
- Do not describe keyword matching as semantic search.
- Do not imply causation from association alone.
- Do not call a non-standard satisfaction scale standard NPS.
- Clearly distinguish findings, interpretations, and recommendations.
- Ask before creating persistent tables, models, embeddings, or indexes.
- Clearly disclose recovery, fallback, and analytical limitations.

---

# Example

**User:**

`/csat Analyze customer satisfaction and identify the most important insights from my survey data.`

If the database is unknown, ask which database to use.

Once resolved, orchestrate:

`td-schema-discovery`
→ `td-data-profile`
→ `td-data-stats`
→ `teradata-analytics`
→ `teradata-text-analytics`
→ `teradata-vector-embeddings`
→ final CSAT synthesis

The user should not need to issue a separate prompt for every stage.

---

# Notes

- This skill orchestrates existing Teradata analytical skills rather than
  replacing them.
- Do not hard-code a database, survey table, score column, sentiment column,
  or embedding table.
- Discover and validate the available data at runtime.
- Prefer existing embeddings over generating new ones.
- The skill is designed to be reusable beyond the workshop dataset.