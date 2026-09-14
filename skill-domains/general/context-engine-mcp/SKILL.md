---
name: context-engine-mcp
title: Teradata Context Engine MCP
description: 'The Teradata Context Engine is a software infrastructure layer that continuously collects, processes, stores, retrieves, and delivers relevant contextual information to applications and AI systems — enabling situation-aware decisions rather than treating each interaction in isolation. It acts as the situational awareness brain, answering: Who is the user? What are they doing? What do they need? What is relevant right now? This skill routes every data product, GDP, knowledge graph, lineage and data quality question to the GDP Supervisor, which answers all of them end-to-end. Use when asking about data products, GDP, entities, lineage, data quality. Triggers for /data-product command.'
when_to_use: 'Triggers on: data product, GDP, governed data product, knowledge graph, lineage, upstream, downstream, data quality, quality score, subject area, entity, element, context engine'
metadata:
  author: context-engine-team
  version: "2.1"
---

# Context Engine mcp (Go — 2026-07-28)

## What is the Context Engine?

The Teradata Context Engine is a software infrastructure layer that continuously collects, processes, stores, retrieves, and delivers relevant contextual information to applications and AI systems at the precise moment it's needed — enabling the system to make informed, situation-aware decisions rather than treating each interaction in isolation.

It acts as the **situational awareness brain** of a system, answering the fundamental questions:
- **Who is the user?** — identity, profile, roles, preferences
- **What are they doing?** — current activity, workflows, history
- **What do they need?** — relevant data products, assets, dependencies
- **What is relevant right now?** — context-specific, time-sensitive information

## How to Use This Skill

Routes ALL data product and GDP questions to the GDP Supervisor via `start_gdp_job`.
Progress and results are delivered automatically via push notifications, so no routine
polling is needed (`check_gdp_job` remains available as a fallback if pushes stop).

Lineage, quality, entity and subject-area questions are **also** answered this way.
They are not separate tools — you ask the Supervisor, and it reaches the graph on your behalf.

**Slash command:** `/data-product`

**Do NOT use for:** general SQL queries, Teradata metadata lookups, or questions unrelated to the Context Engine domain.

> **WARNING — TOOL BOUNDARY — READ THIS BEFORE EVERY ACTION**
>
> You have access to multiple tools. For EVERYTHING in this skill you MUST use
> ONLY the context-engine mcp server tools listed below. No exceptions, ever.
>
> **For workspace discovery:** ONLY call `list_workspaces` from the context-engine mcp
> server and show the exact results without making up things. NEVER use SQL queries,
> `SELECT * FROM dbc.databases`, Teradata system tables, JDBC tools, or any other
> non-CE-MCP tool to find workspaces. Teradata database names are NOT Context Engine
> workspaces — they are completely different things.
>
> **For GDP questions:** ONLY use `start_gdp_job`. NEVER call any SQL tool, analyst
> tool, or non-MCP tool. The GDP Supervisor handles everything internally.
>
> **When working on data product creation or any GDP task — DO NOT use any other
> tools outside the CE MCP server.** All tools required for data product creation,
> modelling, pipelines, and publication are already enabled inside the GDP
> Supervisor by default.
>
> **For GDP and data product questions, use ONLY these tools:**
> - `list_workspaces` — workspace discovery only
> - `start_gdp_job` — start a GDP Supervisor job (all data product questions)
> - `cancel_gdp_job` — stop a running job when the user asks to cancel
>
> The server also exposes graph read tools (search, lineage, schema, DQ/SLA) for
> direct graph queries, but all GDP and data product questions go through `start_gdp_job`.

## When to Use

- You need to discover available workspaces
- You have a data product question — discovery, creation, modification, quality, lineage, pipelines
- You need to run a GDP Supervisor job

## Core Concepts

Every workspace-scoped tool requires a `workspace_id`. Resolve it once per conversation.

| Tool | Purpose |
|------|---------|
| `list_workspaces` | Discover available workspace IDs and names — show exact results, do not make up names or IDs; call once, not workspace-scoped, requires tenant-admin rights |
| `start_gdp_job` | Start a GDP Supervisor job — use for ALL questions, fast or slow |

