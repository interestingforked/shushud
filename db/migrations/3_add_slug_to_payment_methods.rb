Sequel.migration do
  change do
    add_column :payment_methods, :slug, "varchar(255)"
    alter_table(:payment_methods) do
      add_foreign_key :provider_id, :providers
      add_unique_constraint([:provider_id, :slug])
    end
  end
end
