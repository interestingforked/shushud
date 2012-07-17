require File.expand_path('../test_helper', __FILE__)

class UtilsTest < ShushuTest
  def test_uuid_valid
    assert_raises(ArgumentError) {Utils.validate_uuid!("")}
    assert_raises(ArgumentError) do
      Utils.validate_uuid!((SecureRandom.uuid.to_s + "hihihih"))
    end
    assert Utils.validate_uuid!(SecureRandom.uuid)
  end

  def test_start_month
    assert_equal(Time.mktime(2012,1), Utils.start_month(Time.mktime(2012,1,12)))
  end

  def test_end_month
    assert_equal(Time.mktime(2012,12), Utils.end_month(Time.mktime(2012,11)))
    assert_equal(Time.mktime(2013,1), Utils.end_month(Time.mktime(2012,12)))
  end
end
