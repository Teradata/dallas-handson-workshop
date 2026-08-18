# Submission Workflow: From Draft to Marketplace

## The Complete Flow

```
Draft → Validate → Submit → Review → Merge → Marketplace
```

## Phase 1: Draft

### Prepare the Bundle

1. Create `SKILL.md` with frontmatter and markdown body.
2. Create `references/`, `assets/`, `scripts/` subdirectories as needed.
3. Populate each sidecar file.
4. Link every sidecar from SKILL.md using `./` prefix.

### File Structure

```
(bundle root)
├── SKILL.md                          # Required
├── references/
│   ├── frontmatter-checklist.md
│   ├── writing-guide.md
│   └── submission-workflow.md
├── assets/
│   └── (templates, examples, configs)
└── scripts/
    └── (automation, helpers)
```

Paths in the `create_skill_pr` call are **bundle-root-relative**:
- `SKILL.md` (at root)
- `references/frontmatter-checklist.md`
- `assets/template.sql`
- `scripts/run.py`

Do NOT include the full repo path (`skill-domains/general/test-skill-demo/SKILL.md`).

## Phase 2: Validate

### Self-Check Before Submit

- [ ] `name` is kebab-case and unique in the marketplace
- [ ] `description` is 100–500 chars, verb-first, includes user phrases
- [ ] `domain` is in the org's allowlist
- [ ] `trigger.mode` is valid; AUTO/HYBRID has 3+ keywords
- [ ] At least one trigger method (slash command, keyword, or intent category)
- [ ] SKILL.md body has "When to Use" + ≥1 procedure
- [ ] Every `references/`, `assets/`, `scripts/` file is linked from SKILL.md with `./` prefix
- [ ] No parser-ignored fields (e.g., `prompt.examples`, `metadata.labels`)
- [ ] No secrets or sensitive data anywhere
- [ ] SKILL.md ≤ 300 lines; reference files ≤ 650 lines each
- [ ] Total bundle 700–3000 lines (appropriate scope)

### Common Validation Failures

| Issue | Fix |
|-------|-----|
| "name already exists" | Use a unique name; check `skill_context` marketplace |
| "missing frontmatter field" | Add required fields: `name`, `title`, `description`, `domain` |
| "sidecar outside reserved dir" | Move file into `references/`, `assets/`, or `scripts/` |
| "secret scan match" | Remove API keys, credentials, tokens from all files |
| "unlinked reference" | Add link to SKILL.md: `[Title](./references/file.md)` |
| "trigger config empty" | Populate `slash_commands`, `keywords`, or `intent_categories` |

## Phase 3: Submit

### Call `git_contribute create_skill_pr`

```python
git_contribute(
    action="create_skill_pr",
    pr_title="feat(skills): add test-skill-demo",
    commit_message="feat(skills): add test-skill-demo",
    files=[
        {"file_path": "SKILL.md", "content": "<full SKILL.md>"},
        {"file_path": "references/frontmatter-checklist.md", "content": "<content>"},
        {"file_path": "references/writing-guide.md", "content": "<content>"},
        {"file_path": "references/submission-workflow.md", "content": "<content>"}
    ]
)
```

### What Happens

1. **Automatic validation** — Server checks frontmatter, file locations, secrets.
2. **Branch creation** — Unique branch prefixed with `skill-contrib/`.
3. **PR opened** — Against the org's contributable repo (e.g., `Teradata/dallas-handson-workshop`).
4. **URL returned** — Skill is now under review.

## Phase 4: Review

Your PR is reviewed by admins. They may:
- Request clarifications or edits (via PR comments)
- Ask to resubmit with corrections
- Approve and merge

### Update Your Submission

If review feedback requires changes, resubmit the same `create_skill_pr` call with updated content. The tool **amends the open PR in place** — no second PR.

```python
git_contribute(
    action="create_skill_pr",
    pr_title="feat(skills): add test-skill-demo",  # Same title
    commit_message="refactor: clarify trigger logic",  # New message for this commit
    files=[
        {"file_path": "SKILL.md", "content": "<updated SKILL.md>"},
        # ... include all files again
    ]
)
```

The branch persists; commits stack up. The PR title stays the same.

## Phase 5: Merge

Once approved, an admin merges the PR. The skill lands on `main`.

## Phase 6: Marketplace

After the next **SyncSkills** cycle:
- Skill appears in `skill_context.marketplace_skills`
- Visible in `list_skills` output
- Available to all users in the workspace
- Searchable by name, keywords, domain

## Monitoring Status

### Check Your PR

```python
skill_context(
    action="check_pr_status",
    pr_id="<pr_id_from_context>"  # UUID from pending_prs
)
```

Returns: PR number, status (open/merged/closed), last commit.

### Track Changes

Each submission creates a new commit on your branch. View all commits in the GitHub PR UI.

## Best Practices

1. **Start small.** A well-focused skill (1 procedure, 2–3 references) is better than an overloaded one.
2. **Test your markdown** — Use a Markdown preview tool before submitting.
3. **Link liberally** — Reference files are cheap; clarity is valuable.
4. **Update version numbers** — Bump semantically on each submission.
5. **Respond to feedback promptly** — Quick iteration speeds up review.
6. **Reuse existing patterns** — Study marketplace skills; match their structure.

## Examples

Well-formed marketplace skills to study:
- `slow-query-analysis` — rich trigger config + detailed procedures
- `row-level-security` — progressive disclosure across references
- `query-performance-diagnosis` — business-focused procedures + decision tables
