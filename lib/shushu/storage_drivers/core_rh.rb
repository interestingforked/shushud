module CoreRH

  extend self
  
  def find(conditions)
    ResourceHistory.find(:all,
      :conditions => ["app_id = ? and user_id = ?", conditions[:resource_id], conditions[:provider_id]]
    )
  end
  
  def find_open(provider_id, event_id)
    res = ResourceHistory.find(:all,
      :conditions => ["upid = ? and user_id = ? and ended_at IS NULL", event_id, provider_id]
    )
    
    if res.count == 0
      log("could not find an open record")
    elsif res.count == 1
      res[0]
    else
      log("error: too many records found")
    end
  end
  
  def open(args)
    open_on_rh_model(args.merge({:qty => 1, :rate_code => find_rate_code_id(args[:rate_code])}))
  end

  def close(existing_event_id, closed_at)
    ResourceHistory.find(existing_event_id).tap do |rh|
      rh.update_attribute(:ended_at, closed_at)
    end
  end

  private
  
  def open_on_rh_model(args)
    rh = ResourceHistory.legacy_open_new(
      args[:resource_id],
      args[:provider_id], #user_id
      nil,                #res_id
      nil,                #resource
      nil,                #subresource
      args[:qty],         #qty
      args[:rate_code],   #rate
      'month',            #rate_period
      nil,                #beta_status
      nil,                #notes
      args[:event_id]
    )
    rh[:created_at] = args[:reality_from]
    rh.save!
    rh
  end
  
  def find_rate_code_id(slug)
    if rate_code = RateCode.filter(:slug => slug).first
      rate_code.id
    else
      raise "coult not find rate_code"
    end
  end

end

