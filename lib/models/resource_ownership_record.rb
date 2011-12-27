class ResourceOwnershipRecord < Sequel::Model

  Active = "active"
  Inactive = "inactive"

  # should return a collection of hashes
  def self.collapse(account_id)
    Shushu::DB[<<-EOD, account_id].all
      SELECT * from resource_ownerships where account_id = ?
    EOD
  end

  def validate
    super
    if !Account.exists?(self[:account_id])
      raise(Shushu::NotFound, "Could not find account with id=#{self[:account_id]}")
    end
  end

  def to_h
    {
      :account_id => self[:account_id],
      :hid        => self[:hid],
      :from       => self[:from],
      :to         => self[:to]
      }
  end

end
