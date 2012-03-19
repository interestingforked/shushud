require File.expand_path('../../../lib/shushu', __FILE__)

#TableCleaner.clean_tables

provider = Provider.create :name => "shushu@heroku.com", :token => "secret"

RateCodeService.handle_in(
  :provider_id        => provider.id,
  :slug               => "RT01",
  :rate               => 5,
  :product_group      => "dyno",
  :product_name       => "web"
)

SecureRandom.uuid.tap do |eid|
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code_id   => "RT01",
    :hid            => "app123@heorku.com",
    :entity_id      => eid,
    :qty            => 1,
    :time           => Time.utc(2012,1),
    :state          => BillableEvent::Open
  )
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code_id   => "RT01",
    :hid            => "app123@heorku.com",
    :entity_id      => eid,
    :qty            => 1,
    :time           => Time.utc(2012,1,15),
    :state          => BillableEvent::Close
  )
end
