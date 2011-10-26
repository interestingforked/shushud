require 'rubygems'
require 'bundler/setup'
require 'json'
require 'logger'

VERBOSE = ENV["VERBOSE"] == 'true'
module Kernel
  def log(msg)
    puts msg if VERBOSE
  end
end

module Shushu

  VERSION = 0

  class ShushuError < ::RuntimeError; end

  DB = (
    case ENV["RACK_ENV"].to_s
    when "production"
      log("connecting production database url=#{ENV["DATABASE_URL"]}")
      Sequel.connect(ENV["DATABASE_URL"])
    when "test"
      Sequel.connect(ENV["TEST_DATABASE_URL"], :logger => Logger.new("./log/test.log"))
    else
      raise ArgumentError, "RACK_ENV must be production or test. RACK_ENV=#{ENV["RACK_ENV"]}"
    end
  )

end

require './lib/web/authentication'
require './lib/web/api'
require './lib/web/rate_code_api'
require './lib/web/provider_api'

require './lib/models/billable_event'
require './lib/models/provider'
require './lib/models/rate_code'

require './lib/services/event_builder'
require './lib/services/event_handler'
require './lib/services/event_validator'

