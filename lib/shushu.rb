require 'rubygems'
require 'logger'
require 'cgi'

Bundler.require

$stdout.sync = true
VERBOSE = ENV["VERBOSE"] == 'true'
module Kernel
  def shulog(msg)
    puts msg if VERBOSE
  end
end

module Shushu
  NotFound            = Class.new(Exception)
  DataConflict        = Class.new(Exception)
  AuthorizationError  = Class.new(Exception)
  ShushuError         = Class.new(RuntimeError)

  DB = (
    case ENV["RACK_ENV"].to_s
    when "production"
      shulog("connecting production database url=#{ENV["DATABASE_URL"]}")
      Sequel.connect(ENV["DATABASE_URL"], :logger => Logger.new(STDOUT))
    when "test"
      Sequel.connect(ENV["TEST_DATABASE_URL"], :logger => Logger.new(File.new("./log/test.log","w")))
    else
      raise ArgumentError, "RACK_ENV must be production or test. RACK_ENV=#{ENV["RACK_ENV"]}"
    end
  )

  DB.execute("SET timezone TO 'UTC'")
  Sequel.default_timezone = :utc

  def self.test?
    ENV["RACK_ENV"] == "test"
  end
end

require './lib/http/authentication'
require './lib/http/api'

require './lib/models/billable_event'
require './lib/models/provider'
require './lib/models/rate_code'
require './lib/models/account'
require './lib/models/resource_ownership_record'
require './lib/models/payment_method'
require './lib/models/account_ownership_record'

require './lib/services/billable_event_service'
require './lib/services/report_service'
require './lib/services/ownership_service'
require './lib/services/rate_code_service'
require './lib/services/calculator'
