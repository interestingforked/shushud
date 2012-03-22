class BillableEvent < Sequel::Model
  Open = "open"
  Close = "close"

  STATEAMP = {
    Open => 1,
    Close => 0
  }

  def self.enc_state(string)
    STATEAMP[string]
  end

  def self.dec_state(int)
    STATEAMP.invert.fetch(int)
  end

  def self.prev_recorded(state, entity_id, provider_id)
    Log.info_t({:action => "find_prev_rec", :provider => provider_id, :entity => entity_id, :state => state}) do
      events = filter("provider_id = ? AND entity_id = ? AND state = ?", provider_id, entity_id, enc_state(state)).all
      if events.length == 0
        nil
      elsif events.length == 1
        events.pop
      else
        raise(ShushuError, "Found #{events.length} events with state=#{state} AND entity_id=#{entity_id}")
      end
    end
  end

  def to_h
    {
      :id             => self[:id],
      :created_at     => self[:created_at],
      :provider_id    => self[:provider_id],
      :entity_id      => self[:entity_id],
      :entity_id_uuid => self[:entity_id_uuid],
      :hid            => self[:hid],
      :product_group  => rate_code[:product_group],
      :product_name   => product_name,
      :rate           => rate_code[:rate],
      :rate_code      => rate_code[:slug],
      :qty            => self[:qty],
      :time           => self[:time],
      :state          => self.class.dec_state(self[:state])
    }
  end

  def product_name
    rate_code[:product_name] || self[:product_name]
  end

  def rate_code_id=(slug)
    self[:rate_code_id] = begin
      RateCode.first(:slug => slug.to_s) ||
      RateCode.first(:id => slug.to_i)   ||
      raise(ArgumentError, "Unable to resolve rate_code with rate_code_id=#{slug}")
    end[:id]
  end

  def rate_code
    @rate_code ||= RateCode[self[:rate_code_id]]
  end

end
