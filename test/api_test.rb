require File.expand_path('../test_helper', __FILE__)

class ApiTest < Shushu::Test

  def test_heartbeat_with_bad_token
    provider = Shushu::Provider.create(:token => "abc123")
    authorize provider.id, (provider.token + "bad token")
    get "/heartbeat"
    assert_equal 401, last_response.status
  end

  def test_heartbeat
    provider = Shushu::Provider.create(:token => "abc123")
    authorize provider.id, provider.token
    get "/heartbeat"
    assert_equal 200, last_response.status
  end

  def test_open_event
    put_body = {
      :qty          => 1,
      :rate_code    => 'SG001',
      :reality_from => '2011-01-01 00:00:00 -0800',
      :reality_to   => nil
    }

    provider = Shushu::Provider.create(:token => "abc123")
    authorize provider.id, provider.token

    put "/resources/app123@heroku.com/billable_events/1", put_body
    assert_equal 201, last_response.status
  end

  def test_open_event_on_second_call
    put_body = {
      :qty          => 1,
      :rate_code    => 'SG001',
      :reality_from => '2011-01-01 00:00:00 -0800',
      :reality_to   => nil
    }

    provider = Shushu::Provider.create(:token => "abc123")
    authorize provider.id, provider.token

    put "/resources/app123@heroku.com/billable_events/1", put_body
    assert_equal 201, last_response.status

    put "/resources/app123@heroku.com/billable_events/1", put_body
    assert_equal 200, last_response.status
  end

end
