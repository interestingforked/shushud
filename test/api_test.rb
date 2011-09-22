require File.expand_path('../test_helper', __FILE__)

class ApiTest < Shushu::Test

  def setup
    super
    @provider = build_provider(:token => "abc123")
    @rate_code = build_rate_code(:provider_id => @provider.id)
  end

  def setup_auth
    authorize @provider.id, @provider.token
  end

  def test_heartbeat_with_bad_token
    get "/resources/heartbeat"
    assert_equal 401, last_response.status
  end

  def test_heartbeat
    setup_auth
    get "/resources/heartbeat"
    assert_equal 200, last_response.status
  end

  def test_get_events
    setup_auth

    put_body = {
      "qty"       => 1,
      "rate_code" => @rate_code.slug,
      "from"      => '2011-01-01 00:00:00 -0800',
      "to"        => nil
    }
    put "resources/app123@heroku.com/billable_events/1", put_body

    get_body = put_body.merge({
      "provider_id" => @provider.id,
      "resource_id" => "app123@heroku.com",
      "event_id"    => "1"
    })
    get "/resources/app123@heroku.com/billable_events"
    assert_equal get_body, JSON.parse(last_response.body).first
  end

  def test_open_event
    setup_auth
    put_body = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :from       => '2011-01-01 00:00:00 -0800',
      :to         => nil
    }
    put "/resources/app123@heroku.com/billable_events/1", put_body
    assert_equal 201, last_response.status
    assert_equal '2011-01-01 00:00:00 -0800', JSON.parse(last_response.body)["from"]
    assert_equal nil, JSON.parse(last_response.body)["to"]
  end

  def test_open_event_on_second_call
    setup_auth
    put_body = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :from       => '2011-01-01 00:00:00 -0800',
      :to         => nil
    }

    put "/resources/app123@heroku.com/billable_events/1", put_body
    assert_equal 201, last_response.status

    put "/resources/app123@heroku.com/billable_events/1", put_body
    assert_equal 200, last_response.status

  end

  def test_open_event_on_third_call
    setup_auth
    put_body = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :from       => '2011-01-01 00:00:00 -0800',
      :to         => nil
    }
    put "/resources/app123@heroku.com/billable_events/1", put_body
    assert_equal 201, last_response.status
    put "/resources/app123@heroku.com/billable_events/1", put_body
    put "/resources/app123@heroku.com/billable_events/1", put_body
    assert_equal 200, last_response.status
  end

  def test_open_event_on_second_call_and_change_qty
    setup_auth
    put_body = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :from       => '2011-01-01 00:00:00 -0800',
      :to         => nil
    }

    put "/resources/app123@heroku.com/billable_events/1", put_body
    put "/resources/app123@heroku.com/billable_events/1", put_body.merge(:qty => 2)
    assert_equal 409, last_response.status
  end

  def test_open_event_on_second_call_and_change_from
    setup_auth
    put_body = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :from       => '2011-01-01 00:00:00 -0800',
      :to         => nil
    }

    put "/resources/app123@heroku.com/billable_events/1", put_body
    put "/resources/app123@heroku.com/billable_events/1", put_body.merge(:from => '2011-01-10 00:00:00 -0800')
    assert_equal 409, last_response.status
  end

  def test_open_event_on_second_call_and_change_rate_code
    setup_auth
    put_body = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :from       => '2011-01-01 00:00:00 -0800',
      :to         => nil
    }

    put "/resources/app123@heroku.com/billable_events/1", put_body
    some_other_rate_code = build_rate_code(:provider_id => @provider.id, :slug=>'RTXXX')
    put "/resources/app123@heroku.com/billable_events/1", put_body.merge(:rate_code => some_other_rate_code.slug)
    assert_equal 409, last_response.status
  end

  def test_open_event_including_to
    setup_auth
    put_body = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :from       => '2011-01-01 00:00:00 -0800',
      :to         => '2011-01-02 00:00:00 -0800'
    }
    put "/resources/app123@heroku.com/billable_events/1", put_body
    assert_equal 201, last_response.status
  end

  def test_close_event
    setup_auth
    open = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :from       => '2011-01-01 00:00:00 -0800',
      :to         => nil
    }
    put "/resources/app123@heroku.com/billable_events/1", open
    put "/resources/app123@heroku.com/billable_events/1", {:to => '2011-02-01 00:00:00 -0800'}

    assert_equal 200, last_response.status
    assert_equal '2011-01-01 00:00:00 -0800', JSON.parse(last_response.body)["from"]
    assert_equal '2011-02-01 00:00:00 -0800', JSON.parse(last_response.body)["to"]
  end

end
