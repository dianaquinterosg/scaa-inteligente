CREATE TABLE routine (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL REFERENCES profile(id) ON DELETE RESTRICT,
    name TEXT NOT NULL CHECK (length(name) BETWEEN 1 AND 100),
    description TEXT NOT NULL CHECK (length(description) <= 500),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE routine_step (
    id INTEGER PRIMARY KEY,
    routine_id INTEGER NOT NULL REFERENCES routine(id) ON DELETE CASCADE,
    pictogram_id INTEGER NOT NULL REFERENCES pictogram(id) ON DELETE RESTRICT,
    position INTEGER NOT NULL CHECK (position BETWEEN 1 AND 12),
    label TEXT NOT NULL CHECK (length(label) BETWEEN 1 AND 100),
    UNIQUE (routine_id, position)
);

CREATE INDEX routine_step_by_pictogram ON routine_step(pictogram_id);
