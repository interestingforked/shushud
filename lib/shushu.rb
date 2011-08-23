require 'rubygems'
require 'bundler'

Bundler.require

module Shushu
  DB = Sequel.connect(ENV["DATABASE_URL"])
  VERSION = 0
end

require './lib/web/api'
require './lib/shushu/event_curator'
require './lib/shushu/billable_event'
