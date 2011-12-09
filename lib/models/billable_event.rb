class BillableEvent < Sequel::Model

  Open = "open"
  Close = "close"

  # I expect that provider_id & rate_code have been validated by this point.
  def self.append_new_event(args, state)
    shulog("#event_creation #{args}")
    create(
      :provider_id      => args[:provider_id],
      :rate_code_id     => args[:rate_code_id],
      :event_id         => args[:event_id],
      :hid              => args[:hid],
      :qty              => args[:qty],
      :time             => args[:time],
      :state            => state,
      :transitioned_at  => Time.now
    )
  end

  def api_values
    {
      :id          => self[:id],
      :provider_id => self[:provider_id],
      :event_id    => self[:event_id],
      :hid         => self[:hid],
      :rate_code   => rate_code[:slug],
      :qty         => self[:qty],
      :time        => self[:time],
      :state       => self[:state]
    }
  end

  def rate_code
    shulog("find rate_code=#{rate_code_id}")
    RateCode[self[:rate_code_id]]
  end

end
