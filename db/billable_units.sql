-- dev strategy: /i this file and then rollback;
BEGIN;

SET timezone TO 'UTC';

CREATE OR REPLACE VIEW billable_units AS
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

CREATE OR REPLACE VIEW resource_ownerships AS
  SELECT
    a.account_id,
    a.hid,
    a.time as from,
    COALESCE(b.time, now()) as to

    FROM resource_ownership_records a
    LEFT OUTER JOIN resource_ownership_records b
    ON
          a.id          = b.active_id
      AND a.state       = 'active'
      AND b.state       = 'inactive'
    WHERE
          a.state       = 'active'
;

/*
  Test
*/

INSERT INTO accounts (id) VALUES (123);
INSERT INTO accounts (id) VALUES (124);
INSERT INTO providers (id) VALUES (1);
INSERT INTO rate_codes (id) VALUES (1);


--INSERT INTO resource_ownership_records (event_id, account_id, hid, time, state) VALUES (1, 123, 'app123', '2000-01-01 00:00:00 UTC', 'active');
--INSERT INTO resource_ownership_records (event_id, account_id, hid, time, state) VALUES (1, 123, 'app123', '2000-01-01 00:12:00 UTC', 'inactive');
--INSERT INTO billable_events (provider_id, rate_code_id, hid, event_id, time, state) VALUES (1, 1, 'app123', 1, '2000-01-01 00:12:00 UTC', 'open');
--
--INSERT INTO resource_ownership_records (event_id, account_id, hid, time, state) VALUES (2, 123, 'app124', '1999-01-01 00:00:00 UTC', 'active');
--INSERT INTO billable_events (provider_id, rate_code_id, hid, event_id, time, state) VALUES (1, 1, 'app124', 2, '2000-01-01 00:00:00 UTC', 'open');
--INSERT INTO billable_events (provider_id, rate_code_id, hid, event_id, time, state) VALUES (1, 1, 'app124', 2, '2000-01-02 00:12:00 UTC', 'close');

/*
 SELECT * FROM billables;
 account_id |  hid   |          from          |           to
------------+--------+------------------------+------------------------
        123 | app123 | 2000-01-01 00:12:00+00 | 2000-01-01 00:12:00+00
        123 | app124 | 2000-01-01 00:00:00+00 | 2000-01-02 00:12:00+00
*/

-- Billable Event will span a month but ownership goes back and forth
--INSERT INTO billable_events (provider_id, rate_code_id, hid, event_id, time, state) VALUES (1, 1, 'app124', 3, '2000-01-01 00:00:00 UTC', 'open');

INSERT INTO resource_ownership_records (account_id, hid, time, state) VALUES (123, 'app124', '1999-01-01 00:00:00 UTC', 'active');
INSERT INTO resource_ownership_records (active_id, account_id, hid, time, state) VALUES ((SELECT id FROM resource_ownership_records order by id ASC limit 1), 123, 'app124', '2000-01-02 00:00:00 UTC', 'inactive');

INSERT INTO resource_ownership_records (account_id, hid, time, state) VALUES (124, 'app124', '2000-01-02 00:00:00 UTC', 'active');
INSERT INTO resource_ownership_records (active_id, account_id, hid, time, state) VALUES ((SELECT id FROM resource_ownership_records order by id ASC OFFSET 2 limit 1), 124, 'app124', '2000-01-10 00:00:00 UTC', 'inactive');

INSERT INTO resource_ownership_records (account_id, hid, time, state) VALUES (123, 'app124', '2000-01-10 00:00:00 UTC', 'active');

/*
 SELECT * FROM billables;

 account_id |  hid   |          from          |           to
------------+--------+------------------------+------------------------
        123 | app124 | 2000-01-01 00:00:00+00 | 2000-01-02 00:00:00+00
        124 | app124 | 2000-01-02 00:00:00+00 | 2000-01-10 00:00:00+00
        123 | app124 | 2000-01-10 00:00:00+00 | 2000-01-31 00:00:00+00
*/

