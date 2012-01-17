require "rubygems"
require "logger"
require "cgi"
require "securerandom"
require "digest/sha1"

Bundler.require

require "dalli"
require "rack/session/dalli"
require "sinatra/cookies"
require "./lib/gateways/braintree"

$stderr.sync = $stdout.sync = true
$logger = Logger.new($stdout)
$logger.level = Logger::INFO

#TODO replace shulog with $logger
module Kernel
  def shulog(msg)
    $logger.info(msg)
  end
end

module Shushu
  ShushuError         = Class.new(Exception)
  NotFound            = Class.new(ShushuError)
  DataConflict        = Class.new(ShushuError)
  AuthorizationError  = Class.new(ShushuError)

  Conf = {
    :gateway => BraintreeGateway
  }

  DB = (
    case ENV["RACK_ENV"].to_s
    when "production"
      shulog("connecting production database url=#{ENV["DATABASE_URL"]}")
      Sequel.connect(ENV["DATABASE_URL"])
    when "test"
      Sequel.connect(ENV["TEST_DATABASE_URL"], :logger => Logger.new(File.new("./log/test.log","w")))
    else
      raise(ArgumentError, "RACK_ENV must be production or test. RACK_ENV=#{ENV["RACK_ENV"]}")
    end
  )

  DB.sql_log_level = :debug
  DB.logger = $logger
  DB.execute("SET timezone TO 'UTC'")
  Sequel.default_timezone = :utc

  def self.test?
    ENV["RACK_ENV"] == "test"
  end

end

require "./lib/api/helpers"
require "./lib/api/authentication"
require "./lib/api/http"

require "./lib/models/billable_event"
require "./lib/models/provider"
require "./lib/models/rate_code"
require "./lib/models/account"
require "./lib/models/resource_ownership_record"
require "./lib/models/payment_method"
require "./lib/models/account_ownership_record"
require "./lib/models/receivable"
require "./lib/models/payment_attempt_record"
require "./lib/models/card_token"

require "./lib/services/billable_event_service"
require "./lib/services/report_service"
require "./lib/services/ownership_service"
require "./lib/services/rate_code_service"
require "./lib/services/calculator"
require "./lib/services/receivables_service"
require "./lib/services/payment_service"

require "./etc/payment_state_transitions"