### How progress and results are delivered

This server uses the **2026-07-28 MCP spec**: results arrive by **push** (resource subscriptions), so you don't poll in the normal flow. `check_gdp_job` polling remains only as a fallback for when pushes stop or monitoring is degraded (see below).

1. `start_gdp_job` returns a `resource_uri` (e.g. `gdp://jobs/job_abc`) in the JSON and a `ResourceLink` MCP content item
2. Subscribe to that URI via `subscriptions/listen`
3. The server sends `notifications/resources/updated` when job status, progress, or thinking changes — and also as a periodic keepalive, so a notification does not always mean something changed
4. On each notification, always re-read the `resource_uri` resource to see what changed (if anything). Track `progress` and `thinking` **independently** and relay each one only when its own value differs from the last value you relayed for that field — `progress` is live Supervisor updates (tool activity or clarification prompts) and `thinking` is the Supervisor's extended-thinking reasoning while the job runs; both are moving tails that may change or clear between notifications, not the final answer. `thinking` is **cumulative** — each read contains everything so far, so relay only the newly-added portion since the value you last relayed, not the whole field again; it can shift as older reasoning ages out or resets between turns, so if you cannot cleanly diff, just show the current value
5. When the resource returns `status: completed`, show the `result` to the user

### Job statuses

| Status | Terminal? | Meaning |
|--------|-----------|---------|
| `working` | no | Job is PENDING, RUNNING, or CANCEL_REQUESTED — still going |
| `input_required` | no | The Supervisor needs clarification from the user before it can continue — ask the user the question in `progress` and pass the answer back via a follow-up `start_gdp_job` with the same `session_id` |
| `completed` | yes | Finished successfully — `result` is present |
| `failed` | yes | Finished with an error — `error` is present. Check `job_status` for the raw reason: `ORPHANED` means the worker crashed mid-run (offer to restart); `PURGED` means the record aged out of retention (offer to resubmit) |
| `cancelled` | yes | Stopped at the caller's request |

Treat `completed`, `failed`, and `cancelled` as terminal — stop waiting and show result or error.
Treat `input_required` as a pause — relay the question in `progress` to the user and continue the job with their answer.

## Procedure: Resolve Workspace

> **Use ONLY `list_workspaces` from the context-engine mcp server. Never call any other tool.
> Show results exactly as returned — do not make up names or IDs.
> Teradata database names are NOT Context Engine workspaces.**

Run this **once per conversation** before calling any workspace-scoped tool.

1. If the user named a workspace, use it and skip to the GDP procedure.
2. Otherwise call `list_workspaces()` and present an interactive workspace selector using `create_ui_app` — do not make up names or IDs, use only what the tool returns.

   **`create_ui_app` specification:**
   - `layout`: `"stack"`
   - **Header component:**
     - `title`: `"Workspace Selection"`
     - `badge`: `"[N] Available"` (where N is the count of workspaces returned)
     - `description`: brief one-sentence context of what the user wants to do
   - **Table component** (full-width, these columns only):

     | # | Workspace Name | Description | Business Domains |

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
   Record `job_id`, `session_id`, and `resource_uri` from the response.

