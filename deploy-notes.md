# Deploy Notes — Snowflake side (Settlement Operations demo)

Running record of the Snowflake deployment: what was changed from the shipped zip, why, and what a future SC needs to know. Seed of the Phase 5 SC setup doc.

## Environment

- Shared Appian partner account: `a2770166725871` / `appian_partner`, locator `SP64200`, us-east-2 AWS. Snowsight URL confirms org/account; API hostname uses the HYPHENATED regionless form (underscores are invalid in hostnames and can break TLS in some clients): `a2770166725871-appian-partner.snowflakecomputing.com`. The locator form `sp64200.us-east-2.aws.snowflakecomputing.com` also works.
- Working role: **FINSERVADMIN** (day-to-day; owns the FINSERV database, CREATE SCHEMA + full Cortex privileges at schema level, but NO account-level CREATE WAREHOUSE/DATABASE). ACCOUNTADMIN granted to scott.thorn for account-level acts only — switch up, act, switch back down. Objects are owned by the creating role; never build as ACCOUNTADMIN.
- Warehouse: **COMPUTE_WH** (X-Small, auto-suspend 60, auto-resume) — created under ACCOUNTADMIN, USAGE+OPERATE granted to FINSERVADMIN. Matches the guide's assumed name so downstream files need no warehouse edits. (Earlier stopgap SYSTEM$STREAMLIT_NOTEBOOK_WH works for SQL but every Snowsight wizard refuses it; DEMO_WH was created in error and dropped.)
- **Per-SC setup requirement**: each SC gets their own account/user on this instance and connects with their own credentials. Each must: set their default warehouse (`ALTER USER <user> SET DEFAULT_WAREHOUSE = COMPUTE_WH;` — record types throw "no active warehouse" otherwise), generate their own PAT, and hold grants on the demo objects (FINSERVADMIN membership covers it today).

## Standing substitutions (applied to every shipped file)

- `APPIAN_DEMO` → `FINSERV` everywhere (database pre-provisioned to the role; account-level CREATE DATABASE unavailable). Applies to: create_schema.sql (CREATE DATABASE line deleted entirely), run_inference.sql, semantic_view.yaml (base_table database refs), agent_config.sql, Streamlit app location, and any future file from the zip.
- `COMPUTE_WH` needed no substitution after the warehouse was created under that exact name.

## Deployment deltas vs the shipped guide

