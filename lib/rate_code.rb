require 'securerandom'
require 'shushu'
require 'utils'

module Shushu
  module RateCode
    extend self
    PERIODS = %w{month hour}

    def handle_in(args)
      return [400, Utils.enc_j(error: "invalid args")] unless args_valid?(args)

      if s = args[:slug]
        if r = DB[:rate_codes].filter(slug: s).first
          [200, Utils.enc_j(msg: "OK")]
        else
          if create_record(args)
            [201, Utils.enc_j(msg: "OK")]
          else
            [400, Utils.enc_j(error: "invalid args")]
          end
        end
      else
        args[:slug] = SecureRandom.uuid
        [201, Utils.enc_j(create_record(args))]
      end
    end

    private

    def args_valid?(args)
      PERIODS.include?(args[:period])
    end

    def create_record(args)
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
