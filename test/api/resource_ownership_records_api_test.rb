require File.expand_path('../../test_helper', __FILE__)

class ResourceOwnershipRecordApiTest < ShushuTest

  def test_create_record
    post "/resource_ownership_records", {:account_id => account.id, :hid => "123"}
    assert_equal 201, last_response.status
  end

  def account
    @account ||= build_account
  end

end
