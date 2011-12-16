class ResourceOwnershipRecord < Sequel::Model

  Active = "active"
  Inactive = "inactive"

  # should return a collection of hashes
  def self.collapse(account_id, from, to)
    Shushu::DB[<<-EOD, account_id].all
      SELECT * from resource_ownerships where account_id = ?
    EOD
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
