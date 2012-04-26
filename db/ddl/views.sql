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
