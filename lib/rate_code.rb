module Shushu
  module RateCode
    extend self
    PERIODS = %w{month hour}

    def handle_in(args)
      if s = args[:slug]
        if r = DB[:rate_codes].filter(slug: s).first
          [200, r]
        else
          [201, create_record(args)]
        end
      else
        args[:slug] = SecureRandom.uuid
        [201, create_record(args)]
      end
    end

    private

    def create_record(args)
      if !PERIODS.include?(args[:period])
        raise(ArgumentError, "period must be one of #{PERIODS.join(',')}")
      end
      DB[:rate_codes].
        returning.
        insert(provider_id: args[:provider_id],
                rate: args[:rate],
                rate_period: args[:rate_period],
                slug: args[:slug],
                product_group: args[:product_group],
                product_name: args[:product_name]).pop
    end

  end
end
