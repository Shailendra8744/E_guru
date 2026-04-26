# MVP Scope (Phase 1)

This document freezes the minimum deliverables for the first working release.

## Included

- JWT login and refresh token authentication.
- Role-based access for `admin`, `teacher`, and `student`.
- Teacher registration with admin approval gate before login.
- Subject management by admin.
- Teacher subject mapping.
- Teacher note upload metadata management.
- Quiz creation, questions, and student submission.
- Doubt creation with optional teacher selection.
- Auto-assignment when teacher is not selected.
- Polling-first chat over doubts.
- Doubt resolution and student rating.

## Not Included

- Websocket chat (kept as future upgrade path).
- Push notifications.
- Advanced analytics dashboards.
- AI-based recommendation or NLP doubt classification.

## Acceptance Criteria

- Teacher cannot access protected teacher APIs until approved.
- Student can submit doubt with or without choosing a teacher.
- Auto-assignment runs when no teacher is chosen.
- Student and teacher can exchange messages through polling endpoints.
- Student can rate teacher only after doubt is resolved.
