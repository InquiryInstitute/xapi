# Castalia event registry

Machine-readable registry of **canonical** `castalia.*` domain events, aligned with [Castalia xAPI System Specification v0.1](../CASTALIA_XAPI_SYSTEM_SPEC_v0.1.md).

| Artifact | Purpose |
|----------|---------|
| [`v1/registry.json`](v1/registry.json) | **Source of truth** — 20 events with internal field contracts and xAPI mapping |
| [`v1/registry-entry.schema.json`](v1/registry-entry.schema.json) | JSON Schema for each event object (SDK / CI validation) |
| [`v1/examples.md`](v1/examples.md) | End-to-end internal event → xAPI statement examples |

## Rules

1. **No ad hoc events** — producers emit only `event_type` values listed in `registry.json` for the negotiated registry version.
2. **Versioning** — `version` on each event is the schema version; breaking changes increment minor/major per [§13](../CASTALIA_XAPI_SYSTEM_SPEC_v0.1.md#13-versioning).
3. **Gateway** — maps internal events to xAPI using `xapi_mapping`; `activity_id_template` placeholders are filled from `context` / `payload`.
4. **Extensions** — use `https://castalia.institute/xapi/extensions/...` keys in statement `context.extensions` / `result.extensions` as defined in the gateway profile (narrow set: `castalia_event_type`, correlation IDs).

## Event index (v1)

| # | `event_type` | Producers |
|---|--------------|-----------|
| 1 | `castalia.inqspace.notebook.cell_executed` | inqspace, atlas |
| 2 | `castalia.inqspace.notebook.kernel_ready` | inqspace |
| 3 | `castalia.atlas.module.started` | atlas |
| 4 | `castalia.atlas.module.completed` | atlas |
| 5 | `castalia.atlas.resource.accessed` | atlas |
| 6 | `castalia.atlas.assessment.attempt_submitted` | atlas |
| 7 | `castalia.atlas.assessment.scored` | atlas |
| 8 | `castalia.dialogic.session.started` | samwise, dialogic |
| 9 | `castalia.dialogic.session.ended` | samwise, dialogic |
| 10 | `castalia.dialogic.turn.submitted` | samwise, dialogic |
| 11 | `castalia.inq.card.presented` | inq_cards, atlas |
| 12 | `castalia.inq.card.response_recorded` | inq_cards, atlas |
| 13 | `castalia.inquiry.question.recorded` | atlas, inqspace |
| 14 | `castalia.inquiry.hypothesis.recorded` | atlas, inqspace |
| 15 | `castalia.inquiry.evidence.linked` | atlas, inqspace |
| 16 | `castalia.device.observation.recorded` | device, field |
| 17 | `castalia.collaboration.peer_feedback.submitted` | atlas |
| 18 | `castalia.learner.reflection.submitted` | atlas, inqspace |
| 19 | `castalia.atlas.pathway.milestone_reached` | atlas |
| 20 | `castalia.session.registration.recorded` | atlas, inqspace, gateway |

## Next steps (implementation)

- Generate TypeScript / Rust types from `registry.json` in CI.
- Pin **xAPI profile** document (verbs, activity types, extension cardinalities).
- Contract tests: gateway output validates against profile + LRS.
