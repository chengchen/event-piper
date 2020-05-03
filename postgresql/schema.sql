CREATE TABLE events
(
    id         BIGSERIAL PRIMARY KEY,
    type       varchar                     NOT NULL,
    timestamp  timestamp without time zone NOT NULL,
    subscriber varchar                     NOT NULL,
    payload    jsonb                       NOT NULL
);

CREATE INDEX idx_event_subscribers ON events (subscriber);

CREATE OR REPLACE FUNCTION notify_new_event()
RETURNS trigger AS $$
    BEGIN
        PERFORM pg_notify('new_events', row_to_json(NEW)::text);
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_created
    AFTER INSERT
    ON events
    FOR EACH ROW
EXECUTE PROCEDURE notify_new_event();
