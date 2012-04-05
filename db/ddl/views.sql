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
          a.entity_id   = b.entity_id
      AND a.state       = 1
      AND b.state       = 0
    WHERE
          a.state       = 1
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
          a.entity_id   = b.entity_id
      AND a.state       = 1
      AND b.state       = 0
    WHERE
          a.state       = 1
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

CREATE OR REPLACE VIEW billable_units AS
  SELECT
    a.hid,
    a.entity_id_uuid as entity_id,
    a.time as from,
    b.time as to,
    a.rate_code_id,
    rate_codes.product_group,
    COALESCE(rate_codes.product_name, a.product_name) as product_name,
    rate_codes.rate,
    rate_codes.rate_period,
    a.provider_id

    FROM billable_events a
    LEFT OUTER JOIN rate_codes
    ON rate_codes.id = a.rate_code_id
    LEFT OUTER JOIN billable_events b
    ON
      a.entity_id_uuid = b.entity_id_uuid
      AND a.state = 1
      AND b.state = 0
    WHERE
      a.state = 1
;

-- add a condition for resource_ownerships.account_id
-- -- i.e. selelct * from res_bu where resource_ownerships.account_id = X
CREATE OR REPLACE VIEW res_bu AS
  SELECT
    resource_ownerships.account_id,
    billable_units.hid,
    GREATEST(billable_units.from, resource_ownerships.from) as from,
    LEAST(billable_units.to, resource_ownerships.to) as to,
    billable_units.product_name,
    billable_units.product_group,
    billable_units.rate,
    billable_units.rate_period
  FROM billable_units
  INNER JOIN resource_ownerships
    ON billable_units.hid = resource_ownerships.hid
  WHERE
    (billable_units.from, COALESCE(billable_units.to, now()))
    OVERLAPS
    (resource_ownerships.from, resource_ownerships.to)
;

-- add a condition for payment_method_id
-- -- i.e. selelct * from act_bu where payment_method_id = X
CREATE OR REPLACE VIEW act_bu AS
  SELECT
    compacted_act_own.payment_method_id,
    billable_units.hid,
    GREATEST(billable_units.from, compacted_act_own.from) as from,
    LEAST(COALESCE(billable_units.to, now()), compacted_act_own.to) as to,
    NULL::numeric as qty, -- stub this for now. will use it in invoice()
    billable_units.product_name,
    billable_units.product_group,
    billable_units.rate,
    billable_units.rate_period
  FROM
    compacted_act_own
  INNER JOIN billable_units
    ON billable_units.hid = compacted_act_own.hid
  WHERE
    (billable_units.from, COALESCE(billable_units.to, now()))
    OVERLAPS
    (compacted_act_own.from, compacted_act_own.to)
;
