class ResourceOwnershipRecord < Sequel::Model

  Active = "active"
  Inactive = "inactive"

  def self.active
    Active
  end

  def self.inactive
    Inactive
  end

  def account_id=(slug)
    self[:account_id] = begin
      Account.first(:slug => slug.to_s) ||
      Account.first(:id => slug.to_i)   ||
      Account.create(:slug => slug.to_s)||
      raise(ArgumentError, "Unable to resolve or create account with account_id=#{slug}")
    end[:id]
  end

  def to_h
    {
      :account_id  => account.api_id,
      :resource_id => self[:hid],
      :from        => self[:from],
      :to          => self[:to]
      }
  end

  def account
    @account ||= Account[self[:account_id]]
  end

end
