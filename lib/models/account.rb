class Account < Sequel::Model

  def self.exists?(id)
    not find(:id => id).nil?
  end

  def to_h
    {:id => self[:id]}
  end

end
