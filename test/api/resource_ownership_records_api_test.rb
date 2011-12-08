require File.expand_path('../../test_helper', __FILE__)

class ResourceOwnershipApiTest < ShushuTest

  def test_activate_record
    post "/resource_ownership", {:account_id => account.id, :hid => "123"}
    assert_equal 201, last_response.status
  end

  def account
    @account ||= build_account
  end

end
