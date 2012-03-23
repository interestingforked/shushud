require File.expand_path("../../test_helper", __FILE__)

class RateCodeApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
    authorize(@provider.id, "abc123")
  end

  def rate_code_params
    {:rate => 5, :group => "dyno", :name => "web", :period => "month"}
  end

  def test_create_rate_code
    post("/rate_codes", rate_code_params)
    assert_equal(201, last_response.status)
    assert_returns_json(last_response.body)
  end

  def test_only_allows_month_or_hour_for_rate_period
    [[400, "foo"], [201, "hour"], [201, "month"]].each do |status, period|
      post("/rate_codes", rate_code_params.merge(:period => period))
      assert_equal(status, last_response.status)
    end
  end

  def test_create_rate_code_with_slug
    slug = SecureRandom.uuid
    put("/rate_codes/#{slug}", rate_code_params)
    assert_equal(201, last_response.status)
    assert_equal(slug, JSON.parse(last_response.body)["slug"])
    assert_returns_json(last_response.body)
  end

  def test_create_rate_code_idempotent
    slug = SecureRandom.uuid
    put("/rate_codes/#{slug}", rate_code_params)
    assert_equal(201, last_response.status)
    assert_returns_json(last_response.body)
    put("/rate_codes/#{slug}", rate_code_params)
    assert_equal(200, last_response.status)
    assert_returns_json(last_response.body)
  end

  private

  def assert_returns_json(body)
    json = JSON.parse(body)
    assert(json["slug"])
    assert_equal(5, json["rate"])
    assert_equal("dyno", json["group"])
    assert_equal("web", json["name"])
    assert_equal("month", json["period"])
  end

end
