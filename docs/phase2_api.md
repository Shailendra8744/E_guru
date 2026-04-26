# Phase 2 API additions

Base path: `/api/v1` (same as Phase 1).

## Auth

| Method | Path | Notes |
|--------|------|--------|
| POST | `/auth/logout` | Body: `{ "refresh_token": "..." }`. Revokes matching refresh token. |

## Pagination

List endpoints accept optional `page` and `per_page` (max 100). Response includes `meta` when applicable:

```json
{ "items": [], "meta": { "page": 1, "per_page": 20, "total": 42, "total_pages": 3 } }
```

| Method | Path | Query |
|--------|------|--------|
| GET | `/admin/teachers/pending` | `page`, `per_page` |
| GET | `/admin/subjects` | `page`, `per_page` |
| GET | `/student/notes` | `page`, `per_page`, `subject_id` |
| GET | `/student/quizzes` | `page`, `per_page`, `subject_id` |
| GET | `/teacher/doubts` | `page`, `per_page`, `status` |

## Student insights

| Method | Path | Role |
|--------|------|------|
| GET | `/student/quiz-insights` | student — per-subject attempts and average percent |

## Admin analytics

| Method | Path | Role |
|--------|------|------|
| GET | `/admin/analytics/overview` | admin |
| GET | `/admin/analytics/quizzes` | admin — `page`, `per_page` |
| GET | `/admin/analytics/doubts-sla` | admin — SLA snapshot |

## Teacher metrics

| Method | Path | Role |
|--------|------|------|
| GET | `/teacher/metrics` | teacher — rating, active/resolved doubts, avg first reply seconds |

## Uploads (multipart)

`Content-Type: multipart/form-data`, field name: `file`.

| Method | Path | Role | Allowed MIME |
|--------|------|------|--------------|
| POST | `/uploads/note-pdf` | teacher | `application/pdf` |
| POST | `/uploads/chat-image` | student, teacher | jpeg, png, webp |

Response includes `path` (e.g. `/uploads/notes/....pdf`) and `url` if `APP_PUBLIC_URL` is set.

Files are stored under `backend/public/uploads/`.

## Cron (retry pending assignment)

| Method | Path | Auth |
|--------|------|------|
| GET | `/cron/retry-pending-doubts` | `X-Cron-Secret: <CRON_SECRET>` or `?secret=` |

Requires `CRON_SECRET` in `.env`. Retries doubts in `pending_assignment` with backoff and caps (`MAX_ASSIGNMENT_ATTEMPTS`).

## Chat polling

| Method | Path | Query |
|--------|------|--------|
| GET | `/doubts/{id}/messages` | `after`, `limit` (1–200, default 100) |

## Assignment engine

Auto-assignment uses `DoubtAssignmentService`: rating, active workload, and (when available) average first-reply time from resolved doubts in the last 30 days. Weights are configurable via `ASSIGN_*_WEIGHT` env vars.
