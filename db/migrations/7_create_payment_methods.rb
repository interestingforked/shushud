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

      -- don't forget to add a payment_method_id filter.
      CREATE OR REPLACE VIEW payment_methods_with_hids AS
        SELECT DISTINCT ON (resource_ownerships.hid)
          account_ownerships.payment_method_id,
          resource_ownerships.hid,
          account_ownerships.from,
          account_ownerships.to
        FROM
          account_ownerships,
          resource_ownerships
        WHERE
          account_ownerships.account_id = resource_ownerships.account_id
        ORDER BY
          resource_ownerships.hid,
          resource_ownerships.to DESC
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
            payment_methods_with_hids.payment_method_id,
            GREATEST(billable_units.from, payment_methods_with_hids.from, $2) as from,
            LEAST(billable_units.to, payment_methods_with_hids.to, $3) as to
          FROM
            payment_methods_with_hids
          INNER JOIN billable_units
            ON billable_units.hid = payment_methods_with_hids.hid
          WHERE
                payment_methods_with_hids.payment_method_id = $1
            AND ($2, $3) OVERLAPS (payment_methods_with_hids.from, payment_methods_with_hids.to)
        $$ LANGUAGE SQL
      ;
    EOD

  end
end
