module ResourceOwnershipService

  class NoAccount < Exception; end

  extend self

  def query(query)
    query[:state] = ResourceOwnershipRecord::Active
    ResourceOwnershipRecord[query] || raise(NoAccount)
  end

  def activate(account_id, hid)
    assert_valid_account_id!(account_id)
    create_record(account_id, hid, ResourceOwnershipRecord::Active)
  end

  def deactivate(account_id, hid)
    assert_valid_account_id!(account_id)
    create_record(account_id, hid, ResourceOwnershipRecord::Inactive)
  end

  def transfer(previos_account_id, new_account_id, hid)
    if new_account_id.nil?
      deactivate(previos_account_id, hid)
    else
      assert_valid_account_id!(previos_account_id, new_account_id)
      deactivate(previos_account_id, hid)
      create_record(new_account_id, hid, ResourceOwnershipRecord::Active)
    end
  end

  def assert_valid_account_id!(*ids)
    unless ids.all? {|i| Account.exists?(i)}
      raise(NoAccount, "Could not find account with ids=#{ids}")
    end
  end

  def create_record(account_id, hid, state)
    ResourceOwnershipRecord.create({
      :account_id => account_id,
      :hid        => hid,
      :state      => state
    })
  end

end
