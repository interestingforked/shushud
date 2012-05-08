$stderr.sync = $stdout.sync = true

require 'bundler'
Bundler.require

Scrolls::Log.start
Instruments.defaults = {
  :logger => Scrolls,
  :method => :log,
  :default_data => {:app => "shushu", :level => :info}
}

module Kernel
  def log(data)
    data[:level] ||= :info
    Scrolls.log(data)
  end
end

module Shushu
  Root = File.expand_path("..", File.dirname(__FILE__))
  ShushuError         = Class.new(Exception)
  NotFound            = Class.new(ShushuError)
  DataConflict        = Class.new(ShushuError)
  AuthorizationError  = Class.new(ShushuError)

  Conf = {}
  DB, RSDB = (
    case ENV["RACK_ENV"].to_s
    when "production"
      [
        Sequel.connect(ENV["DATABASE_URL"]),
        Sequel.connect(ENV["READ_SLAVE_DATABASE_URL"])
      ]
    when "test"
      [
        Sequel.connect(ENV["TEST_DATABASE_URL"], :logger => Logger.new(File.new("./log/test.log","w"))),
        Sequel.connect(ENV["TEST_DATABASE_URL"], :logger => Logger.new(File.new("./log/test.log","w")))
      ]
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

require "./lib/api/helpers"
require "./lib/api/authentication"
require "./lib/api/http"

require "./lib/models/event_tracker"
require "./lib/models/billable_event"
require "./lib/models/provider"
require "./lib/models/rate_code"
require "./lib/models/account"
require "./lib/models/resource_ownership_record"
require "./lib/models/payment_method"
require "./lib/models/receivable"
require "./lib/models/payment_attempt_record"
require "./lib/models/card_token"

require "./lib/services/billable_event_service"
require "./lib/services/resource_ownership_service"
require "./lib/services/rate_code_service"
require "./lib/services/receivables_service"
require "./lib/services/payment_service"
require "./lib/services/authorizer"
require "./lib/services/payment_method_service"

require "./etc/payment_state_transitions"

require "./lib/gateways/braintree"

Shushu::Conf[:gateway] = BraintreeGateway
Shushu::DB.execute("SET timezone TO 'UTC'")
Sequel.default_timezone = :utc
