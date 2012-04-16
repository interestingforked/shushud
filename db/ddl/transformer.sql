CREATE OR REPLACE FUNCTION
transform(
  max_transformers int,
  transformer_id int
)
RETURNS void
AS $function$
  DECLARE
    event RECORD;
  BEGIN
    FOR event IN EXECUTE $insert$
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
        ON a.entity_id_uuid = b.entity_id_uuid
        AND a.state = 1 AND b.state = 0
      INNER JOIN
        rate_codes
        ON rate_codes.id = a.rate_code_id
      WHERE
        a.recorded_at IS NULL
        AND
        b.recorded_at IS NULL
        AND
      $insert$ || ' MOD(a.id,' ||  max_transformers || ') = ' || transformer_id
               || ' FOR UPDATE OF a, b NOWAIT '
               || ' RETURNING entity_id'
    LOOP
      UPDATE
        billable_events
      SET
        recorded_at = now()
      WHERE
        entity_id_uuid = event.entity_id;
    END LOOP;
  END;
$function$ LANGUAGE plpgsql;
