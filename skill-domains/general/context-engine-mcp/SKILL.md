---
name: context-engine-mcp
title: Teradata Context Engine MCP
description: 'Query the Teradata Context Engine via polling — for legacy MCP clients (pre-2026-07-28) that cannot subscribe to resource notifications. Routes all data product, GDP, knowledge graph, lineage, and data quality questions to the GDP Supervisor. Results are obtained by polling check_gdp_job. Use when asking about data products, GDP, entities, lineage, data quality. Triggers for /data-product command.'
when_to_use: 'Triggers on: data product, GDP, governed data product, knowledge graph, lineage, upstream, downstream, data quality, quality score, subject area, entity, element, context engine'
metadata:
  author: context-engine-team
  version: "1.2"
---

# Context Graph MCP (Go — Legacy Polling)

> **LEGACY CLIENT SKILL — for MCP clients that pre-date the 2026-07-28 protocol.**
>
> This skill applies when your client CANNOT use `subscriptions/listen` or receive
> `notifications/resources/updated` push events. If your client supports those,
> use SKILL.md instead and ignore this file.
>
> Legacy polling path: `start_gdp_job` → `check_gdp_job(wait=15)` → repeat until terminal.

## What is the Context Engine?

The Teradata Context Engine is a software infrastructure layer that continuously collects, processes, stores, retrieves, and delivers relevant contextual information to applications and AI systems at the precise moment it is needed — enabling the system to make informed, situation-aware decisions rather than treating each interaction in isolation.

It acts as the **situational awareness brain** of a system, answering the fundamental questions:
- **Who is the user?** — identity, profile, roles, preferences
- **What are they doing?** — current activity, workflows, history
- **What do they need?** — relevant data products, assets, dependencies
- **What is relevant right now?** — context-specific, time-sensitive information

## How to Use This Skill

Routes ALL data product and GDP questions to the GDP Supervisor via `start_gdp_job`.

Because this client cannot receive push notifications, you poll progress using
`check_gdp_job` with `wait=15` until a terminal status is returned.

Lineage, quality, entity and subject-area questions are **also** answered this way.
They are not separate tools — you ask the Supervisor, and it reaches the graph on your behalf.

**Slash command:** `/data-product`

**Do NOT use for:** general SQL queries, Teradata metadata lookups, or questions unrelated to the Context Engine domain.

> **WARNING — TOOL BOUNDARY — READ THIS BEFORE EVERY ACTION**
>
> You have access to multiple tools. For EVERYTHING in this skill you MUST use
> ONLY the CE graph MCP server tools listed below. No exceptions, ever.
>
> **For workspace discovery:** ONLY call `list_workspaces` from the CE graph MCP
> server and show the exact results without making up things. NEVER use SQL queries,
> `SELECT * FROM dbc.databases`, Teradata system tables, JDBC tools, or any other
> non-CE-MCP tool to find workspaces. Teradata database names are NOT Context Engine
> workspaces — they are completely different things.
>
> **For GDP questions:** ONLY use `start_gdp_job` then `check_gdp_job`. NEVER call
> any SQL tool, analyst tool, or non-MCP tool. The GDP Supervisor handles everything
> internally.
>
> **When working on data product creation or any GDP task — DO NOT use any other
> tools outside the CE MCP server.** All tools required for data product creation,
> modelling, pipelines, and publication are already enabled inside the GDP Supervisor
> by default.
>
> **For GDP and data product questions, use ONLY these tools:**
> - `list_workspaces` — workspace discovery only
> - `start_gdp_job` — start a GDP Supervisor job (all data product questions)
> - `check_gdp_job` — poll an in-progress job (legacy polling path)
> - `cancel_gdp_job` — request cancellation of a running job

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
| `check_gdp_job` | Poll an in-progress job; pass `wait=15` so the server holds the connection for up to 15s before returning |
| `cancel_gdp_job` | Ask a running job to stop |

### How progress and results are delivered (legacy polling)

This client does NOT use resource subscriptions. Instead:

1. Call `start_gdp_job` — record `job_id` and `session_id` from the response.
2. **Check the `status` field immediately.** If it is already `completed`, `failed`, or `cancelled`, you are done — skip polling entirely.
3. If `status` is `working` or `input_required`, begin polling: call `check_gdp_job(job_id=..., wait=15, workspace_id=...)` in a loop.
4. On each poll response: relay any `progress` message to the user, then check `status`.

> **Progress messages are a live tail — not the answer.** They may be superseded or
> disappear between polls. Never treat a progress message as the result.
> Only `status: COMPLETED` with a populated `result` field is the authoritative answer.

