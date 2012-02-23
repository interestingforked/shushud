Sequel.migration do
  change do
    #Provider
    create_table(:providers) do
      primary_key :id
    end
    add_column :providers, :created_at,   "timestamptz"
    add_column :providers, :root,         "boolean DEFAULT 'false'"
    add_column :providers, :disabled,     "boolean DEFAULT 'false'"
    add_column :providers, :name,         "varchar(255)"
    add_column :providers, :token,        "varchar(255)"

    #PaymentMethod
    create_table(:payment_methods) do
      primary_key :id
      foreign_key :provider_id, :providers
    end
    add_column :payment_methods, :created_at, "timestamptz"
    add_column :payment_methods, :slug, "varchar(255)"
    alter_table(:payment_methods) do
      add_unique_constraint([:provider_id, :slug])
    end

    #CardToken
    create_table(:card_tokens) do
      primary_key :id
      foreign_key :payment_method_id, :payment_methods
      foreign_key :provider_id, :providers
    end
    add_column :card_tokens, :created_at, "timestamptz"
    add_column :card_tokens, :token,      "varchar(255)"

    #Receivable
    create_table(:receivables) do
      primary_key :id
      foreign_key :init_payment_method_id, :payment_methods
      foreign_key :provider_id, :providers
    end
    add_column :receivables, :amount,       "int"
    add_column :receivables, :period_start, "timestamptz"
    add_column :receivables, :period_end,   "timestamptz"
    add_column :receivables, :created_at,   "timestamptz"

    #PaymentAttemptRecord
    create_table(:payment_attempt_records) do
      primary_key :id
      foreign_key :receivable_id, :receivables
      foreign_key :payment_method_id, :payment_methods
      foreign_key :provider_id, :providers
    end
    add_column :payment_attempt_records, :retry,        "boolean"
    add_column :payment_attempt_records, :state,        "varchar(255)"
    add_column :payment_attempt_records, :wait_until,   "timestamptz"
    add_column :payment_attempt_records, :created_at,   "timestamptz"
    add_column :payment_attempt_records, :desc,         "text"

    # couldn't find a good way to do this in sequel.
    execute(<<-EOD)
      CREATE UNIQUE INDEX succeeded_receivable_attempt
      ON payment_attempt_records (receivable_id)
      WHERE state = 'success'
    EOD

    #Account
    create_table(:accounts) do |t|
      primary_key :id
      foreign_key :payment_method_id, :payment_methods
      foreign_key :provider_id, :providers
    end
    add_column :accounts, :created_at, "timestamptz"

    #AccountOwnershipRecord
    create_table(:account_ownership_records) do
      primary_key :id
      foreign_key :payment_method_id, :payment_methods
      foreign_key :account_id, :accounts
      foreign_key :provider_id, :providers
    end
    add_column :account_ownership_records, :created_at, "timestamptz"
    add_column :account_ownership_records, :entity_id,  "varchar(255)"
    add_column :account_ownership_records, :time,       "timestamptz"
    add_column :account_ownership_records, :state,      "varchar(255)"
    alter_table(:account_ownership_records) do
      add_unique_constraint([:entity_id, :state])
    end

    #ResourceOwnershipRecord
    create_table(:resource_ownership_records) do |t|
      primary_key :id
      foreign_key :account_id, :accounts
      foreign_key :provider_id, :providers
    end
    add_column :resource_ownership_records, :created_at,  "timestamptz"
    add_column :resource_ownership_records, :time,        "timestamptz"
    add_column :resource_ownership_records, :entity_id,   "varchar(255)"
    add_column :resource_ownership_records, :hid,         "varchar(255)"
    add_column :resource_ownership_records, :state,       "varchar(255)"
    alter_table(:resource_ownership_records) do
      add_unique_constraint([:entity_id, :state])
    end

    #RateCode
    create_table(:rate_codes) do
      primary_key :id
      foreign_key :provider_id, :providers
    end
    add_column :rate_codes, :created_at,    "timestamptz"
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
    add_column :billable_events, :created_at,         "timestamptz"
    add_column :billable_events, :entity_id,          "varchar(255)"
    add_column :billable_events, :hid,                "varchar(255)"
    add_column :billable_events, :qty,                "int"
    add_column :billable_events, :product_name,       "varchar(255)"
    add_column :billable_events, :description,        "varchar(255)"
    add_column :billable_events, :time,               "timestamptz"
    add_column :billable_events, :state,              "varchar(255)"
    alter_table(:billable_events) do
      add_unique_constraint([:provider_id, :entity_id, :state])
    end

  end
end
