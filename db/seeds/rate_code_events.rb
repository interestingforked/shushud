require File.expand_path('../../../lib/shushu', __FILE__)

provider = Provider.create :name => "rate-code@heroku.com", :token => "secret"

_, rate_code = RateCodeService.handle_in(
  :provider_id   => provider.id,
  :rate          => 20,
  :period        => 'month',
  :product_group => 'web',
  :product_name  => 'add-on'
)
uuid_slug = rate_code[:slug]
puts uuid_slug

RateCodeService.handle_in(
  :provider_id   => provider.id,
  :slug          => 'memcache:5mb',
  :rate          => 10,
  :period        => 'month',
  :product_group => 'web',
  :product_name  => 'add-on'
)

RateCodeService.handle_in(
  :provider_id   => provider.id,
  :slug          => 'hourly-dyno',
  :rate          => 5,
  :period        => 'hour',
  :product_group => 'web',
  :product_name  => 'dyno'
)

[uuid_slug, 'hourly-dyno', 'memcache:5mb'].each do |rate_code|
  SecureRandom.uuid.tap do |eid|
    BillableEventService.handle_in(
      :provider_id    => provider.id,
      :rate_code_id   => rate_code,
      :hid            => "app123@heorku.com",
      :entity_id      => eid,
      :qty            => 1,
      :time           => Time.utc(2012,1),
      :state          => BillableEvent::Open
    )
    BillableEventService.handle_in(
      :provider_id    => provider.id,
      :rate_code_id   => rate_code,
      :hid            => "app123@heorku.com",
      :entity_id      => eid,
      :qty            => 1,
      :time           => Time.utc(2012,1,15),
      :state          => BillableEvent::Close
    )
  end
end
