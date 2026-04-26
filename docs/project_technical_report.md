# e_guru Project Technical Report

Prepared from the repository snapshot in `c:\Users\hp\Desktop\e_guru` on April 26, 2026.

## 1. Project Overview

`e_guru` is a role-based smart education platform built as a Flutter application with a PHP REST API and a MySQL database. The product focuses on three user roles:

- `student`
- `teacher`
- `admin`

The main business goal is to support learning workflows around:

- authentication and role-based access
- teacher approval by admin
- subject management
- note upload and PDF-based study materials
- quiz creation, attempt, scoring, and history
- doubt posting and teacher-student discussion
- automated doubt assignment
- ratings and gamification
- analytics dashboards for each role

## 2. High-Level Architecture

### Frontend

- Framework: Flutter
- Language: Dart
- State management: Riverpod
- Local persistence: `shared_preferences`
- Networking: `http`
- PDF reading: `syncfusion_flutter_pdfviewer`
- File picking/upload helpers: `file_picker`, `image_picker`
- Charts: `fl_chart`

### Backend

- Language: PHP 8+
- API style: REST-like JSON endpoints
- Entrypoint: `backend/public/index.php`
- Data access: PDO
- Authentication: custom JWT + refresh token table
- File uploads: local filesystem under `backend/public/uploads`

### Database

- Engine target: MySQL / MariaDB
- Schema management: SQL migrations in `backend/database/migrations`
- Seed data: SQL seed files in `backend/database/seeds`

## 3. Repository Structure

- `lib/` - Flutter app source
- `backend/public/` - public PHP API entry and helper files
- `backend/src/` - backend infrastructure classes and services
- `backend/database/migrations/` - 5 schema migration files
- `backend/database/seeds/` - seed SQL
- `backend/scripts/` - migration and seed runners
- `docs/` - scope, API, UAT, deployment, and testing docs
- `test/` - Flutter widget test placeholder
- platform folders: `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`

Observed codebase counts:

- 31 Dart files under `lib/`
- 14 PHP files under `backend/`
- 5 SQL migration files
- 6 documentation files under `docs/`

## 4. Functional Features

### 4.1 Authentication and Session

- student and teacher registration
- login with email and password
- session persistence in local storage
- logout with backend refresh token revocation
- role-based landing page selection
- teacher login blocked until admin approval
- unauthorized callback that clears local session

### 4.2 Admin Features

- view pending teacher registrations
- approve or reject teacher accounts
- create subjects
- list all users with pagination
- change user role
- change user status
- assign subjects to teachers
- view analytics overview
- view quiz analytics
- view doubt SLA analytics

### 4.3 Teacher Features

- teacher dashboard
- upload note PDFs
- create quizzes with multiple questions
- edit existing quizzes
- list created quizzes
- inspect quiz participation/results
- view assigned doubts
- open doubt chat
- send text and image replies
- resolve doubts
- view metrics such as rating and counts

### 4.4 Student Features

- student dashboard
- fetch study materials from teachers
- open PDFs inside app
- view quizzes
- attempt quizzes
- automatic score calculation and result screen
- view quiz history
- view subject-wise quiz insights
- post doubts
- view own doubts and status
- chat on doubts
- rate teacher after doubt resolution
- leaderboard view
- profile and personal analytics view
- local to-do list stored with shared preferences

### 4.5 Gamification Features

- XP stored on `users.xp`
- XP awarded after quiz submission
- XP awarded to teacher and student when a doubt is resolved
- leaderboard endpoint for students ordered by XP

### 4.6 Analytics Features

- admin overview counts for users, students, teachers, doubts, resolved doubts, quizzes
- admin quiz analytics with attempt counts and average score percentage
- admin doubt SLA metrics including average resolution time
- teacher metrics for rating, active doubts, resolved doubts, first reply metric
- student metrics endpoint for average score, total activity, recent quiz activity, XP
- student subject-wise quiz insights

### 4.7 File Handling Features

- PDF upload for study notes
- image upload for doubt chat
- MIME validation on uploads
- size validation on uploads
- automatic upload directory creation
- generated unique filenames

## 5. Frontend Module Inventory

### Core files

- `lib/main.dart` - app bootstrap, theme selection, role-based home switch
- `lib/core/auth_store.dart` - session model, login/logout, persistence, API base URL
- `lib/core/api_client.dart` - GET/POST/PUT/multipart helpers, bearer auth, JSON decoding
- `lib/core/quiz_store.dart` - quiz and question models plus quiz providers
- `lib/core/theme_provider.dart` - light/dark theme state

