Sequel.migration do
  change do
    create_table(:accounts) do |t|
      primary_key :id
    end
  end
end
