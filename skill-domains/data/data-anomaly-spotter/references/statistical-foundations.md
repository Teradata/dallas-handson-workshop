# Statistical Foundations for Anomaly Detection

## Overview

Anomaly detection relies on statistical measures to quantify "normal" behavior and identify deviations. This reference explains the methods, their trade-offs, and when to apply each.

## Method 1: Interquartile Range (IQR)

### Formula

```
Q1 = 25th percentile
Q3 = 75th percentile
IQR = Q3 - Q1

Lower Fence = Q1 - 1.5 * IQR
Upper Fence = Q3 + 1.5 * IQR

Outlier if value < Lower Fence OR value > Upper Fence
```

### Advantages
- **Robust to skew**: Works well with non-normal distributions (common in real data).
- **Interpretable**: Directly tied to data distribution.
- **Resistant**: Not pulled by extreme values in the tail.

### Disadvantages
- **Conservative**: May miss moderate anomalies in uniform distributions.
- **Fixed threshold**: The 1.5 multiplier works for most cases but is arbitrary.

### When to Use
- Distributions are skewed or unknown.
- Data has a clear central tendency with occasional spikes.
- You prefer interpretability over statistical power.

### Example
For a salary distribution: Q1 = $40k, Q3 = $100k, IQR = $60k.
Outliers are salaries < $40k - 1.5*$60k = -$50k (impossible) or > $100k + 1.5*$60k = $190k.
Anyone earning > $190k is flagged.

---

## Method 2: Z-Score (Standard Deviation)

### Formula

```
mean = arithmetic average
stddev = population or sample standard deviation

z-score = (value - mean) / stddev

Extreme if |z-score| > 3
Moderate if |z-score| > 2
```

### Advantages
- **Standardized**: Universally understood; comparable across datasets.
- **Sensitive**: Picks up moderate deviations in normal data.
- **Mathematically tractable**: Supports confidence intervals and hypothesis tests.

### Disadvantages
- **Assumes normality**: Breaks down for skewed or multimodal data.
- **Pulled by extremes**: A single outlier inflates stddev, reducing sensitivity.
- **Percentage-based**: Extreme threshold (z > 3) captures only ~0.3% of normal data.

### When to Use
- Data is approximately normal (bell-shaped).
- You need to compare anomalies across multiple columns.
- Statistical rigor and p-values matter for your use case.

### Example
For a test score with mean = 75, stddev = 10:
A score of 95: z-score = (95 - 75) / 10 = 2.0 (moderate outlier).
A score of 105: z-score = (105 - 75) / 10 = 3.0 (extreme outlier).

---

## Method 3: Median Absolute Deviation (MAD)

### Formula

```
median = 50th percentile
MAD = median(|value - median|)

Modified z-score = 0.6745 * (value - median) / MAD

Outlier if modified z-score > 3.5
```

### Advantages
- **Most robust**: Resistant to both skew and extreme outliers.
- **Better for real data**: Median is less influenced by tail values than mean.
- **No normality assumption**: Works for any distribution.

### Disadvantages
- **Less familiar**: Not as widely taught or expected.
- **Slower to compute**: Requires full data pass; no incremental updates.
- **Overkill for simple cases**: Adds complexity when IQR suffices.

### When to Use
- Data has multiple outliers that inflate standard deviation.
- Distribution is highly skewed or multimodal.
- You want maximum robustness without distributional assumptions.

### Example
For a transaction amount with median = $500:
MAD = median(|amount - 500|) = $150.
A transaction of $2000: modified z-score = 0.6745 * (2000 - 500) / 150 ≈ 6.75 (extreme outlier).

---

## Method 4: Time-Series Trend Detection

### Concept

For sequential or time-indexed data (e.g., daily sales, hourly CPU), anomalies are deviations from expected trend, not just statistical distance.

### Approach

1. **Establish baseline**: 7-day, 30-day, or seasonal moving average.
2. **Compute deviation**: % difference from baseline or residual from trend fit.
3. **Flag threshold**: Typically > ±20% (or tune for your domain).

