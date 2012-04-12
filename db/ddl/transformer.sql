CREATE OR REPLACE FUNCTION
transform(integer)
RETURNS void
AS $$
  INSERT INTO close_events(
    entity_id,
    provider_id,
    resource_id,
    "from",
    "to",
    qty,
    rate,
    rate_period,
    product_group,
    product_name,
    created_at
  )
  SELECT
    a.entity_id_uuid,
    a.provider_id,
    a.hid,
    a.time,
    b.time,
    (extract('epoch' from (b.time - a.time))),
    rate_codes.rate,
    rate_codes.rate_period,
    rate_codes.product_group,
    COALESCE(a.product_name, rate_codes.product_name),
    now()
  FROM
    billable_events a
  INNER JOIN
    billable_events b
    ON a.entity_id = b.entity_id
    AND a.state = 1 AND b.state = 0
  INNER JOIN
    rate_codes
    ON rate_codes.id = a.rate_code_id
  WHERE
    a.recorded_at IS NULL
    AND
    b.recorded_at IS NULL
  FOR UPDATE OF a, b NOWAIT
  LIMIT $1;

  UPDATE
    billable_events
  SET
    recorded_at = now()
  FROM
    close_events
  WHERE
    close_events.entity_id = billable_events.entity_id_uuid
    AND
    billable_events.recorded_at IS NULL;
$$ LANGUAGE SQL;