2. **Check status before subscribing** — inspect the `status` field returned directly
   by `start_gdp_job`. If it is already `completed`, `failed`, or `cancelled`, skip
   directly to step 3 or 4 — do not subscribe or wait for push notifications.

   If status is `working`, subscribe to `resource_uri` via `subscriptions/listen` and
   wait for `notifications/resources/updated` push notifications. Some pushes are periodic
   keepalives, so on each one re-read the resource and relay `progress` or `thinking` only
   when its value changed since the one you last relayed — `thinking` shows the Supervisor's
   extended-thinking reasoning while the job runs and, like `progress`, is a moving tail that
   may change or clear between notifications.

   > **Progress and thinking messages are a live tail — not the answer.** Both may be
   > superseded or disappear between notifications. A push may carry `thinking` (Supervisor
   > reasoning), `progress` (live Supervisor updates — tool activity or clarification
   > prompts), or both — relay both to the user as they
   > arrive. Never treat either as the result.
   > Only `status: completed` with a populated `result` field is the authoritative answer.

   > **`monitoring: degraded`** — if a resource read returns `monitoring: "degraded"` and
   > a `poll_error` field, the Go server has temporarily lost sight of the job (e.g. a
   > brief network blip or a service restart). This is **NOT a job failure** — the job is
   > likely still running. Do NOT tell the user the job failed. Instead tell them:
   > *"I've temporarily lost connection to the job monitor — the job is still running.
   > I'll keep watching and update you when monitoring resumes."*
   > If pushes stop arriving entirely, re-subscribe to `resource_uri` to restart monitoring
   > with fresh credentials, or fall back to `check_gdp_job(job_id=...)` which queries
   > kp-service-layer directly and is unaffected by monitor state.

   > **Timeout fallback:** if no push notification arrives for approximately 30 minutes,
   > stop waiting. Tell the user: *"The job is still running but I've lost the connection.
   > Your job_id is `{job_id}` and session_id is `{session_id}` — ask me again later and
   > I'll resume from where we left off."* The job continues running unaffected.

3. **Show result** — when `status: completed`, render ALL result content exclusively
   inside `create_ui_app`. **Nothing goes into the chat conversation text.** After the
   UI app renders, write ONLY a brief next-action prompt in chat.

   Detect the result shape and pick the matching component:

   | Result shape | `create_ui_app` component |
   |---|---|
   | Source-to-target attribute mapping table | `table` |
   | Narrative text, analysis, or mixed prose + structured data | `report` |

   **Table results** — use a `table` component with these exact columns, never collapse
   or omit any row:

   | Target Attribute | Source Column | Source URN | Confidence | Rationale |

   Unmapped attributes go at the bottom, clearly marked **UNMAPPED**.

   **Report results** — use a `report` component. Render the Supervisor's output
   verbatim without modification or summarisation unless the user asked for a summary.

   If `result_truncated` is true, add a visible notice **inside the `create_ui_app`
   component** — the result was too large to return in full and the user is not seeing
   all of it.

4. **On failure** — if `status` is `failed` or `cancelled`, report the status and
   any `error` detail to the user verbatim. Check `job_status` for the raw reason:
   - `ORPHANED` — the worker crashed mid-run; offer to start the job again
   - `PURGED` — the record aged out of retention; offer to resubmit
   - Any other value — surface as-is

5. **Session continuity** — on follow-up turns, pass `session_id` exactly as
   returned by `start_gdp_job`. Never pass `job_id` where `session_id` is
   expected. This matters: the schema lock and governance approvals live on the
   session, so a follow-up sent without it starts from scratch and cannot
   progress a build.

   > **`X-Conversation-Id` header** — if your MCP client or adapter sets a stable
   > `X-Conversation-Id` header per user conversation, the server uses it as the
   > GDP `session_id` fallback when no explicit `session_id` argument is passed.
   > This keeps multi-turn builds connected across reconnects without the model
   > having to remember and replay the opaque `session_id` value. The explicit
   > `session_id` argument always takes priority.

You do not need to supply any retry or idempotency key. Re-sending the identical
call while it is still running returns the SAME job rather than starting a second one.

**Example:**

> User: *"Which autopay payments failed last cycle and how much is unpaid?"*
>
> 1. → `start_gdp_job(message="Which autopay payments failed last cycle and how much is unpaid?", workspace_id="ws-prod-01")`
> 2. → returns `{"job_id": "job_abc123", "session_id": "ses_xyz", "status": "working", "job_status": "PENDING", "poll_after_s": 15, "resource_uri": "gdp://jobs/job_abc123", "resource_link": "gdp://jobs/job_abc123", "result": "", "error": ""}`
> 3. → status is "working" — subscribe to `gdp://jobs/job_abc123` via `subscriptions/listen`
> 4. → push arrives: thinking: "the unpaid figure needs the failed-payment source joined to the mandate table" — relay to user, keep waiting
> 5. → push arrives: progress: "locating autopay source tables" — relay to user, keep waiting
> 6. → push arrives: progress: "analysing failures" — relay to user, keep waiting
> 7. → push arrives: status: "completed" — re-read resource, render result in `create_ui_app`; render mapping table if present

