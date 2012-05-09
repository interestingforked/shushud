module RateCodeService
  extend self
  PERIODS = %w{month hour}

  def handle_in(args)
    if s = args[:slug]
      if r = RateCode.first(:slug => s)
        [200, r.to_h]
      else
        [201, create_record(args).to_h]
      end
    else
      args[:slug] = SecureRandom.uuid
      [201, create_record(args).to_h]
    end
  end

  def create_record(args)
    if !PERIODS.include?(args[:period])
      raise(ArgumentError, "period must be one of #{PERIODS.join(',')}")
    end

    RateCode.create(
      :provider_id   => args[:provider_id],
      :rate          => args[:rate],
      :rate_period   => args[:period],
      :slug          => args[:slug],
      :product_group => args[:product_group],
      :product_name  => args[:product_name]
    )
  end

end