> **`resource_uri` and `resource_link`** are present in the `start_gdp_job` response
> (e.g. `gdp://jobs/job_abc`). Legacy clients MUST ignore these fields and use
> `check_gdp_job` for polling instead.

> **Timeout fallback:** if polling has continued for approximately 30 minutes without
> a terminal status, stop polling. Tell the user: *"The job is still running but I have
> been waiting a long time. Your job_id is `{job_id}` and session_id is `{session_id}` —
> ask me again later and I will resume from where we left off."*
> The job continues running unaffected on the server.

### Job statuses

**Important:** `start_gdp_job` returns a lowercase mapped `status` field. `check_gdp_job` returns the raw **uppercase** status from kp-service-layer — no transformation applied.

| `start_gdp_job` status | `check_gdp_job` status | Terminal? | Meaning |
|------------------------|------------------------|-----------|---------|
| `working` | `PENDING` / `RUNNING` / `CANCEL_REQUESTED` | no | Job is in progress — keep polling |
| `input_required` | `INPUT_REQUIRED` | no | The Supervisor needs clarification — read the question from `progress`, ask the user, then pass their answer via a follow-up `start_gdp_job` with the same `session_id` |
| `completed` | `COMPLETED` | yes | Finished successfully — `result` is present |
| `failed` | `FAILED` | yes | Finished with an error — `error` is present; check `job_status` for the raw reason (`ORPHANED`, `PURGED`, etc.) |
| `cancelled` | `CANCELLED` | yes | Stopped at the caller's request |

Treat `completed`/`COMPLETED`, `failed`/`FAILED`, and `cancelled`/`CANCELLED` as terminal — stop polling and show result or error.

## Procedure: Resolve Workspace

> **Use ONLY `list_workspaces` from the CE graph MCP server. Never call any other tool.
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

## Procedure: GDP Supervisor Job (Legacy Polling)

Use for ALL data product and GDP questions, including:
- **Data product discovery** — what exists, who owns it, certification status, subject area
- **Data product creation** — build, model, generate, design a data product
- **Data product modification** — amend, update, publish, register a data product
- **Data product quality** — quality scores, failed checks, thresholds
- **Lineage** — upstream/downstream dependencies, lineage tracing
- **Pipelines** — run, schedule, govern a pipeline
- **Any other GDP Supervisor question**

1. **Start** — call `start_gdp_job(message=..., workspace_id=...)`.
   Record `job_id` and `session_id` from the response.
   The response also contains `resource_uri` and `resource_link` — **ignore these**;
   legacy clients use `check_gdp_job` for polling, not resource subscriptions.

2. **Check status immediately** — inspect the `status` field returned by `start_gdp_job`.
   - `completed`, `failed`, or `cancelled` → skip to step 4 or 5 — no polling needed.
   - `input_required` → skip to step 3b.
   - `working` → proceed to step 3.

3. **Poll** — call `check_gdp_job(job_id=..., wait=15, workspace_id=...)`.

   3a. Status is a working status (`PENDING`, `RUNNING`, `CANCEL_REQUESTED`): relay
       any `progress` message to the user, loop back to step 3.

   3b. Status is `INPUT_REQUIRED`: read the question from the `progress` field and ask
       it to the user. Once they reply, call `start_gdp_job` again with the same
       `session_id` and the user's answer as `message`. Return to step 2.

   3c. Status is terminal (`COMPLETED`, `FAILED`, `CANCELLED`): proceed to step 4 or 5.

   > **`check_gdp_job` returns raw uppercase status.** Do not expect lowercase values.

4. **Show result** — when status is `COMPLETED`, render ALL result content exclusively
   inside `create_ui_app`. **Nothing goes into the chat conversation text.** After the
   UI app renders, write ONLY a brief next-action prompt in chat.

   Detect the result shape and pick the matching component:

   | Result shape | `create_ui_app` component |
   |---|---|
   | Source-to-target attribute mapping table | `table` |
   | Narrative text, analysis, or mixed prose + structured data | `report` |

   **Table results** — use a `table` component with these exact columns, never collapse or omit any row:

   | Target Attribute | Source Column | Source URN | Confidence | Rationale |

   Unmapped attributes go at the bottom, clearly marked **UNMAPPED**.

   **Report results** — use a `report` component. Render the Supervisor's output verbatim
   without modification or summarisation unless the user asked for a summary.

   If `result_truncated` is true, add a visible notice **inside the `create_ui_app`
   component** — the result was too large to return in full and the user is not seeing all of it.

5. **On failure** — if status is `FAILED` or `CANCELLED`, report the status and any
   `error` detail to the user verbatim. Check `job_status` for the raw reason:
   - `ORPHANED` — the worker crashed mid-run; offer to start the job again
   - `PURGED` — the record aged out of retention; offer to resubmit
   - Any other value — surface as-is

