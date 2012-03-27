require File.expand_path('../test_helper', __FILE__)

class UtilsTest < ShushuTest
  def test_uuid_valid
    assert_raises(ArgumentError) {Utils.validate_uuid!("")}
    assert_raises(ArgumentError) {Utils.validate_uuid!((SecureRandom.uuid.to_s + "hihihih"))}
    assert Utils.validate_uuid!(SecureRandom.uuid)
  end
end
