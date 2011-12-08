require 'rubygems'
require 'bundler/setup'
require 'json'
require 'logger'

Bundler.require

VERBOSE = ENV["VERBOSE"] == 'true'
module Kernel
  def shulog(msg)
    puts msg if VERBOSE
  end
end

module Shushu

  VERSION = 0

  class ShushuError < ::RuntimeError; end

  DB = (
    case ENV["RACK_ENV"].to_s
    when "production"
      shulog("connecting production database url=#{ENV["DATABASE_URL"]}")
      Sequel.connect(ENV["DATABASE_URL"])
    when "test"
      Sequel.connect(ENV["TEST_DATABASE_URL"], :logger => Logger.new(File.new("./log/test.log","w")))
    else
      raise ArgumentError, "RACK_ENV must be production or test. RACK_ENV=#{ENV["RACK_ENV"]}"
    end
  )

  def self.http_api
    @@http_api ||= Rack::Builder.new do
      map("/resources")          {run Api}
      map("/rate_codes")         {run RateCodeApi}
      map("/providers")          {run ProviderApi}
      map("/resource_ownership") {run ResourceOwnershipApi}
    end
  end

end

require './lib/http_api/authentication'
require './lib/http_api/api'
require './lib/http_api/rate_code_api'
require './lib/http_api/provider_api'
require './lib/http_api/resource_ownership_api'

require './lib/models/billable_event'
require './lib/models/provider'
require './lib/models/rate_code'
require './lib/models/account'
require './lib/models/resource_ownership_record'

require './lib/services/event_builder'
require './lib/services/event_handler'
require './lib/services/event_validator'
require './lib/services/resource_ownership_service'
