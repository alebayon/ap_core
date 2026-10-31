# ap_core

Shared Accounts Payable dbt package for invoice spine, match, neutral timing, and treasury arbitration. Product KPIs live in separate repos.

## Disclaimer

This project is for educational and demonstration purposes. The datasets are made to have realistic dates, amounts, and process variants. All data is synthetic, no real invoices, vendors, or company systems are used. Policies and process design are illustrative, not copied from any employer or client.

## Context

I've worked several years in Finance Operations using Process Mining. One of the things I often struggled with is how little control we had over process logic and data quality in large, complex models. Process Mining tools often focus on customer experience, fast and effective dashboarding, and multiple possibilities of executions. What I often miss is having a modular, comprehensive, and scalable quality and modeling control system. This is what I've found in dbt, an open-source tool for developing data models with end-to-end modular testing against the warehouse.

Analytics Engineering is the discipline centered on that layer: data modeling and the transformations between raw sources and dashboard-ready KPIs. It sits between Data Engineering (platforms and pipelines) and business analysis (functional specifications), where ownership of business rules is often split and neither side alone owns end-to-end logic.

The Analytics Engineer closes that gap by making transformations deterministic and explainable. When the model is trustworthy, stakeholders challenge the process, not the dashboard.

I'm building a series of dbt data solutions inspired by my Process Mining background, each addressing a major common business problem. ap_core is the shared backbone those products install as a package so invoice grain, match, and neutral process timing stay consistent while each product owns its own KPI funnel and marts.

## Project Goal

This project simulates an Accounts Payable domain at the shared layer. It is not a final business product. It is the common foundation for several AP analytics products that reuse the same SAP invoice grain, Coupa workflow evidence, cross-system match, and neutral timing instrumentation.

It delivers a tested data and domain model as baseline for:

