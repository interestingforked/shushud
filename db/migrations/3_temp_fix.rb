Sequel.migration do
  change do

    alter_table(:resource_ownership_records) do
      add_foreign_key :provider_id, :providers
    end

    alter_table(:account_ownership_records) do
      add_foreign_key :provider_id, :providers
    end

    alter_table(:receivables) do
      add_foreign_key :provider_id, :providers
    end

    alter_table(:card_tokens) do
      add_foreign_key :provider_id, :providers
    end

    alter_table(:payment_attempt_records) do
      add_foreign_key :provider_id, :providers
    end

    alter_table(:accounts) do
      add_foreign_key :provider_id, :providers
    end

    add_column :payment_methods, :slug, "varchar(255)"
    alter_table(:payment_methods) do
      add_foreign_key :provider_id, :providers
      add_unique_constraint([:provider_id, :slug])
    end

  end
end
