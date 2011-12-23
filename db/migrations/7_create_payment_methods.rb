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
    EOD

  end
end