- cash_discount — released (https://github.com/alebayon/cash_discount)
- on_time_payments — work in progress
- working_capital_optimizer — pending
- operational_cockpit — pending

Products depend on ap_core. They do not depend on each other for primary KPIs.

## How products consume ap_core

Publish and develop this repo as the dbt package `ap_core` (release tag v0.1.0 on GitHub). A product repo lists the package in `packages.yml`, runs `dbt deps`, and references models with `ref('ap_core', 'model_name')`.

Example consumer build (cash_discount):

    dbt build --select +tag:cash_discount

The leading `+` builds package ancestors (core) first. Do not use `tag:cash_discount+` when the goal is upstream core before product models.

Package repository: https://github.com/alebayon/ap_core

## Design rationale

This README is the public architecture summary (scope, layers, SAP vs Coupa, timing boundary, arbitration, how products consume the package).

Maintainer decision log (grains, columns, shared policy, naming, model inventory): [docs/core_decisions.md](docs/core_decisions.md) in this repo.

Product-specific KPI and funnel choices live in each product repo (for example [cash_discount](https://github.com/alebayon/cash_discount) README and architecture docs).

## Term definitions

Terms below describe the shared layer. Product-specific funnel and leakage language lives in each product README (for example cash_discount).

Arbitration (CD/WCO): Treasury-style gates on top of structurally valid discount terms — minimum potential discount EUR and maximum cash-acceleration days — plus a payment strategy label for downstream products.

Blocker: A labeled reason (hold, rework, payment block) with a date range (overlay) that explains delay inside a phase.

Coupa posting ref: SAP field used as an input to matching. It is not a substitute for map_inv_sap_coupa.

Data/domain model: AP architecture spanning this package and product extensions at the same invoice grain.

Dataset: Synthetic demo extracts (raw_* seeds) plus reference seeds for payment terms, maps, overlay reasons, and arbitration policy.

Dbt model: Materialized object (table, view, or ephemeral) with its own .sql file. Core models are tagged `core` in this repo.

Grain: What one row represents. The anchor grain is one row per in-scope SAP vendor invoice (`sap_inv_key`).

Map (match): Confirmed link between a SAP invoice and a Coupa invoice at posting, keyed for joins on the spine.

Neutral timing: Phase spans and observed blocker intervals without product KPIs, leakage amounts, or euro allocation.

Overlay: Dated interval for a blocker reason on an invoice.

Phase: Time division in invoice lifecycle. Ownership level (pre_sap, payment) and subprocess level (intake, verification, approval, interface) are modeled in fct_inv_timing_span.

SAP invoice spine: fct_inv_sap_core — terms, dates, amounts, clearing facts, map-based Coupa fields, neutral elapsed days. No reporting-period gates or product leakage flags.

Span: Calendar days elapsed in a phase (neutral clock for timing diagnostics).

## Architecture design overview

The shared model is built around posted vendor invoices in accounts payable. One row per payable vendor invoice in SAP (`sap_inv_key`) is the anchor for every downstream product.

SAP carries invoice identity, amounts, payment terms, posting and clearing dates, and discount taken at clearing. Coupa carries pre-SAP receipt and workflow evidence and change history. When the same attribute exists in both systems, products treat SAP as the system of record for payable and clearing facts. Coupa supports process diagnosis before and through posting.

Cross-system enrichment on the spine uses map_inv_sap_coupa for `coupa_id` and `receipt_date`. Do not bypass the map with posting reference alone.

### Design principles

#### Invoice-centric spine

Facts and neutral timing roll up to invoice grain. Event-level change tables feed overlays and history. Headline KPI marts belong in product repos, not in core.

#### SAP authoritative for payable facts

Terms, deadlines, clearing, and discount captured at clearing come from the spine. Coupa does not redefine those facts for core consumers.

#### Coupa for process evidence

Coupa invoices, statuses, and changes explain pre-SAP and workflow time. Core stores them for match and timing, not for product numerators.

#### Shared policy, product scope

CD/WCO arbitration policy and facts live in core because both cash discount and working-capital-style products need the same gates. Processing-day attribution thresholds and leakage waterfalls stay in cash_discount only.

#### Bounded system scope

Only SAP and Coupa are modeled. Logic and data are synthetic. Additional source systems are out of scope for this showcase.

### Minimum model grains

| Grain | Purpose |
| ----- | ------- |
| Invoice (header) | One row per SAP vendor invoice — spine, arbitration, neutral timing joins |
| Change / event | One row per status or field change — overlay construction |
| Supplier (master) | One row per vendor or Coupa supplier — names and attributes (inactive rows kept) |
| Match | One confirmed SAP ↔ Coupa pair at posting |
| Timing span / overlay | Phase intervals and blocker intervals on an invoice |

Reporting-period aggregates and product KPI grains are implemented in product repos.

### What core deliberately excludes

- Reporting-period paid gates and product entitlement flags (`is_kpi_entitled`, and similar)
- Cash discount leakage, primary cause, lost discount EUR
- On-time payment lateness KPIs
- Timing euro allocation and action marts
- Product-only overlays such as payment_run_wait (cash_discount)

### How this document is organized

- Policy — shared CD/WCO arbitration thresholds
- Design layers — seeds, src, dim, map, int, fct in this repo
- Build process — how the shared layer grew and was packaged
- Implementation — local develop and test commands
- Model inventory — core tables and seeds
- Product extensions — how repos add fct_inv_sap_cd and related models

## Design layers

All models below are in this repository and carry the dbt tag `core` unless noted.

### Seeds

- raw_*: Synthetic SAP and Coupa extracts (invoices, vendors, change history).
- seed_payment_term_sap: Payment term reference (discount and net days).
- seed_cd_wco_arbitration_policy: Treasury gates and effective dating for arbitration.
- seed_coupa_status_map, seed_sap_payment_block_map, seed_timing_overlay_reason_map: Reference maps for workflow and overlay labeling.

Product attribution seeds (for example processing-day thresholds for cash discount) stay in product repos.

### SRC (src_*)

Views — rename, cast, trim source-style columns. No KPI business rules.

### DIM (dim_vendor_*)

Vendor and supplier master. Inactive suppliers are retained with `is_active` (and Coupa `status`) so historical invoices keep valid keys.

### MAP (map_inv_sap_coupa)

Confirmed SAP invoice ↔ Coupa match at posting. Single front door for Coupa fields on the spine.

### INT (int_*)

Ephemeral interval builders — Coupa overlay intervals and SAP payment-block intervals — inputs to observed overlays.

### FCT (core facts)

- fct_inv_sap_core — Invoice spine and public contract for all products.
- fct_inv_cd_wco_arbitration — Arbitration gates and payment_strategy.
- fct_inv_coupa, fct_inv_coupa_changes, fct_inv_sap_changes — Coupa and SAP process streams.
- fct_inv_timing_span — Neutral ownership and subprocess phase spans.
- fct_inv_timing_overlay_core — Observed Coupa and SAP block intervals only.

No product marts, leakage waterfall, or timing euro allocation in this package.

### Product extensions (not in this repo)

Products add same-grain facts that ref core spines, for example:

| Core | Product example | Role |
| ---- | ----------------- | ---- |
| fct_inv_sap_core | fct_inv_sap_cd (cash_discount) | KPI funnel, leakage, primary cause |
| fct_inv_timing_overlay_core | fct_inv_timing_overlay_cd | Union observed overlays plus product-only rows |
| — | fct_inv_sap_otp (planned) | On-time payment on net due date |
| — | fct_inv_sap_wco (planned) | Strategy compliance vs payment_strategy |

Naming pairs (`*_core` / `*_cd`) mark cross-package contracts. Marts and allocation facts in product repos usually have no `_cd` suffix when they are not spine pairs.

## Policy attributions

Shared treasury arbitration (seed_cd_wco_arbitration_policy, fct_inv_cd_wco_arbitration). Evaluated on structurally discount-eligible terms using document date for policy effective dating in the demo.

1. Minimum potential discount EUR: Ignore cash discount targets when the euro saving is below program materiality. Default: 10 EUR on potential discount (`invoice_amount_eur * discount_pct`).
2. Maximum cash acceleration days: Ignore cash discount targets when paying by the discount deadline would accelerate cash by more than the allowed calendar days versus net due. Default: 20 days inclusive (`discount_deadline_date` to `net_due_date`).
3. Payment strategy: When gates pass, label `pursue_cd`. When a gate fails, label `target_net` and expose `not_cd_eligible_reason` (first failing gate wins when terms qualify for arbitration).

Cash discount consumes `is_cd_eligible` in its KPI entitled population. On-time payment does not use arbitration in its first version. Working capital products can reuse `payment_strategy` without redefining gates.

Processing-day thresholds and leakage ownership rules are not in ap_core. They live in cash_discount (seed_attribution_policy on fct_inv_sap_cd).

## Build process overview

The shared layer was built in dependency order inside the original monorepo, then extracted as package v0.1.0 (2026-10-26). Product repos pin the tag and drop duplicate core SQL.

### SAP invoice foundation

- Landed synthetic SAP invoice and vendor extracts and payment-term reference data.
- Defined fct_inv_sap_core at one row per payable vendor invoice with terms, discount and net dates, clearing facts, and neutral elapsed days.

### Coupa and cross-system match

- Added Coupa invoice and change streams for workflow evidence.
- Built map_inv_sap_coupa so spine rows gain mapped coupa_id and receipt_date without using posting ref as the join.

### Neutral timing

- Measured ownership phases (pre-SAP and payment through clearing) and subprocess phases from Coupa events.
- Added observed blocker overlays from Coupa holds or rework and SAP payment blocks (fct_inv_timing_overlay_core).

### CD/WCO arbitration

- Centralized treasury gates in seed and fct_inv_cd_wco_arbitration so cash discount and future WCO share one fact at invoice grain.

### Package extract

- Published ap_core v0.1.0 on GitHub with models, seeds, core tests, and docs/core_decisions.md.
- cash_discount pins the package and references core with ref('ap_core', …). Verified with dbt build --select +tag:cash_discount.

### How tests evolved

- Schema and relationship tests on core YAML guard grain and keys.
- Singular tests guard synthetic curriculum rows (match, spine counts, arbitration heroes, timing reconciliation).
- Product curriculum tests remain in product repos after extract.

## Implementation

Develop this package standalone or as the source for tagged releases.

Profile: ap_core in ~/.dbt/profiles.yml (Snowflake target as configured locally). You can reuse the same database as product projects and use a dedicated schema if you want isolated tables.

From the package root:

    dbt debug
    dbt build

Build only core-tagged nodes:

    dbt build --select tag:core

Release: tag the git repo (for example v0.1.0). Consumers set revision in packages.yml and run dbt deps in the product project.

Tests and credentials: core tests ship in this repo. profiles.yml is not committed.

## Model inventory

Update row counts in docs/core_decisions.md after material changes. Summary of core objects:

### Tier A — spine, match, arbitration, timing

#### fct_inv_sap_core

Description: SAP vendor invoice spine — identity, terms, dates, amounts, clearing, map-based Coupa fields, neutral elapsed days.

Grain: one row per sap_inv_key (in-scope vendor invoice, KR with vendor present in demo).

Sources: src_inv_sap, seed_payment_term_sap, map_inv_sap_coupa.

Consumed by: all product invoice facts, fct_inv_cd_wco_arbitration, fct_inv_timing_span, timing overlays.

Not on spine: reporting-period gates, leakage, primary cause, product attribution diagnostics.

---

#### fct_inv_cd_wco_arbitration

Description: CD/WCO treasury gates and payment_strategy at invoice grain.

Grain: one row per sap_inv_key aligned to spine.

Sources: fct_inv_sap_core, seed_cd_wco_arbitration_policy.

Notable outputs: potential_discount_eur, cash_acceleration_days, is_cd_eligible, not_cd_eligible_reason, payment_strategy.

Consumed by: fct_inv_sap_cd (cash_discount), future WCO fact.

---

#### map_inv_sap_coupa

Description: Confirmed SAP ↔ Coupa match at posting.

Grain: match grain (sap_inv_key with coupa_id).

Consumed by: fct_inv_sap_core enrichment.

---

#### fct_inv_timing_span

Description: Neutral phase spans — ownership and subprocess clocks.

Grain: span rows per invoice and phase definition.

Sources: fct_inv_sap_core, Coupa change logic, span rules in SQL.

Consumed by: product timing allocation and phase profile marts (via package ref).

---

#### fct_inv_timing_overlay_core

Description: Observed blocker intervals from Coupa and SAP payment blocks only.

Grain: sap_inv_key × overlay reason × interval sequence.

Sources: int_inv_coupa_overlay_intervals, int_inv_sap_payment_block_intervals, reason maps.

Consumed by: fct_inv_timing_overlay_cd union in cash_discount.

---

### Tier B — streams, dimensions, staging

| Model | Grain | Role |
| ----- | ----- | ---- |
| fct_inv_coupa | coupa invoice | Coupa invoice fact |
| fct_inv_coupa_changes | change event | Coupa workflow history |
| fct_inv_sap_changes | change event | SAP posting change history |
| dim_vendor_sap / dim_vendor_coupa | vendor / supplier | Master data, inactive retained |
| src_* | source row | Staging views from raw seeds |
| int_inv_coupa_overlay_intervals | interval | Ephemeral Coupa overlay builder |
| int_inv_sap_payment_block_intervals | interval | Ephemeral SAP block builder |

### Seeds (reference and demo)

| Seed | Role |
| ---- | ---- |
| raw_inv_sap, raw_vendor_sap, raw_inv_sap_changes | SAP demo extract |
| raw_inv_coupa, raw_vendor_coupa, raw_inv_coupa_changes | Coupa demo extract |
| seed_payment_term_sap | SAP payment terms |
| seed_cd_wco_arbitration_policy | Arbitration thresholds |
| seed_coupa_status_map, seed_sap_payment_block_map, seed_timing_overlay_reason_map | Labeling and overlay metadata |

Full column contract and row-count notes: docs/core_decisions.md (Model inventory section).

## Sample consumers

cash_discount adds fct_inv_sap_cd, timing overlay union, allocation, and marts on top of this package. See its README for funnel, leakage, and build commands.

No sample PDF lives in ap_core. Product repos own stakeholder reports.
