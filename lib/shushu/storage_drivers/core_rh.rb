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
    ResourceHistory.create!({
      :app_id      => args[:resource_id],
      :user_id     => args[:provider_id],
      :resource_id => nil,
      :resource    => nil,
      :subresource => nil,
      :qty         => args[:qty],
      :rate        => find_rate_code_id(args[:rate_code]),
      :rate_period => 'month',
      :notes       => nil,
      :upid        => args[:event_id],
      :created_at  => args[:reality_from],
      :ended_at    => args[:reality_to],
      :version     => 4
    })
  end

  def close(existing_event_id, closed_at)
    ResourceHistory.find(existing_event_id).tap do |rh|
      rh.update_attribute(:ended_at, closed_at)
    end
  end

  private

  def find_rate_code_id(slug)
    if rate_code = RateCode.filter(:slug => slug).first
      rate_code.id
    else
      raise "coult not find rate_code"
    end
  end

end