### Auth screens

- `login_page.dart` - login UI
- `registration_page.dart` - registration UI with role picker

### Admin screens

- `admin_home_page.dart` - admin dashboard and pending teacher actions
- `admin_analytics_page.dart` - analytics dashboard
- `user_management_page.dart` - role/status management and teacher subject assignment
- `subjects_page.dart` - subject creation and listing

### Teacher screens

- `teacher_home_page.dart` - dashboard, quick actions, metrics, assigned doubts
- `upload_note_page.dart` - note PDF upload flow
- `create_quiz_page.dart` - create/edit quiz with dynamic question list
- `quiz_history_page.dart` - list teacher quizzes
- `quiz_results_page.dart` - quiz attempt results
- `doubt_chat_page.dart` - doubt discussion screen, image upload, resolve action

### Student screens

- `student_home_page.dart` - dashboard with notes, quizzes, insights, to-do list
- `student_profile_page.dart` - profile and shortcut cards
- `student_analytics_page.dart` - charts and activity metrics
- `study_materials_page.dart` - study note listing
- `all_notes_page.dart` - external notes API integration
- `pdf_reader_page.dart` - in-app PDF reader
- `quizzes_page.dart` / `quiz_list_page.dart` - quiz browsing flows
- `quiz_taking_page.dart` - answering and submission
- `quiz_analysis_page.dart` - result/analysis presentation
- `my_quiz_history_page.dart` - previous attempts
- `post_doubt_page.dart` - doubt creation
- `my_doubts_page.dart` - doubt history and statuses
- `leaderboard_page.dart` - XP ranking display

## 6. Backend API Inventory

