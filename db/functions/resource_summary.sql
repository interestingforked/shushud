create function resource_summary(int, timestamptz, timestamptz)
returns TABLE(
  resource_id int,
  rate int,
  product_group text,
  product_name text,
  description text,
  qty numeric,
  count bigint
)
as $$
select
  hid::int as resource_id,
  rate,
  product_group,
  COALESCE(billable_events.product_name, rate_codes.product_name) as product_name,
  (CASE WHEN billable_events.product_name = 'run' THEN billable_events.description ELSE '' END) as description,
  sum(
    extract(epoch from $3)
    -
    extract(epoch from greatest("time", $2)))::numeric / 3600 as qty,
  count(*)
from
  billable_events, rate_codes
where
  billable_events.provider_id = 5
  and rate_codes.id = rate_code_id
  and hid = $1::text
  and time <= $3
  and billable_events.product_name != 'cron'
group by
  1,2,3,4,5
union all
select
  resource_id,
  rate,
  product_group,
  COALESCE(closed_events.product_name, rate_codes.product_name) as product_name,
  (CASE WHEN closed_events.product_name = 'run' THEN closed_events.description ELSE '' END) as description,
  sum(
    extract(epoch from least("to", $3))
    -
    extract(epoch from greatest("from", $2)))::numeric / 3600 as qty,
  count(*)
from
  closed_events, rate_codes
where
  closed_events.provider_id = 5
  and rate_codes.id = rate_code_id
  and resource_id = $1
  and ("from", "to") overlaps ($2, $3)
  and closed_events.product_name != 'cron'
group by
  1,2,3,4,5
$$ language sql immutable;
