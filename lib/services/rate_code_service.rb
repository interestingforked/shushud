module RateCodeService
  extend self

  def find(slug)
    if rate_code = RateCode.find(:slug => slug)
      Log.info(:action => "find_rate_code", :rate_code => rate_code.id)
      [200, rate_code.to_h]
    else
      Log.error(:error => true, :action => "find_rate_code", :slug => slug)
      raise(Shushu::NotFound, "Could not find rate code with slug=#{slug}")
    end
  end

  def create(args)
    if args[:target_provider_id].nil?
      [201, create_record(args).to_h]
    else
      if Provider[args[:provider_id]].root?
        target_id = args.delete(:target_provider_id)
        [201, create_record(args.merge(:provider_id => target_id))]
      else
        raise(
          Shushu::AuthorizationError,
          "Provider is not authrozied to create rate_codes"
        )
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
        Log.info(:action => "update_rate_code", :rate_code => "#{rate_code.id}")
        rate_code.set(
          :rate          => args[:rate],
          :product_group => args[:product_group],
          :product_name  => args[:product_name]
        )
        if rate_code.save(:raise_on_failure => false)
          Log.info(:action=>"update_rate_code",:rate_code=>"#{rate_code.id}")
          [200, rate_code]
        else
          raise(RuntimeError,"rate code save fail args=#{args[:rate_code]}")
        end
      else
        Log.error({
          :error => true,
          :action => "update_rate_code",
          :message => "rate code not found",
        }.merge(args))
        raise(Shushu::NotFound, "rate_code not found slug=#{args[:slug]}")
      end
    rescue Sequel::Error => e
      raise(RuntimeError, e.message)
    end
  end

end