### Auth endpoints

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/logout`
- `POST /api/v1/auth/refresh`

### Admin endpoints

- `GET /api/v1/admin/teachers/pending`
- `POST /api/v1/admin/teachers/{id}/approve`
- `POST /api/v1/admin/teachers/{id}/reject`
- `GET /api/v1/admin/users`
- `POST /api/v1/admin/users/{id}/role`
- `POST /api/v1/admin/users/{id}/status`
- `GET /api/v1/admin/teachers/{id}/subjects`
- `POST /api/v1/admin/teachers/{id}/subjects`
- `GET /api/v1/admin/subjects`
- `POST /api/v1/admin/subjects`
- `GET /api/v1/admin/analytics/overview`
- `GET /api/v1/admin/analytics/quizzes`
- `GET /api/v1/admin/quizzes/{id}/results`
- `GET /api/v1/admin/analytics/doubts-sla`

### Shared / subject endpoints

- `GET /api/v1/subjects`

### Teacher endpoints

- `POST /api/v1/teacher/notes`
- `POST /api/v1/teacher/quizzes`
- `GET /api/v1/teacher/quizzes`
- `GET /api/v1/teacher/quizzes/{id}`
- `PUT /api/v1/teacher/quizzes/{id}`
- `GET /api/v1/teacher/quizzes/{id}/results`
- `GET /api/v1/teacher/doubts`
- `POST /api/v1/teacher/doubts/{id}/resolve`
- `GET /api/v1/teacher/metrics`

### Student endpoints

- `GET /api/v1/student/notes`
- `GET /api/v1/student/quizzes`
- `GET /api/v1/student/quizzes/{id}`
- `POST /api/v1/student/quizzes/{id}/submit`
- `GET /api/v1/student/quiz-history`
- `GET /api/v1/student/quiz-insights`
- `GET /api/v1/student/metrics`
- `POST /api/v1/student/doubts`
- `GET /api/v1/student/doubts`
- `POST /api/v1/student/doubts/{id}/rate`

### Doubt chat endpoints

- `GET /api/v1/doubts/{id}/messages`
- `POST /api/v1/doubts/{id}/messages`

### Upload endpoints

- `POST /api/v1/uploads/note-pdf`
- `POST /api/v1/uploads/chat-image`

### Cron / system endpoints

- `GET /api/v1/cron/retry-pending-doubts`
- `GET /api/v1/leaderboard`

## 7. Database Design

Main tables created by migration:

- `users`
- `subjects`
- `teacher_subjects`
- `notes`
- `quizzes`
- `quiz_questions`
- `quiz_results`
- `doubts`
- `doubt_messages`
- `teacher_ratings`
- `refresh_tokens`
- `user_activity_logs`

Later schema additions:

- `doubts.assignment_attempts`
- `doubts.last_assignment_attempt_at`
- `quizzes.time_limit_minutes`
- `users.xp`
- `quiz_results.answers`

### Important relationships

- one admin can approve many teachers
- many teachers can map to many subjects through `teacher_subjects`
- one teacher can create many notes and quizzes
- one quiz has many quiz questions
- one student can have one result per quiz because of unique `(quiz_id, student_id)`
- one doubt belongs to one student and one subject
- one doubt may have a chosen teacher and/or assigned teacher
- one doubt has many messages
- one resolved doubt can have one rating
- one user can own many refresh tokens

### Indexing observed

- doubt lookup by subject/status/created time
- doubt lookup by assigned teacher and status
- message lookup by doubt and sent time
- teacher rating lookup by teacher and created time
- retry lookup for pending assignments

## 8. Algorithms and Data Structures Used

This project is mostly CRUD plus workflow logic, but several concrete algorithms and structures are used.

### 8.1 Auto-assignment scoring algorithm

File: `backend/src/DoubtAssignmentService.php`

Type:

- weighted scoring / ranking algorithm
- greedy best-candidate selection

Inputs:

- teacher average rating
- active doubt workload
- recent average first response time
- subject match through `teacher_subjects`
- max active doubts threshold

Score formula:

- normalized rating score
- inverse workload score: `1 / (1 + active_count)`
- inverse response-time score based on 7200-second normalization
- weighted sum using environment-configured weights

Selection strategy:

- iterate over all eligible teachers for the subject
- skip overloaded teachers
- compute composite score
- keep the teacher with the highest score

This is effectively a linear scan over candidate teachers: `O(n)` for `n` matching teachers after the SQL result is loaded.

### 8.2 Quiz evaluation algorithm

File: `backend/public/index.php`

Type:

- answer matching and accumulation

Steps:

- fetch all quiz questions
- iterate through each question
- compare submitted answer with `correct_option`
- accumulate `score`
- accumulate `total_marks`
- upsert final result into `quiz_results`

Time complexity:

- `O(q)` where `q` is the number of questions in the quiz

### 8.3 Pagination algorithm

File: `backend/src/Pagination.php`

Type:

- offset-based pagination

Logic:

- normalize `page`
- clamp `per_page` to max 100
- compute `offset = (page - 1) * per_page`
- return metadata including total pages

### 8.4 Polling-based chat retrieval

Files:

- `backend/public/index.php`
- `lib/features/teacher/doubt_chat_page.dart`

Type:

- incremental fetch using ordered IDs

Logic:

- request messages for a doubt
- optionally filter by `after` message ID
- order ascending by message ID
- limit result count

This is a simple append-friendly retrieval pattern using ordered records.

### 8.5 Leaderboard ranking

File: `backend/src/api/gamification.php`

Type:

- sorting/ranking by XP descending

Logic:

- query students
- order by `xp DESC`
- limit to top 20

### 8.6 Data structures used in code

- Dart `List<dynamic>` for notes, quizzes, doubts, insights
- Dart `Map<String, dynamic>` for decoded JSON objects
- Riverpod providers for reactive state access
- SQL tables for persistent relational data
- JSON column in `quiz_results.answers` for submitted answer maps
- session JSON serialized into shared preferences

## 9. Workflow and Control Flow Design

### Login flow

1. user submits email/password
2. backend validates credentials
3. backend creates access and refresh tokens
4. app stores tokens in `shared_preferences`
5. app routes user to role-specific home page

### Teacher approval flow

1. teacher registers
2. backend stores status `pending_approval`
3. admin sees teacher in pending list
4. admin approves or rejects
5. teacher can log in only after activation

### Doubt flow

1. student posts doubt
2. if teacher chosen, assign directly
3. otherwise run auto-assignment
4. if no teacher found, mark as `pending_assignment`
5. cron retry endpoint attempts later assignment
6. chat happens through polling endpoints
7. teacher resolves doubt
8. student can rate teacher

### Quiz flow

1. teacher creates quiz metadata and questions
2. student lists active quizzes
3. student opens quiz details
4. student submits answers
5. backend calculates score
6. result stored or updated
7. XP awarded
8. history and analytics update

## 10. Security and Reliability Mechanisms

Implemented:

- password hashing with `password_hash`
- password verification with `password_verify`
- JWT signing with HMAC SHA-256
- refresh tokens stored hashed in database
- role-based authorization checks
- teacher approval gate before login
- MIME type and size validation for uploads
- prepared statements through PDO
- CORS headers for API access

Important operational controls:

- `.env` based configuration
- cron secret for retry endpoint
- upload size limits through env values
- assignment weight tuning through env values

## 11. External Integrations and Special Behaviors

- production API base URL currently points to `https://engineerfarm.in/backend/public/api/v1`
- some frontend code directly references `https://engineerfarm.in/backend/public`
- `all_notes_page.dart` calls an external endpoint `https://engineerfarm.in/api/notes.php`
- leaderboard avatars use `ui-avatars.com`

