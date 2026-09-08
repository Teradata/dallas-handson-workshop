---
name: context-engine-mcp
description: 'The Teradata Context Engine is a software infrastructure layer that continuously collects, processes, stores, retrieves, and delivers relevant contextual information to applications and AI systems — enabling situation-aware decisions rather than treating each interaction in isolation. It acts as the situational awareness brain, answering: Who is the user? What are they doing? What do they need? What is relevant right now? This skill routes every data product, GDP, knowledge graph, lineage and data quality question to the GDP Supervisor, which answers all of them end-to-end. Use when asking about data products, GDP, entities, lineage, data quality. Triggers for /data-product command.'
when_to_use: 'Triggers on: data product, GDP, governed data product, knowledge graph, lineage, upstream, downstream, data quality, quality score, subject area, entity, element, context engine'
metadata:
  author: context-engine-team
  version: "1.1"
---

# Context Graph MCP (CE MCP FinalTest)

## What is the Context Engine?

The Teradata Context Engine is a software infrastructure layer that continuously collects, processes, stores, retrieves, and delivers relevant contextual information to applications and AI systems at the precise moment it's needed — enabling the system to make informed, situation-aware decisions rather than treating each interaction in isolation.

It acts as the **situational awareness brain** of a system, answering the fundamental questions:
- **Who is the user?** — identity, profile, roles, preferences
- **What are they doing?** — current activity, workflows, history
- **What do they need?** — relevant data products, assets, dependencies
- **What is relevant right now?** — context-specific, time-sensitive information

## How to Use This Skill

Routes ALL data product and GDP questions to the GDP Supervisor via `start_gdp_job` + `check_gdp_job`. Never routes to any non-MCP tool.

Lineage, quality, entity and subject-area questions are **also** answered this way. They are not separate tools you call — you ask the Supervisor, and it reaches the graph on your behalf.

**Slash command:** `/data-product`

**Do NOT use for:** general SQL queries, Teradata metadata lookups, or questions unrelated to the Context Engine domain.

> **WARNING — TOOL BOUNDARY — READ THIS BEFORE EVERY ACTION**
>
> You have access to multiple tools. For EVERYTHING in this skill you MUST use
> ONLY the CE graph MCP server tools listed below. No exceptions, ever.
>
> **For workspace discovery:** ONLY call `list_workspaces` from the CE graph MCP
> server and show the exact results without makeup things. NEVER use SQL queries, `SELECT * FROM dbc.databases`, Teradata system
> tables, JDBC tools, or any other non-CE-MCP tool to find workspaces.
> Teradata database names are NOT Context Engine workspaces — they are completely
> different things. Using any other tool gives the user wrong workspace results.
> Do NOT combine results from multiple tools — use ONLY `list_workspaces` and
> nothing else.
>
> **For GDP questions:** ONLY use `start_gdp_job` and `check_gdp_job`.
> NEVER call any SQL tool, analyst tool, or non-MCP tool to answer data product
> questions — the GDP Supervisor handles everything internally.
>
> **When working on data product creation or any GDP task — DO NOT use any other
> tools outside the CE MCP server.** All tools required for data product creation,
> modelling, pipelines, and publication are already enabled inside the GDP
> Supervisor by default. You do not need to call any external tool — the
> Supervisor handles everything end-to-end.
>
> **The ONLY permitted tools in this skill — nothing else:**
> - `list_workspaces` — workspace discovery only
> - `start_gdp_job` — start a GDP job
> - `check_gdp_job` — poll a GDP job
> - `cancel_gdp_job` — cancel a GDP job

## When to Use

- You need to discover available workspaces
- You have a data product question — discovery, creation, modification, quality, lineage, pipelines
- You need to run or cancel a GDP Supervisor job

## Core Concepts

Every workspace-scoped tool requires a `workspace_id`. Without one, all CE tool
calls fail. Resolve the workspace **once per conversation** before any tool call.

| Tool | Purpose |
|------|---------|
| `list_workspaces` | Discover available workspace IDs and names but don't make up names or IDs — call once, not workspace-scoped, requires tenant-admin rights |
| `start_gdp_job` | Start a GDP Supervisor job — use for ALL data product and GDP questions |
| `check_gdp_job` | Poll a running job until terminal status — call it with `wait=15` so each call paces itself; returns the result when complete |
| `cancel_gdp_job` | Ask a running job to stop |

### Job statuses

