CREATE TABLE category (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(name) BETWEEN 1 AND 50),
    name_key TEXT NOT NULL UNIQUE
);

CREATE TABLE pictogram (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT NOT NULL CHECK (length(label) BETWEEN 1 AND 100),
    label_key TEXT NOT NULL,
    source TEXT NOT NULL CHECK (source IN ('ARASAAC', 'CUSTOM')),
    external_id INTEGER,
    image_path TEXT NOT NULL UNIQUE,
    media_type TEXT NOT NULL,
    attribution TEXT,
    CHECK (
        (source = 'ARASAAC' AND external_id IS NOT NULL AND external_id > 0 AND attribution IS NOT NULL)
        OR (source = 'CUSTOM' AND external_id IS NULL AND attribution IS NULL)
    ),
    UNIQUE (source, external_id)
);

CREATE TABLE pictogram_category (
    pictogram_id INTEGER NOT NULL REFERENCES pictogram(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES category(id) ON DELETE CASCADE,
    PRIMARY KEY (pictogram_id, category_id)
);

CREATE INDEX pictogram_category_by_category ON pictogram_category(category_id);
