module OwnershipService
  def query(primary_id)
    [200, model.collapse(primary_id)]
  end

  def activate(primary_id, secondary_id, time, entity_id)
    [201, create_record(primary_id, secondary_id, model.active, time, entity_id)]
  end

  def deactivate(primary_id, secondary_id, time, entity_id)
    [201, create_record(primary_id, secondary_id, model.inactive, time, entity_id)]
  end

  def transfer(previos_primary_id, new_primary_id, secondary_id, time, prev_entity_id, new_entity_id)
    if new_primary_id.nil?
      deactivate(previos_primary_id, secondary_id, time, prev_entity_id)
    else
      deactivate(previos_primary_id, secondary_id, time, prev_entity_id)
      [201, create_record(new_primary_id, secondary_id, model.active, time, new_entity_id)]
    end
  end
end

module AccountOwnershipService
  extend OwnershipService
  extend self

  def model
    AccountOwnershipRecord
  end

  def create_record(primary_id, secondary_id, state, time, entity_id)
    model.create({
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

  def create_record(primary_id, secondary_id, state, time, entity_id)
    model.create({
      :account_id => primary_id,
      :hid        => secondary_id,
      :state      => state,
      :time       => time,
      :entity_id   => entity_id
    }).to_h
  end
end
