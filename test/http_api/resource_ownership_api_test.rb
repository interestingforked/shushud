require File.expand_path('../../test_helper', __FILE__)

class ResourceOwnershipApiTest < ShushuTest

  def test_activate_record
    post "/resource_ownerships", {:account_id => account.id, :hid => "123"}
    assert_equal 200, last_response.status
  end

  def test_transfer_record
    second_account = build_account
    post "/resource_ownerships", {:account_id => account.id, :hid => "123"}
    put "/resource_ownerships", {:prev_account_id => account.id, :account_id => second_account.id, :hid => "123"}
    assert_equal 200, last_response.status
    updated_record = JSON.parse(last_response.body)
    assert_equal second_account.id, updated_record["account_id"].to_i
  end

  def test_query_record
    get "/resource_ownerships", {:account_id => account.id}
    assert_equal 404, last_response.status
  end

  def test_query_record_finds_with_hid
    post "/resource_ownerships", {:account_id => account.id, :hid => "123"}
    newly_created_r = JSON.parse(last_response.body)
    hid = newly_created_r["hid"]
    get "/resource_ownerships", {:hid => hid}
    assert_equal 200, last_response.status
  end

  def test_query_record_finds_with_account_id
    post "/resource_ownerships", {:account_id => account.id, :hid => "123"}
    newly_created_r = JSON.parse(last_response.body)
    account_id = newly_created_r["account_id"]
    get "/resource_ownerships", {:account_id => account_id}
    assert_equal 200, last_response.status
  end

  def account
    @account ||= build_account
  end

end
