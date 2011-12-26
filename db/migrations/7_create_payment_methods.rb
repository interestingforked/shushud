Sequel.migration do
  change do

    #PaymentMethod
    create_table(:payment_methods) do
      primary_key :id
    end
    add_column :payment_methods, :card_token, "varchar(255)"

    #AccountOwnershipRecords
    create_table(:account_ownership_records) do
      primary_key :id
      foreign_key :payment_method_id, :payment_methods
      foreign_key :account_id, :accounts
    end
    add_column :account_ownership_records, :event_id,   "varchar(255)"
    add_column :account_ownership_records, :time,       "timestamptz"
    add_column :account_ownership_records, :state,      "varchar(255)"
    alter_table(:account_ownership_records) do
      add_unique_constraint([:event_id, :state])
    end
    alter_table(:accounts) do
      add_foreign_key :payment_method_id, :payment_methods
    end


    execute(<<-EOD)
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
