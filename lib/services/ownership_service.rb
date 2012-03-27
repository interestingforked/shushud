module OwnershipService
  def query(primary_id)
    [200, model.collapse(primary_id).map(&:to_h)]
  end

  def handle_in(state, provider_id, primary_id, secondary_id, time, entity_id)
    case state
    when "active"
      activate(provider_id, primary_id, secondary_id, time, entity_id)
    when "inactive"
      deactivate(provider_id, primary_id, secondary_id, time, entity_id)
    end
  end

  def activate(provider_id, primary_id, secondary_id, time, entity_id)
    [200, create_record(provider_id, primary_id, secondary_id, model::ACTIVE, time, entity_id)]
  end

  def deactivate(provider_id, primary_id, secondary_id, time, entity_id)
    [200, create_record(provider_id, primary_id, secondary_id, model::INACTIVE, time, entity_id)]
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
      :entity_id         => entity_id
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
      :provider_id  => provider_id,
      :account_id   => primary_id,
      :hid          => secondary_id,
      :state        => state,
      :time         => time,
      :entity_id    => entity_id
    }).to_h
  end
end
