class RateCode < Sequel::Model

  def self.resolve_id(slug)
    if r = RateCode[:slug => Utils.validate_uuid!(slug)]
      r[:id]
    else
      raise(NotFound, "Could not find rate_code with slug=#{slug}")
    end
  end

  def to_h
    {
      :slug   => self[:slug],
      :rate   => self[:rate],
      :group  => self[:product_group],
      :name   => self[:product_name],
      :period => self[:rate_period]
    }
  end

end
