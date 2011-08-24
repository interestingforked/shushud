require 'rubygems'
require 'bundler'

Bundler.require

require 'logger'

module Kernel
  def log(msg)
    puts msg
  end
end

module Shushu
  VERSION = 0

  DB = (
    case ENV["RACK_ENV"].to_s
    when "production"
      log("connecting production database url=#{ENV["DATABASE_URL"]}")
      Sequel.connect(ENV["DATABASE_URL"])
    when "test"
      Sequel.connect(ENV["TEST_DATABASE_URL"], :logger => Logger.new("./log/test.log"))
    else
      raise ArgumentError, "RACK_ENV must be production or test. RACK_ENV=#{ENV["RACK_ENV"]}"
    end
  )
end

require './lib/web/authentication'
require './lib/web/api'
require './lib/shushu/event_curator'
require './lib/shushu/billable_event'
require './lib/shushu/provider'
