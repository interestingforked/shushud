require File.expand_path("../../test_helper", __FILE__)

class RateCodeReportTest < ShushuTest

  def test_rate_code_report
    slug1 = SecureRandom.uuid
    rate_code = build_rate_code(:slug => slug1)
    build_billable_event("app123", nil, 1, jan, rate_code.slug)

    slug2 = SecureRandom.uuid
    provider2  = build_provider(:name => "service depot")
    rate_code2 = build_rate_code(:slug => slug2, :provider_id => provider2.id)
    build_billable_event("app123", nil, 1, jan, rate_code2.slug)
    build_billable_event("app123", nil, 1, jan, rate_code2.slug)

    authorize(provider2.id, "password")
    get("/rate_codes/#{slug2}/report?from=2011-01-01&to=2012-01-01")
    assert_equal(200, last_response.status)
    json_body = JSON.parse(last_response.body)
    assert_equal(slug2, json_body["rate_code"])
    assert_equal(2, json_body["billable_units"].size)
  end

end
