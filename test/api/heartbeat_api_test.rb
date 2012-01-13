require File.expand_path('../../test_helper', __FILE__)

class HeartbeatApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
  end

  def setup_auth
    authorize(@provider.id, "abc123")
  end

  def test_heartbeat_with_no_token
    get "/heartbeat"
    assert_equal 400, last_response.status
  end

  def test_heartbeat
    setup_auth
    get "/heartbeat"
    assert_equal 200, last_response.status
  end

end