| Status | Terminal? | Meaning |
|--------|-----------|---------|
| `PENDING` | no | Accepted and queued, not started yet |
| `RUNNING` | no | Supervisor is working |
| `CANCEL_REQUESTED` | no | A cancel was recorded; the job is still finishing. Keep polling |
| `COMPLETED` | yes | Finished successfully — `result` is present |
| `FAILED` | yes | Finished with an error — `error` is present |
| `CANCELLED` | yes | Stopped at the caller's request |
| `ORPHANED` | yes | The worker holding the job went away mid-run (deploy, restart, crash) before it could record an outcome. The work did not complete. Nothing is known about how far it got — offer to start it again |
| `PURGED` | yes | The record aged out of retention; the result is no longer available |

Treat any of the five terminal statuses as "stop polling".

## Procedure: Resolve Workspace

> **Use ONLY `list_workspaces` from the CE graph MCP server to discover workspaces and don't make up things just use what this tool gave you as a result to user.
> NEVER call any other tool — not SQL, not Teradata system tables, not JDBC, nothing else.
> Do NOT combine workspace results from multiple tools.
> Teradata database names are NOT Context Engine workspaces.**

Run this **once per conversation** before calling any workspace-scoped tool. Present results with `create_ui_app` (see step 2 below), never as raw text.

1. If the user named a workspace, use it and skip to the GDP procedure.
2. Otherwise call `list_workspaces()` and present an interactive workspace selector using `create_ui_app` — do not make up names or IDs, use only what the tool returns.

   **`create_ui_app` specification:**
   - `layout`: `"stack"`
   - No instructions section
   - **Header component:**
     - `title`: `"Workspace Selection"`
     - `badge`: `"[N] Available"` (where N is the count of workspaces returned)
     - `description`: brief one-sentence context of what the user wants to do
   - **Table component** (full-width, these columns only):
     | # | Workspace Name | Description | Business Domains |
     |---|---------------|-------------|-----------------|

   After rendering the UI app, write ONLY this in the chat (nothing else):
   *"Type the workspace number, name, or description to continue."*
3. If `list_workspaces` returns **403**, do NOT stop. Listing workspaces needs
   tenant-admin rights that running a job does not, so an ordinary user hits
   this while still being perfectly able to run GDP jobs. Ask the user for their
   workspace id directly and continue.
4. If `list_workspaces` fails for any other reason, say:
   *"I wasn't able to retrieve workspaces — please check that the Context Engine
   MCP server is connected, or tell me your workspace id and I'll continue."*
5. Store the resolved `workspace_id` for the rest of the conversation.

## Procedure: GDP Supervisor Job

Use for ALL data product and GDP questions, including:
- **Data product discovery** — what exists, who owns it, certification status, subject area
- **Data product creation** — build, model, generate, design a data product
- **Data product modification** — amend, update, publish, register a data product
- **Data product quality** — quality scores, failed checks, thresholds
- **Lineage** — upstream/downstream dependencies, lineage tracing
- **Pipelines** — run, schedule, govern a pipeline
- **Any other GDP Supervisor question**

1. **Start** — call `start_gdp_job(message=..., workspace_id=...)`.
   Record both `job_id` and `session_id` from the response exactly as returned.

2. **Check the returned status before polling.** If the call collapsed onto a run
   that had already finished, `status` is already terminal and `result` (or
   `error`) is already present — go straight to step 4.

3. **Poll** — call `check_gdp_job(job_id=<job_id>, wait=15)` repeatedly until
   `status` is terminal. Always pass `wait=15`: the call itself holds for that
   long on the server, which is what paces the polling. Do not add a sleep of
   your own, and do not call it in a tight loop — repeated immediate calls only
   burn tokens, because the answer cannot arrive before the work does. Do not
   give up after a single poll: a build legitimately takes many minutes, and
   `PENDING`, `RUNNING` and `CANCEL_REQUESTED` all mean "still going".

   A job that has already finished answers immediately whatever you passed, so
   `wait` never delays a result that is ready.

   While it runs, the response may carry a `progress` field — the most recent
   narration from the run. Relay it to the user between polls so they can see
   what is happening instead of a silent wait. It is a moving tail, not an
   answer: never present it as the result, and do not be surprised when it
   changes completely or disappears on the next poll.

   If you are still not terminal after roughly 30 minutes of polling (about 120
   checks at this cadence), stop polling and tell the user the job is still
   running, giving them the `job_id` so they can ask again later. The job is
   unaffected — it keeps running.

