require File.expand_path('../test_helper', __FILE__)

class ProviderApiTest < Shushu::Test
  def test_create_rate_code
    post "/rate_codes"
    assert_equal 201, last_response.status
  end
end
