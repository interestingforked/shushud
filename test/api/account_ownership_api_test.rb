require File.expand_path('../../test_helper', __FILE__)

class AccountOwnershipApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
    authorize(@provider.id, "abc123")
  end

  def account
    @account ||= build_account(:provider_id => @provider.id)
  end

  def payment_method
    @payment_method ||= build_payment_method(:provider_id => @provider.id)
  end

  def test_activate_record
    put("/payment_methods/#{payment_method.id}/account_ownerships/event1", {
      :state => AccountOwnershipRecord::Active,
      :account_id => account.id,
      :time => Time.now.utc.to_s
    })
    assert_equal(200, last_response.status)
    created_record = JSON.parse(last_response.body)
    assert_equal(payment_method.id, created_record["payment_method_id"])
  end

end
