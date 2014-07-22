CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body VARCHAR(255) NOT NULL,
  author_id VARCHAR(255) NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_followers (
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_reply INTEGER,
  author_id INTEGER NOT NULL,
  body VARCHAR(255) NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_reply) REFERENCES replies(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users(fname, lname)
VALUES
  ('John', 'Smith'), ('Derek', 'Jeter'), ('Sam', 'Rodriguez');

INSERT INTO
  questions(title, body, author_id)
VALUES
  ('How do you program?', 'I want to learn how to program', (SELECT id FROM users WHERE lname = 'Smith')),
  ('How do you use a computer?', 'I want to use computers', (SELECT id FROM users WHERE lname = 'Jeter'));

INSERT INTO
  question_followers(question_id, user_id)
VALUES
  ((SELECT id FROM questions WHERE title = 'How do you program?'), (SELECT id FROM users WHERE lname = 'Smith'));

INSERT INTO
  replies(question_id, parent_reply, author_id, body)
VALUES
  ((SELECT id FROM questions WHERE title = 'How do you program?'), NULL,
   (SELECT id FROM users WHERE lname = 'Jeter'), 'Great question!');

INSERT INTO
  question_likes(user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE lname = 'Jeter'), (SELECT id FROM questions WHERE title = 'How do you program?'));



