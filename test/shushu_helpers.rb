module ShushuHelpers

  def build_provider(opts={})
    Provider.create({
      :name  => "sendgrid",
      :token => "password"
    }.merge(opts))
  end

  def build_rate_code(opts={})
    RateCode.create({
      :slug => "RT01",
      :rate => 5,
      :description => "dyno hour"
    }.merge(opts))
  end

end
