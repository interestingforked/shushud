Sequel.migration do
  change do

    create_table(:providers) do
      primary_key :id
      String :name
      String :token, :text => true
    end


    create_table(:billable_events) do
      primary_key :id
      foreign_key :provider_id, :providers

      Integer :qty
      String :event_id
      String :rate_code
      String :resource_id

      DateTime :system_from
      DateTime :system_to

      DateTime :reality_from
      DateTime :reality_to
    end
    
    create_table(:rate_codes) do
      primary_key :id
      foreign_key :provider_id, :providers

      String :slug
      String :description
      Integer :rate
    end

  end
end
