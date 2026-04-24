-- Phase 2: assignment retry tracking for pending doubts
ALTER TABLE doubts
  ADD COLUMN assignment_attempts INT UNSIGNED NOT NULL DEFAULT 0 AFTER assignment_reason,
  ADD COLUMN last_assignment_attempt_at DATETIME NULL AFTER assignment_attempts;

CREATE INDEX idx_doubts_pending_retry ON doubts (status, last_assignment_attempt_at, created_at);
