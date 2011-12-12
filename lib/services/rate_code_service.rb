module RateCodeService
  extend self

  def find(slug)
    if rate_code = RateCode.find(:slug => slug)
      shulog("action=get_rate_code found rate_code=#{rate_code.id}")
      rate_code
    else
      shulog("action=get_rate_code not_found slug=#{slug}")
      raise(HttpApi::NotFound, "Could not find rate code with slug=#{slug}")
    end
  end

  def create(args)
    if args[:target_provider_id].nil?
      create_record(args)
    else
      if Provider[args[:provider_id]].root?
        target_id = args.delete(:target_provider_id)
        create_record(args.merge(:provider_id => target_id))
      else
        raise(HttpApi::AuthorizationError, "Provider is not authrozied to create rate_codes")
      end
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

  def update(args)
    begin
      if rate_code = RateCode.find(:slug => args[:slug])
        shulog("action=update_rate_code rate_code=#{rate_code.id}")
        rate_code.set(
          :rate          => args[:rate],
          :product_group => args[:product_group],
          :product_name  => args[:product_name]
        )
        if rate_code.save(:raise_on_failure => false)
          shulog("action=update_rate_code rate_code=#{rate_code.id} saved")
          rate_code
        else
          raise(RuntimeError, "rate_code=#{rate_code.id} args=#{args[:rate_code]} Failed to save changes")
        end
      else
        shulog("action=update_rate_code not_found rate_code_id=#{args[:rate_code_id]}")
        raise(HttpApi::NotFound, "Could not find rate_code with slug=#{args[:slug]}")
      end
    rescue Sequel::Error => e
      raise(RuntimeError, e.message)
    end
  end

end
