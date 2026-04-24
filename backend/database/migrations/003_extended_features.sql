-- e_guru Extended Features Migration (Phase 1)
-- Adds fields required for learningapp ported features.

-- Add time limit to quizzes
ALTER TABLE quizzes 
ADD COLUMN time_limit_minutes INT UNSIGNED NULL AFTER description;

-- Note: doubts.image_path already exists in 001_init_schema.sql
