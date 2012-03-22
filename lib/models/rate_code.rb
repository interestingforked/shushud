class RateCode < Sequel::Model

  def to_h
    {
      :slug  => self[:slug],
      :rate  => self[:rate],
      :group => self[:product_group],
      :name  => self[:product_name],
      :period => self[:rate_period]
    }
  end

end
