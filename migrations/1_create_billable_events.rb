Sequel.migration do
  change do
    create_table(:billable_events) do
      primary_key :id
      Integer :qty
      String :rate_code
      String :resource_id
      String :event_id
      DateTime :created_at
      DateTime :ended_at
    end
  end
end
