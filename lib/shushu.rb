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
end

Shushu::DB.execute("SET timezone TO 'UTC'")
Sequel.default_timezone = :utc

require "./lib/utils"

require "./lib/api/helpers"
require "./lib/api/authentication"
require "./lib/api/http"
