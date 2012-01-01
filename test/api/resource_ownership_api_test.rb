require File.expand_path('../../test_helper', __FILE__)

class ResourceOwnershipApiTest < ShushuTest

  def setup_auth
    authorize('core', ENV["VAULT_PASSWORD"])
  end

  def test_activate_record
    setup_auth
    post "/accounts/#{account.id}/resource_ownerships/event1", {:hid => "123", :time => Time.now.utc.to_s}
    assert_equal 201, last_response.status
  end

  def test_activate_record_with_invalid_account_id
    setup_auth
    post "/accounts/INVALID_ID/resource_ownerships/event1", {:hid => "123", :time => Time.now.utc.to_s}
    assert_equal 404, last_response.status
  end

  def test_transfer_record
    setup_auth
    second_account = build_account
    post "/accounts/#{account.id}/resource_ownerships/event1", {:hid => "123", :time => Time.now.utc.to_s}
    put "/accounts/#{account.id}/resource_ownerships/event1", {:account_id => second_account.id, :hid => "123", :entity_id => "event2", :time => Time.now.utc.to_s}
    assert_equal 201, last_response.status
    updated_record = JSON.parse(last_response.body)
    assert_equal second_account.id, updated_record["account_id"].to_i
  end

  def test_deactivate_record
    setup_auth
    post "/accounts/#{account.id}/resource_ownerships/event1", {:hid => "123", :time => Time.now.utc.to_s}
    delete "/accounts/#{account.id}/resource_ownerships/event1", {:hid => "123", :time => Time.now.utc.to_s}
    assert_equal 201, last_response.status
    updated_record = JSON.parse(last_response.body)
    assert_equal account.id, updated_record["account_id"].to_i
  end

  def test_query_record_with_data
    setup_auth
    post "/accounts/#{account.id}/resource_ownerships/event1", {:hid => "123", :time => Time.now.utc.to_s}
    assert_equal(201, last_response.status)

    f, t = (Time.now - 1000), (Time.now + 1000)
    get "/accounts/#{account.id}/resource_ownerships"
    results = JSON.parse(last_response.body)
    assert_equal(1, results.length)
    result = results.pop
    assert_equal(200, last_response.status)
    assert_equal(account.id, result["account_id"])
    assert_equal("123", result["hid"])
  end

  def account
    @account ||= build_account
  end

end
