require 'bundler/setup'
Bundler.require

require './lib/config'

APP_NAME = Shushu::Config.app_name || "shushud"
Instruments.defaults = {
  logger: Scrolls,
  method: "log",
  default_data: {app: APP_NAME, level: "info"}
}

module Kernel
  def log(data)
    data[:level] ||= :info
    block_given? ? Scrolls.log(data) {yield} : Scrolls.log(data)
  end
end

module Shushu
  DB = Sequel.connect(Config.database_url)
  Shushu::DB.execute("SET timezone TO 'UTC'")
  Sequel.default_timezone = :utc
end