- **CSV loads via stage + COPY INTO, not the Load Data wizard** — the wizard (and the stage file browser) refuse system warehouses and showed "no warehouse available" before COMPUTE_WH existed. Stage `CSV_STAGE` in the schema; files uploaded via Catalog stage UI (upload works without a warehouse; LISTING the stage needs one — verify uploads with `LIST @FINSERV.TRADE_SETTLEMENT.CSV_STAGE;` in a worksheet). COPY INTO with `SKIP_HEADER=1 FIELD_OPTIONALLY_ENCLOSED_BY='"'`. Loaded counts verified: 50 / 200 / 50,000 / 50,000.
- **Semantic view**: paste truncation in the Workspaces editor created a PARTIAL view that reported success (SHOW showed it existing; the agent then couldn't see fail columns). Rebuilt via TextEdit-assembled `CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML('FINSERV.TRADE_SETTLEMENT', $$<yaml>$$, FALSE);` pasted as one block. **Verify semantic views with `DESC SEMANTIC VIEW` and check for expected tables/fields — existence via SHOW proves nothing.** YAML gotchas per the guide: `metrics:` not `measures:`; epoch integers for `verified_at`; watch editor auto-indent on the first pasted line.
- **Agent smoke test**: the guide's two-string `DATA_AGENT_RUN` call is stale — the current API wants a structured request body (`$${"messages":[{"role":"user","content":[{"type":"text","text":"…"}]}]}$$`). Verified answer: 12.83% (6,416/50,000).
- **Streamlit**: deployed via the container-runtime dialog (compute pool `SYSTEM_COMPUTE_POOL_CPU`, query warehouse COMPUTE_WH), matching the original build's snowflake.yml, not the guide's warehouse-runtime suggestion. App `TRADE_SETTLEMENT_DASHBOARD` in FINSERV.TRADE_SETTLEMENT.
- **Zip hygiene**: the shipped zip contained the developer's Python venv (hidden folders; ~300MB incl. libllvmlite.dylib) which broke folder uploads. If re-downloading: strip `.venv`/`venv`/`__pycache__`/`.git`/`.DS_Store` before any upload. Flagged to Snowflake for a re-cut.

## MCP server

- `FINSERV.TRADE_SETTLEMENT.TRADE_SETTLEMENT_MCP`, created via CREATE MCP SERVER FROM SPECIFICATION. Tools: `trade_settlement_analyst` (type CORTEX_ANALYST_MESSAGE over TRADE_SETTLEMENT_ANALYTICS; input `message`), `settlement_risk_agent` (type CORTEX_AGENT_RUN over SETTLEMENT_RISK_AGENT; input `text`). Per-tool grants required on backing objects (SELECT on the semantic view, USAGE on the agent) — server USAGE alone does not confer tool access.
- Endpoint (no stored URL; deterministic pattern): `https://a2770166725871-appian-partner.snowflakecomputing.com/api/v2/databases/FINSERV/schemas/TRADE_SETTLEMENT/mcp-servers/TRADE_SETTLEMENT_MCP`
- Auth: PAT `appian_ny_mcp`, **restricted to role FINSERVADMIN** (never unrestricted — an unscoped PAT rides with ACCOUNTADMIN). Stored in password manager. **Expiry: 2027-08-26** (token `Appian_NY_MCP`, verified in Snowsight 2026-09-02; last used 2026-09-01). First PAT was exposed in a screenshot and rotated; never curl with a token visible in scrollback.
- Externally verified: curl `tools/list` with bearer PAT returns both tools with schemas.
- Adding a tool later (e.g. Phase 8 on-demand scoring) = edit the server's specification + grant on the new backing object.

## Appian-side connection facts

- `SO Snowflake Data Source` connected system: **Account Name field takes the bare identifier `a2770166725871-appian_partner`** (underscore fine here — it's not a hostname), NOT a URL. Role FINSERVADMIN, user, PAT as password. The MCP URL pasted there produces "Connection string is invalid."
- The native 26.6 template is **"Snowflake Data Source"**; the plain **"Snowflake"** tile is the AppMarket plugin (Operation dropdown, integration wizard) — never use it for record types.
- `SO Snowflake MCP` connected system: endpoint URL above, bearer auth with the PAT (one `Bearer` prefix — don't double it).
- Network policy: **`TRADE_SETTLEMENT_POLICY` is active at account level and is allow-all (`0.0.0.0/0`)** — required for PAT auth to work. Production hygiene: tighten to Appian egress IPs later; tracked, not urgent for demo use.
- Network: NY currently reaches Snowflake under a **24h network policy bypass**. **PENDING: permanent network policy from Daniel — the only hard external dependency.** When the bypass lapses, connected systems fail on schedule; that's expected, not a defect.

## Known failure modes and fallbacks

- MCP flake in a client room → REST/SQL fallback: `SNOWFLAKE.CORTEX.DATA_AGENT_RUN` through the data-source connection (structured body per above).
- Cortex hang → pre-scored batch already in TRADE_PREDICTIONS (inference is TRUNCATE-then-INSERT idempotent; rerun run_inference.sql to restore pristine predictions in one shot).
- Cold warehouse first-query lag (~5-10s) → pre-warm before showings.
- PAT expiry → regenerate, update the MCP connected system; expiry date above is the tripwire.

## Appian-side MCP servers and executing identity (2026-09-02)

Two Appian MCP servers are configured and **both surface under the same `mcp__appian__` tool namespace**, so a tool name does not reveal which server — or which identity — it runs as.

- **Dev MCP** (`lcp-mcp-server`, local): authenticates as **`scott.thorn`**; full design surface plus `SO Supervisors` scope. Tools are camelCase and unprefixed (`listRecordTypes`, `testRule`, `testProcessModel`, `listRecordData`, `createExpressionRule`). **This is the only server used for this project.**
- **Runtime MCP**: API key belonging to the **`scott.mcp` Service Account**, created for and scoped to the **Starwood** demo — a different application, with **no scope here**. Tools are snake_case with an `appian_` prefix (`appian_invoke_process_model`, `appian_data_fabric_sql_query`, `appian_search_tools`, `appian_get_tool_schema`, `appian_invoke_agent`, `appian_get_process_status`, `appian_data_fabric_metadata`), plus `ping`. **BANNED for this project, no exceptions.**

`scott.mcp` must never be granted group membership or scope in Settlement Operations. Measured consequence of using it here: row-secured reads return empty **silently** while PK-targeted writes still succeed, so a triage run completes green having read nothing and writes a forged escalation into the audit trail. Full detail in `build-log.md` (2026-09-02/03) and `CLAUDE.md`.