6. **Session continuity** — on follow-up turns, pass `session_id` exactly as returned
   by `start_gdp_job`. Never pass `job_id` where `session_id` is expected. The schema
   lock and governance approvals live on the session, so a follow-up without it starts
   from scratch and cannot progress a build.

You do not need to supply any retry or idempotency key. Re-sending the identical call
while it is still running returns the SAME job rather than starting a second one.

**Example:**

> User: *"Which autopay payments failed last cycle and how much is unpaid?"*
>
> 1. → `start_gdp_job(message="Which autopay payments failed last cycle and how much is unpaid?", workspace_id="ws-prod-01")`
> 2. → returns `{"job_id": "job_abc123", "session_id": "ses_xyz", "status": "working", "job_status": "PENDING", "poll_after_s": 15, "resource_uri": "gdp://jobs/job_abc123", "resource_link": "gdp://jobs/job_abc123"}` — ignore resource_uri/resource_link
> 3. → status is "working" — begin polling
> 4. → `check_gdp_job(job_id="job_abc123", wait=15, workspace_id="ws-prod-01")`
> 5. → returns `{"status": "RUNNING", "progress": "locating autopay source tables"}` — relay progress to user, keep polling
> 6. → `check_gdp_job(job_id="job_abc123", wait=15, workspace_id="ws-prod-01")`
> 7. → returns `{"status": "COMPLETED", "result": "..."}` — render result in `create_ui_app`

## Procedure: Create Business Data Product

**Always run this procedure instead of going straight to creation.** Never skip
the similarity check — a duplicate data product wastes governance effort and
fragments the workspace.

### Step 1 — Check for similar products

1. Call `start_gdp_job` with a discovery message describing what the user wants to build.
   Example: *"Find existing data products similar to: [user's description]"*
2. Poll with `check_gdp_job(wait=15)` until `COMPLETED`. Relay progress as it arrives.
3. Render similarity results exclusively in `create_ui_app` using a `table` component.
   Nothing goes into the chat conversation text.

   **Table columns (in order):**

   | # | Product Name | Description | Business Domain | Owner | Match % |

   Sort rows by Match % descending. Include ALL returned candidates — do not filter or drop low-scoring ones.

4. In chat write only:
   *"[N] similar product(s) found. Would you like to use one as a template, or create from scratch?"*

### Step 2 — Template decision

- **If the user wants to use a template:** note which product they chose and proceed to Step 3.
- **If no similar products were found OR the user prefers to start fresh:** skip to Step 4.

### Step 3 — Load template and propose values

1. Call `start_gdp_job` asking the Supervisor to load the chosen product as a template.
2. Poll with `check_gdp_job(wait=15)` until `COMPLETED`. Relay progress as it arrives.
3. Render proposed values exclusively in `create_ui_app` as a `table` component:

   | Field | Current Value | Editable? |

   Pre-fill every field from the template. Mark non-editable fields clearly.

4. In chat write only:
   *"Review the values above. Tell me which fields you'd like to change before I create the product."*

### Step 4 — Pre-creation verification

1. Collect any field overrides the user requested.
2. Render the FINAL set of values in `create_ui_app` as a `table` component:

   | Field | Value |

   Include every field that will be submitted — no omissions.

3. In chat write only:
   *"Please confirm these values are correct. Reply 'yes' to create, or tell me what to change."*
4. **DO NOT call `start_gdp_job` for creation until the user explicitly confirms.**

### Step 5 — Create

Once confirmed, call `start_gdp_job` with the full creation intent and verified field values.
Poll with `check_gdp_job(wait=15)` until terminal and render the result per the standard procedure above.

## Procedure: User Asks to Cancel

1. Call `cancel_gdp_job(job_id=..., workspace_id=...)`.
2. Tell the user: *"Cancellation requested — the job will stop shortly. Work already completed is not rolled back."*
3. Keep polling `check_gdp_job(job_id=..., wait=15)` until terminal (`COMPLETED`, `FAILED`, or `CANCELLED`).
4. Report the final status to the user.

Cancellation does **not** undo work already done. If a dbt build already ran or lineage
was already registered, those effects stand — cancelling means "do no more", not "roll back".

If the job has already finished, `cancel_gdp_job` returns a **409 error** — nothing is left
to cancel. Call `check_gdp_job` and report the terminal status instead.

## Error Handling

