CREATE OR REPLACE FUNCTION bn_month(timestamptz)
RETURNS timestamptz AS $$
  SELECT (date_trunc('month', $1) + '1 month'::interval);
$$ LANGUAGE 'sql' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION b_month(timestamptz)
RETURNS timestamptz AS $$
  SELECT date_trunc('MONTH', $1);
$$ LANGUAGE 'sql' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sec_in_month(timestamptz)
RETURNS integer AS $$
  SELECT extract('epoch' from (bn_month($1) - b_month($1)))::integer
$$ LANGUAGE 'sql' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION rate_code_report(integer, timestamptz, timestamptz)
RETURNS TABLE(
  hid text,
  "from" timestamptz,
  "to" timestamptz,
  qty numeric,
  rate integer,
  rate_period text,
  product_name text,
  product_group text
) AS $$
  SELECT
    billable_units.hid,
    GREATEST(billable_units.from, $2) as from,
    LEAST(COALESCE(billable_units.to, now()), $3) as to,
    (
      CASE
      WHEN billable_units.rate_period = 'month' THEN
        (extract('epoch' FROM
          LEAST(COALESCE(billable_units.to, now()), $3)
          -
          GREATEST(billable_units.from, $2)
        )::numeric / (3600) / sec_in_month($3)) -- convert seconds into hours
      ELSE
        (extract('epoch' FROM
          LEAST(COALESCE(billable_units.to, now()), $3)
          -
          GREATEST(billable_units.from, $2)
        )::numeric / (3600)) -- convert seconds into hours
      END
    ) as qty,
    billable_units.rate,
    billable_units.rate_period,
    billable_units.product_name,
    billable_units.product_group
  FROM
    billable_units
  WHERE
    (billable_units.from, COALESCE(billable_units.to, now()))
    OVERLAPS
    ($2, $3)
    AND
    billable_units.rate_code_id = $1
$$ LANGUAGE SQL STABLE
;

CREATE OR REPLACE FUNCTION usage_report(int, timestamptz, timestamptz)
RETURNS TABLE(
  account_id int,
  hid text,
  product_name text,
  product_group text,
  rate_period text,
  rate int,
  "from" timestamptz,
  "to" timestamptz,
  qty numeric
) AS $$
  SELECT
    res_bu.account_id,
    res_bu.hid,
    res_bu.product_name,
    res_bu.product_group,
    res_bu.rate_period,
    res_bu.rate,
    GREATEST(res_bu.from, $2) as from,
    LEAST(COALESCE(res_bu.to, now()), $3) as to,
    (
      CASE
      WHEN res_bu.rate_period = 'month' THEN
        (extract('epoch' FROM
          LEAST(COALESCE(res_bu.to, now()), $3)
          -
          GREATEST(res_bu.from, $2)
        )::numeric / (3600) / sec_in_month($3)) -- convert seconds into hours
      ELSE
        (extract('epoch' FROM
          LEAST(COALESCE(res_bu.to, now()), $3)
          -
          GREATEST(res_bu.from, $2)
        )::numeric / (3600)) -- convert seconds into hours
      END
    ) as qty
  FROM res_bu
  WHERE
    res_bu.account_id = $1
    AND
    (res_bu.from, COALESCE(res_bu.to, now()))
    OVERLAPS
    ($2, $3)
$$ LANGUAGE SQL
;

/*
  invoice()

  $1 payment_method_id
  $2 start of invoice period
  $3 end of invoice period
  $4 number of free dyno hours

*/

CREATE OR REPLACE FUNCTION invoice(timestamptz, timestamptz, int)
RETURNS TABLE(
  payment_method_id int,
  hid text,
  billable_units hstore[],
  dyno_hours numeric,
  adjusted_dyno_hours numeric
) AS $$
  SELECT
    act_bu.payment_method_id,
    act_bu.hid,
    array_agg(hstore(
      ROW(
        act_bu.payment_method_id,
        act_bu.hid,
        act_bu.from,
        LEAST(act_bu.to, $2),
        (
          CASE WHEN act_bu.rate_period = 'month' THEN
            extract('epoch' from (LEAST(act_bu.to, $2) - GREATEST(act_bu.from, $1)))::numeric /  sec_in_month($1)
          ELSE
            extract('epoch' from (LEAST(act_bu.to, $2) - GREATEST(act_bu.from, $1)))::numeric / 3600
          END
        ),
        act_bu.product_name,
        act_bu.product_group,
        act_bu.rate,
        act_bu.rate_period
      )::act_bu
    )) as billable_units,
    -- compute the total number of dyno hours for the invoice
    sum(
      CASE WHEN act_bu.rate_period = 'month' THEN
        (
          (extract('epoch' FROM
            LEAST(act_bu.to, $2)
            -
            GREATEST(act_bu.from, $1)
          )::numeric / (3600)) -- convert seconds into hours
        )
      ELSE 0
      END
    ) as dyno_hours,
    -- compute the adjusted dyno hours for the dyno-hour credit
    sum(
      CASE WHEN act_bu.rate_period = 'month' THEN
        (
          (extract('epoch' FROM
            LEAST(act_bu.to, $2)
            -
            GREATEST(act_bu.from, $1)
          )::numeric / (3600)) -- convert seconds into hours
        )
        -
        LEAST(
          (
            (extract('epoch' FROM
              LEAST(act_bu.to, $2)
              -
              GREATEST(act_bu.from, $1)
            )::numeric / (3600)) -- convert seconds into hours
          ), $3 -- number of free dyno-hours
        )
      ELSE 0
      END
    ) as adjusted_dyno_hours
  FROM act_bu
  WHERE
    (act_bu.from, act_bu.to)
    OVERLAPS
    ($1, $2)
  GROUP BY
    act_bu.hid, act_bu.payment_method_id
