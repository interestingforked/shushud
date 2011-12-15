BEGIN;

INSERT INTO accounts (id) VALUES (123);
INSERT INTO providers (id) VALUES (1);
INSERT INTO rate_codes (id) VALUES (1);


INSERT INTO resource_ownership_records (account_id, hid, time, state) VALUES (123, 'app123', '2011-12-01 00:00:00 UTC', 'active');
INSERT INTO resource_ownership_records (account_id, hid, time, state) VALUES (123, 'app124', '2011-12-01 00:00:00 UTC', 'active');
INSERT INTO resource_ownership_records (account_id, hid, time, state) VALUES (123, 'app123', '2011-12-01 00:12:00 UTC', 'inactive');

INSERT INTO billable_events (provider_id, rate_code_id, hid, event_id, time, state) VALUES (1, 1, 'app123', 1, '2010-12-01 00:12:00 UTC', 'open');
INSERT INTO billable_events (provider_id, rate_code_id, hid, event_id, time, state) VALUES (1, 1, 'app124', 2, '2011-12-01 00:12:00 UTC', 'open');

CREATE VIEW billable_units AS
  SELECT
    a.hid,
    a.time as from,
    COALESCE(b.time, now()) as to

    FROM billable_events a
    LEFT OUTER JOIN billable_events b
    ON
          a.event_id    = b.event_id
      AND a.state       = 'open'
      AND b.state       = 'close'
    WHERE
          a.state       = 'open'
;

CREATE VIEW resource_ownerships AS
  SELECT a.account_id, a.hid, a.time as from, COALESCE(b.time, now()) as to
    FROM resource_ownership_records a
    LEFT OUTER JOIN resource_ownership_records b
    ON
          a.account_id  = b.account_id
      AND a.state       = 'active'
      AND b.state       = 'inactive'
    WHERE
          a.state       = 'active'
;

CREATE VIEW billables AS
SELECT
  billable_units.hid,
  GREATEST(billable_units.from, resource_ownerships.from) as from,
  LEAST(billable_units.to, resource_ownerships.to) as to
  FROM billable_units
  INNER JOIN resource_ownerships
    ON
      billable_units.hid = resource_ownerships.hid
;
