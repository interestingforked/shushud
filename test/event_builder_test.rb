require File.expand_path('../test_helper', __FILE__)

class EventBuilderTest < Shushu::Test

  def setup
    super
    @provider = build_provider
  end

  def test_handle_incoming_when_open_new
    args = {
      :provider_id    => @provider.id,
      :resource_id    => "app123",
      :qty            => 1,
      :rate_code      => "RT01",
      :reality_from   => Time.mktime(2011,1)
    }

    assert_equal 0, BillableEvent.count

    _, event = EventBuilder.handle_incomming(args)

    assert_equal 1, BillableEvent.count
    assert event.errors.length.zero?
  end

  def test_handle_incoming_when_close_existing
    args = {
      :provider_id    => @provider.id,
      :event_id       => '123',
      :resource_id    => "app123",
      :qty            => 1,
      :rate_code      => "RT01",
      :reality_from   => Time.mktime(2011,1)
    }
    BillableEvent.create(args)
    _, event = EventBuilder.handle_incomming(:provider_id => @provider.id, :event_id => '123', :reality_to => Time.mktime(2011,1,15))
    assert event.errors.length.zero?
    assert_equal Time.mktime(2011,1,15), event.reality_to
    assert_nil event.system_to
  end

  def test_handle_incoming_creates_another_record_on_close
    args = {
      :provider_id    => @provider.id,
      :event_id       => '123',
      :resource_id    => "app123",
      :qty            => 1,
      :rate_code      => "RT01",
      :reality_from   => Time.mktime(2011,1)
    }
    BillableEvent.create(args)
    assert_equal 1, BillableEvent.count
    _, event = EventBuilder.handle_incomming(:provider_id => @provider.id, :event_id => '123', :reality_to => Time.mktime(2011,1,15))
    assert_equal 2, BillableEvent.count
  end

  def test_handle_incoming_sets_system_to_on_existing_record
    args = {
      :provider_id    => @provider.id,
      :event_id       => '123',
      :resource_id    => "app123",
      :qty            => 1,
      :rate_code      => "RT01",
      :reality_from   => Time.mktime(2011,1)
    }
    existing_event = BillableEvent.create(args)
    _, event = EventBuilder.handle_incomming(:provider_id => @provider.id, :event_id => '123', :reality_to => Time.mktime(2011,1,15))
    assert ! existing_event.reload.system_to.nil?
  end

end
