require File.expand_path('../../test_helper', __FILE__)

class ResourceOwnershipApiTest < ShushuTest

  def setup_auth
    authorize('core', ENV["VAULT_PASSWORD"])
  end

  def test_activate_record
    setup_auth
    post "/resource_ownerships", {:account_id => account.id, :hid => "123", :event_id => "event1"}
    assert_equal 201, last_response.status
  end

  def test_transfer_record
    setup_auth
    second_account = build_account
    post "/resource_ownerships", {:account_id => account.id, :hid => "123", :event_id => "event1"}
    put "/resource_ownerships", {:prev_account_id => account.id, :account_id => second_account.id, :hid => "123", :prev_event_id => "event1", :event_id => "event2"}
    assert_equal 200, last_response.status
    updated_record = JSON.parse(last_response.body)
    assert_equal second_account.id, updated_record["account_id"].to_i
  end

  def test_deactivate_record
    setup_auth
    post "/resource_ownerships", {:account_id => account.id, :hid => "123", :event_id => "event1"}
    put "/resource_ownerships", {:prev_account_id => account.id, :account_id => nil, :hid => "123", :event_id => "event1"}
    assert_equal 200, last_response.status
    updated_record = JSON.parse(last_response.body)
    assert_equal account.id, updated_record["account_id"].to_i
  end

  def test_query_record_with_data
    setup_auth
    post "/resource_ownerships", {:account_id => account.id, :hid => "123"}
    assert_equal(201, last_response.status)

    f, t = (Time.now - 1000), (Time.now + 1000)
    get "/resource_ownerships", {:account_id => account.id, :from => f, :to => t}
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
