require 'rubygems'
require 'bundler'

Bundler.require

require 'logger'

module Shushu
  VERSION = 0

  DB = (
    case ENV["RACK_ENV"].to_s
    when "production"
      Sequel.connect(ENV["DATABASE_URL"], :logger => Logger.new("./log/production.log"))
    when "test"
      Sequel.connect(ENV["TEST_DATABASE_URL"], :logger => Logger.new("./log/test.log"))
    end
  )
end

require './lib/web/authentication'
require './lib/web/api'
require './lib/shushu/event_curator'
require './lib/shushu/billable_event'
require './lib/shushu/provider'
