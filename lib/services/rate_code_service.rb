module RateCodeService
  extend self

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
    RateCode.create(
      :provider_id   => args[:provider_id],
      :rate          => args[:rate],
      :slug          => args[:slug],
      :product_group => args[:product_group],
      :product_name  => args[:product_name]
    )
  end

end
