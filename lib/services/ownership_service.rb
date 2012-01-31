module OwnershipService
  def query(primary_id)
    [200, model.collapse(primary_id)]
  end

  def activate(provider_id, primary_id, secondary_id, time, entity_id)
    [201, create_record(provider_id, primary_id, secondary_id, model.active, time, entity_id)]
  end

  def deactivate(provider_id, primary_id, secondary_id, time, entity_id)
    [201, create_record(provider_id, primary_id, secondary_id, model.inactive, time, entity_id)]
  end

  def transfer(provider_id, previos_primary_id, new_primary_id, secondary_id, time, prev_entity_id, new_entity_id)
    if new_primary_id.nil?
      deactivate(provider_id, previos_primary_id, secondary_id, time, prev_entity_id)
    else
      deactivate(provider_id, previos_primary_id, secondary_id, time, prev_entity_id)
      [201, create_record(provider_id, new_primary_id, secondary_id, model.active, time, new_entity_id)]
    end
  end
end

module AccountOwnershipService
  extend OwnershipService
  extend self

  def model
    AccountOwnershipRecord
  end

  def create_record(provider_id, primary_id, secondary_id, state, time, entity_id)
    model.create({
      :provider_id       => provider_id,
      :payment_method_id => primary_id,
      :account_id        => secondary_id,
      :state             => state,
      :time              => time,
      :entity_id          => entity_id
    }).to_h
  end
end

module ResourceOwnershipService
  extend OwnershipService
  extend self

  def model
    ResourceOwnershipRecord
  end

  def create_record(provider_id, primary_id, secondary_id, state, time, entity_id)
    model.create({
      :provider_id => provider_id,
      :account_id => primary_id,
      :hid        => secondary_id,
      :state      => state,
      :time       => time,
      :entity_id  => entity_id
    }).to_h
  end
end
