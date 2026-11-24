-- +goose Up
CREATE TABLE events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL CHECK (char_length(trim(name)) > 0),
    start_time TIMESTAMPTZ NOT NULL
);

CREATE TABLE seats (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES events (id) ON DELETE NO ACTION,
    code VARCHAR(20) NOT NULL CHECK (char_length(trim(code)) > 0),
    price BIGINT NOT NULL CHECK (price >= 0),
    CONSTRAINT seat_at_event_constraint UNIQUE (event_id, code)
);

-- +goose Down
DROP TABLE seats;
DROP TABLE events;
