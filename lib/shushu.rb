require "logger"
require "cgi"
require "securerandom"
require "digest/sha1"

require "sinatra"
require "braintree"
require "yajl"
require "sequel"

module Shushu
  Root = File.expand_path("..", File.dirname(__FILE__))
  ShushuError         = Class.new(Exception)
  NotFound            = Class.new(ShushuError)
  DataConflict        = Class.new(ShushuError)
  AuthorizationError  = Class.new(ShushuError)

  Conf = {}
  DB = (
    case ENV["RACK_ENV"].to_s
    when "production"
      Sequel.connect(ENV["DATABASE_URL"])
    when "test"
      Sequel.connect(ENV["TEST_DATABASE_URL"], :logger => Logger.new(File.new("./log/test.log","w")))
    else
      raise(ArgumentError, "RACK_ENV must be production or test. RACK_ENV=#{ENV["RACK_ENV"]}")
    end
  )

  def self.test?
    ENV["RACK_ENV"] == "test"
  end

end

require "./lib/utils"
require "./lib/plugins/created_at_setter"
require "./lib/plugins/model"
require "./lib/plugins/log"

require "./lib/api/helpers"
require "./lib/api/authentication"
require "./lib/api/http"
require "./lib/api/http/reports"
require "./lib/api/http/events"

require "./lib/models/event_tracker"
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
require "./lib/services/authorizer"
require "./lib/services/payment_method_service"

require "./etc/payment_state_transitions"

require "./lib/gateways/braintree"

PG_WARN_THREASHOLD = ENV["PG_WARN_THREASHOLD"].to_i

$stderr.sync = $stdout.sync = true
Log = ShuLog.new($stdout)
Log.level = ENV["LOG_LEVEL"].to_i
Log.formatter = Proc.new do |severity, datetime, progname, msg|
  "#{msg}\n"
end

Shushu::Conf[:gateway] = BraintreeGateway
Shushu::DB.loggers << Log
Shushu::DB.class.send(:include, SequelLogger)
Shushu::DB.execute("SET timezone TO 'UTC'")
Sequel.default_timezone = :utc
