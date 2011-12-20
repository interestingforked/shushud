Sequel.migration do
  change do
    alter_table(:billable_events) do
      add_unique_constraint([:event_id, :state])
    end
    alter_table(:resource_ownership_records) do
      add_unique_constraint([:event_id, :state])
    end
  end
end
