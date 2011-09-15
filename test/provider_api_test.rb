require File.expand_path('../test_helper', __FILE__)

class ProviderApiTest < Shushu::Test

  def setup
    super
    @provider = build_provider(:token => "abc123")
  end

  def setup_auth
    authorize @provider.id, @provider.token
  end

  def test_create_rate_code
    setup_auth
    post "/rate_codes"
    assert_equal 201, last_response.status
  end
  
end
