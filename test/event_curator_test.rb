require File.expand_path('../test_helper', __FILE__)

class EventCuratorTest < Shushu::Test

  def test_process_when_event_is_new
    provider = Shushu::Provider.create
    code, body = Shushu::EventCurator.process(
      :provider_id   => provider.id,
      :resource_id   => "app123@heroku.com",
      :event_id      => "123",
      :reality_from  => Time.now,
      :reality_to    => nil,
      :qty           => 10,
      :rate_code     => 'SG001'
    )
    assert_equal 201, code
  end

end
