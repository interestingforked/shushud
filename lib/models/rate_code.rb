class RateCode < Sequel::Model

  def before_create
    self.slug ||= SecureRandom.uuid
    super
  end

  def to_h
    {
      :slug  => self[:slug],
      :rate  => self[:rate],
      :group => self[:product_group],
      :name  => self[:product_name]
    }
  end

end
