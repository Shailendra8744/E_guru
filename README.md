# e_guru — Smart Education Doubt Solving App

Role-based mobile learning platform: **Flutter** app + **PHP** REST API + **MySQL**. Students read notes, take quizzes, and open doubts with teachers; admins approve teachers and manage subjects.

## Documentation map

| Document | Purpose |
|----------|---------|
| [TODO.md](TODO.md) | Checklist: verify setup, then next tasks |
| [docs/mvp_scope.md](docs/mvp_scope.md) | Phase 1 MVP scope and acceptance criteria |
| [docs/uat_checklist.md](docs/uat_checklist.md) | User acceptance testing checklist |
| [docs/hostinger_deploy.md](docs/hostinger_deploy.md) | Hostinger / production deployment notes |
| [docs/phase2_backlog.md](docs/phase2_backlog.md) | Phase 2 scope and delivered items |
| [docs/phase2_api.md](docs/phase2_api.md) | Phase 2 API reference |
| [docs/phase2_testing.md](docs/phase2_testing.md) | Manual API checks |

## Tech stack

- **Mobile:** Flutter (Dart), Riverpod
- **Backend:** PHP REST API (`backend/public/index.php`)
- **Database:** MySQL
- **Hosting:** Compatible with Hostinger-style PHP + MySQL hosting
- **Auth:** JWT access token + refresh token (stored hashed in DB)

## Prerequisites

- PHP 8+ with PDO MySQL extension
- MySQL 5.7+ or MariaDB 10+
- Flutter SDK (see `pubspec.yaml` for Dart SDK constraint)
- On **Windows**, Flutter may ask you to enable **Developer Mode** for symlink support when building with certain plugins

## Repository layout

```
e_guru/
├── lib/                    # Flutter application
├── backend/
│   ├── public/index.php    # API entrypoint
│   ├── src/                # bootstrap, DB, JWT helpers
│   ├── database/
│   │   ├── migrations/     # SQL schema
│   │   └── seeds/          # seed data (admin, sample subjects)
│   ├── scripts/            # migrate.php, seed.php
│   └── .env.example        # copy to .env
├── docs/                   # scope, UAT, deploy, backlog
├── TODO.md                 # project checklist
└── README.md               # this file
```

## Backend setup (local)

1. Create a MySQL database (e.g. `e_guru`).
2. Copy `backend/.env.example` to `backend/.env` and set:
   - `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`
   - `JWT_SECRET` (use a long random string in production)
   - `JWT_ACCESS_TTL`, `JWT_REFRESH_TTL` as needed
3. From the project root, run (runs every `*.sql` file in `backend/database/migrations/`, including Phase 2):

   ```bash
   php backend/scripts/migrate.php
   php backend/scripts/seed.php
   ```

4. Copy Phase 2 settings from `backend/.env.example` into `backend/.env` as needed: `CRON_SECRET`, `APP_PUBLIC_URL`, `UPLOAD_MAX_BYTES`, assignment weights, etc.

5. Point your web server document root to **`backend/public`**, or use PHP’s built-in server for quick tests:

   ```bash
   php -S localhost:8080 -t backend/public
   ```

6. Smoke test: open `http://localhost:8080/` — you should see a small JSON greeting from the API. Uploaded files are stored under `backend/public/uploads/`.

On Hostinger, schedule a request to `GET /api/v1/cron/retry-pending-doubts` with your `CRON_SECRET` (header or query) so `pending_assignment` doubts are retried.

## Flutter app setup

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Set the API base URL in **`lib/core/auth_store.dart`** — look for `apiClientProvider`. Examples:
   - Android emulator hitting PHP on the host: often `http://10.0.2.2:8080/api/v1` (if using port 8080)
   - Physical device: use your PC’s LAN IP, e.g. `http://192.168.1.x:8080/api/v1`
   - Production: `https://your-api-domain.com/api/v1`

3. Run the app:

   ```bash
   flutter run
   ```

## Implemented MVP features (summary)

- Register/login; JWT + refresh
- Roles: **admin**, **teacher**, **student**; teachers need admin approval before login
- Admin: pending teachers, approve/reject, create subjects
- Student: list notes (PDF viewer), list quizzes, submit quiz, create doubts, chat (polling), rate after resolve
- Teacher: create notes/quizzes (metadata/API), list assigned doubts, resolve doubts
- Smart doubt assignment when the student does not pick a teacher (subject-based scoring)

## Phase 2 (delivered)

- Admin analytics (`/admin/analytics/*`), teacher metrics (`/teacher/metrics`), student quiz insights (`/student/quiz-insights`)
- Paginated list APIs with `meta`
- Multipart uploads (`/uploads/note-pdf`, `/uploads/chat-image`)
- Improved assignment scoring and cron retry for unassigned doubts
- `POST /auth/logout` revokes refresh tokens

Details: [docs/phase2_api.md](docs/phase2_api.md), [docs/phase2_backlog.md](docs/phase2_backlog.md).

## API prefix

All versioned routes are under **`/api/v1`** (see `backend/public/index.php`).

## Security notes

- Never commit **`backend/.env`** (it is gitignored).
- Change any default seeded admin credentials before production; prefer creating a new admin via DB or a one-off script.
- Use HTTPS in production; keep `JWT_SECRET` private.

## After you verify everything works

Open **[TODO.md](TODO.md)** and work through the verification section, then the short-term and deployment items.
# E_guru
