require File.expand_path('../../test_helper', __FILE__)

class LogTest < ShushuTest
  def test_escape
    assert_equal("{\"name\":\"ryan.smith\"}", LogParser.unparse(:name => "ryan.smith"))
    assert_equal("{\"name\":\"ryan.smith(\\\"name\\\")\"}", LogParser.unparse(:name => 'ryan.smith("name")'))
  end
end
