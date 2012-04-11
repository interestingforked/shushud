class ResourceOwnershipRecord < Sequel::Model
  ACTIVE = 1
  INACTIVE = 0

  def account_id=(slug)
    self[:account_id] = begin
      if a = Account.first(:slug => slug.to_s)
        log(:provider_id => self[:provider_id], :action => "resolve_account_id", :method => "slug", :slug => slug)
        a
      elsif a = Account.first(:id => slug.to_i)
        log(:provider_id => self[:provider_id], :action => "resolve_account_id", :method => "id", :id => slug)
        a
      elsif a = Account.create(:slug => slug.to_s, :provider_id => self[:provider_id])
        log(:provider_id => self[:provider_id], :action => "resolve_account_id", :method => "create", :id => a[:id], :slug => a[:slug])
        a
      else
        raise(ArgumentError, "Unable to resolve or create account with account_id=#{slug}")
      end
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
