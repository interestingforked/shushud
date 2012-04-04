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
    t0 = Time.mktime(2012,1)
    t1 = t0 + 60 * 60
    t2 = t1 + 60 * 60
    t3 = t2 + 60 * 60
    [t0, t1, t2, t3]
  end

  def uuids
    [SecureRandom.uuid, SecureRandom.uuid]
  end

  def make_increased_then_decreased
    t0, t1, t2, t3 = time
    eid1, eid2     = uuids
    rate_code = build_rate_code(:rate => 5)
    build_billable_event("app123", eid1, 1, t0, rate_code.slug)
    build_billable_event("app123", eid2, 1, t1, rate_code.slug)
    build_billable_event("app123", eid2, 0, t2, rate_code.slug)
    [t0, t1, t2, t3]
  end

  def make_new_and_attrition
    t0, t1, t2, t3 = time
    eid1, eid2     = uuids
    rate_code = build_rate_code(:rate => 5)
    build_billable_event("app123", eid1, 1, t0, rate_code.slug)
    build_billable_event("app123", eid1, 0, t1, rate_code.slug)
    build_billable_event("app124", eid2, 1, t1, rate_code.slug)
    build_billable_event("app124", eid2, 0, t2, rate_code.slug)
    [t0, t1, t2, t3]
  end

  def build_multiple
    t0, t1, t2, t3 = time
    eid1, eid2     = uuids
    rate_code = build_rate_code(:rate => 5)
    build_billable_event("app124", eid1, 1, t1, rate_code.slug)
    build_billable_event("app124", eid1, 0, t2, rate_code.slug)
    build_billable_event("app123", eid2, 1, t1, rate_code.slug)
    build_billable_event("app123", eid2, 0, t2, rate_code.slug)
    [t0, t1, t2, t3]
  end

  def assert_agg_diff(n)
    assert_equal(200, last_response.status)
    agg = JSON.parse(last_response.body)
    assert_equal(n, agg['diff'].to_f)
  end

  def test_res_diff_aggregate_with_multiple
    t0, t1, t2, t3 = build_multiple.map(&:to_s)
    get('/res_diff', {lfrom: t0, lto: t1, rfrom: t1, rto: t2, 
                      delta_increasing: 1, lrev_zero: 1, rrev_zero: 0})
    assert_agg_diff(10)
  end

  def test_res_diff_with_increased
    t0, t1, t2, t3 = make_increased_then_decreased.map(&:to_s)
    params = {lfrom: t0, lto: t1, rfrom: t1, rto: t2, delta_increasing: 1, lrev_zero: 0, rrev_zero: 0}

    get('/res_diff/resources', params) 
    assert_equal(200, last_response.status)

    report = JSON.parse(last_response.body)
    assert_equal(1, report['resources'].length)

    resource = report['resources'].pop
    assert_equal(5, resource["ltotal"].to_f)
    assert_equal(10, resource["rtotal"].to_f)
    assert_equal(5, resource["diff"].to_f)

    get('/res_diff', params)
    assert_agg_diff(5)
  end

  def test_res_diff_with_new
    t0, t1, t2, t3 = make_new_and_attrition.map(&:to_s)
    params = {lfrom: t0, lto: t1, rfrom: t1, rto: t2, delta_increasing: 1, lrev_zero: 1, rrev_zero: 0}

    get('/res_diff/resources', params) 
    assert_equal(200, last_response.status)

    report = JSON.parse(last_response.body)
    assert_equal(1, report['resources'].length)

    resource = report['resources'].pop
    assert_equal(0, resource["ltotal"].to_f)
    assert_equal(5, resource["rtotal"].to_f)
    assert_equal(5, resource["diff"].to_f)
     
    get('/res_diff', params) 
    assert_agg_diff(5)
  end

  def test_res_diff_with_attrition
    t0, t1, t2, t3 = make_new_and_attrition.map(&:to_s)
    params = {lfrom: t0, lto: t1, rfrom: t1, rto: t2, delta_increasing: 0, lrev_zero: 0, rrev_zero: 1}

    get('/res_diff/resources', params) 
    assert_equal(200, last_response.status)

    report = JSON.parse(last_response.body)
    assert_equal(1, report['resources'].length)

    resource = report['resources'].pop
    assert_equal(5, resource["ltotal"].to_f)
    assert_equal(0, resource["rtotal"].to_f)
    assert_equal(-5, resource["diff"].to_f)

    get('/res_diff', params) 
    assert_agg_diff(-5)
  end

  def test_res_diff_with_decreased
    t0, t1, t2, t3 = make_increased_then_decreased.map(&:to_s)
    params = {lfrom: t1, lto: t2, rfrom: t2, rto: t3, delta_increasing: 0, lrev_zero: 0, rrev_zero: 0}

    get('/res_diff/resources', params)
    assert_equal(200, last_response.status)

    report = JSON.parse(last_response.body)
    assert_equal(1, report['resources'].length)

    resource = report['resources'].pop
    assert_equal(10, resource["ltotal"].to_f)
    assert_equal(5, resource["rtotal"].to_f)
    assert_equal(-5, resource["diff"].to_f)

    get('/res_diff', params) 
    assert_agg_diff(-5)
  end

  def test_res_diff_drilldown_with_limit
    t0, t1, t2, t3 = build_multiple.map(&:to_s)
    get('/res_diff/resources', {lfrom: t0, lto: t1, rfrom: t1, rto: t2, 
                                delta_increasing: 1, lrev_zero: 1, rrev_zero: 0, limit: 1})

    assert_equal(200, last_response.status)
    report = JSON.parse(last_response.body)
    assert_equal(1, report['resources'].length)

    get('/res_diff/resources', {lfrom: t0, lto: t1, rfrom: t1, rto: t2, 
                                delta_increasing: 1, lrev_zero: 1, rrev_zero: 0})

    assert_equal(200, last_response.status)
    report = JSON.parse(last_response.body)
    assert_equal(2, report['resources'].length)
  end
end
