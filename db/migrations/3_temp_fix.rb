Sequel.migration do
  change do

    alter_table(:resource_ownership_records) do
      foreign_key :provider_id, :providers
    end

    alter_table(:account_ownership_records) do
      foreign_key :provider_id, :providers
    end

    alter_table(:receivables) do
      foreign_key :provider_id, :providers
    end

    alter_table(:card_tokens) do
      foreign_key :provider_id, :providers
    end

    alter_table(:payment_methods) do
      foreign_key :provider_id, :providers
    end

    alter_table(:payment_attempt_records) do
      foreign_key :provider_id, :providers
    end

    alter_table(:accounts) do
      foreign_key :provider_id, :providers
    end

    add_column :payment_methods, :slug, "varchar(255)"
    alter_table(:payment_methods) do
      foreign_key :provider_id, :providers
      add_unique_constraint([:provider_id, :slug])
    end

  end
end
