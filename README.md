# Dallas Hands-On Workshop — Tera Skills Registry

This repository is a **skills registry** for [Tera](https://www.teradata.com/). It holds a
curated set of *skills* that extend what Tera can do, and it is used for **customer demos**
and hands-on workshops.

A skill is a small, self-contained bundle of instructions (and optional tools/constraints)
that teaches Tera how to perform a specific task really well — for example reviewing code,
analyzing a dataset, or writing SQL. When this repository is connected to Tera, the skills
defined here become available to use in conversations.

## What you can do with this repo

- **Create your own skills** by adding a new skill definition under `skill-domains/`.
- **Use those skills with Tera** — once the repo is registered as a skills source, Tera can
  discover and invoke the skills based on their triggers (slash commands and keywords).
- **Learn by example** — the included demo skill shows the expected structure and format.

## Repository structure

```
.
├── README.md                     # You are here
├── .gitignore
└── skill-domains/                # All skills, grouped by domain
    └── demo/                     # Example domain
        └── hello-tera/
            └── SKILL.md          # A small test skill
```

Skills are organized into **domains** (e.g. `demo`, `code`, `data`). Each domain is a folder
under `skill-domains/`, and each skill lives inside its domain.

## Skill formats

Two formats are supported:

1. **Folder-based (`SKILL.md`)** — a folder named after the skill containing a `SKILL.md`
   file. Use this when the skill needs supporting files or richer documentation.

   ```
   skill-domains/<domain>/<skill-name>/SKILL.md
   ```

2. **Single-file (`.yaml`)** — a single YAML file for compact skills.

   ```
   skill-domains/<domain>/<skill-name>.yaml
   ```

## Anatomy of a skill

Every `SKILL.md` starts with a YAML frontmatter block that describes the skill and how it is
triggered, followed by Markdown that instructs Tera how to behave.

```markdown
---
name: hello-tera
title: Hello Tera
description: A minimal demo skill that greets the user and confirms the registry works.
domain: demo
version: 1.0.0
status: active
trigger:
  slash_commands:
    - /hello-tera
  keywords:
    - hello tera
    - say hello
  mode: HYBRID
  min_confidence: 0.7
---

# Hello Tera

Instructions for how Tera should behave when this skill activates...
```

| Field                    | Purpose                                                        |
| ------------------------ | ------------------------------------------------------------- |
| `name`                   | Unique identifier for the skill (kebab-case).                 |
| `title`                  | Human-friendly display name.                                  |
| `description`            | Short summary of what the skill does.                         |
| `domain`                 | The domain folder the skill belongs to.                       |
| `version`                | Semantic version of the skill.                                |
| `status`                 | Lifecycle status, e.g. `active`.                              |
| `trigger.slash_commands` | Slash commands that activate the skill.                       |
| `trigger.keywords`       | Natural-language phrases that activate the skill.             |
| `trigger.mode`           | Matching mode (e.g. `HYBRID` for keywords + intent).          |
| `trigger.min_confidence` | Minimum confidence required before the skill activates.       |

## Add your own skill

1. Pick or create a domain folder under `skill-domains/`.
2. Create a folder named after your skill and add a `SKILL.md` (or add a `<skill-name>.yaml`).
3. Fill in the frontmatter and write clear instructions for how Tera should respond.
4. Commit and push. Once the repo is connected to Tera, your skill is ready to use.

## Try the demo skill

The [`hello-tera`](skill-domains/demo/hello-tera/SKILL.md) skill is a minimal example you can
use to confirm the registry is wired up correctly. Trigger it with `/hello-tera` or by saying
"hello tera".
