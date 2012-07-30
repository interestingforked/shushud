require 'bundler/setup'
Bundler.require
require 'config'

module Shushu
  APP_NAME = Config.app_name || "shushud"

  Instruments.defaults = {
    logger: Scrolls,
    method: "log",
    default_data: {app: APP_NAME, level: "info"}
  }

  Scrolls.global_context(app: APP_NAME)

  Sequel.default_timezone = :utc
  DB = Sequel.connect(Config.database_url)
  DB.execute("SET timezone TO 'UTC'")
  FollowerDB = Sequel.connect(Config.follower_database_url)
  FollowerDB.execute("SET timezone TO 'UTC'")
end
