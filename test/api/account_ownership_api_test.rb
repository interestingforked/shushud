require File.expand_path('../../test_helper', __FILE__)

class AccountOwnershipApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
    authorize(@provider.id, "abc123")
  end

  def test_activate_record
    acct = build_account(:provider_id => @provider.id)
    s = SecureRandom.uuid
    pm = build_payment_method(:slug => s)
    put("/payment_methods/#{s}/account_ownerships/event1", {
      :state => AccountOwnershipRecord::Active,
      :account_id => acct.id,
      :time => Time.now.utc.to_s
    })
    assert_equal(200, last_response.status)
    created_record = JSON.parse(last_response.body)
    assert_equal(s, created_record["payment_method_id"])
  end

end
