$: << File.expand_path('lib')
require 'shushu'

Sequel.migration do
  up do
    execute(<<-EOD)
      CREATE EXTENSION hstore;

      CREATE TYPE report_type AS (
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

      CREATE OR REPLACE VIEW payments_ready_for_process AS
        SELECT DISTINCT ON (a.receivable_id)
          a.payment_method_id,
          a.receivable_id
        FROM payment_attempt_records a
        WHERE NOT EXISTS (
          SELECT 1
          FROM payment_attempt_records b
          WHERE
            a.receivable_id = b.receivable_id
            AND b.state = 'success'
        )
        AND (a.wait_until <= now() OR a.wait_until IS NULL)
      ;

      CREATE OR REPLACE VIEW account_ownerships AS
        SELECT
          a.entity_id,
          a.payment_method_id,
          a.account_id,
          a.time as from,
          COALESCE(b.time, now()) as to

          FROM account_ownership_records a
          LEFT OUTER JOIN account_ownership_records b
          ON
                a.entity_id    = b.entity_id
            AND a.state       = 'active'
            AND b.state       = 'inactive'
          WHERE
                a.state       = 'active'
      ;

      CREATE OR REPLACE VIEW billable_units AS
        SELECT
          a.hid,
          a.entity_id,
          a.time as from,
          COALESCE(b.time, now()) as to,
          (
            extract('epoch' FROM COALESCE(b.time, now()) - a.time)::numeric
            / 3600
          ) as qty,
          a.rate_code_id,
          rate_codes.product_group,
          COALESCE(rate_codes.product_name, a.product_name) as product_name,
          rate_codes.rate,
          rate_codes.rate_period

          FROM billable_events a
          LEFT OUTER JOIN rate_codes
          ON
            rate_codes.id = a.rate_code_id
          LEFT OUTER JOIN billable_events b
          ON
                a.entity_id   = b.entity_id
            AND a.state       = 1
            AND b.state       = 0
          WHERE
                a.state       = 1
      ;

      CREATE OR REPLACE VIEW inv AS
        SELECT
          a.hid,
          array_agg(hstore(a.*)) as billable_units,
          sum(a.qty) as dyno_hours,
          (sum(a.qty) - LEAST(sum(a.qty), 750)) as adjusted_dyno_hours
        FROM billable_units a
        GROUP BY a.hid
      ;

      CREATE OR REPLACE VIEW resource_ownerships AS
        SELECT
          a.entity_id,
          a.account_id,
          a.hid,
          a.time as from,
          COALESCE(b.time, now()) as to

          FROM resource_ownership_records a
          LEFT OUTER JOIN resource_ownership_records b
          ON
                a.entity_id    = b.entity_id
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

      CREATE TYPE rate_code_report_type AS (
        hid text,
        "from" timestamptz,
        "to" timestamptz,
        qty numeric,
        rate int,
        rate_period text,
        product_name text,
        product_group text
      );

      CREATE OR REPLACE FUNCTION rate_code_report(integer, timestamptz, timestamptz)
      RETURNS SETOF rate_code_report_type AS $$
        SELECT
          billable_units.hid,
          GREATEST(billable_units.from, $2) as from,
          LEAST(billable_units.to, $3) as to,
          (
            (extract('epoch' FROM
              LEAST(billable_units.to, $3) - GREATEST(billable_units.from, $2)
            )::numeric / (3600)) -- convert seconds into hours
          ) as qty,
          billable_units.rate,
          billable_units.rate_period,
          billable_units.product_name,
          billable_units.product_group
        FROM
          billable_units
        WHERE
          (billable_units.from, billable_units.to) OVERLAPS ($2, $3)
          AND
          billable_units.rate_code_id = $1
      $$ LANGUAGE SQL
      ;

      CREATE OR REPLACE FUNCTION usage_report(int, timestamptz, timestamptz) RETURNS SETOF report_type
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
            billable_units.product_name,
            billable_units.product_group,
            billable_units.rate,
            billable_units.rate_period

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

      CREATE OR REPLACE FUNCTION invoice(int, timestamptz, timestamptz) RETURNS SETOF report_type
        AS $$
          SELECT
            compacted_act_own.payment_method_id,
            billable_units.hid,
            GREATEST(billable_units.from, compacted_act_own.from, $2) as from,
            LEAST(billable_units.to, compacted_act_own.to, $3) as to,
            (
              (extract('epoch' FROM
                LEAST(billable_units.to, compacted_act_own.to, $3) - GREATEST(billable_units.from, compacted_act_own.from, $2)
              )::numeric / (3600)) -- convert seconds into hours
            ) as qty,
            billable_units.product_name,
            billable_units.product_group,
            billable_units.rate,
            billable_units.rate_period
          FROM
            compacted_act_own
          INNER JOIN billable_units
            ON billable_units.hid = compacted_act_own.hid
          LEFT OUTER JOIN rate_codes
            ON billable_units.rate_code_id = rate_codes.id
          WHERE
                compacted_act_own.payment_method_id = $1
            AND ($2, $3) OVERLAPS (compacted_act_own.from, compacted_act_own.to)
        $$ LANGUAGE SQL
      ;

      CREATE TYPE group_bu_type AS (
        qty numeric,
        rate int
      );

      CREATE OR REPLACE FUNCTION grouped_billable_units(timestamptz, timestamptz) RETURNS SETOF group_bu_type
        AS $$
          SELECT
            sum(
              (extract('epoch' FROM
                LEAST(billable_units.to, $2) - GREATEST(billable_units.from, $1)
              )::numeric / (3600)) -- convert seconds into hours
            ) as qty,
            rate
          FROM billable_units
          WHERE (billable_units.from, billable_units.to) OVERLAPS ($1, $2)
          GROUP BY rate
        $$ LANGUAGE SQL
      ;

      CREATE OR REPLACE FUNCTION rev_report(timestamptz, timestamptz) RETURNS numeric
        AS $$
          SELECT sum(qty * rate) as total
          FROM grouped_billable_units($1, $2)
        $$ LANGUAGE SQL
      ;

    EOD
  end
end
