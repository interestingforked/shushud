require 'rubygems'
require 'bundler'

Bundler.require

require 'json'
require 'logger'

VERBOSE = ENV["VERBOSE"] == 'true'
module Kernel
  def log(msg)
    puts msg if VERBOSE
  end
end

module Shushu
  
  VERSION = 0

  class ShushuError < ::RuntimeError; end

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
  
  NotifyChangeQueue = QC::Queue.new("notify_change_jobs")
  
  if CORE_DB_URL = ENV["HEROKU_POSTGRESQL_CORE_URL"]
    db_uri = URI.parse(ENV["HEROKU_POSTGRESQL_CORE_URL"])
    ActiveRecord::Base.establish_connection({
      :adapter  => 'postgresql',
      :host     => db_uri.host,
      :database => db_uri.path.gsub('/',''),
      :username => db_uri.user,
      :password => db_uri.password
    })    
  else
    raise "HEROKU_POSTGRESQL_CORE_URL is not set."
  end

end

require './lib/web/authentication'
require './lib/web/api'
require './lib/web/rate_code_api'
require './lib/web/provider_api'

require './lib/shushu/billable_event'
require './lib/shushu/resource_history'
require './lib/shushu/event_builder'
require './lib/shushu/event_validator'
require './lib/shushu/provider'
require './lib/shushu/rate_code'

require './lib/shushu/storage_drivers/core_rh'
require './lib/shushu/storage_drivers/shushu_be'
