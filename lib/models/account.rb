class Account < Sequel::Model

  def self.exists?(id)
    not find(:id => id).nil?
  end

end
