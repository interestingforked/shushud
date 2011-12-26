Sequel.migration do
  up do

    execute(<<-EOD)
      CREATE OR REPLACE FUNCTION last_day(timestamptz)
      RETURNS timestamptz AS
      $$
        SELECT (date_trunc('MONTH', $1) + INTERVAL '1 MONTH - 1 day');
      $$ LANGUAGE 'sql' IMMUTABLE STRICT;

      CREATE OR REPLACE FUNCTION first_day(timestamptz)
      RETURNS timestamptz AS
      $$
        SELECT date_trunc('MONTH', $1);
      $$ LANGUAGE 'sql' IMMUTABLE STRICT;
    EOD

    execute(<<-EOD)
      CREATE OR REPLACE VIEW billable_units AS
        SELECT
          a.hid,
          a.event_id,
          a.rate_code_id,
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
          a.event_id,
          a.account_id,
          a.hid,
          a.time as from,
          COALESCE(b.time, now()) as to

          FROM resource_ownership_records a
          LEFT OUTER JOIN resource_ownership_records b
          ON
                a.event_id    = b.event_id
            AND a.state       = 'active'
            AND b.state       = 'inactive'
          WHERE
                a.state       = 'active'
      ;
    EOD

  end
end
