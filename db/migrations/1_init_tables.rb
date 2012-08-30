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

    #ResourceOwnershipRecord
    create_table(:resource_ownership_records) do |t|
      primary_key :id
      foreign_key :provider_id, :providers
    end
    add_column :resource_ownership_records, :owner,       "int"
    add_column :resource_ownership_records, :created_at,  "timestamptz"
    add_column :resource_ownership_records, :time,        "timestamptz"
    add_column :resource_ownership_records, :entity_id,   "uuid"
    add_column :resource_ownership_records, :resource_id, "varchar(255)"
    add_column :resource_ownership_records, :state,       "integer"
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
    add_column :billable_events, :entity_id_uuid,     "uuid"
    add_column :billable_events, :resource_id,        "varchar(255)"
    add_column :billable_events, :qty,                "int"
    add_column :billable_events, :product_name,       "varchar(255)"
    add_column :billable_events, :description,        "varchar(255)"
    add_column :billable_events, :time,               "timestamptz"
    add_column :billable_events, :state,              "int"
    alter_table(:billable_events) do
      add_unique_constraint([:provider_id, :entity_id_uuid, :state])
    end

    create_table(:closed_events) do
      primary_key :entity_id, :uuid
      foreign_key :provider_id, :providers
      foreign_key :rate_code_id, :rate_codes
    end
    add_column :closed_events, :created_at,         "timestamptz"
    add_column :closed_events, :resource_id,        "int"
    add_column :closed_events, :qty,                "int"
    add_column :closed_events, :product_name,       "varchar(255)"
    add_column :closed_events, :description,        "varchar(255)"
    add_column :closed_events, :from,               "timestamptz"
    add_column :closed_events, :to,                 "timestamptz"

  end
end
