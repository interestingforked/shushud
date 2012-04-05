require File.expand_path("../../../lib/shushu", __FILE__)

def provider
  @provider ||= Provider.create :name => "shushu@heroku.com", :token => "secret"
end

def reid
  @reid ||= SecureRandom.uuid
end

def be(eid, hid, time, qty, state)
  BillableEventService.handle_in({
    :provider_id    => provider.id,
    :rate_code      => reid,
    :hid            => hid,
    :entity_id      => eid,
    :time           => time,
    :state          => state,
    :qty            => qty
  })
end

RateCodeService.handle_in(
  :provider_id        => provider.id,
  :slug               => reid,
  :rate               => 5,
  :period             => "hour",
  :product_group      => "dyno",
  :product_name       => "web"
)

# open event
SecureRandom.uuid.tap do |eid|
  be(eid, 'app123@heroku.com', Time.utc(2000, 1), 1, 'open')
  be(eid, 'app123@heroku.com', Time.utc(2000, 2), 1, 'close')
end

SecureRandom.uuid.tap do |eid|
  be(eid, 'app123@heroku.com', Time.utc(2000, 2), 2, 'open')
end

# new
SecureRandom.uuid.tap do |eid|
  be(eid, 'app124@heroku.com', Time.utc(2000, 2), 2, 'open')
  be(eid, 'app124@heroku.com', Time.utc(2000, 3), 2, 'close')
end

# attrition
SecureRandom.uuid.tap do |eid|
  be(eid, 'app125@heroku.com', Time.utc(2000, 1), 1, 'open')
  be(eid, 'app125@heroku.com', Time.utc(2000, 2), 1, 'close')
end

# decrease
SecureRandom.uuid.tap do |eid|
  be(eid, 'app126@heroku.com', Time.utc(2000, 1), 6, 'open')
  be(eid, 'app126@heroku.com', Time.utc(2000, 2), 6, 'close')
end

SecureRandom.uuid.tap do |eid|
  be(eid, 'app126@heroku.com', Time.utc(2000, 2), 3, 'open')
  be(eid, 'app126@heroku.com', Time.utc(2000, 3), 3, 'close')
end

# increase
SecureRandom.uuid.tap do |eid|
  be(eid, 'app127@heroku.com', Time.utc(2000, 1), 1, 'open')
  be(eid, 'app127@heroku.com', Time.utc(2000, 2), 1, 'close')
end

SecureRandom.uuid.tap do |eid|
  be(eid, 'app127@heroku.com', Time.utc(2000, 2), 2, 'open')
  be(eid, 'app127@heroku.com', Time.utc(2000, 3), 2, 'close')
end
