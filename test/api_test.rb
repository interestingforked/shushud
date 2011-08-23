require File.expand_path('../test_helper', __FILE__)

class ApiTest < ShushuTest

  def test_heartbeat
    get "/heartbeat"
    assert_equal 200, last_response.status
  end

end