This means the app is partly environment-coupled to one deployed domain instead of being fully configuration-driven.

## 12. Technical Assessment

### Strengths

- clear separation between mobile app, backend, DB migrations, and docs
- strong feature coverage for an academic workflow MVP plus phase-2 extensions
- role-based architecture is consistent across UI, API, and schema
- custom auto-assignment logic is meaningful and configurable
- pagination, analytics, uploads, and logout revocation improve production readiness
- database schema uses foreign keys and useful indexes
- Flutter UI has dedicated screens for each role and decent modular separation

### Good engineering choices

- PDO with prepared statements
- hashed refresh tokens instead of storing raw refresh tokens
- relational modeling for users, subjects, quizzes, doubts, and ratings
- migration and seed scripts for reproducible setup
- use of Riverpod for session and async state
- multipart upload support handled centrally

### Weaknesses / risks

- `backend/public/index.php` is a very large monolithic router and contains most business logic in one file
- `backend/src/api/quizzes.php` exists but is not yet implemented, showing incomplete modularization
- the frontend contains hardcoded production URLs in multiple places
- several list screens still rely on `List<dynamic>` and untyped maps rather than fully modeled entities
- chat is polling-based, so it is simpler but less real-time and less scalable than websockets
- teacher metrics currently returns a fixed fallback value `120` seconds for average first reply instead of a complete implementation
- logout and refresh token matching iterate through active refresh tokens and verify hashes row by row, which can become inefficient as token count grows
- app theme state is not persisted
- the included Flutter widget test is still the default counter test and does not match the actual app
- no automated backend test suite is present

### Dependency observations

Dependencies clearly used:

- `http`
- `shared_preferences`
- `syncfusion_flutter_pdfviewer`
- `file_picker`
- `fl_chart`
- `image_picker`

Dependencies present but not obviously used in the inspected app code:

- `go_router`
- `mailer`
- `flutter_pdfview`
- `path_provider`
- `flutter_dotenv`

This may indicate planned work, leftovers, or partially removed experiments.

### Maintainability assessment

Overall maintainability is moderate:

- frontend structure is understandable and feature-oriented
- backend structure is functionally workable
- the main maintainability problem is backend concentration of logic in one file and limited typed modeling on the frontend

### Scalability assessment

Suitable for:

- MVP
- student project
- internal demo
- small to moderate real deployment after cleanup

Would need work before larger scale:

- router/controller/service separation
- stronger environment management
- automated tests
- better token revocation lookup strategy
- websocket or push-based messaging
- stricter typing and DTO/model layers

## 13. Documentation and Testing Status

Present documentation:

- `README.md`
- `docs/mvp_scope.md`
- `docs/phase2_api.md`
- `docs/phase2_backlog.md`
- `docs/phase2_testing.md`
- `docs/uat_checklist.md`
- `docs/hostinger_deploy.md`

Testing status observed:

- manual API test notes exist
- UAT checklist exists
- only one Flutter widget test exists and it is still template-level, not project-relevant
- no PHPUnit or automated integration tests found

## 14. Summary for Academic / Viva Report

Short summary you can reuse:

`e_guru` is a multi-role education support application that combines study material sharing, quiz-based assessment, doubt resolution, analytics, and gamification. The system is implemented with a Flutter frontend, a PHP REST backend, and a MySQL relational database. Its most notable technical feature is a weighted doubt auto-assignment algorithm that ranks eligible teachers using rating, current workload, and historical response time. The system follows a role-based workflow for students, teachers, and admins, includes JWT-based authentication with refresh token revocation, supports PDF and image uploads, and provides dashboard analytics. Technically, it is a strong MVP/phase-2 level project with solid breadth of functionality, though it would benefit from backend modularization, automated testing, and stronger environment abstraction for production maturity.

## 15. Recommended Attachments for Final Project Report

When preparing your final report document, include these supporting items:

- architecture diagram: Flutter -> PHP API -> MySQL
- ER diagram for main tables
- API endpoint table
- UI screenshots for student, teacher, and admin dashboards
- explanation of the auto-assignment algorithm
- database schema summary
- testing/UAT checklist results
- limitations and future enhancements

