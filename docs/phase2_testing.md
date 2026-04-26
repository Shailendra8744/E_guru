# Phase 2 manual API checks

Replace `BASE` with your API root (e.g. `http://localhost:8080/api/v1`) and `TOKEN` with a JWT access token.

## Logout

```http
POST BASE/auth/logout
Authorization: Bearer TOKEN
Content-Type: application/json

{"refresh_token":"YOUR_REFRESH_TOKEN"}
```

## Admin analytics

```http
GET BASE/admin/analytics/overview
Authorization: Bearer ADMIN_TOKEN
```

## Teacher metrics

```http
GET BASE/teacher/metrics
Authorization: Bearer TEACHER_TOKEN
```

## Cron retry (server-side)

```http
GET BASE/cron/retry-pending-doubts?secret=YOUR_CRON_SECRET
```

## Upload (PDF)

```bash
curl -X POST -H "Authorization: Bearer TEACHER_TOKEN" -F "file=@/path/to/note.pdf" BASE/uploads/note-pdf
```

Ensure `backend/public/uploads` exists or let the API create it on first upload.
