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

  def build_resource_ownership_record(account_id, hid, entity_id, state, time)
    ResourceOwnershipRecord.create({
      :account_id => account_id,
      :entity_id => entity_id,
      :hid => hid,
      :time => time,
      :state => state
    })
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
    eid = entity_id || SecureRandom.uuid
    BillableEvent.create(
      :hid => hid,
      :entity_id => eid,
      :entity_id_uuid => eid,
      :state => state,
      :time => time,
      :rate_code_id => rate_code_slug || build_rate_code.slug
    )
  end

end
