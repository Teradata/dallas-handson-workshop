# Text Analysis for Customer Feedback Mining

When the CSAT table includes a free-text feedback column, use Teradata text analytics functions to extract themes from satisfied and dissatisfied customers.

## Prerequisites

- Confirm the feedback column has ≥ 30% non-null coverage (see data-validation checks).
- Split feedback into two groups for comparative analysis:
  - **High-CSAT group**: satisfaction_score in the top quartile (or ≥ 4 on a 1–5 scale)
  - **Low-CSAT group**: satisfaction_score in the bottom quartile (or ≤ 2 on a 1–5 scale)

## Step 1: Tokenize Feedback

Use TD_TextParser to break comments into individual tokens:

```sql
SELECT *
FROM TD_TextParser (
  ON (SELECT id, feedback_text FROM <db>.<table> WHERE satisfaction_score <= 2)
  USING
    TextColumn('feedback_text')
    OutputType('TOKENS')
    RemoveStopWords('true')
    ToLowerCase('true')
) AS dt;
```

Repeat for the high-satisfaction group (score ≥ 4).

## Step 2: Extract N-Grams

Bigrams and trigrams reveal multi-word themes (e.g., "long wait time", "friendly staff"):

```sql
SELECT *
FROM TD_NGramSplitter (
  ON (SELECT id, feedback_text FROM <db>.<table> WHERE satisfaction_score <= 2)
  USING
    TextColumn('feedback_text')
    Grams('2,3')
    ToLowerCase('true')
    Delimiter(' ')
) AS dt;
```

Aggregate by n-gram frequency to find the most common phrases in each satisfaction tier.

## Step 3: Sentiment Extraction

Validate the numeric score against detected sentiment in the text:

```sql
SELECT *
FROM TD_SentimentExtractor (
  ON (SELECT id, feedback_text, satisfaction_score FROM <db>.<table>)
  USING
    TextColumn('feedback_text')
    Model('dictionary')
) AS dt;
```

Cross-tabulate detected sentiment (positive/negative/neutral) with the numeric score to identify mismatches (e.g., high score but negative text may indicate sarcasm or data entry error).

## Step 4: Comparative Theme Ranking

After extracting n-grams for both groups, rank by frequency difference:

```sql
-- Conceptual: join high-CSAT n-grams with low-CSAT n-grams
SELECT
  COALESCE(h.ngram, l.ngram) AS theme,
  ZEROIFNULL(h.freq) AS high_sat_freq,
  ZEROIFNULL(l.freq) AS low_sat_freq,
  ZEROIFNULL(l.freq) - ZEROIFNULL(h.freq) AS dissatisfaction_signal
FROM high_csat_ngrams h
FULL OUTER JOIN low_csat_ngrams l ON h.ngram = l.ngram
ORDER BY dissatisfaction_signal DESC;
```

Themes with high `dissatisfaction_signal` are top dissatisfaction drivers from customer voice.
Themes with large negative `dissatisfaction_signal` (i.e., much more frequent in high-CSAT) are satisfaction drivers.

## Interpretation Guidelines

| Signal | Meaning | Action |
|--------|---------|--------|
| N-gram frequent only in low-CSAT | Pain point unique to unhappy customers | Priority fix |
| N-gram frequent in both groups | Common topic, not differentiating | Lower priority |
| N-gram frequent only in high-CSAT | Delight factor | Protect and amplify |
| Sentiment mismatch (score ↑, text ↓) | Possible data quality issue | Investigate before reporting |
