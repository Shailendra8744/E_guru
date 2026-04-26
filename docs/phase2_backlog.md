# Phase 2 backlog — status

## Delivered in this phase

- Admin analytics endpoints: overview, per-quiz stats (paginated), doubt SLA snapshot.
- Teacher dashboard metrics: average rating, active/resolved doubts, average first-reply time.
- Student quiz insights by subject (`/student/quiz-insights`).
- Pagination (`page`, `per_page`) and filters on major list endpoints; `meta` in responses.
- Improved auto-assignment scoring (rating + availability + recent first-reply performance).
- Multipart uploads for PDF notes and chat images under `backend/public/uploads/`.
- Cron-style retry for `pending_assignment` doubts (`/cron/retry-pending-doubts` + `CRON_SECRET`).
- Server-side refresh token revocation on `POST /auth/logout`.
- Flutter: admin analytics screen, teacher metrics card, student quiz insights; API client query support; logout calls backend.
- Docs: `docs/phase2_api.md`, `docs/phase2_testing.md`; migration `002_phase2.sql` for assignment retry columns.

## Still open (Phase 3 or later)

- Push notifications for new doubts/messages.
- Automated PHPUnit (or CI) suite hitting a test database.
- Optional “signed” download URLs for private files (current uploads are public paths under `public/`).
- Richer quiz analytics (per-question difficulty, topic tags).
