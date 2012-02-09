class AccountOwnershipRecord < Sequel::Model
  Active = "active"
  Inactive = "inactive"

  def self.active
    Active
  end

  def self.inactive
    Inactive
  end

  def payment_method_id=(slug)
    self[:payment_method_id] = begin
      PaymentMethod.first(:slug => slug.to_s) ||
      PaymentMethod.first(:id => slug.to_i)   ||
      raise(ArgumentError, "Unable to resolve rate_code with rate_code_id=#{slug}")
    end[:id]
  end

  def self.collapse(payment_method_id)
    Shushu::DB.synchronize do |conn|
      conn.exec("SELECT * from account_ownerships WHERE payment_method_id = ? ", payment_method_id).to_a
    end
  end

  def to_h
    {
      :entity_id         => self[:entity_id],
      :payment_method_id => self[:payment_method_id],
      :account_id        => self[:account_id],
      :from              => self[:from],
      :to                => self[:to]
    }
  end
end
