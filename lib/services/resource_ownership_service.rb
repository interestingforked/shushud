module ResourceOwnershipService

  extend self

  # You can pass time represented as strings of instances of Time.
  def query(account_id, from, to)
    from  = Time.parse(from)  if from.class == String
    to    = Time.parse(to)    if to.class   == String

    ResourceOwnershipRecord.collapse(account_id, from, to).all
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
      raise(Shushu::NotFound, "Could not find account with ids=#{ids}")
    end
  end

  def create_record(account_id, hid, state)
    ResourceOwnershipRecord.create({
      :account_id => account_id,
      :hid        => hid,
      :state      => state,
      :time       => Time.now
    })
  end

end
