module ShushuHelpers

  def build_provider(opts={})
    params = {
      :name  => "sendgrid",
      :token => "password"
    }.merge(opts)
    Provider.create(params).tap {|p| p.reset_token!(params[:token])}.reload
  end

  def build_rate_code(opts={})
    RateCode.create({
      :slug => SecureRandom.uuid,
      :rate => 5,
      :rate_period => "hour",
      :provider_id => provider.id,
    }.merge(opts))
  end

  def build_account(opts={})
    Account.create(opts)
  end

  def build_payment_method(opts={})
    PaymentMethod.create(opts)
  end

  def build_resource_ownership_record(account_id, hid, entity_id, state, time)
    ResourceOwnershipRecord.create({
      :account_id => account_id,
      :entity_id => entity_id || SecureRandom.uuid,
      :hid => hid,
      :time => time,
      :state => state
    })
  end

  def build_act_own(account_id, payment_method_id, entity_id, state, time)
    AccountOwnershipRecord.create(
      :account_id        => account_id,
      :payment_method_id => payment_method_id,
      :entity_id         => entity_id || SecureRandom.uuid,
      :state             => state,
      :time              => time
    )
  end

  def build_res_own(account_id, hid, entity_id, state, time)
    ResourceOwnershipRecord.create(
      :account_id => account_id,
      :hid        => hid,
      :entity_id  => entity_id,
      :state      => state,
      :time       => time
    )
  end

  def build_billable_event(hid, entity_id, state, time, rate_code_slug=nil)
    BillableEvent.create(
      :hid => hid,
      :entity_id => entity_id || SecureRandom.uuid,
      :state => state,
      :time => time,
      :rate_code_id => rate_code_slug || build_rate_code.slug
    )
  end

  def build_receivable(pmid, amount, period_start, period_end)
    Receivable.create(
      :init_payment_method_id => pmid,
      :amount                 => amount,
      :period_start           => period_start,
      :period_end             => period_end
    )
  end

  def build_attempt(state, provider_id, recid, pmid, wait_until, rtry)
    PaymentAttemptRecord.create(
      :provider_id       => provider_id,
      :payment_method_id => pmid,
      :receivable_id     => recid,
      :wait_until        => wait_until,
      :retry             => rtry,
      :state             => state
    )
  end

end
