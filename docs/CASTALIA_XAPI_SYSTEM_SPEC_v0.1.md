# Castalia xAPI System Specification

**Version:** 0.1  
**Status:** Draft  
**Scope:** Distributed, profile-governed learning evidence, local-first operation, credential derivation, and hybrid sync.

This document is **normative** for Castalia’s xAPI-related architecture. Sections marked *Informative* are rationale and risk analysis; they do not relax normative requirements.

---

## Table of contents

1. [Purpose and conformance](#1-purpose-and-conformance)
2. [Part I — Design review (*Informative*)](#2-part-i--design-review-informative)
3. [Part II — System overview](#3-part-ii--system-overview)
4. [Core components](#4-core-components)
5. [Event model](#5-event-model)
6. [Identity model](#6-identity-model)
7. [xAPI endpoints and interfaces](#7-xapi-endpoints-and-interfaces)
8. [Statement guarantees](#8-statement-guarantees)
9. [Gateway specification](#9-gateway-specification)
10. [Sync model](#10-sync-model)
11. [Security model](#11-security-model)
12. [Credential model](#12-credential-model)
13. [Versioning](#13-versioning)
14. [Deployment modes](#14-deployment-modes)
15. [Non-functional requirements](#15-non-functional-requirements)
16. [Roadmap (*Informative*)](#16-roadmap-informative)
17. [Strategic assessment (*Informative*)](#17-strategic-assessment-informative)

---

## 1. Purpose and conformance

**Goal.** Castalia implements xAPI as a **distributed learning event system with credential authority**, not merely an LMS connector or a single LRS deployment.

**Conformance classes** (future certification may reference these):

| Class | Meaning |
|-------|---------|
| **Producer** | Emits only **registered** domain events; uses SDK validation; never writes xAPI directly to an LRS except through a **conformant gateway** where required by profile |
| **Gateway** | Implements [§9](#9-gateway-specification) |
| **LRS** | Append-only statement store with query as specified in product contracts |
| **Read model** | Maintains derived state per [§4.4](#44-read-model-layer-mandatory) |
| **Sync** | Implements [§10](#10-sync-model) |
| **Credential** | Implements [§12](#12-credential-model) |

**Design principle:** *Tight constraints early, controlled expansion later.* Unregistered events and ad hoc semantics are **non-conforming**.

---

## 2. Part I — Design review (*Informative*)

This section records **failure modes and gaps** in unconstrained designs. It motivates the normative requirements in Part II.

### 2.1 Semantic drift

**Risk.** Separate teams name the same concept differently (`cell_executed` vs `cell_run` vs `code_evaluated`). Downstream mapping to xAPI diverges → analytics and credentials break.

**Mitigation (normative):** [§5](#5-event-model) event registry, versioned schemas, compile-time validation in producer SDKs. **The gateway alone is insufficient** without registry + SDK enforcement.

### 2.2 Underspecified gateway

**Risk.** Without idempotency, ordering semantics, batching, failure/replay behavior, and version negotiation, the system duplicates or loses statements and diverges local vs cloud.

**Mitigation (normative):** [§9](#9-gateway-specification).

### 2.3 Local vs cloud consistency

**Risk.** Multiple appliances, duplicate activities, timestamp skew, out-of-order delivery: append-only xAPI does not remove the need for **context** in credential and progress logic.

**Mitigation (normative):** [§8](#8-statement-guarantees), [§10](#10-sync-model), [§6](#6-identity-model), read models [§4.4](#44-read-model-layer-mandatory).

### 2.4 Missing identity model

**Risk.** Statements from different nodes do not reconcile; credentials are not globally meaningful.

**Mitigation (normative):** [§6](#6-identity-model).

### 2.5 Over-reliance on LRS queries

**Risk.** LRS query APIs are limited and slow for complex product queries; UX becomes brittle and vendor-dependent.

**Mitigation (normative):** [§4.4](#44-read-model-layer-mandatory) — product surfaces **must not** depend on ad hoc LRS queries.

### 2.6 Underspecified credential engine

**Risk.** “Evaluate evidence → issue credential” without declarative, versioned, reproducible, auditable rules → credentials are indefensible (e.g. Magister-level scrutiny).

**Mitigation (normative):** [§12](#12-credential-model).

### 2.7 Vague sync

**Risk.** “Selective sync” without contracts and conflict rules → fragmentation, privacy leaks, inconsistent credentials.

**Mitigation (normative):** [§10](#10-sync-model).

### 2.8 Security gaps

**Risk.** Event forgery, untrusted devices, malicious clients, replay attacks, credential fraud — especially acute if credentials anchor to external trust systems later.

**Mitigation (normative):** [§11](#11-security-model).

### 2.9 Missing versioning

**Risk.** Unsafe evolution of profiles, events, rules, and APIs.

**Mitigation (normative):** [§13](#13-versioning).

### 2.10 Excess flexibility

**Risk.** “Everything is possible → nothing is consistent.”

**Mitigation:** Conformance classes and mandatory registry ([§1](#1-purpose-and-conformance), [§5](#5-event-model)).

---

## 3. Part II — System overview

Castalia provides:

- Cloud and **local appliance** deployment  
- **Hybrid synchronization** with explicit contracts  
- **Credential derivation** from evidence with auditable rules  
- **Profile-governed** xAPI semantics  

Architecturally, this is closer to **a distributed learning event system + credential authority** than to a single LMS or a thin xAPI pipe.

---

## 4. Core components

### 4.1 Event producers

Systems that emit learning-domain events, including but not limited to:

- Atlas  
- iNQspace  
- SAMWISE / Dialogic  
- iNQ Card system  
- Device and field systems  

Producers **must** emit **registered** event types only ([§5.2](#52-event-registry-mandatory)).

### 4.2 Event gateway (mandatory layer)

All **xAPI writes** intended for Castalia-controlled stores **must** pass through a **conformant gateway** unless a written exception exists for a specific integration (exceptions must be rare and documented).

Responsibilities are enumerated in [§9](#9-gateway-specification).

### 4.3 Learning Record Store (LRS)

Stores **validated** xAPI statements in an **immutable, append-only** log.

**Required capabilities** (minimum product contract):

- Statement ingestion (per xAPI / LRS conformance target chosen by implementation)  
- Query with pagination and time filtering  
- Stable statement IDs  

### 4.4 Read model layer (mandatory)

**Derived** databases (or materialized views) for:

- Progress tracking  
- Inquiry graph state  
- Credential evaluation inputs  
- Dashboards and UX  

**Normative:** Product UX **must not** query the LRS directly for routine screens; it **must** use read models defined for each surface. (Ad hoc analytics or research tools may use LRS query under governance.)

### 4.5 Credential engine

Evaluates:

- xAPI statements (and bundles)  
- Derived read-model state  

Produces:

- Eligibility decisions  
- Evidence bundles suitable for audit  

Rules: [§12](#12-credential-model).

### 4.6 Issuer service

Creates:

- Open Badges 3.0 artifacts  
- W3C Verifiable Credentials  

Signs with **local or cloud** issuer keys per deployment policy.

### 4.7 Sync service

Handles local ↔ cloud replication with filtering, batching, deduplication, and explicit modes ([§10](#10-sync-model)).

---

## 5. Event model

### 5.1 Internal event structure

Canonical shape (fields may extend with registry approval):

```json
{
  "event_id": "uuidv7",
  "event_type": "inqspace.notebook.cell_executed",
  "version": "1.0",
  "actor_id": "user-123",
  "timestamp": "ISO8601",
  "context": {},
  "payload": {}
}
```

- `event_id`: **UUIDv7** (time-ordered, globally unique)  
- `event_type`: **Registered** string; no ad hoc types  
- `version`: Schema version for that `event_type`  

### 5.2 Event registry (mandatory)

All event types must be:

- Registered in the **Castalia Event Registry**  
- Versioned  
- Documented (semantics, mapping, examples)  

**No ad hoc events** in conforming producers.

### 5.3 Mapping rules

Each registered event type defines:

- Target xAPI **verb**(s)  
- **Activity type** IRI  
- Required and optional **context** fields  
- **Extension** keys under agreed IRIs  

Mapping tables are **versioned** with the registry.

---

## 6. Identity model

### 6.1 Global identity

Each human or system **actor** has:

- A **global identifier** (DID, `https:` URI, or other registered scheme)  
- **Mappings** from local IDs issued by apps or appliances  

### 6.2 Device / appliance identity

Each appliance or field device has:

- A **node ID**  
- Optional **signing** capability for batches or events  

### 6.3 Session identity

Learning sessions use:

- A **registration** identifier (UUID) carried in xAPI context where applicable  

### 6.4 Offline resolution

**Requirement:** The architecture **must** define how local-only identifiers are merged or linked when connectivity returns, without issuing duplicate credentials for the same evidence. Exact merge algorithms are specified in implementation guides; this spec requires **documented** resolution rules per deployment.

---

## 7. xAPI endpoints and interfaces

### 7.1 Cloud

Example (authoritative hostname may vary by environment):

- `https://xapi.castalia.institute/xAPI/statements`  
- `https://xapi.castalia.institute/xAPI/about`  

### 7.2 Local appliance

- `https://xapi.local/xAPI/statements` (or deployment-specific TLS)  
- **Same** abstract interface as cloud for clients using the gateway pattern  

Path and version prefixes **must** be versioned at the API level ([§13](#13-versioning)).

---

## 8. Statement guarantees

### 8.1 Idempotency

**Same `event_id` → at most one canonical statement** in the LRS (duplicate submits are acknowledged without double insert). Gateway enforces idempotency keys and maps to stable statement IDs.

### 8.2 Ordering

**Best-effort** delivery order. **Consumers must not** depend on strict global ordering for correctness; read models **must** tolerate out-of-order ingestion.

### 8.3 Immutability

Statements are **not** modified after commit; corrections use supplementary statements per xAPI practice.

---

## 9. Gateway specification

The gateway is the **most critical** operational component. Minimum normative behaviors:

| Concern | Requirement |
|--------|----------------|
| **Authentication** | Verify producer identity ([§11](#11-security-model)) |
| **Schema validation** | Reject non-registry or invalid-payload events at ingress |
| **Statement ID** | Assign or deterministically derive statement ID tied to `event_id` + mapping version |
| **Idempotency** | Deduplicate on `event_id` (or equivalent key) |
| **Context enrichment** | Add deployment, node, profile version, registry version |
| **xAPI mapping** | Apply versioned mapping rules ([§5.3](#53-mapping-rules)) |
| **Profile validation** | Validate against target xAPI profile |
| **Persistence** | Write to LRS only after full validation |
| **Queue + retry** | Durable outbound retry to LRS; no silent drop |
| **Replay** | Support re-processing from durable event log for disaster recovery (replay **must** preserve idempotency) |
| **Batching** | Support configurable batch ingest with per-batch failure isolation |
| **Version negotiation** | Clients declare registry / API version; gateway rejects unsupported combinations with explicit errors |
| **Failure modes** | Documented: partial batch, LRS unavailable, clock skew — including operator runbooks |

**Ordering:** The gateway may assign **monotonic sequence numbers** per stream for debugging; these do **not** override [§8.2](#82-ordering).

---

## 10. Sync model

### 10.1 Sync unit

A **batch of statements** (and optional derived checkpoints), with a defined maximum size and cryptographic hash where required by deployment.

### 10.2 Sync modes

| Mode | Description |
|------|-------------|
| **FULL** | All allowed statements per policy |
| **CREDENTIAL_ONLY** | Subset required for credential evaluation |
| **SUMMARY_ONLY** | Aggregates / digests where full detail must not leave locale |
| **NONE** | No outbound sync (local-only) |

Modes **must** be explicit in appliance configuration and sync contracts.

### 10.3 Deduplication

By **statement ID** (and secondarily by `event_id` where present in extensions).

### 10.4 Conflict strategy

- **Statements:** Append-only → **no overwrites**; duplicates rejected by idempotency.  
- **Read models:** On conflicting derived state, **latest valid write wins** per defined wall-clock / logical clock rules documented per read model.

### 10.5 Trust boundaries

Sync **must** specify which actors and nodes are trusted for which statement types; untrusted sources are quarantined or rejected.

---

## 11. Security model

### 11.1 Producer authentication

- **Service tokens** for server-side producers  
- **Device tokens** for appliances with attestation where available  

### 11.2 Statement integrity

- Optional **gateway signing** of statements or batches  
- Roadmap: **appliance-signed** batches for field deployments  

### 11.3 Replay protection

- **`event_id` uniqueness** enforced at gateway  
- **Timestamp** plausibility checks (skew bounds, monotonicity hints)  

### 11.4 Threat coverage

Design **must** explicitly address: event forgery, compromised devices, malicious clients, replay of old events, and credential fraud. Exact controls vary by deployment but **must** be documented in a threat model per release.

---

## 12. Credential model

### 12.1 Rule engine

Competency and eligibility rules **must** be:

- **Declarative** (machine-readable)  
- **Versioned** immutably once published  
- **Reproducible** (same inputs + rule version → same decision)  
- **Auditable** (evidence pointers and rule hashes retained)  

### 12.2 Evidence

Each credential issuance or eligibility decision **must** reference:

- Relevant **xAPI statement IDs** (and/or bundles)  
- **Derived summaries** where used, with hash or version  

### 12.3 Issuance

May occur **locally** (appliance) or **centrally** (cloud issuer), subject to key management and policy.

### 12.4 Competency definition

**Competency** is defined only through published rule sets and registry concepts — not ad hoc UI logic.

---

## 13. Versioning

The following **must** carry explicit version identifiers:

- Event schemas and registry entries  
- xAPI profile versions used in validation  
- Credential rule sets  
- Public HTTP API surfaces (including gateway and sync)  

Breaking changes require **new major versions** and coexistence or migration windows as defined in release policy.

---

## 14. Deployment modes

| Mode | Behavior |
|------|----------|
| **Local-only** | Full offline operation; no sync required |
| **Hybrid** | Local capture with periodic sync ([§10](#10-sync-model)) |
| **Cloud-only** | Producers → cloud gateway → cloud LRS |

---

## 15. Non-functional requirements

Targets (refine per environment):

| Metric | Target |
|--------|--------|
| Ingest latency (gateway accept → durable) | &lt; 100 ms p95 where network permits |
| Durability | **No acknowledged event loss** |
| Offline | Core capture works without cloud |
| Scalability | **Horizontal** scaling of stateless gateway tier |

---

## 16. Roadmap (*Informative*)

**Recommended next design deliverable:** **Atlas Event Registry** with **20 canonical events**, each mapped to xAPI and shared across iNQspace, Atlas, and card flows. That step forces semantic discipline and de-risks downstream gateway, LRS, and credential work.

---

## 17. Strategic assessment (*Informative*)

**Strengths of the architecture direction**

- Local-first LRS aligns with field and privacy constraints  
- Gateway abstraction is the correct control point  
- Profile-driven semantics align with xAPI best practice  
- Credential layering enables serious issuance, not stickers  

**Areas that require continued rigor**

- Identity and offline resolution ([§6](#6-identity-model))  
- Sync contracts and trust boundaries ([§10](#10-sync-model))  
- Event governance and SDK enforcement ([§5](#5-event-model))  
- Gateway operational semantics ([§9](#9-gateway-specification))  
- Defensible credential rules ([§12](#12-credential-model))  

---

## Document history

| Version | Date | Notes |
|---------|------|--------|
| 0.1 | 2026-03-29 | Initial integrated spec + design review |
