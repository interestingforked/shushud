Sequel.migration do
  up do
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

      CREATE TYPE usage_report_type AS (
        account_id int,
        hid varchar(255),
        "from" timestamptz,
        "to" timestamptz,
        qty numeric,
        product_name varchar(255),
        product_group varchar(255),
        rate int,
        rate_period varchar(255)
      );


      CREATE OR REPLACE FUNCTION usage_report(int, timestamptz, timestamptz) RETURNS SETOF usage_report_type
        AS $$
          SELECT
            resource_ownerships.account_id,
            billable_units.hid,
            GREATEST(billable_units.from, resource_ownerships.from, $2) as from,
            LEAST(billable_units.to, resource_ownerships.to, $3) as to,
            (
              (extract('epoch' FROM
                LEAST(billable_units.to, resource_ownerships.to, $3) - GREATEST(billable_units.from, resource_ownerships.from, $2)
              )::numeric / (3600)) -- convert seconds into hours
            ) as qty,
            rate_codes.product_name,
            rate_codes.product_group,
            rate_codes.rate,
            rate_codes.rate_period

            FROM billable_units
            LEFT OUTER JOIN rate_codes
              ON
                rate_codes.id = billable_units.rate_code_id
            INNER JOIN resource_ownerships
              ON
                billable_units.hid = resource_ownerships.hid
            WHERE
              resource_ownerships.account_id = $1
              AND
                (billable_units.from, billable_units.to)
                OVERLAPS
                (resource_ownerships.from, resource_ownerships.to)
        $$ LANGUAGE SQL
      ;

      CREATE OR REPLACE VIEW account_ownerships AS
        SELECT
          a.event_id,
          a.payment_method_id,
          a.account_id,
          a.time as from,
          COALESCE(b.time, now()) as to

          FROM account_ownership_records a
          LEFT OUTER JOIN account_ownership_records b
          ON
                a.event_id    = b.event_id
            AND a.state       = 'active'
            AND b.state       = 'inactive'
          WHERE
                a.state       = 'active'
      ;

      CREATE OR REPLACE VIEW compacted_res_own AS
        SELECT
          hid,
          account_ownerships.payment_method_id,
          min(resource_ownerships.from) as from,
          max(resource_ownerships.to) as to
        FROM
          resource_ownerships
        INNER JOIN account_ownerships
          ON account_ownerships.account_id = resource_ownerships.account_id
        GROUP BY
          hid, account_ownerships.payment_method_id
        ;

      -- don't forget to add a payment_method_id filter.
      CREATE OR REPLACE VIEW compacted_act_own AS
        SELECT DISTINCT ON(account_ownerships.payment_method_id, compacted_res_own.hid)
          compacted_res_own.hid,
          compacted_res_own.payment_method_id,
          GREATEST(account_ownerships.from, compacted_res_own.from) as from,
          LEAST(account_ownerships.to, compacted_res_own.to) as to
        FROM account_ownerships
        INNER JOIN compacted_res_own
          ON account_ownerships.payment_method_id = compacted_res_own.payment_method_id
      ;

      CREATE TYPE invoice_report_type AS (
        hid varchar(255),
        payment_method_id int,
        "from" timestamptz,
        "to" timestamptz
        --qty numeric,
        --product_name varchar(255),
        --product_group varchar(255),
        --rate int,
        --rate_period varchar(255)
      );

      CREATE OR REPLACE FUNCTION invoice(int, timestamptz, timestamptz) RETURNS SETOF invoice_report_type
        AS $$
          SELECT
            billable_units.hid,
            compacted_act_own.payment_method_id,
            GREATEST(billable_units.from, compacted_act_own.from, $2) as from,
            LEAST(billable_units.to, compacted_act_own.to, $3) as to
          FROM
            compacted_act_own
          INNER JOIN billable_units
            ON billable_units.hid = compacted_act_own.hid
          WHERE
                compacted_act_own.payment_method_id = $1
            AND ($2, $3) OVERLAPS (compacted_act_own.from, compacted_act_own.to)
        $$ LANGUAGE SQL
      ;

    EOD
  end
end