## Procedure: Create Business Data Product

**Always run this procedure instead of going straight to creation.** Never skip
the similarity check — a duplicate data product wastes governance effort and
fragments the workspace.

### Step 1 — Check for similar products

Before any creation work, search for existing products that might match.

1. Call `start_gdp_job` with a discovery message describing what the user wants to build.
   Example: *"Find existing data products similar to: [user's description]"*
2. Wait for push notifications and read the resource until `status: completed`.
3. Render the similarity results exclusively in `create_ui_app` using a `table` component.
   Nothing goes into the chat conversation text.

   **Table columns (in order):**

   | # | Product Name | Description | Business Domain | Owner | Match % |

   Sort rows by Match % descending. Include ALL returned candidates — do not filter or drop low-scoring ones.

4. In chat write only:
   *"[N] similar product(s) found. Would you like to use one as a template, or create from scratch?"*

### Step 2 — Template decision

- **If the user wants to use a template:** note which product they chose (by number, name, or description) and proceed to Step 3.
- **If no similar products were found OR the user prefers to start fresh:** skip to Step 4 (pre-creation verification).

### Step 3 — Load template and propose values

1. Call `start_gdp_job` asking the Supervisor to load the chosen product as a template and return all its editable field values.
2. Wait for push notifications until `status: completed`.
3. Render the proposed values exclusively in `create_ui_app` as a `table` component:

   | Field | Current Value | Editable? |

   Pre-fill every field from the template. Mark non-editable fields clearly.

4. In chat write only:
   *"Review the values above. Tell me which fields you'd like to change before I create the product."*

### Step 4 — Pre-creation verification

Before submitting the creation job:

1. Collect any field overrides the user requested (in the current or previous turn).
2. Render the FINAL set of values in `create_ui_app` as a `table` component:

   | Field | Value |

   Include every field that will be submitted — no omissions.

3. In chat write only:
   *"Please confirm these values are correct. Reply 'yes' to create, or tell me what to change."*
4. **DO NOT call `start_gdp_job` for creation until the user explicitly confirms.**
   A single "yes", "looks good", or equivalent is sufficient.

### Step 5 — Create

Once confirmed, call `start_gdp_job` with the full creation intent and all verified field values.
Wait for push notifications and render the result following the standard GDP Supervisor Job procedure above.

## Procedure: User Asks to Cancel

To actually stop a running job you MUST call the **`cancel_gdp_job`** tool. The event
subscription alone does not cancel anything — dropping the subscription only stops the
server *watching* the job; the job keeps running server-side until `cancel_gdp_job`
reaches it.

When the user says "cancel this" or "stop":
1. Call `cancel_gdp_job(job_id=..., workspace_id=...)`.
2. Tell the user: "Cancellation requested — the job will stop shortly. Work already completed is not rolled back."
3. Keep watching the subscription: while cancellation is pending, pushes show
   `status: working` (CANCEL_REQUESTED maps to working); the final push shows
   `status: cancelled` once the job has stopped.

Cancellation is a request, not a guarantee — work may continue briefly after the call.
It does **not** undo work already done. If a dbt build already ran or lineage
was already registered, those effects stand — cancelling means "do no more", not "roll back".

If the job has already finished (terminal status), `cancel_gdp_job` returns an
**error, not a no-op** — nothing is left to cancel. Check the last known status first.

## Error Handling

