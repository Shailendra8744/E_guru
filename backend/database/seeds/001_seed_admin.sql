INSERT INTO users (full_name, email, password_hash, role, status)
VALUES (
  'System Admin',
  'admin@eguru.local',
  '$2y$10$DHC7uvE5qf8j2OQwqVjLQurF5T9TJYF6gskzm5LMv57F9Nw6M2x8m',
  'admin',
  'active'
)
ON DUPLICATE KEY UPDATE email = email;

INSERT INTO subjects (name, description) VALUES
('Mathematics', 'Core mathematics for school students'),
('Physics', 'Mechanics, optics, electricity, and modern physics'),
('Chemistry', 'Organic, inorganic, and physical chemistry')
ON DUPLICATE KEY UPDATE name = VALUES(name);
