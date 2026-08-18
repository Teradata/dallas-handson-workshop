# Frontmatter Checklist

Use this checklist to validate frontmatter before submission.

## Required Fields

### `name`
- **Format**: kebab-case (lowercase, hyphens only, no spaces/underscores)
- **Length**: 3–50 characters
- **Uniqueness**: No existing skill in the marketplace has this name
- **Immutability**: Never changes once submitted; renames require a new skill
- **Example**: `test-skill-demo`, `query-performance-diagnosis`

### `title`
- **Format**: Human-readable, title case
- **Length**: 10–80 characters
- **Clarity**: Reflects skill purpose at a glance
- **Example**: `Test Skill Demo`, `Query Performance Diagnosis`

### `description`
- **Format**: Single-quoted to avoid YAML colon issues
- **Length**: 100–500 characters
- **Voice**: Verb-first, active, user-centric
- **Phrases**: Include the exact words users would say to trigger it
- **Example**: `'Demonstrate skill creation workflow with a minimal, reusable test skill that validates trigger modes…'`

### `domain`
- **Allowed values**: `general`, `data`, `sql`, `operations`, `security`, `analytics` (org-specific)
- **Default**: `general` if omitted (not recommended)
- **Single value**: Exactly one domain per skill
- **Example**: `general`, `data`

## Metadata Block

### `metadata.author`
- **Format**: Team name or user email
- **Purpose**: Attribution and contact for updates
- **Example**: `test-user`, `data-engineering-team`

### `metadata.version`
- **Format**: Semantic versioning (`MAJOR.MINOR.PATCH`)
- **Initial**: `1.0.0` for new skills
- **Bump rules**:
  - PATCH (x.x.Z): Bug fixes, clarifications
  - MINOR (x.Y.0): New procedures, references, features
  - MAJOR (X.0.0): Breaking changes, renamed trigger keywords
- **Example**: `1.0.0`, `1.2.3`, `2.0.0`

## Trigger Block

### `trigger.mode`
- **Allowed values**: `MANUAL`, `AUTO`, `HYBRID`, `ALWAYS`
- **Recommended**: `HYBRID` for broad utility
- **Rules**:
  - `MANUAL` — user explicitly invokes (e.g., `/test-demo`)
  - `AUTO` — agent auto-loads on matching keywords or intent
  - `HYBRID` — both manual and auto
  - `ALWAYS` — reserved for foundational skills (rare)
- **Example**: `HYBRID`

### `trigger.slash_commands`
- **Format**: Array of command strings
- **Pattern**: `/` prefix, kebab-case name (e.g., `/test-demo`)
- **Requirement**: Optional; omit if not needed
- **Example**: `['/test-demo', '/validate-skill']`

### `trigger.keywords`
- **Format**: Array of phrases or single words
- **Count**: 3–10 for AUTO/HYBRID; may be empty for `MANUAL`
- **Content**: Exact phrases users say in natural language
- **Example**: `['test skill', 'demo', 'prototype', 'validation']`

### `trigger.intent_categories`
- **Format**: Array of category labels
- **Count**: 1–5 per skill
- **Values**: Domain-specific categories (e.g., `testing`, `diagnosis`, `optimization`)
- **Example**: `['testing', 'demonstration']`

### `trigger.min_confidence`
- **Format**: Float between 0.0 and 1.0
- **Default**: 0.70 if omitted
- **Meaning**: Minimum confidence threshold for AUTO/HYBRID keyword matching
- **Tuning**: Raise to reduce false positives; lower to increase sensitivity
- **Example**: `0.65`, `0.75`

## Prompt Block

### `prompt.constraints`
- **Format**: Array of imperative strings
- **Purpose**: Hard rules the agent must follow
- **Count**: 2–5 for clarity
- **Example**:
  ```yaml
  - Follow the procedure steps in order.
  - Validate inputs before proceeding.
  ```

### `prompt.output_format`
- **Format**: Multiline string (use `|` for literal text)
- **Purpose**: Define what the agent should return
- **Example**:
  ```yaml
  output_format: |
    Report the test outcome with:
    1. Status (pass/fail)
    2. Procedure steps executed
    3. Key findings
  ```

## Parser-Ignored Fields

These fields are silently ignored; avoid them:
- `prompt.examples` — use references instead
- `metadata.labels`, `metadata.status`, `metadata.risk_level`
- `argument-hint`, `user-invocable`, `disable-model-invocation`
- `context`, `license`, `compatibility`, `enforcement`

## Quick Validation

```bash
✓ name: kebab-case, unique, 3–50 chars
✓ title: human-readable, 10–80 chars
✓ description: 100–500 chars, verb-first, single-quoted, user phrases
✓ domain: in allowlist, single value
✓ metadata.author, metadata.version (semantic)
✓ trigger.mode: MANUAL | AUTO | HYBRID | ALWAYS
✓ trigger: ≥1 of slash_commands, keywords, intent_categories
✓ trigger (AUTO/HYBRID): keywords populated with 3–10 phrases
✓ prompt.constraints: 2–5 rules
✓ prompt.output_format: defined
```
