Sequel.migration do
  change do
    #PaymentMethod
    create_table(:payment_methods) do
      primary_key :id
    end
    add_column :payment_methods, :card_token, "varchar(255)"


    #Account
    create_table(:accounts) do |t|
      primary_key :id
    end
    alter_table(:accounts) do
      add_foreign_key :payment_method_id, :payment_methods
    end

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

    #ResourceOwnershipRecord
    create_table(:resource_ownership_records) do |t|
      primary_key :id
      foreign_key :account_id, :accounts
    end
    add_column :resource_ownership_records, :event_id,    "varchar(255)"
    add_column :resource_ownership_records, :hid,         "varchar(255)"
    add_column :resource_ownership_records, :time,        "timestamptz"
    add_column :resource_ownership_records, :state,       "varchar(255)"
    alter_table(:resource_ownership_records) do
      add_unique_constraint([:event_id, :state])
    end


    #Provider
    create_table(:providers) do
      primary_key :id
    end
    add_column :providers, :root,   "boolean DEFAULT 'false'"
    add_column :providers, :name,   "varchar(255)"
    add_column :providers, :token,  "varchar(255)"

    #RateCode
    create_table(:rate_codes) do
      primary_key :id
      foreign_key :provider_id, :providers
    end
    add_column :rate_codes, :rate,          "int"
    add_column :rate_codes, :rate_period,   "varchar(255)"
    add_column :rate_codes, :slug,          "varchar(255)"
    add_column :rate_codes, :product_group, "varchar(255)"
    add_column :rate_codes, :product_name,  "varchar(255)"

    #BillableEvent
    create_table(:billable_events) do
      primary_key :id
      foreign_key :provider_id, :providers
      foreign_key :rate_code_id, :rate_codes
    end
    add_column :billable_events, :qty,                "int"
    add_column :billable_events, :event_id,           "varchar(255)"
    add_column :billable_events, :hid,                "varchar(255)"
    add_column :billable_events, :time,               "timestamptz"
    add_column :billable_events, :state,              "varchar(255)"
    add_column :billable_events, :transitioned_at,    "varchar(255)"
    alter_table(:billable_events) do
      add_unique_constraint([:event_id, :state])
    end

  end
end
