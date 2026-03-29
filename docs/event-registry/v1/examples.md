# Registry examples (v1)

Illustrative **internal events** and resulting **xAPI statements** after gateway mapping. IDs and timestamps are examples only.

**Extension IRI (event correlation):** `https://castalia.institute/xapi/extensions/castalia`

---

## 1. `castalia.inqspace.notebook.cell_executed`

**Internal**

```json
{
  "event_id": "0195b2e0-7c00-7b00-8000-000000000001",
  "event_type": "castalia.inqspace.notebook.cell_executed",
  "version": "1.0",
  "actor_id": "https://castalia.institute/actors/pat-abc",
  "timestamp": "2026-03-29T12:00:00.000Z",
  "context": {
    "notebook_id": "nb-001",
    "session_id": "sess-77",
    "course_id": "course-42"
  },
  "payload": {
    "cell_id": "c12",
    "language": "python",
    "execution_ms": 340,
    "success": true
  }
}
```

**xAPI (conceptual)**

```json
{
  "actor": { "mbox": "mailto:pat@example.org" },
  "verb": { "id": "http://adlnet.gov/expapi/verbs/interacted", "display": { "en-US": "interacted" } },
  "object": {
    "objectType": "Activity",
    "id": "https://castalia.institute/xapi/activities/notebook/nb-001/cell/c12",
    "definition": {
      "type": "https://castalia.institute/xapi/activity-types/notebook-cell",
      "name": { "en-US": "Notebook cell c12" }
    }
  },
  "result": { "success": true, "duration": "PT0.34S" },
  "context": {
    "registration": "77e7e2fb-3f97-4e8a-9c2a-1b2c3d4e5f00",
    "extensions": {
      "https://castalia.institute/xapi/extensions/castalia": {
        "event_type": "castalia.inqspace.notebook.cell_executed",
        "schema_version": "1.0",
        "notebook_id": "nb-001",
        "session_id": "sess-77"
      }
    }
  },
  "timestamp": "2026-03-29T12:00:00.000Z"
}
```

---

## 2. `castalia.atlas.module.completed`

**Internal**

```json
{
  "event_id": "0195b2e0-7c00-7b00-8000-000000000002",
  "event_type": "castalia.atlas.module.completed",
  "version": "1.0",
  "actor_id": "https://castalia.institute/actors/pat-abc",
  "timestamp": "2026-03-29T12:05:00.000Z",
  "context": {
    "module_id": "mod-kinetics-01",
    "registration_id": "77e7e2fb-3f97-4e8a-9c2a-1b2c3d4e5f00",
    "pathway_id": "path-sci-2026"
  },
  "payload": {
    "success": true,
    "duration_ms": 120000
  }
}
```

**xAPI (conceptual)**

```json
{
  "actor": { "mbox": "mailto:pat@example.org" },
  "verb": { "id": "http://adlnet.gov/expapi/verbs/completed", "display": { "en-US": "completed" } },
  "object": {
    "objectType": "Activity",
    "id": "https://castalia.institute/xapi/activities/module/mod-kinetics-01",
    "definition": {
      "type": "https://castalia.institute/xapi/activity-types/learning-module",
      "name": { "en-US": "Module mod-kinetics-01" }
    }
  },
  "result": { "completion": true, "duration": "PT120S" },
  "context": {
    "registration": "77e7e2fb-3f97-4e8a-9c2a-1b2c3d4e5f00",
    "extensions": {
      "https://castalia.institute/xapi/extensions/castalia": {
        "event_type": "castalia.atlas.module.completed",
        "schema_version": "1.0"
      }
    }
  },
  "timestamp": "2026-03-29T12:05:00.000Z"
}
```

---

## 3. `castalia.session.registration.recorded`

**Internal**

```json
{
  "event_id": "0195b2e0-7c00-7b00-8000-000000000003",
  "event_type": "castalia.session.registration.recorded",
  "version": "1.0",
  "actor_id": "https://castalia.institute/actors/pat-abc",
  "timestamp": "2026-03-29T11:59:00.000Z",
  "context": {
    "registration_id": "77e7e2fb-3f97-4e8a-9c2a-1b2c3d4e5f00",
    "course_id": "course-42",
    "module_id": "mod-kinetics-01"
  },
  "payload": {
    "client_id": "atlas-web",
    "appliance_node_id": "node-local-01"
  }
}
```

**xAPI (conceptual)**

```json
{
  "actor": { "mbox": "mailto:pat@example.org" },
  "verb": { "id": "http://adlnet.gov/expapi/verbs/registered", "display": { "en-US": "registered" } },
  "object": {
    "objectType": "Activity",
    "id": "https://castalia.institute/xapi/activities/session/77e7e2fb-3f97-4e8a-9c2a-1b2c3d4e5f00",
    "definition": {
      "type": "https://castalia.institute/xapi/activity-types/learning-session",
      "name": { "en-US": "Learning session" }
    }
  },
  "context": {
    "registration": "77e7e2fb-3f97-4e8a-9c2a-1b2c3d4e5f00",
    "extensions": {
      "https://castalia.institute/xapi/extensions/castalia": {
        "event_type": "castalia.session.registration.recorded",
        "schema_version": "1.0"
      }
    }
  },
  "timestamp": "2026-03-29T11:59:00.000Z"
}
```
