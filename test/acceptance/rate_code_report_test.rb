require File.expand_path('../../test_helper', __FILE__)

class RateCodeReportTest < ShushuTest

  def test_rate_code_report
    rate_code = build_rate_code :slug => "foo"
    build_billable_event("app123", nil, 1, jan, rate_code.id)
    provider2  = build_provider :name => "service depot"
    rate_code2 = build_rate_code :slug => 'foo', :provider_id => provider2.id
    build_billable_event("app123", nil, 1, jan, rate_code2.id)
    build_billable_event("app123", nil, 1, jan, rate_code2.id)

    authorize provider2.id, "password"
    get '/rate_codes/foo/report?from=2011-01-01&to=2012-01-01' 
    assert_equal 200, last_response.status
    json_body = JSON.parse(last_response.body)
    assert_equal 'foo', json_body['rate_code']
    assert_equal 2, json_body['billable_units'].size
  end

end