| Situation | Action |
|-----------|--------|
| Session already busy (409 from `start_gdp_job`) | The previous turn is still running. The error message contains `active_job_id=<id>` — extract that job ID, subscribe to `gdp://jobs/{active_job_id}` via `subscriptions/listen`, and wait for its push notifications. Resume the session once it completes. Offer to cancel it if the user wants to abandon it |
| Capacity exceeded (429) | Inform the user the service is at capacity; retry after a short backoff |
| Job not found (404) | Means no such job in this workspace — not that it finished. Check you are using the right `workspace_id` and the `job_id` exactly as returned |
| `list_workspaces` returns 403 | Expected for non-admin users. Ask the user for their workspace id and continue — job tools still work |
| `list_workspaces` fails otherwise | Tell user the MCP server may be disconnected; ask them to check the connector or supply a workspace id |
| `start_gdp_job` error | Surface the error verbatim and offer to retry |
| `status: failed` with `job_status: ORPHANED` | Worker crashed mid-run — offer to start the job again |
| `status: failed` with `job_status: PURGED` | Record aged out of retention — offer to resubmit |
| `monitoring: degraded` in resource read | Go server temporarily lost sight of the job — **NOT a job failure**. Tell user monitoring is degraded but job is still running. Re-subscribe to `resource_uri` to restart monitoring with fresh credentials, or fall back to `check_gdp_job(job_id=...)` |
| User asks to cancel mid-job | Call `cancel_gdp_job(job_id=..., workspace_id=...)`; inform the user work already done is not rolled back; keep watching the subscription until the `cancelled` push |
| Cancel rejected (409 from `cancel_gdp_job`) | Job already finished — nothing to cancel; report the last known terminal status instead |
| User's question is ambiguous | Ask one clarifying question before calling the tool |

## Tools

### Workspace discovery

| Tool | Parameters | Returns |
|------|-----------|---------|
| `list_workspaces` | `page`, `page_size`, `state`, `search` (all optional) | Page-based workspace list; not workspace-scoped; requires tenant-admin rights, so 403 is a normal outcome for ordinary users |

### GDP tools

| Tool | When to use | Parameters | Returns |
|------|------------|-----------|---------|
| `start_gdp_job` | ALL GDP and data product questions | `message` (required), `workspace_id` (optional), `session_id` (optional — pass to continue a conversation) | `job_id`, `session_id`, `resource_uri`, `status` (working/input_required/completed/failed/cancelled), `job_status` (raw service-layer value) |
| `cancel_gdp_job` | User asks to stop a running job | `job_id` (required), `workspace_id` (optional) | Cancel acknowledgement; job moves to CANCEL_REQUESTED then `cancelled`. Errors if the job already finished. Does NOT roll back completed work |

Progress and results arrive via push notifications on `resource_uri`.

**`gdp://jobs/{id}` resource read returns:**

| Field | Always present? | Meaning |
|---|---|---|
| `job_id` | yes | Job identifier |
| `session_id` | yes | Session identifier |
| `status` | yes | `working` / `input_required` / `completed` / `failed` / `cancelled` |
| `job_status` | yes | Raw uppercase from kp-service-layer (e.g. `RUNNING`, `COMPLETED`, `ORPHANED`) |
| `progress` | when running | Live progress message from the Supervisor |
| `thinking` | while the Supervisor reasons | Supervisor's extended-thinking reasoning between tool calls — a **cumulative** moving tail (each read contains everything so far; relay only the newly-added part) that may change or clear between reads; absent when the Supervisor is not actively reasoning |
| `result` | when completed | Final answer from the Supervisor |
| `error` | when failed | Error detail from kp-service-layer |
| `monitoring` | yes | `"ok"` normally; `"degraded"` if the Go server temporarily lost sight of the job |
| `poll_error` | when degraded | Why monitoring is degraded — this is NOT the job's error |

Jobs are visible to the whole workspace, so a `job_id` a colleague started can
be referenced in the same conversation if needed — a 404 means no such job in
this workspace, not that it finished.

`job_id` is NOT the `invocation_id` that `lock_schema`, `amend_model` and
`reopen_schema` take — those are Supervisor-internal tools, not tools you call directly.
Passing `job_id` where `invocation_id` is expected will fail.

## How answers are delivered

The GDP Supervisor agent handles all data product and GDP questions end-to-end.
Call `start_gdp_job` once and receive live progress and the final result via push notifications.
Always relay progress messages to the user as they arrive.
Always render results inside `create_ui_app` — never in the chat stream.
Always show the source to target mappings locked for the data product to the user after schema is locked,
rendered as a `table` component in `create_ui_app` with columns: Target Attribute | Source Column | Source URN | Confidence | Rationale.
Never apply emoticons to the response you show to the user.
 