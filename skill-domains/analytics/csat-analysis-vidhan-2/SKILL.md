---
name: "csat-analysis-vidhan-2"
title: "CSAT Analysis Skill Vidhan"
description: "Analyzes customer satisfaction data to identify key satisfaction and dissatisfaction drivers, customer feedback patterns, and actionable insights."
domain: "analytics"
metadata:
  author: "demouser9@workshop-keycloak.com"
  version: "1.0.0"
labels:
  "use_case": "customer_satisfaction"
trigger:
  mode: "HYBRID"
prompt:
  output_format: "Present the Customer Satisfaction Analysis as a clear business-focused summary containing:\n\n- Data analyzed\n- Overall satisfaction patterns and score distribution\n- Key dissatisfaction drivers\n- Key satisfaction drivers\n- Important topics and themes from customer feedback\n- Sentiment versus rating insights, when available\n- Key findings\n- Evidence-based recommendations\n\nUse tables and visualizations where they improve understanding. Create an interactive dashboard when appropriate and supported."
tools:
  required_tools: ["teradata-mcp"]
---

Perform an end-to-end customer satisfaction analysis using available Teradata data.

1. Discover relevant customer satisfaction, survey, and feedback data.
2. Identify and understand the relevant tables and fields.
3. Analyze satisfaction scores and overall satisfaction patterns.
4. Identify the main drivers of customer dissatisfaction and satisfaction.
5. Analyze free-text feedback to identify important topics and themes.
6. Compare customer sentiment with survey ratings when the data supports it.
7. Use semantic similarity to explore related customer feedback when suitable embeddings are available.
8. Summarize the most important findings and provide evidence-based recommendations.

Adapt the analysis to the data available. Do not assume specific database, table, column, rating scale, or metric definitions.

Use existing Teradata capabilities where appropriate for data discovery, profiling, statistical analysis, text analytics, and semantic analysis.

Do not fabricate analytical results or create or modify persistent database objects without user confirmation.
