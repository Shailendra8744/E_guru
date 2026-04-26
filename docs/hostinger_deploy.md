# Hostinger Deployment Guide

## Backend Deployment

1. Upload `backend/` to server.
2. Set web root to `backend/public`.
3. Create `.env` from `.env.example` with production DB/JWT values.
4. Ensure write permissions for uploads (Phase 2 stores files under **`public/uploads/`** — e.g. `public/uploads/notes`, `public/uploads/chat`).
5. Set `APP_PUBLIC_URL` (e.g. `https://api.yourdomain.com`) so upload responses return absolute URLs when needed.
6. Set a strong `CRON_SECRET` and schedule a cron job (every 5–15 minutes) to call:
   - `GET https://api.yourdomain.com/api/v1/cron/retry-pending-doubts?secret=YOUR_CRON_SECRET`
   - or use header `X-Cron-Secret: YOUR_CRON_SECRET`
7. Run migrations and seeds via SSH:
   - `php backend/scripts/migrate.php`
   - `php backend/scripts/seed.php`

## Web Server Notes

- Enable URL rewriting to forward requests to `index.php`.
- Configure CORS based on your app origin.
- Use HTTPS and strong JWT secret.

## App Configuration

- Point Flutter `baseUrl` to your live API host:
  - Example: `https://api.yourdomain.com/api/v1`
