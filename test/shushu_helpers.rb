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

  def build_resource_ownership_record(opts={})
    ResourceOwnershipRecord.create({
      :hid => "12345",
      :time => Time.now,
      :state => ResourceOwnershipRecord::Active
    }.merge(opts))
  end

end