### Formula (Moving Average)

```
baseline_t = average(value[t-7] to value[t-1])  -- 7-day trailing avg
deviation_pct = 100 * (value_t - baseline_t) / baseline_t

Anomaly if |deviation_pct| > 20
```

### Advantages
- **Captures seasonality**: Recognizes normal peaks (weekends, holidays) vs. true anomalies.
- **Adaptive**: Baseline updates as new data arrives.
- **Domain-friendly**: % deviation is intuitive ("sales dropped 30%").

### Disadvantages
- **Lag**: Recent baseline includes data close to the anomaly, reducing sensitivity.
- **Cold start**: First N days have insufficient history for baseline.
- **Requires temporal ordering**: Assumes data is sorted by time.

### When to Use
- Data has a time dimension (timestamps, dates).
- Seasonality and trends are expected (e.g., sales, website traffic).
- You want to detect "unexpected" changes relative to recent history.

---

## Choosing the Right Method

### Decision Tree

1. **Is your data time-indexed (dates, timestamps)?**
   - Yes → Use time-series trend detection first; supplement with IQR on residuals.
   - No → Go to question 2.

2. **Is your data approximately normally distributed?** (Check: plot histogram or Q-Q plot.)
   - Yes → Z-score is reasonable; but IQR is safer for production.
   - No → Go to question 3.

3. **Is the distribution highly skewed or do you see extreme outliers?**
   - Yes → Use MAD (most robust) or IQR (simpler, still good).
   - No → IQR is sufficient.

### Quick Reference Table

| Distribution | Method | Rationale |
|--------------|--------|----------|
| Normal, no extremes | Z-score or IQR | Both work; z-score slightly more powerful |
| Skewed | IQR or MAD | IQR simpler; MAD most robust |
| Multimodal | MAD | Z-score fails; IQR may miss within-mode outliers |
| Time-series | Moving average + residual IQR/z-score | Captures trend and seasonality |
| Unknown | IQR | Default safe choice |

---

## False Positives and Domain Context

Statistical anomalies are not automatically business anomalies.

### Example
- **Data**: E-commerce transaction amount.
- **Statistical flag**: Z-score > 3 for a $50,000 order.
- **Business reality**: Legitimate bulk purchase from a corporate client.
- **Action**: Whitelist, don't investigate.

### Strategies to Reduce False Positives

1. **Segment first**: Separate high-value customers, bulk sellers, etc., then detect within segment.
2. **Use domain thresholds**: Define business rules in addition to statistics (e.g., "flag if > $50k AND not in approved vendor list").
3. **Validate with domain expert**: Have a human review flagged records before acting.
4. **Adjust threshold**: For 10% false positive tolerance, lower z-score threshold from 3 to 2 or increase IQR multiplier from 1.5 to 2.

---

## Implementation Notes for Teradata

### PERCENTILE_CONT vs. PERCENTILE_DISC

- **PERCENTILE_CONT**: Interpolates between values; recommended for IQR.
- **PERCENTILE_DISC**: Returns actual data value; use if you need concrete examples.

### Performance Optimization

- **Large tables**: Use `SAMPLE` clause to profile on a subset, then apply thresholds to full table.
- **Repeated detection**: Materialize stats in a summary table; join instead of recomputing each time.
- **Streaming**: For near-real-time anomalies, maintain a rolling window of recent data; update baseline daily.

### NULL Handling

Always filter out nulls before computing statistics — they skew percentiles and averages.

```sql
WHERE <column> IS NOT NULL
```

---

## Further Reading

- **Box and Whisker Plot**: Visual method using IQR; popular in exploratory data analysis.
- **Robust Statistics**: Academic field focused on methods resistant to outliers (MAD, trimmed means).
- **Change Point Detection**: Advanced technique for time-series anomalies; detects when baseline shift occurs.
- **Isolation Forest**: ML algorithm for multivariate anomaly detection (not covered here; use `td-train-eval-model-indb` if needed).
