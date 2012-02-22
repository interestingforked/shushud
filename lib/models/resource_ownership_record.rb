class ResourceOwnershipRecord < Sequel::Model

  Active = "active"
  Inactive = "inactive"

  def self.active
    Active
  end

  def self.inactive
    Inactive
  end

  def validate
    super
    if !Account.exists?(self[:account_id])
      raise(Shushu::NotFound, "Could not find account with id=#{self[:account_id]}")
    end
  end

  def to_h
    {
      :account_id  => self[:account_id],
      :resource_id => self[:hid],
      :from        => self[:from],
      :to          => self[:to]
      }
  end

end
