require File.expand_path('../../test_helper', __FILE__)

class EventsApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
    @rate_code = build_rate_code(:provider_id => @provider.id)
  end

  def setup_auth
    authorize(@provider.id, @provider.token)
  end

  def open_event(event_id, opts={})
    body = {
      "qty"       => 1,
      "rate_code" => @rate_code.slug,
      "time"      => '2011-01-01 00:00:00',
      "state"     => 'open'
    }.merge(opts)
    put "resources/123/billable_events/#{event_id || 1}", body
  end

  def test_get_events
    setup_auth
    open_event("456")
    get("/resources/123/billable_events")
    assert_equal("456", JSON.parse(last_response.body).first["event_id"])
  end

  def test_open_event
    setup_auth
    body = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :time       => '2011-01-01 00:00:00',
      :state      => 'open'
    }
    put("/resources/123/billable_events/1", body)
    assert_equal(200, last_response.status)
    assert_equal('2011-01-01 00:00:00 UTC', JSON.parse(last_response.body)["time"])
    assert_equal('open', JSON.parse(last_response.body)["state"])
  end

  def test_open_event_on_second_call_returns_same_billable_event_id
    setup_auth
    put_body = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :time       => '2011-01-01 00:00:00 +0000',
      :state      => 'open'
    }

    put "/resources/app123@heroku.com/billable_events/1", put_body
    billable_event_id = JSON.parse(last_response.body)["id"]
    assert(!billable_event_id.nil?, "Did not receive id")
    put "/resources/app123@heroku.com/billable_events/1", put_body
    assert_equal billable_event_id, JSON.parse(last_response.body)["id"]
  end

  def test_open_event_on_third_call
    setup_auth
    put_body = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :time       => '2011-01-01 00:00:00 +0000',
      :state      => 'open'
    }
    put "/resources/app123/billable_events/1", put_body
    assert_equal 200, last_response.status
    put "/resources/app123/billable_events/1", put_body
    put "/resources/app123/billable_events/1", put_body
    assert_equal 200, last_response.status
  end

  def test_open_event_on_second_call_and_ignores_change
    setup_auth
    put_body = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :time       => '2011-01-01 00:00:00 +0000',
      :state      => 'open'
    }

    put "/resources/app123@heroku.com/billable_events/1", put_body
    qty = JSON.parse(last_response.body)["qty"]
    time = JSON.parse(last_response.body)["time"]
    put "/resources/app123@heroku.com/billable_events/1", put_body.merge(:qty => 2, :time => '2011-01-01 00:00:00 +0000')
    assert_equal qty, JSON.parse(last_response.body)["qty"]
    assert_equal time, JSON.parse(last_response.body)["time"]
  end

  def test_close_event
    setup_auth
    body = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :time       => '2011-01-01 00:00:00 +0000',
      :state      => 'open'
    }
    put "/resources/123/billable_events/1", body
    put "/resources/123/billable_events/1", body.merge({:state => "close", :time => '2011-01-01 00:00:01 +0000'})
    assert_equal 200, last_response.status
  end

end
