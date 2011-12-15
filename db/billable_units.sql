-- dev strategy: /i this file and then rollback;
BEGIN;

SET timezone TO 'UTC';

/*
  BillableUnit
  Setup correct from and to timestamps
*/

/*
  Test
*/

INSERT INTO accounts (id) VALUES (123);
INSERT INTO accounts (id) VALUES (124);
INSERT INTO providers (id) VALUES (1);
INSERT INTO rate_codes (id) VALUES (1);


INSERT INTO resource_ownership_records (event_id, account_id, hid, time, state) VALUES (1, 123, 'app123', '2000-01-01 00:00:00 UTC', 'active');
INSERT INTO resource_ownership_records (event_id, account_id, hid, time, state) VALUES (1, 123, 'app123', '2000-01-01 00:12:00 UTC', 'inactive');
INSERT INTO billable_events (provider_id, rate_code_id, hid, event_id, time, state) VALUES (1, 1, 'app123', 1, '2000-01-01 00:12:00 UTC', 'open');

INSERT INTO resource_ownership_records (event_id, account_id, hid, time, state) VALUES (2, 123, 'app124', '1999-01-01 00:00:00 UTC', 'active');
INSERT INTO billable_events (provider_id, rate_code_id, hid, event_id, time, state) VALUES (1, 1, 'app124', 2, '2000-01-01 00:00:00 UTC', 'open');
INSERT INTO billable_events (provider_id, rate_code_id, hid, event_id, time, state) VALUES (1, 1, 'app124', 2, '2000-01-02 00:12:00 UTC', 'close');

/*
 SELECT * FROM billables;
 account_id |  hid   |          from          |           to
------------+--------+------------------------+------------------------
        123 | app123 | 2000-01-01 00:12:00+00 | 2000-01-01 00:12:00+00
        123 | app124 | 2000-01-01 00:00:00+00 | 2000-01-02 00:12:00+00
*/

-- Billable Event will span a month but ownership goes back and forth
INSERT INTO billable_events (provider_id, rate_code_id, hid, event_id, time, state) VALUES (1, 1, 'app124', 3, '2000-01-01 00:00:00 UTC', 'open');

INSERT INTO resource_ownership_records (event_id, account_id, hid, time, state) VALUES (3, 123, 'app124', '1999-01-01 00:00:00 UTC', 'active');
INSERT INTO resource_ownership_records (event_id, account_id, hid, time, state) VALUES (3, 123, 'app124', '2000-01-02 00:00:00 UTC', 'inactive');

INSERT INTO resource_ownership_records (event_id, account_id, hid, time, state) VALUES (4, 124, 'app124', '2000-01-02 00:00:00 UTC', 'active');
INSERT INTO resource_ownership_records (event_id, account_id, hid, time, state) VALUES (4, 124, 'app124', '2000-01-10 00:00:00 UTC', 'inactive');

INSERT INTO resource_ownership_records (event_id, account_id, hid, time, state) VALUES (5, 123, 'app124', '2000-01-10 00:00:00 UTC', 'active');

/*
 SELECT * FROM billables;

 account_id |  hid   |          from          |           to
------------+--------+------------------------+------------------------
        123 | app124 | 2000-01-01 00:00:00+00 | 2000-01-02 00:00:00+00
        124 | app124 | 2000-01-02 00:00:00+00 | 2000-01-10 00:00:00+00
        123 | app124 | 2000-01-10 00:00:00+00 | 2000-01-31 00:00:00+00
*/

