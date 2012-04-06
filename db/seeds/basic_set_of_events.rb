require File.expand_path("../../../lib/shushu", __FILE__)

provider = Provider.create :name => "shushu@heroku.com", :token => "secret"

reid = SecureRandom.uuid
RateCodeService.handle_in(
  :provider_id        => provider.id,
  :slug               => reid,
  :rate               => 5,
  :period             => "hour",
  :product_group      => "dyno",
  :product_name       => "web"
)

SecureRandom.uuid.tap do |eid|
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code      => reid,
    :hid            => "app123@heorku.com",
    :entity_id      => eid,
    :entity_id_uuid => eid,
    :qty            => 1,
    :time           => Time.utc(2000,1),
    :state          => "open"
  )
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code      => reid,
    :hid            => "app123@heorku.com",
    :entity_id      => eid,
    :entity_id_uuid => eid,
    :qty            => 1,
    :time           => Time.utc(2000,3),
    :state          => "close"
  )
end

SecureRandom.uuid.tap do |eid|
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code      => reid,
    :hid            => "app123@heorku.com",
    :entity_id      => eid,
    :entity_id_uuid => eid,
    :qty            => 1,
    :time           => Time.utc(2000,2),
    :state          => "open"
  )
end

SecureRandom.uuid.tap do |eid|
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code      => reid,
    :hid            => "app124@heorku.com",
    :entity_id      => eid,
    :entity_id_uuid => eid,
    :qty            => 2,
    :time           => Time.utc(2000,2),
    :state          => "open"
  )
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code      => reid,
    :hid            => "app124@heorku.com",
    :entity_id      => eid,
    :entity_id_uuid => eid,
    :qty            => 2,
    :time           => Time.utc(2000,3),
    :state          => "close"
  )
end

SecureRandom.uuid.tap do |eid|
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code      => reid,
    :hid            => "app125@heorku.com",
    :entity_id      => eid,
    :entity_id_uuid => eid,
    :qty            => 1,
    :time           => Time.utc(2000,1),
    :state          => "open"
  )
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code      => reid,
    :hid            => "app125@heorku.com",
    :entity_id      => eid,
    :entity_id_uuid => eid,
    :qty            => 1,
    :time           => Time.utc(2000,2),
    :state          => "close"
  )
end

SecureRandom.uuid.tap do |eid|
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code      => reid,
    :hid            => "app126@heorku.com",
    :entity_id      => eid,
    :entity_id_uuid => eid,
    :qty            => 6,
    :time           => Time.utc(2000,1),
    :state          => "open"
  )
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code      => reid,
    :hid            => "app126@heorku.com",
    :entity_id      => eid,
    :entity_id_uuid => eid,
    :qty            => 6,
    :time           => Time.utc(2000,2),
    :state          => "close"
  )
end

SecureRandom.uuid.tap do |eid|
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code      => reid,
    :hid            => "app126@heorku.com",
    :entity_id      => eid,
    :entity_id_uuid => eid,
    :qty            => 3,
    :time           => Time.utc(2000,2),
    :state          => "open"
  )
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code      => reid,
    :hid            => "app126@heorku.com",
    :entity_id      => eid,
    :entity_id_uuid => eid,
    :qty            => 3,
    :time           => Time.utc(2000,3),
    :state          => "close"
  )
end
