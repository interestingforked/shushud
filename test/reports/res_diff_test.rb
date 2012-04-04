require File.expand_path('../../test_helper', __FILE__)

class ResDiffReportTest < ShushuTest
  def app
    Api::Reports
  end

  def setup
    super
    @provider = build_provider(:token => "abc123")
    authorize(@provider.id, "abc123")
  end

  def time
    Time.mktime(2012,1)
  end

  def make_increased_app
    t0 = time 
    t1 = t0 + 60 * 60
    t2 = t1 + 60 * 60
    t3 = t2 + 60 * 60
    eid1 = SecureRandom.uuid
    eid2 = SecureRandom.uuid
    rate_code = build_rate_code(:rate => 5)
    build_billable_event("app123", eid1, 1, t0, rate_code.slug)
    build_billable_event("app123", eid2, 1, t1, rate_code.slug)
    build_billable_event("app123", eid2, 0, t2, rate_code.slug)
    [t0, t1, t2]
  end


  def test_res_diff_with_increased_app
    t0, t1, t2 = make_increased_app.map(&:to_s)
    get '/res_diff', {lfrom: t0, lto: t1, rfrom: t1, rto: t2, 
                      delta_increasing: 1, lrev_zero: 0, rrev_zero: 0}

    assert_equal 200, last_response.status
    report = JSON.parse(last_response.body)
    assert_equal 1, report['resources'].length
    resource = report['resources'].pop
    assert_equal(5, resource["ltotal"].to_f)
    assert_equal(10, resource["rtotal"].to_f)
    assert_equal(5, resource["diff"].to_f)
  end
end
