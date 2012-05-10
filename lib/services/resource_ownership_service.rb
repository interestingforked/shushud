module ResourceOwnershipService
  extend self

  def handle_in(state, provider_id, account_id, resource_id, time, entity_id)
    case state
    when "active"
      activate(provider_id, account_id, resource_id, time, entity_id)
    when "inactive"
      deactivate(provider_id, account_id, resource_id, time, entity_id)
    end
  end

  def activate(provider_id, account_id, resource_id, time, entity_id)
    [
      200,
      create_record(
        provider_id,
        account_id,
        resource_id,
        ResourceOwnershipRecord::ACTIVE,
        time,
        entity_id
      )
    ]
  end

  def deactivate(provider_id, account_id, resource_id, time, entity_id)
    [
      200,
      create_record(
        provider_id,
        account_id,
        resource_id,
        ResourceOwnershipRecord::INACTIVE,
        time,
        entity_id
      )
    ]

  end

  def create_record(provider_id, account_id, resource_id, state, time, entity_id)
    ResourceOwnershipRecord.create({
      :provider_id  => provider_id,
      :account_id   => account_id,
      :hid          => resource_id,
      :state        => state,
      :time         => time,
      :entity_id    => entity_id
    }).to_h
  end
end
