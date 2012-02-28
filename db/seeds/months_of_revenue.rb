require File.expand_path('../../../lib/shushu', __FILE__)

jan = Time.utc(2011,1)
feb = Time.utc(2011,2)
mar = Time.utc(2011,3)
dec = Time.utc(2011,12)

provider_token = "secret"
hid = "app123@heroku.com"
provider = Provider.create :name => "shushu@heroku.com", :token => provider_token

RateCodeService.create(
  :provider_id        => provider.id,
  :slug               => "RT01",
  :rate               => 5,
  :product_group      => "dyno",
  :product_name       => "web"
)

SecureRandom.uuid.tap do |eid|
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code_slug => "RT01",
    :hid            => hid,
    :entity_id      => eid,
    :qty            => 1,
    :time           => jan,
    :state          => BillableEvent::Open
  )
  BillableEventService.handle_in(
    :provider_id    => provider.id,
    :rate_code_slug => "RT01",
    :hid            => hid,
    :entity_id      => eid,
    :qty            => 1,
    :time           => dec,
    :state          => BillableEvent::Close
  )
end

puts(<<-EOD)

\t SELECT * from rev_report('2011-01-01', '2011-02-01');

EOD
