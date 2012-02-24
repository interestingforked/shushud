class Account < Sequel::Model

  def self.exists?(id)
    not find(:id => id).nil?
  end

  def to_h
    {:id => api_id}
  end

  def api_id
    self[:slug] || self[:id]
  end

end
