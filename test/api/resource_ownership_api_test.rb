require File.expand_path('../../test_helper', __FILE__)

class ResourceOwnershipApiTest < ShushuTest

  def test_activate_record
    post "/resource_ownership", {:account_id => account.id, :hid => "123"}
    assert_equal 201, last_response.status
  end

  def test_transfer_record
    second_account = build_account
    post "/resource_ownership", {:account_id => account.id, :hid => "123"}
    put "/resource_ownership", {:prev_account_id => account.id, :account_id => second_account.id, :hid => "123"}
    assert_equal 201, last_response.status
  end

  def account
    @account ||= build_account
  end

end
