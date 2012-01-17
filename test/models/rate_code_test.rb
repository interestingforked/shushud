require File.expand_path('../../test_helper', __FILE__)

class RateCodeTest < ShushuTest

  def test_slug_generation
    rate_code = RateCode.create
    refute_nil rate_code.slug
  end

  def test_slug_generation_with_slug
    rate_code = RateCode.create :slug => "OHHAI"
    assert_equal "OHHAI", rate_code.slug
  end

end
