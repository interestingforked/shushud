class BillableEvent < Sequel::Model

  Open = "open"
  Close = "close"

  def self.prev_recorded(state, event_id)
    events = filter("event_id = ? AND state = ?", event_id, state).all
    if events.length == 0
      nil
    elsif events.length == 1
      events.pop
    else
      raise(ShushuError, "Found #{events.length} events with state=#{state} AND event_id=#{event_id}")
    end
  end

  def to_h
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
    RateCode[self[:rate_code_id]]
  end

end
