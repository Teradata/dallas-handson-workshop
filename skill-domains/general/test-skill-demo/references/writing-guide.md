# Writing Guide: Skill Documentation

## Tone and Voice

**Use imperative voice** — tell the agent what to do, not what not to do.

- ✓ "Run this query to collect statistics."
- ✗ "Don't forget to collect statistics."

**Explain WHY** — agents follow reasoning better than rigid commands.

- ✓ "Collect stats first because stale statistics mislead the optimizer and cause poor execution plans."
- ✗ "ALWAYS collect stats first."

**Be concise but clear** — avoid jargon unless defined; use concrete examples.

## Structure: SKILL.md Body

Follow this order for maximum clarity:

### 1. When to Use
Answer: **When should this skill activate?** List 2–4 scenarios. Include a "Do NOT use" section that cites alternative skills.

```markdown
## When to Use

- User asks to optimize a slow-running query.
- Need to recommend indexing strategy.
- Collecting baseline performance metrics.

**Do NOT use for** production schema changes — use `create-index` instead.
```

### 2. Core Concepts (Optional)
If the skill requires background knowledge, define it briefly. Use a table for mappings or type conversions.

```markdown
## Core Concepts

**Trigger Modes**: Configuration patterns that determine when a skill activates.

| Mode | Behavior | Use Case |
|------|----------|----------|
| MANUAL | User explicitly invokes | Rarely-used specialized tasks |
| AUTO | Agent auto-loads | Broad utility, keyword-driven |
| HYBRID | Both manual + auto | Recommended default |
```

### 3. Procedure(s)
Break the task into **imperative steps**. Each step should explain the action and the reasoning.

```markdown
## Procedure: Optimize Query Performance

1. **Collect query statistics** — Run EXPLAIN PLAN to understand the execution strategy and identify bottlenecks.
   ```sql
   EXPLAIN <query>;
   ```

2. **Identify missing indexes** — Check the plan for full-table scans on large tables that could benefit from an index on the join or filter column.
   See [Index Recommendations](./references/index-guide.md) for detail.

3. **Propose index creation** — Suggest indexes and estimate impact on query cost.
```

### 4. Common Errors (Recommended)
A table listing frequent mistakes, their causes, and fixes.

```markdown
## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "name must be kebab-case" | Spaces, underscores, or capitals | Use lowercase + hyphens only |
| "Skill not found" | Skill hasn't been submitted or name is misspelled | Check marketplace; use list_skills |
```

### 5. References (Recommended)
List all linked reference files with a one-line description.

```markdown
## References

- [Frontmatter Checklist](./references/frontmatter-checklist.md) — Validate all frontmatter fields before submission.
- [Writing Guide](./references/writing-guide.md) — Tone, structure, and progressive disclosure.
- [Index Recommendations](./references/index-guide.md) — When and how to recommend indexes.
```

## Code Blocks

**Always include a language hint.**

```sql
SELECT * FROM dbc.tables WHERE tablename = 'my_table';
```

```python
result = client.query("SELECT * FROM table")
print(result)
```

```yaml
name: my-skill
title: My Skill
```

## Progressive Disclosure

Keep SKILL.md under 300 lines. Push detailed workflows, exhaustive parameter lists, and edge cases into `references/` files and link them.

**In SKILL.md**: Summary, key steps, common gotchas.

**In references/**: Deep dives, parameter tables, advanced workflows.

Example link in SKILL.md:
```markdown
For advanced configuration, see [Advanced Setup](./references/advanced-setup.md).
```

## Reference File Guidelines

- **Scope**: One topic per file (e.g., "Index Strategy", "DDL Syntax", "Error Handling")
- **Length**: 150–650 lines
- **Headings**: Use consistent hierarchy (##, ###, ####)
- **Tables**: Preferred for mappings, parameter lists, decision trees
- **Examples**: Real SQL or YAML — no pseudocode
- **Linking**: Every reference file must be cited in SKILL.md with a `./` prefix

## Quality Checklist

- [ ] SKILL.md is 200–300 lines (refactor if > 500)
- [ ] Every reference file is linked from SKILL.md
- [ ] Procedures are imperative ("Run X", "Check Y")
- [ ] WHY is explained for non-obvious steps
- [ ] Code blocks have language hints
- [ ] Tables used for mappings/decisions, not narrative
- [ ] No fabricated examples — all SQL verified
- [ ] No secrets (API keys, credentials) anywhere
