module OwnershipService
  def query(primary_id)
    model.collapse(primary_id)
  end

  def activate(primary_id, secondary_id, time, event_id)
    create_record(primary_id, secondary_id, model.active, time, event_id)
  end

  def deactivate(primary_id, secondary_id, time, event_id)
    create_record(primary_id, secondary_id, model.inactive, time, event_id)
  end

  def transfer(previos_primary_id, new_primary_id, secondary_id, time, prev_event_id, new_event_id)
    if new_primary_id.nil?
      deactivate(previos_primary_id, secondary_id, time, prev_event_id)
    else
      deactivate(previos_primary_id, secondary_id, time, prev_event_id)
      create_record(new_primary_id, secondary_id, model.active, time, new_event_id)
    end
  end
end

module AccountOwnershipService
  extend OwnershipService
  extend self

  def model
    AccountOwnershipRecord
  end

  def create_record(primary_id, secondary_id, state, time, event_id)
    model.create({
      :payment_method_id => primary_id,
      :account_id        => secondary_id,
      :state             => state,
      :time              => time,
      :event_id          => event_id
    }).to_h
  end
end

module ResourceOwnershipService
  extend OwnershipService
  extend self

  def model
    ResourceOwnershipRecord
  end

  def create_record(primary_id, secondary_id, state, time, event_id)
    model.create({
      :account_id => primary_id,
      :hid        => secondary_id,
      :state      => state,
      :time       => time,
      :event_id   => event_id
    }).to_h
  end
end