4. **Show result** — when `status` is `COMPLETED`:

   - Render ALL result content exclusively inside `create_ui_app`. **Nothing goes
     into the chat conversation text.** Do not repeat, summarise, or echo any part
     of the result in chat.
   - After the UI app renders, write ONLY a brief next-action prompt in chat — one
     sentence telling the user what they can do next (e.g. *"The results are ready
     above — let me know if you'd like to refine or continue."*).

   Detect the result shape and pick the matching component:

   | Result shape | `create_ui_app` component |
   |---|---|
   | Tabular data (rows + columns), including the source-to-target mapping table | `table` |
   | Narrative text, analysis, or mixed prose + structured data | `report` |

   **Table results** — use a `table` component. For the source-to-target mapping
   table specifically, use these exact columns and never collapse, omit, or skip
   any row:

   | Target Attribute | Source Column | Source URN | Confidence | Rationale |

   Unmapped attributes go at the bottom, clearly marked **UNMAPPED**.

   **Report results** — use a `report` component. Render the Supervisor's output
   verbatim without modification or summarisation unless the user asked for a
   summary. Structure multi-section responses with headings inside the report.

   If `result_truncated` is true, add a visible notice inside the `create_ui_app`
   output — the result was too large to return in full and the user is not seeing
   all of it.

5. **On failure** — if `status` is `FAILED`, `CANCELLED`, `ORPHANED` or
   `PURGED`, report the status and any `error` detail to the user verbatim.

6. **Session continuity** — on follow-up turns, pass `session_id` exactly as
   returned by `start_gdp_job`. Never pass `job_id` where `session_id` is
   expected. This matters: the schema lock and governance approvals live on the
   session, so a follow-up sent without it starts from scratch and cannot
   progress a build.

You do not need to supply any retry or idempotency key. Re-sending an identical
call while it is still running returns the SAME job rather than starting a
second one.

**Example:**

> User: *"Which autopay payments failed last cycle and how much is unpaid?"*
>
> 1. → `start_gdp_job(message="Which autopay payments failed last cycle and how much is unpaid?", workspace_id="ws-prod-01")`
> 2. → returns `{"job_id": "job_abc123", "session_id": "ses_xyz", "status": "PENDING", "poll_after_ms": 15000}`
> 3. → status is not terminal, so call `check_gdp_job(job_id="job_abc123", wait=15)` — the call itself takes ~15s
> 4. → status: "RUNNING", progress: "locating autopay source tables" — relay that to user, then poll again with `wait=15`
> 5. → status: "COMPLETED" — show `result` verbatim to user; render mapping table as markdown if present

## Procedure: Create Business Data Product

**Always run this procedure instead of going straight to creation.** Never skip
the similarity check — a duplicate data product wastes governance effort and
fragments the workspace.

### Step 1 — Check for similar products

Before any creation work, search for existing products that might match.

1. Call `start_gdp_job` with a discovery message that describes what the user
   wants to build. Example:
   *"Find existing data products similar to: [user's description]"*
2. Poll to completion with `check_gdp_job(wait=15)`.
3. Render the similarity results exclusively in `create_ui_app` using a `table`
   component. Nothing goes into the chat conversation text.

   **Table columns (in order):**
   | # | Product Name | Description | Business Domain | Owner | Match % |

   Sort rows by Match % descending. Include ALL returned candidates — do not
   filter or drop low-scoring ones.

4. In chat write only:
   *"[N] similar product(s) found. Would you like to use one as a template, or
   create from scratch?"*

### Step 2 — Template decision

- **If the user wants to use a template:** note which product they chose (by
  number, name, or description) and proceed to Step 3.
- **If no similar products were found OR the user prefers to start fresh:**
  skip to Step 4 (pre-creation verification).

### Step 3 — Load template and propose values

1. Call `start_gdp_job` asking the Supervisor to load the chosen product as a
   template and return all its editable field values.
2. Poll to completion.
3. Render the proposed values exclusively in `create_ui_app` as a `table`
   component with these columns:

   | Field | Current Value | Editable? |

   Pre-fill every field from the template. Mark non-editable fields clearly.

4. In chat write only:
   *"Review the values above. Tell me which fields you'd like to change before I
   create the product."*

### Step 4 — Pre-creation verification

Before submitting the creation job:

1. Collect any field overrides the user requested (in the current or previous
   turn).
2. Render the FINAL set of values in `create_ui_app` as a `table` component:

   | Field | Value |

   Include every field that will be submitted — no omissions.

3. In chat write only:
   *"Please confirm these values are correct. Reply 'yes' to create, or tell me
   what to change."*
4. **Do NOT call `start_gdp_job` for creation until the user explicitly
   confirms.** A single "yes", "looks good", or equivalent is sufficient.

### Step 5 — Create

Once confirmed, call `start_gdp_job` with the full creation intent and all
verified field values. Poll and render the result following the standard GDP
Supervisor Job procedure (step 4 above).

## Procedure: Cancel a Job

Cancellation is a **request, not a guarantee**, and it is never immediate.

- A job still queued stops before it starts.
- A job already running is asked to stop at its next opportunity, best-effort
  only. The request is always recorded, but work may continue for a while after.
- Keep polling `check_gdp_job` with `wait=15` until the status is terminal rather
  than assuming the job stopped. You will normally see `CANCEL_REQUESTED` first,
  then `CANCELLED`.
- It does **not** undo work already done. If a dbt build already ran or lineage
  was already registered, those effects stand — cancelling means "do no more",
  not "roll back". Tell the user this when they ask to cancel a build.
- Cancelling a job that has already finished is an **error, not a no-op**. If you
  get a 409 here, check the job's status — it has already reached a terminal
  state, and there is nothing to cancel.

## Error Handling

| Situation | Action |
|-----------|--------|
| Session already busy (409 from `start_gdp_job`) | The previous turn is still running. The error names the job holding the session as `active_job_id=<id>` — poll THAT id with `check_gdp_job` rather than retrying. Send the next turn only once it is terminal. Offer to cancel it if the user wants to abandon it |
| Capacity exceeded (429) | Inform the user the service is at capacity; retry after a short backoff |
| Job not found (404 from `check_gdp_job`) | Means no such job **in this workspace** — not that it finished. Check you are using the right `workspace_id` and passed `job_id` exactly as returned |
| Cancel rejected (409 from `cancel_gdp_job`) | The job already finished. Call `check_gdp_job` and report its terminal status |
| `list_workspaces` returns 403 | Expected for non-admin users. Ask the user for their workspace id and continue — job tools still work |
| `list_workspaces` fails otherwise | Tell user the MCP server may be disconnected; ask them to check the connector or supply a workspace id |
| `start_gdp_job` / `check_gdp_job` error | Surface the error verbatim and offer to cancel and retry |
| User's question is ambiguous | Ask one clarifying question before calling the tool |

## Tools

### Workspace discovery

| Tool | Parameters | Returns |
|------|-----------|---------|
| `list_workspaces` | `page`, `page_size`, `state`, `search` (all optional) | Page-based workspace list; not workspace-scoped; requires tenant-admin rights, so 403 is a normal outcome for ordinary users |

### GDP tools

All three return the same compact JSON shape; fields absent from a given
response are simply omitted.

| Tool | When to use | Parameters | Returns |
|------|------------|-----------|---------|
| `start_gdp_job` | All GDP and data product questions | `message` (required), `workspace_id` (optional), `session_id` (optional — pass to continue a conversation) | `job_id`, `session_id`, `status`, `poll_after_ms`; plus `result`/`error` if it collapsed onto an already-finished run |
| `check_gdp_job` | Poll a running job until terminal, always with `wait=15` | `job_id` (required), `wait` (seconds to hold the call, capped at 15, default 1), `workspace_id` (optional) | `job_id`, `session_id`, `status`, `poll_after_ms`; `progress` while running; once terminal, `result` (with `result_truncated`) or `error` |
| `cancel_gdp_job` | Ask a running job to stop | `job_id` (required), `workspace_id` (optional) | `job_id`, `status` |

Jobs are visible to the whole workspace, so a `job_id` a colleague started can
be polled here too.

`job_id` is NOT the `invocation_id` that `lock_schema`, `amend_model` and
`reopen_schema` take — those identify a model proposal, not a job. Passing one
where the other belongs will fail.

## How answers are delivered

The GDP Supervisor agent handles all data product and GDP questions end-to-end.
Start a job with `start_gdp_job`, poll with `check_gdp_job`, and the Supervisor
returns the complete answer when done.
Always show the source-to-target mappings after schema lock, rendered as a `table` component via `create_ui_app`.
Never apply emoticons to the response you show to the user.