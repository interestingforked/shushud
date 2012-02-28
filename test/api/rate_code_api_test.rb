require File.expand_path('../../test_helper', __FILE__)

class RateCodeApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
    authorize(@provider.id, "abc123")
  end

  def test_create_rate_code
    post("/rate_codes", {:rate => 5, :group => "dyno", :name => "web"})
    assert_equal(201, last_response.status)
  end

  def test_create_rate_code_with_slug
    slug = SecureRandom.uuid
    put("/rate_codes/#{slug}", {
      :rate => 5, :group => "dyno", :name => "web"
    })
    assert_equal(201, last_response.status)
    assert_equal(slug, JSON.parse(last_response.body)["slug"])
  end

  def test_create_rate_code_idempotent
    slug = SecureRandom.uuid
    put("/rate_codes/#{slug}", {
      :rate => 5, :group => "dyno", :name => "web"
    })
    assert_equal(201, last_response.status)
    put("/rate_codes/#{slug}", {
      :rate => 5, :group => "dyno", :name => "web"
    })
    assert_equal(200, last_response.status)
  end

end
