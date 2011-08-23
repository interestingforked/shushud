require File.expand_path('../test_helper', __FILE__)

class ApiTest < ShushuTest

  def test_heartbeat
    authorize 'sendgrid', 'sendgrid_token'
    get "/heartbeat"
    assert_equal 200, last_response.status
  end

  def test_open_event
    put_body = { :event => {
      :qty        => 1,
      :rate_code  => 'SG001',
      :created_at => nil,
      :ended_at   => nil
    }}

    authorize 'sendgrid', 'sendgrid_token'
    put "/resources/app123@heroku.com/billable_events/1", put_body
    assert_equal 201, last_response.status
  end

end
