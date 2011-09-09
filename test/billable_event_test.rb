require File.expand_path('../test_helper', __FILE__)

class BillableEventTest < Shushu::Test

  def test_not_valid_when_changing_reality_from
    event = Shushu::BillableEvent.create(:reality_from => Time.mktime(2011,1), :qty => 1, :rate_code => "SG001")
    event.set(:qty => 2, :reality_to => Time.now)
    assert(!event.valid?)
    assert_equal({:qty => [BillableEvent::ILLEGAL_CHANGE]}, event.errors)
  end

  def test_detect_incorrect_data_change_when_modify_qty
    event = Shushu::BillableEvent.create(:reality_from => Time.mktime(2011,1), :qty => 1, :rate_code => "SG001")

    event.detect_incorrect_data_change
    assert event.errors.empty?

    event.set(:qty => 2)
    event.detect_incorrect_data_change
    assert(!event.errors.empty?)
  end

end