$$ LANGUAGE SQL
;

CREATE OR REPLACE FUNCTION
adjusted_billable_units(timestamptz, timestamptz, int)
RETURNS TABLE(
  hid varchar,
  rate int,
  dyno_hours numeric,
  adjusted_dyno_hours numeric
) AS $$
  SELECT
    bu.hid,
    bu.rate,
    sum (
      (extract('epoch' FROM
        LEAST(COALESCE(bu.to, now()), $2)
        -
        GREATEST(bu.from, $1)
      )::numeric / (3600)) -- convert seconds into hours
    ) as dyno_hours,
    -- compute the adjusted dyno hours for the dyno-hour credit
    (
      sum (
        (extract('epoch' FROM
          LEAST(COALESCE(bu.to, now()), $2)
          -
          GREATEST(bu.from, $1)
        )::numeric / (3600)) -- convert seconds into hours
      )
      -
      LEAST(
        (
          sum (extract('epoch' FROM
            LEAST(COALESCE(bu.to, now()), $2)
            -
            GREATEST(bu.from, $1)
          )::numeric / (3600)) -- convert seconds into hours
        ), $3 -- number of free dyno-hours
      )
    ) as adjusted_dyno_hours
  FROM billable_units bu
  WHERE
  (bu.from, COALESCE(bu.to, now()))
  OVERLAPS
  (($1 - '1 second'::interval), ($2 + '1 second'::interval))
  GROUP BY
    bu.hid, bu.rate
$$ LANGUAGE SQL STABLE
;

CREATE OR REPLACE FUNCTION rev_report(timestamptz, timestamptz, int)
RETURNS numeric AS $$
  SELECT
    sum(adjusted_dyno_hours * rate) as total
  FROM
    adjusted_billable_units($1, $2, $3) bu
  $$ LANGUAGE SQL STABLE
;

CREATE OR REPLACE FUNCTION
res_diff_inner(timestamptz, timestamptz, timestamptz, timestamptz)
RETURNS TABLE(
  hid text,
  ltotal numeric,
  rtotal numeric,
  diff numeric
) AS $$
  SELECT
    l.hid,
    sum(l.adjusted_dyno_hours) * l.rate  as ltotal,
    sum(r.adjusted_dyno_hours) * r.rate as rtotal,
    (sum(r.adjusted_dyno_hours)*r.rate)-(sum(l.adjusted_dyno_hours)*l.rate) diff
  FROM
    adjusted_billable_units($1, $2, 0) as l
    INNER JOIN adjusted_billable_units($3, $4, 0) as r
    ON l.hid = r.hid
  GROUP BY l.hid, l.rate, r.rate
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION res_diff(
  timestamptz, --lfrom
  timestamptz, --lto
  timestamptz, --rfrom
  timestamptz, --rto
  boolean,     --delta_increaase
  boolean,     --lrev_zero
  boolean      --rrev_zero
)
RETURNS TABLE(
  hid text,
  ltotal numeric,
  rtotal numeric,
  diff numeric
) AS $$
  SELECT *
  FROM
    res_diff_inner($1, $2, $3, $4)
  WHERE
    (diff > 0) = $5
    AND
    (diff != 0)
    AND
    (ltotal = 0) = $6
    AND
    (rtotal = 0) = $7
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION
res_diff_agg(timestamptz, timestamptz, timestamptz, timestamptz, boolean, boolean, boolean)
RETURNS TABLE(
  sdiff numeric,
  sltotal numeric,
  srtotal numeric
) AS $$
  SELECT
    sum(diff),
    sum(ltotal),
    sum(rtotal)
  FROM res_diff($1, $2, $3, $4, $5, $6, $7)
$$ LANGUAGE SQL STABLE;
