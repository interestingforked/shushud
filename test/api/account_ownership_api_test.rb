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
    post "/payment_methods/#{payment_method.id}/account_ownerships/event1", {:account_id => account.id, :time => Time.now.utc.to_s}
    assert_equal 201, last_response.status
    created_record = JSON.parse(last_response.body)
    assert_equal(payment_method.id, created_record["payment_method_id"])
  end

  def test_transfer_record
    another_payment_method = build_payment_method(:provider_id => @provider.id)
    post "/payment_methods/#{payment_method.id}/account_ownerships/event1", {:account_id => account.id, :time => Time.now.utc.to_s}
    put  "/payment_methods/#{payment_method.id}/account_ownerships/event1", {:payment_method_id => another_payment_method.id, :account_id => account.id, :entity_id => "event2", :time => Time.now.utc.to_s}
    assert_equal 201, last_response.status
    updated_record = JSON.parse(last_response.body)
    assert_equal another_payment_method.id, updated_record["payment_method_id"].to_i
  end

end

