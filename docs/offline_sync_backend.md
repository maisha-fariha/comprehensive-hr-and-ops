# Offline sync — backend contract

The mobile app now saves writes made without a connection to an on-device
outbox and replays them, oldest first, when the server is reachable again.
Nothing about existing request or response shapes has changed. This document
lists what the API should do so replays are safe and correct.

Client code: `lib/core/offline/` (outbox, sync engine, staged uploads) and
`lib/core/network/app_api_client.dart` (headers, queueing).

## 1. Headers the app sends

Every write (`POST`, `PUT`, `PATCH`, `DELETE`) from the iOS / Android app now
carries:

| Header | Example | Meaning |
| --- | --- | --- |
| `Idempotency-Key` | `5b0f8c0e-2f7a-4f39-9b2e-6c1d3f0a9e11` | UUID v4, unique per user action. |
| `X-Client-Occurred-At` | `2026-10-05T08:14:03.512Z` | UTC time the user actually did the action on the device. |

- The **same** `Idempotency-Key` is sent on the first live attempt and on every
  replay of that action, so a request that reached the server but whose
  response was lost is not applied twice.
- Uploads staged offline are sent as `POST /uploads` with key
  `<parent-key>:<attachment-id>` before the write that references them.
- Auth, OTP, token refresh, device registration, payments, billing and exports
  never get these headers and are never queued.
- **Web**: the headers are not sent from the Flutter web build until CORS
  allows them (see §6). Flip `OfflineConfig.sendClientHeadersOnWeb` once done.

Unknown headers are ignored by most frameworks, so nothing breaks before the
backend implements the rest of this document.

## 2. Idempotency (required for safe replays)

- Store `(tenant, userId, Idempotency-Key) → (status code, response body)` for
  **at least 24 hours** (72 hours recommended — devices can be offline over a
  weekend).
- If the same key arrives again with the same route, return the stored
  response with the original status code instead of executing the write.
- If the key arrives while the first request is still running, wait for it
  and return its response, or answer `503` / `429` with `Retry-After` so the
  app retries automatically. (A `409` here would be shown to the user as a
  conflict.)
- Scope keys per tenant and user. A key from another user must never match.

Highest-value endpoints (duplicates here are harmful):

- `POST /mar/administrations` — a duplicate dose record is a clinical incident.
- `POST /attendance/...` clock in / clock out.
- `POST /daily-logs` and `PATCH /daily-logs/:id`.
- `POST /incidents`, `POST /tasks`, task completion, recurring-check results,
  handovers, messages.

## 3. Time the action happened

Replays can arrive minutes or days after the user acted. For time-sensitive
records the server should use the client time, not the arrival time:

- Prefer an explicit body field when present (e.g. `administeredAt` on MAR,
  which the app already sends with the device time of the action).
- Otherwise read `X-Client-Occurred-At`.
- Accept it if it is no more than **72 hours** in the past and no more than
  **5 minutes** in the future relative to server time; otherwise fall back to
  server time and flag the record (`clientTimeRejected: true`) or reject with
  `422`.
- Keep the server receive time too (`receivedAt`) for audit.

Optional: the app can also put `clientOccurredAt` in the JSON body of
time-sensitive writes. This is **off** (`OfflineConfig.includeOccurredAtInBody`)
because strict validators reject unknown fields. Turn it on only once every
affected endpoint accepts the field.

## 4. Status codes the app relies on

| Response | App behaviour |
| --- | --- |
| `2xx` | Item removed from the outbox; screens refresh. |
| `0` / timeout / `408` / `429` / `5xx` | Retried with exponential backoff (5 s → 15 min, jitter), up to 8 attempts, then shown as "Not sent". Later items wait (strict order). |
| `401` | Token refreshed once; if still 401 the queue pauses until the user signs in again. Items are kept. |
| `409` | Shown as "Conflict" in *Unsent changes*; user can edit, retry or discard. |
| other `4xx` (400, 403, 404, 422) | Shown as "Not sent" with the server message; the rest of the queue continues. |

Please:

- Return `409` (not `400`) when a write conflicts with newer server state
  (record edited by someone else, dose already recorded for that slot,
  shift already clocked out). Include a readable `message` and, when useful,
  the current server version, e.g.
  `{"code": "CONFLICT", "message": "Dose already recorded by J. Smith at 08:02", "current": {...}}`.
- Keep `message` short and human-readable — it is shown to the user as-is.
- Use `429` with `Retry-After` for rate limiting rather than `503`.

## 5. Uploads made offline

When a file is attached offline the app keeps it on the device and inserts a
placeholder `offline-upload://<id>/<filename>` in the form. On replay it:

1. `POST /uploads?category=…` the file (with `Idempotency-Key`
   `<parent-key>:<id>`),
2. replaces the placeholder with the returned `fileUrl` / `url` / `publicUrl`,
3. sends the original write.

The server should therefore never receive an `offline-upload://` value. If one
ever arrives, reject it with `422` so the item is surfaced to the user rather
than storing a broken link. Making `/uploads` idempotent on the key avoids
orphan files when the upload succeeds but the response is lost.

Currently opted in: staff daily-log attachments and staff attendance selfies.

### Records created offline

A create made offline gets a temporary id `offline-<uuid>` on the device, so
the user can keep working with it (open a new conversation and send messages
into it, add notes to a new task…). Later queued writes may use that id in
their path or body. On replay, when the create succeeds the app reads the new
id from the response and swaps it into every later queued write before
sending them.

The server therefore must return the created record's id as `id` (top level
or under `data`) on every `POST` that creates something. It should never
receive an `offline-` id; if one arrives (create response had no id), answer
`404`/`422` so the change is shown to the user instead of being stored.

## 6. CORS (web build only)

Add to `Access-Control-Allow-Headers`:

```
Idempotency-Key, X-Client-Occurred-At
```

Then set `OfflineConfig.sendClientHeadersOnWeb = true` in the app.

## 7. Nice to have

- `HEAD /` (or `GET /health`) answering quickly without auth — the app uses
  any HTTP response from the API base URL as a reachability probe.
- `ETag` / `Last-Modified` on list endpoints for cheaper refreshes.
- A `GET /mar/round` field indicating doses recorded with client time later
  than the round, so manager screens can label late-synced records.
