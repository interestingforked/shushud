Sequel.migration do
  up do
    execute(<<-EOD)

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
    EOD
  end
end
