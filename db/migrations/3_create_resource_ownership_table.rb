Sequel.migration do
  change do
    create_table(:resource_ownership_records) do |t|
      primary_key :id
      foreign_key :account_id, :accounts
    end
    add_column :resource_ownership_records, :event_id,    "varchar(255)"
    add_column :resource_ownership_records, :hid,         "varchar(255)"
    add_column :resource_ownership_records, :time,        "timestamptz"
    add_column :resource_ownership_records, :state,       "varchar(255)"
  end
end