| Situation | Action |
|-----------|--------|
| Session already busy (409 from `start_gdp_job`) | The previous turn is still running. The error message contains the suffix `(active_job_id=<uuid>)` — extract that job ID and poll it with `check_gdp_job(job_id=<active_job_id>, wait=15, workspace_id=...)` until terminal. Resume the session once it completes. Offer to cancel if the user wants to abandon it |
| Capacity exceeded (429) | Inform the user the service is at capacity; retry after a short backoff |
| Job not found (404) | Means no such job in this workspace — not that it finished. Check you are using the right `workspace_id` and `job_id` exactly as returned |
| `list_workspaces` returns 403 | Expected for non-admin users. Ask the user for their workspace id and continue — job tools still work |
| `list_workspaces` fails otherwise | Tell user the MCP server may be disconnected; ask them to check the connector or supply a workspace id |
| `start_gdp_job` error | Surface the error verbatim and offer to retry |
| `status: failed` / `FAILED` with `ORPHANED` in `job_status` | Worker crashed mid-run — offer to start the job again |
| `status: failed` / `FAILED` with `PURGED` in `job_status` | Record aged out of retention — offer to resubmit |
| `input_required` (start_gdp_job) or `INPUT_REQUIRED` (check_gdp_job) | Read the question from `progress`, ask the user, pass their answer via `start_gdp_job` with same `session_id` |
| Cancel rejected (409 from `cancel_gdp_job`) | Job already finished — call `check_gdp_job` and report its terminal status |
| User's question is ambiguous | Ask one clarifying question before calling the tool |

## Tools

### Workspace discovery

| Tool | Parameters | Returns |
|------|-----------|---------|
| `list_workspaces` | `page`, `page_size`, `state`, `search` (all optional) | Page-based workspace list; not workspace-scoped; requires tenant-admin rights, so 403 is a normal outcome for ordinary users |

### GDP tools

#### start_gdp_job

Starts a GDP Supervisor job. Use for ALL data product and GDP questions.

**Parameters:** `message` (required), `workspace_id` (optional), `session_id` (optional — pass to continue a conversation)

**Returns:**

| Field | Type | Notes |
|-------|------|-------|
| `job_id` | string | Unique job identifier |
| `session_id` | string | Conversation session — pass on follow-up turns |
| `status` | string | Lowercase mapped: `working`, `input_required`, `completed`, `failed`, `cancelled` |
| `job_status` | string | Raw uppercase from kp-service-layer: `PENDING`, `RUNNING`, `FAILED`, `ORPHANED`, `PURGED`, etc. |
| `poll_after_s` | integer | Suggested polling interval in **seconds** (not milliseconds) |
| `resource_uri` | string | `gdp://jobs/{id}` — **legacy clients: ignore** |
| `resource_link` | string | Alias for `resource_uri` — **legacy clients: ignore** |
| `result` | string | Populated when `status` is `completed` |
| `error` | string | Populated when `status` is `failed` |

> **`poll_after_s` is in seconds.** Do not multiply by 1000. The field name is `poll_after_s` — not `poll_after_ms`.

#### check_gdp_job

Polls an in-progress job. For legacy clients only. Always pass `wait=15`.

**Parameters:** `job_id` (required), `wait` (seconds, capped at 15 — always pass 15), `workspace_id` (optional)

**Returns:** Raw pass-through of kp-service-layer response — no field transformation by the Go server.

| Field | Type | Notes |
|-------|------|-------|
| `job_id` | string | Job identifier |
| `session_id` | string | Session identifier |
| `status` | string | **Raw uppercase**: `PENDING`, `RUNNING`, `COMPLETED`, `FAILED`, `CANCELLED`, `CANCEL_REQUESTED`, `INPUT_REQUIRED` |
| `progress` | string | Human-readable progress or clarification question (present when `INPUT_REQUIRED`) |
| `result` | string | Populated when `COMPLETED` |
| `result_truncated` | boolean | Present if service-layer sends it — result was too large to return in full |
| `error` | string | Populated when `FAILED` |

> **`check_gdp_job` does NOT transform status.** Values are raw uppercase. This differs from `start_gdp_job`.

#### cancel_gdp_job

Requests cancellation of a running job. For legacy clients only.

**Parameters:** `job_id` (required), `workspace_id` (optional)

**Returns:** Raw pass-through of kp-service-layer cancel response.

## How answers are delivered

The GDP Supervisor agent handles all data product and GDP questions end-to-end.
Call `start_gdp_job` once and poll using `check_gdp_job(wait=15)` until terminal.
Always relay progress messages to the user as they arrive between polls.
Always render results inside `create_ui_app` — never in the chat stream.
Always show the source-to-target mappings locked for the data product to the user after schema is locked,
rendered as a `table` component in `create_ui_app` with columns: Target Attribute | Source Column | Source URN | Confidence | Rationale.
Never apply emoticons to the response you show to the user.