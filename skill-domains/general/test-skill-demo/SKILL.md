---
name: test-skill-demo
title: Test Skill Demo
description: 'Demonstrate skill creation workflow with a minimal, reusable test skill that validates trigger modes, basic procedures, and reference file linking. Use this to prototype skill authoring patterns and verify submission.'
domain: general
metadata:
  author: test-user
  version: 1.0.0
trigger:
  mode: HYBRID
  slash_commands: ['/test-demo']
  keywords: ['test skill', 'demo', 'prototype', 'validation']
  intent_categories: ['testing', 'demonstration']
  min_confidence: 0.65
prompt:
  constraints:
    - Follow the procedure steps in order.
    - Validate inputs before proceeding.
    - Report findings clearly.
  output_format: |
    Report the test outcome with:
    1. Status (pass/fail)
    2. Procedure steps executed
    3. Key findings
    4. Next steps or recommendations
---

# Test Skill Demo

## When to Use

- User wants to prototype or validate a skill workflow.
- Testing skill-creation procedures and submission pipelines.
- Demonstrating the complete skill lifecycle (creation, update, deletion).

**Do NOT use for** production workloads — use domain-specific skills (`td-data-profile`, `query-performance-diagnosis`, etc.) instead.

## Core Concepts

**Skill Lifecycle**: Creation → Validation → Submission → Review → Marketplace entry

**Skill Components**:
- **SKILL.md** — frontmatter (metadata, triggers) + markdown instructions
- **References** — linked guides, detailed workflows, syntax tables
- **Assets** — templates, examples, configurations
- **Scripts** — automation, helpers, reproducible workflows

**Trigger Modes**:
- `MANUAL` — user explicitly loads the skill
- `AUTO` — agent auto-loads based on keywords/intent
- `HYBRID` — both (recommended for broad utility)

## Procedure: Validate Skill Structure

1. **Check frontmatter** — Verify `name` (kebab-case), `title`, `domain`, `trigger`, and `metadata.version` are present and well-formed. See [Frontmatter Checklist](./references/frontmatter-checklist.md).

2. **Verify trigger configuration** — Confirm at least one of `slash_commands`, `keywords`, or `intent_categories` is populated. AUTO/HYBRID modes require meaningful keywords.

3. **Validate reference links** — Every file in `references/`, `assets/`, or `scripts/` must be linked from SKILL.md with a `./` prefix (e.g., `[Topic](./references/topic.md)`).

4. **Test bundle paths** — Confirm all file paths are bundle-root-relative: `SKILL.md` at root, sidecars under `references/`, `assets/`, `scripts/`.

5. **Scan for secrets** — Ensure no API keys, credentials, or sensitive data appear in any file.

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "name must be kebab-case" | Name contains spaces, underscores, or capitals | Use lowercase with hyphens only (e.g., `test-skill-demo`) |
| "sidecar files outside reserved dirs" | Reference/asset/script file not under `references/`/`assets/`/`scripts/` | Move file into correct subdirectory |
| "unlinked reference file" | SKILL.md does not link a file that exists in the bundle | Add `[Link](./references/file.md)` to markdown body |
| "description too short" | Description < 100 characters | Expand to 100–500 chars, include trigger phrases |
| "missing trigger configuration" | No slash_commands, keywords, or intent_categories | Add ≥1 of these to `trigger` frontmatter |

## References

- [Frontmatter Checklist](./references/frontmatter-checklist.md) — field-by-field validation and syntax
- [Writing Guide](./references/writing-guide.md) — tone, structure, and progressive disclosure patterns
- [Submission Workflow](./references/submission-workflow.md) — from draft to PR to marketplace
