class BillableEvent < Sequel::Model

  Open = "open"
  Close = "close"

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
