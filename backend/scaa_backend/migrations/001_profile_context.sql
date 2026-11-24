CREATE TABLE profile (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    alias TEXT NOT NULL CHECK (length(alias) BETWEEN 1 AND 50),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE context_item (
    id INTEGER PRIMARY KEY,
    profile_id INTEGER NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('INTEREST', 'ACTIVITY', 'ROUTINE')),
    value TEXT NOT NULL CHECK (length(value) BETWEEN 1 AND 50),
    value_key TEXT NOT NULL,
    UNIQUE (profile_id, type, value_key)
);
