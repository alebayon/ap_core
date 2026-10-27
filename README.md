# ap_core

Personal dbt project to sustain a series of data analytic and operational products related to Accounts Payable domain

## Disclaimer

This project is for educational and demonstration purposes. The datasets are made to have realistic dates, amounts, and process variants. All data is synthetic, no real invoices, vendors, or company systems are used. Policies and process design are illustrative, not copied from any employer or client.

## Context

I've worked several years in Finance Operations using Process Mining. One of the things I often struggled with is how little control we had over process logic and data quality in large, complex models. Process Mining tools often focus on customer experience, fast and effective dashboarding, and multiple possibilities of executions. What I often miss is having a modular, comprehensive, and scalable quality and modeling control system. This is what I've found in dbt, an open-source tool for developing data models with end-to-end modular testing against the warehouse.

Analytics Engineering is the discipline centered on that layer: data modeling and the transformations between raw sources and dashboard-ready KPIs. It sits between Data Engineering (platforms and pipelines) and business analysis (functional specifications), where ownership of business rules is often split and neither side alone owns end-to-end logic.

The Analytics Engineer closes that gap by making transformations deterministic and explainable. When the model is trustworthy, stakeholders challenge the process, not the dashboard.

I'm building a series of dbt data solutions inspired by my Process Mining background, each addressing a major common business problem. These solutions are a strong baseline adaptable to any company and bring the end-to-end control every organization needs.

## Project Goal

This dbt project simulates an Accounts Payable domain. It's not a final product, it's the common backbone of several data products designed to resolve the most common business problems within this domain. It contains the skeleton of models/tables with invoice facts and changes, master data, and intermediate transformations that are applicable for multiple use cases.

It delivers a tested and structured data/domain model as baseline for the following solutions:
- cash_discount: released
- on_time_payments: work in progress
- working_capital_optimizer: pending
- operational_cockpit: pending

## Design rationale


| Model | Role |

|-------|------|

| `fct\_inv\_sap\_core` | SAP invoice facts, terms, dates, map-based Coupa fields |

| `fct\_inv\_cd\_wco\_arbitration` | CD/WCO eligibility gates and `payment\_strategy` |

| `fct\_inv\_timing\_overlay\_core` | Observed Coupa + SAP block intervals |

| `fct\_inv\_timing\_span` | Phase spans (ownership / subprocess) |

| `fct\_inv\_coupa` | Coupa invoice fact (`coupa\_id`) |

| `fct\_inv\_\*\_changes` | SAP / Coupa change history |

| `map\_inv\_sap\_coupa` | Confirmed SAP ↔ Coupa match |

| `dim\_vendor\_sap` / `dim\_vendor\_coupa` | Vendors (includes inactive; `is\_active`) |



Product repos (e.g. \*\*cash\_discount\*\*) extend this with `fct\_inv\_sap\_cd`, timing allocation, and marts.



\## Develop this repo



Prerequisites: dbt 1.x, Snowflake profile \*\*`ap\_core`\*\* in `\~/.dbt/profiles.yml` (same connection as your other AP projects is fine; use a dedicated `schema` if you want isolated tables).



```bash

cd C:\\dbt\\ap\_core

dbt debug

dbt build

