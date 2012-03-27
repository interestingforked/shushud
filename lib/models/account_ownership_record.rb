class AccountOwnershipRecord < Sequel::Model
  ACTIVE = 1
  INACTIVE = 0

  def payment_method_id=(slug)
    self[:payment_method_id] = begin
      PaymentMethod.first(:slug => slug.to_s) ||
      PaymentMethod.first(:id => slug.to_i)   ||
      raise(ArgumentError, "Unable to resolve payment_method with payment_method_id=#{slug}")
    end[:id]
  end

  def account_id=(slug)
    self[:account_id] = begin
      if a = Account.first(:slug => slug.to_s)
        Log.info(:provider => self[:provider_id], :action => "resolve_account_id", :method => "slug", :slug => slug)
        a
      elsif a = Account.first(:id => slug.to_i)
        Log.info(:provider => self[:provider_id], :action => "resolve_account_id", :method => "id", :id => slug)
        a
      elsif a = Account.create(:slug => slug.to_s, :provider_id => self[:provider_id])
        Log.info(:provider => self[:provider_id], :action => "resolve_account_id", :method => "create", :id => a[:id], :slug => a[:slug])
        a
      else
        raise(ArgumentError, "Unable to resolve or create account with account_id=#{slug}")
      end
    end[:id]
  end

  def to_h
    {
      :entity_id         => self[:entity_id],
      :payment_method_id => payment_method.api_id,
      :account_id        => account.api_id,
      :from              => self[:from],
      :to                => self[:to]
    }
  end

  def payment_method
    @payment_method ||= PaymentMethod[self[:payment_method_id]]
  end

  def account
    @account ||= Account[self[:account_id]]
  end

end
