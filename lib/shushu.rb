require 'rubygems'
require 'bundler/setup'
require 'json'
require 'logger'

Bundler.require

$stdout.sync = true
VERBOSE = ENV["VERBOSE"] == 'true'
module Kernel
  def shulog(msg)
    puts msg if VERBOSE
  end
end

module Shushu

  VERSION = 0

  NotFound            = Class.new(Exception)
  DataConflict        = Class.new(Exception)
  AuthorizationError  = Class.new(Exception)
  ShushuError         = Class.new(RuntimeError)

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

require './lib/services/billable_event_service'
require './lib/services/resource_ownership_service'
require './lib/services/rate_code_service'
