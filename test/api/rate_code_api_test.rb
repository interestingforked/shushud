require File.expand_path('../../test_helper', __FILE__)

class RateCodeApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
    authorize(@provider.id, "abc123")
  end

  def test_create_rate_code
    post("/rate_codes")
    assert_equal(201, last_response.status)
  end

  def test_find_rate_code_can_succeed
    RateCode.create(:provider_id => @provider.id, :slug => "rt01", :rate => 5)
    get("/rate_codes/rt01")
    assert_equal(200, last_response.status)
  end

  def test_find_rate_code_can_404
    get("/rate_codes/not_A_rate_code")
    assert_equal(404, last_response.status)
  end

  def test_update_rate_code
    RateCode.create(:provider_id => @provider.id, :slug => "rt01", :rate => 5)

    put("/rate_codes/rt01", {:rate_code => {:rate => 10}})
    assert_equal(200, last_response.status)
  end

end
