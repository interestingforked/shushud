require File.expand_path('../../test_helper', __FILE__)

class ProviderApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
  end

  def setup_auth
    authorize @provider.id, @provider.token
  end

  def test_create_rate_code_for_target
    @provider.update(:root => true)
    setup_auth
    target_provier = build_provider

    post "/providers/#{target_provier.id}/rate_codes", {:rate_code => {:rate => 5}}
    assert_equal 201, last_response.status
  end

  def test_create_rate_code_for_target_when_not_authorized
    setup_auth
    target_provier = build_provider

    post "/providers/#{target_provier.id}/rate_codes", {:rate => 5}
    assert_equal 403, last_response.status
  end

end
