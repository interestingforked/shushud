require './lib/shushu'
require './lib/provider'

module ShushuHelpers

  def build_provider(opts={})
    params = {
      :name  => "sendgrid",
      :token => "password"
    }.merge(opts)
    Shushu::Provider.
      create(params).tap {|p| p.reset_token!(params[:token])}.reload
  end

  def build_rate_code(opts={})
    Shushu::DB[:rate_codes].returning.insert({
      :slug => SecureRandom.uuid,
      :rate => 5,
      :rate_period => "hour",
      :provider_id => provider.id,
    }.merge(opts)).pop
  end

end
