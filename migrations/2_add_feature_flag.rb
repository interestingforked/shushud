Sequel.migration do
  change do
    add_column(:providers, :billable_events, :boolean, :default => false)
  end
end
