require File.expand_path("../../test_helper", __FILE__)

class BillableEventsApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
    @rate_code = build_rate_code(:provider_id => @provider.id)
  end

  def setup_auth
    authorize(@provider.id, "abc123")
  end

  def test_open_event
    setup_auth
    put("/resources/123/billable_events/1", {
      :entity_id_uuid => SecureRandom.uuid,
      :qty         => 1,
      :rate_code   => @rate_code.slug,
      :time        => "2011-01-01 00:00:00",
      :description => "perhaps a command name?",
      :state       => "open"
    })
    assert_equal(201, last_response.status)
  end


  def test_open_event_with_incorrect_params
    setup_auth
    body = {
      :qty        => 1,
      :time       => "2011-01-01 00:00:00",
      :state      => "open"
    }
    put("/resources/123/billable_events/1", body)
    assert_equal(400, last_response.status)
  end


  def test_open_event_with_incorrect_auth
    authorize("something that is not a provider id", "not a provider token")
    body = {
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :time       => "2011-01-01 00:00:00",
      :state      => "open"
    }
    put("/resources/123/billable_events/1", body)
    assert_equal(401, last_response.status)
  end


  def test_open_event_idempotency
    setup_auth
    eid = SecureRandom.uuid
    put("/resources/app123@heroku.com/billable_events/1", {
      :entity_id_uuid => eid,
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :time       => "2011-01-01 00:00:00 +0000",
      :state      => "open"
    })
    assert_equal(201, last_response.status)

    put("/resources/app123@heroku.com/billable_events/1", {
      :entity_id_uuid => eid,
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :time       => "2011-01-01 00:00:00 +0000",
      :state      => "open"
    })
    assert_equal(200, last_response.status)
  end


  def test_close_event
    setup_auth
    body = {
      :entity_id_uuid => SecureRandom.uuid,
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :time       => "2011-01-01 00:00:00 +0000",
      :state      => "open"
    }
    put("/resources/123/billable_events/1", body)
    assert_equal(201, last_response.status)

    put("/resources/123/billable_events/1",
         body.merge({:state => "close", :time => "2011-01-01 00:00:01 +0000"}))
    assert_equal(201, last_response.status)
  end

  def test_idempotent_close
    setup_auth
    body = {
      :entity_id_uuid => SecureRandom.uuid,
      :qty        => 1,
      :rate_code  => @rate_code.slug,
      :time       => "2011-01-01 00:00:00 +0000",
      :state      => "open"
    }
    put("/resources/123/billable_events/1", body)
    assert_equal(201, last_response.status)

    put("/resources/123/billable_events/1",
         body.merge({:state => "close", :time => "2011-01-01 00:00:01 +0000"}))
    assert_equal(201, last_response.status)

    put("/resources/123/billable_events/1",
         body.merge({:state => "close", :time => "2011-01-01 00:00:01 +0000"}))
    assert_equal(200, last_response.status)
  end

end
