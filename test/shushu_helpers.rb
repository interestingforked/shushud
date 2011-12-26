module ShushuHelpers

  def build_provider(opts={})
    Provider.create({
      :name  => "sendgrid",
      :token => "password"
    }.merge(opts))
  end

  def build_rate_code(opts={})
    RateCode.create({
      :slug => "RT01",
      :rate => 5,
    }.merge(opts))
  end

  def build_account(opts={})
    Account.create(opts)
  end

  def build_payment_method(opts={})
    PaymentMethod.create(opts)
  end

  def build_resource_ownership_record(opts={})
    ResourceOwnershipRecord.create({
      :hid => "12345",
      :time => Time.now,
      :state => ResourceOwnershipRecord::Active
    }.merge(opts))
  end

  def build_act_own(account_id, payment_method_id, event_id, state, time)
    AccountOwnershipRecord.create(
      :account_id        => account_id,
      :payment_method_id => payment_method_id,
      :event_id          => event_id,
      :state             => state,
      :time              => time
    )
  end

  def build_res_own(account_id, hid, event_id, state, time)
    ResourceOwnershipRecord.create(
      :account_id => account_id,
      :hid        => hid,
      :event_id   => event_id,
      :state      => state,
      :time       => time
    )
  end

  def build_billable_event(hid, event_id, state, time)
    BillableEvent.create(
      :hid => hid,
      :event_id => event_id,
      :state => state,
      :time => time
    )
  end

end
