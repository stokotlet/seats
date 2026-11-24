-- Development data: a few events, one of them a 20 000-seat arena.
-- Safe to run repeatedly: existing events and seats are left untouched.
-- Run with `make seed` after the migrations are applied.

CREATE TEMP TABLE seed_events (
    name TEXT NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    row_count INT NOT NULL,
    seats_per_row INT NOT NULL,
    front_row_price BIGINT NOT NULL
) ON COMMIT DROP;

INSERT INTO seed_events (name, start_time, row_count, seats_per_row, front_row_price) VALUES
    ('Arena Live: Main Stage',    '2027-03-14 19:00:00+00', 100, 200, 450000),
    ('Chamber Orchestra Evening', '2027-02-20 18:30:00+00',  20,  25, 250000),
    ('Stand-up Night',            '2027-01-30 20:00:00+00',  10,  15, 150000),
    ('Private Rehearsal',         '2027-01-15 12:00:00+00',   0,   0,      0);

INSERT INTO events (name, start_time)
SELECT s.name, s.start_time
FROM seed_events s
WHERE NOT EXISTS (SELECT 1 FROM events e WHERE e.name = s.name);

-- Rows are labelled A..Z, then AA, AB, ... like spreadsheet columns.
-- Price drops linearly from the front row to half of it in the last row.
INSERT INTO seats (event_id, code, price)
SELECT
    e.id,
    CASE
        WHEN r <= 26 THEN chr(64 + r)
        ELSE chr(64 + (r - 1) / 26) || chr(65 + (r - 1) % 26)
    END || '-' || n,
    s.front_row_price - (r - 1) * s.front_row_price / (2 * s.row_count)
FROM seed_events s
JOIN events e ON e.name = s.name
CROSS JOIN LATERAL generate_series(1, s.row_count) AS r
CROSS JOIN LATERAL generate_series(1, s.seats_per_row) AS n
ON CONFLICT (event_id, code) DO NOTHING;

-- Refresh planner statistics so EXPLAIN reflects the new row counts.
ANALYZE events;
ANALYZE seats;

SELECT e.id, e.name, count(s.id) AS seats
FROM events e
LEFT JOIN seats s ON s.event_id = e.id
WHERE e.name IN (SELECT name FROM seed_events)
GROUP BY e.id, e.name
ORDER BY e.id;
