$stderr.sync = $stdout.sync = true

require 'bundler'
Bundler.require

APP_NAME = ENV["APP_NAME"] || "shushu"
Scrolls::Log.start
Instruments.defaults = {
  :logger => Scrolls,
  :method => :log,
  :default_data => {app: APP_NAME, level: "info"}
}

module Kernel
  def log(data)
    data[:level] ||= :info
    if block_given?
      Scrolls.log({app: APP_NAME}.merge(data))  {yield}
    else
      Scrolls.log({app: APP_NAME}.merge(data))
    end
  end
end

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
      Sequel.connect(ENV["TEST_DATABASE_URL"])
    else
      raise(ArgumentError, "RACK_ENV must be production or test.")
    end
  )

  def self.test?
    ENV["RACK_ENV"] == "test"
  end

end

Shushu::DB.execute("SET timezone TO 'UTC'")
Sequel.default_timezone = :utc

require "./lib/utils"
require "./lib/plugins/created_at_setter"
require "./lib/plugins/model"

require "./lib/api/helpers"
require "./lib/api/authentication"
require "./lib/api/http"
require "./lib/api/health/http"

require "./lib/models/billable_event"
require "./lib/models/provider"
require "./lib/models/rate_code"
require "./lib/models/resource_ownership_record"

require "./lib/services/billable_event_service"
require "./lib/services/resource_ownership_service"
require "./lib/services/rate_code_service"
