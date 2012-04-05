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

  def test_res_diff_with_increased
    t0, t1, t2, t3 = build_events
    params = {lfrom: t0, lto: t1, rfrom: t1, rto: t2, delta_increasing: 1, lrev_zero: 0, rrev_zero: 0}

    get('/res_diff/resources', params) 
    assert_equal(200, last_response.status)

    report = JSON.parse(last_response.body)
    assert_equal(1, report['resources'].length)

    resource = report['resources'].pop
    assert_equal(120, resource["ltotal"].to_f)
    assert_equal(240, resource["rtotal"].to_f)
    assert_equal(120, resource["diff"].to_f)

    get('/res_diff', params)
    assert_agg_diff(120)
  end

  def test_res_diff_with_new
    t0, t1, t2, t3 = build_events
    params = {lfrom: t0, lto: t1, rfrom: t1, rto: t2, delta_increasing: 1, lrev_zero: 1, rrev_zero: 0}

    get('/res_diff/resources', params) 
    assert_equal(200, last_response.status)

    report = JSON.parse(last_response.body)
    assert_equal(1, report['resources'].length)

    resource = report['resources'].pop
    assert_equal(0, resource["ltotal"].to_f)
    assert_equal(120, resource["rtotal"].to_f)
    assert_equal(120, resource["diff"].to_f)
     
    get('/res_diff', params) 
    assert_agg_diff(120)
  end

  def test_res_diff_with_attrition
    t0, t1, t2, t3 = build_events
    params = {lfrom: t0, lto: t1, rfrom: t1, rto: t2, delta_increasing: 0, lrev_zero: 0, rrev_zero: 1}

    get('/res_diff/resources', params) 
    assert_equal(200, last_response.status)

    report = JSON.parse(last_response.body)
    assert_equal(1, report['resources'].length)

    resource = report['resources'].pop
    assert_equal(120, resource["ltotal"].to_f)
    assert_equal(0, resource["rtotal"].to_f)
    assert_equal(-120, resource["diff"].to_f)

    get('/res_diff', params) 
    assert_agg_diff(-120)
  end

  def test_res_diff_with_decreased
    t0, t1, t2, t3 = build_events
    params = {lfrom: t1, lto: t2, rfrom: t2, rto: t3, delta_increasing: 0, lrev_zero: 0, rrev_zero: 0}

    get('/res_diff/resources', params)
    assert_equal(200, last_response.status)

    report = JSON.parse(last_response.body)
    assert_equal(1, report['resources'].length)

    resource = report['resources'].pop
    assert_equal(240, resource["ltotal"].to_f)
    assert_equal(120, resource["rtotal"].to_f)
    assert_equal(-120, resource["diff"].to_f)

    get('/res_diff', params) 
    assert_agg_diff(-120)
  end

  def test_res_diff_drilldown_with_limit
    t0, t1, t2, t3 = build_multiple_new.map(&:to_s)
    params = {lfrom: t0, lto: t1, rfrom: t1, rto: t2, delta_increasing: 1, lrev_zero: 1, rrev_zero: 0} 

    get('/res_diff/resources', params.merge(limit: 1)) 
    assert_equal(200, last_response.status)

    report = JSON.parse(last_response.body)
    assert_equal(1, report['resources'].length)

    get('/res_diff/resources', params)
    report = JSON.parse(last_response.body)
    assert_equal(200, last_response.status)
    assert_equal(2, report['resources'].length)
  end

  def test_res_diff_aggregate_with_multiple_new
    t0, t1, t2, t3 = build_multiple_new.map(&:to_s)
    params = {lfrom: t0, lto: t1, rfrom: t1, rto: t2,  delta_increasing: 1, lrev_zero: 1, rrev_zero: 0}
    get('/res_diff', params)
    assert_agg_diff(240)
  end

  private
  def assert_agg_diff(n)
    assert_equal(200, last_response.status)
    agg = JSON.parse(last_response.body)
    assert_equal(n, agg['diff'].to_f)
  end

  # app123 increases t1 -> t2 then decreases t2 -> t3
  # app124 is new in t1 -> t2
  # app125 is attrition in t1 -> t2
  def build_events
    t0, t1, t2, t3 = time
    eid1, eid2, eid3, eid4 = 4.times.map { SecureRandom.uuid }
    rate_code = build_rate_code(:rate => 5)
    build_billable_event("app123", eid1, 1, t0, rate_code.slug)
    build_billable_event("app123", eid2, 1, t1, rate_code.slug)
    build_billable_event("app123", eid2, 0, t2, rate_code.slug)
    build_billable_event("app124", eid3, 1, t1, rate_code.slug)
    build_billable_event("app124", eid3, 0, t2, rate_code.slug)
    build_billable_event("app125", eid4, 1, t0, rate_code.slug)
    build_billable_event("app125", eid4, 0, t1, rate_code.slug)
    [t0, t1, t2, t3].map{ |t| t.strftime('%Y-%m-%d') }
  end

  # app123 and app124 both are new in t1 -> t2
  def build_multiple_new
    t0, t1, t2, t3 = time
    eid1, eid2     = 2.times.map { SecureRandom.uuid }
    rate_code = build_rate_code(:rate => 5)
    build_billable_event("app124", eid1, 1, t1, rate_code.slug)
    build_billable_event("app124", eid1, 0, t2, rate_code.slug)
    build_billable_event("app123", eid2, 1, t1, rate_code.slug)
    build_billable_event("app123", eid2, 0, t2, rate_code.slug)
    [t0, t1, t2, t3].map{ |t| t.strftime('%Y-%m-%d') }
  end

  def time
    t0 = Time.mktime(2012,1)
    t1 = t0 + 60 * 60 * 24
    t2 = t1 + 60 * 60 * 24
    t3 = t2 + 60 * 60 * 24
    [t0, t1, t2, t3]
  end
end
