module ResourceOwnershipService

  extend self

  def query(account_id)
    ResourceOwnershipRecord.collapse(account_id)
  end

  def activate(account_id, hid, time, event_id)
    assert_valid_account_id!(account_id)
    create_record(account_id, hid, ResourceOwnershipRecord::Active, time, event_id)
  end

  def deactivate(account_id, hid, time, event_id)
    assert_valid_account_id!(account_id)
    create_record(account_id, hid, ResourceOwnershipRecord::Inactive, time, event_id)
  end

  def transfer(previos_account_id, new_account_id, hid, time, prev_event_id, new_event_id)
    if new_account_id.nil?
      deactivate(previos_account_id, hid, time, prev_event_id)
    else
      assert_valid_account_id!(previos_account_id, new_account_id)
      deactivate(previos_account_id, hid, time, prev_event_id)
      create_record(new_account_id, hid, ResourceOwnershipRecord::Active, time, new_event_id)
    end
  end

  def assert_valid_account_id!(*ids)
    unless ids.all? {|i| Account.exists?(i)}
      raise(Shushu::NotFound, "Could not find account with ids=#{ids}")
    end
  end

  def create_record(account_id, hid, state, time, event_id)
    ResourceOwnershipRecord.create({
      :account_id => account_id,
      :hid        => hid,
      :state      => state,
      :time       => time,
      :event_id   => event_id
    }).to_h
  end

end
