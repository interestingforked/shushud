require File.expand_path('../../test_helper', __FILE__)

class AccountsApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
  end

  def setup_auth
    authorize(@provider.id, "abc123")
  end

  def test_create_account
    setup_auth
    post("/accounts")
    assert_equal(201, last_response.status)
    refute_nil(JSON.parse(last_response.body)["id"])
  end

end
