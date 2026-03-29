# Castalia xAPI — Integrations (Atlas, iNQspace, Codespaces)

This document ties the **xapi** repository (specification, [event registry](event-registry/v1/registry.json), marketing site) to sibling Castalia applications and to **GitHub Codespaces** as a course-delivery runtime.

**Normative architecture:** [Castalia xAPI System Specification v0.1](CASTALIA_XAPI_SYSTEM_SPEC_v0.1.md).

---

## 1. Repository roles

| Repository | Path (typical monorepo layout) | Role |
|------------|----------------------------------|------|
| **xapi** | `../xapi` | Specification, **event registry**, gateway contract, GitHub Pages (`xapi.castalia.institute`). |
| **atlas** | `../atlas` | Curriculum shell (e.g. Astro): modules, pathways, resources, assessments — **producer** `atlas` in the registry. |
| **inqspace** | `../inqspace` | GitHub Classroom–style flows: assignments, forks, submissions, grading — **producer** `inqspace` (and notebook-adjacent events). |

All three share **Castalia Web Platform** conventions (`@castalia/platform`); keep tokens and entitlement patterns aligned with [castalia-platform](https://github.com/InquiryInstitute/castalia-platform).

---

## 2. Target integration pattern

**Direction:** every learning product emits **only [registered](event-registry/README.md) `castalia.*` domain events** at the edge; a **Castalia Gateway** validates, assigns idempotency, maps to xAPI, and writes to an LRS. Read models and credentials consume the LRS **downstream**, not ad hoc per-app analytics queries.

```
┌─────────────┐     ┌─────────────┐     ┌──────────────────┐     ┌─────┐
│ Atlas (UI) │     │  iNQspace   │     │ Codespace / IDE  │     │ …   │
│  producers  │     │  producers  │     │  (notebook ext)  │     │     │
└──────┬──────┘     └──────┬──────┘     └────────┬─────────┘     └──┬──┘
       │                   │                     │                 │
       └───────────────────┴─────────────────────┴─────────────────┘
                                       │
                                       ▼
                            ┌──────────────────────┐
                            │  Castalia Gateway      │
                            │  (validate + map)      │
                            └───────────┬────────────┘
                                        ▼
                            ┌──────────────────────┐
                            │  LRS (cloud / local)   │
                            └──────────────────────┘
```

**Contrast with a legacy shortcut:** posting xAPI **directly** from an app to an LRS skips registry enforcement and duplicates mapping logic. iNQspace’s earlier [xAPI / LRS integration design](https://github.com/InquiryInstitute/inqspace/blob/main/.kiro/specs/xapi-lrs-integration/design.md) describes that pattern for **bootstrap**; production alignment should **converge on gateway + registry** (see §4).

---

## 3. Atlas (`../atlas`)

**Registry producers:** `atlas` (and shared events with `inqspace` where notebook inquiry overlaps).

**Emit at:**

- Module / pathway boundaries → `castalia.atlas.module.started`, `castalia.atlas.module.completed`, `castalia.atlas.pathway.milestone_reached`
- Resource views → `castalia.atlas.resource.accessed`
- Assessments → `castalia.atlas.assessment.attempt_submitted`, `castalia.atlas.assessment.scored`
- Reflection prompts → `castalia.learner.reflection.submitted`
- Session correlation → `castalia.session.registration.recorded` when a learner session is bound to an xAPI `registration` UUID

**Configuration (conceptual):**

| Variable | Purpose |
|----------|---------|
| `CASTALIA_XAPI_GATEWAY_URL` | Base URL for the gateway (not raw LRS) in cloud or hybrid |
| `CASTALIA_EVENT_REGISTRY_URL` | Optional pinned URL to `registry.json` for SDK validation in CI |
| `CASTALIA_REGISTRATION_STRATEGY` | How `registration_id` is issued (server-side UUID per course/module) |

**Implementation note:** Atlas is Astro-oriented; emit from **server endpoints** or **trusted client islands** that call your API — never put LRS secrets in the browser. Prefer batching high-frequency events (e.g. resource scroll) at the product layer before gateway submission.

---

## 4. iNQspace (`../inqspace`)

**Registry producers:** `inqspace`, `gateway` (for `castalia.session.registration.recorded` when the platform issues registrations).

**Existing work:** [xAPI / LRS integration requirements & design](https://github.com/InquiryInstitute/inqspace/blob/main/.kiro/specs/xapi-lrs-integration/design.md) define:

- Opt-in LRS config per scope  
- Domain events: `assignment_forked`, `assignment_submitted`, `submission_graded`, `feedback_added`  
- Non-blocking delivery, outbox, idempotency  

**Alignment with the registry:**

| Legacy domain event (Kiro) | Direction |
|----------------------------|-----------|
| `assignment_forked` | Add **registry vNext** entries (e.g. `castalia.inq.assignment.forked`) **or** map only in gateway — do not leave unregistered strings long-term. |
| `assignment_submitted` | Map to `castalia.atlas.assessment.attempt_submitted` where it is the same semantic unit, **or** register an `castalia.inq.assignment.submitted` event with explicit xAPI mapping. |
| `submission_graded` | Align with `castalia.atlas.assessment.scored` or a dedicated graded event; **verb** must match [registry](event-registry/v1/registry.json) (e.g. `completed` + `result.score`). |
| `feedback_added` | Align with `castalia.collaboration.peer_feedback.submitted` when peer feedback; instructor feedback may need a separate registry entry. |

**Single rule:** internal DTO names can stay until refactor; **gateway output** must use **registered** `event_type` + version in extensions and stable statement IDs for idempotency.

---

## 5. GitHub Codespaces (course delivery)

Codespaces is **not** a fourth codebase: it is the **runtime** where students open repos, run notebooks, and submit PRs managed by iNQspace / GitHub Classroom.

**Integration points:**

1. **Assignment lifecycle** — Same events as iNQspace (fork, submit, grade) whether work happens on laptop or in a Codespace; include **context extensions** such as `delivery_environment: codespace` and `codespace_name` when available (non-secret).

2. **Notebook execution** — If inquiry notebooks run inside VS Code / Jupyter in a Codespace, emit `castalia.inqspace.notebook.cell_executed` (and related) via:
   - an **editor extension** or **sidecar** that posts domain events to the gateway, or  
   - **server-side** capture if execution is relayed through iNQspace.

3. **Local dev parity** — Developers working in `../atlas`, `../inqspace`, `../xapi` side by side can point `CASTALIA_XAPI_GATEWAY_URL` at a **local appliance** or mock gateway for integration tests.

4. **Optional devcontainer** — A repo-level `.devcontainer` can set env vars and install CLI tools that validate events against `registry.json` before commit (policy as code).

**Privacy:** do not put OAuth tokens or Classroom secrets into xAPI statements; follow [§11](CASTALIA_XAPI_SYSTEM_SPEC_v0.1.md#11-security-model) of the system spec.

---

## 6. Versioning and CI

- **Registry:** bump `registry_version` in [registry.json](event-registry/v1/registry.json) when adding or breaking events; Atlas/iNQspace CI should pin a **registry URL or git SHA**.  
- **Cross-repo PRs:** When changing the registry, open companion PRs or issues in **atlas** and **inqspace** to update mappers and SDKs.

---

## 7. Quick links

| Artifact | Location |
|----------|----------|
| System spec | [CASTALIA_XAPI_SYSTEM_SPEC_v0.1.md](CASTALIA_XAPI_SYSTEM_SPEC_v0.1.md) |
| Event registry | [event-registry/README.md](event-registry/README.md) |
| iNQspace xAPI Kiro design | [inqspace repo](https://github.com/InquiryInstitute/inqspace/blob/main/.kiro/specs/xapi-lrs-integration/design.md) |
| Marketing / overview site | [https://xapi.castalia.institute/](https://xapi.castalia.institute/) |

---

## Document history

| Version | Date | Notes |
|---------|------|--------|
| 1.0 | 2026-03-29 | Initial Atlas + iNQspace + Codespaces integration |
