Sequel.migration do
  change do
    # Provider
    create_table(:providers) do
      primary_key :id
    end
    add_column :providers, :root,   "boolean DEFAULT 'false'"
    add_column :providers, :name,   "varchar(255)"
    add_column :providers, :token,  "varchar(255)"

    # Rate Codes
    create_table(:rate_codes) do
      primary_key :id
      foreign_key :provider_id, :providers
    end
    add_column :rate_codes, :rate,          "int"
    add_column :rate_codes, :slug,          "varchar(255)"
    add_column :rate_codes, :product_group, "varchar(255)"
    add_column :rate_codes, :product_name,  "varchar(255)"

    # Billable Events
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
  end
end
