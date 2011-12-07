$:.unshift("lib")
$:.unshift("test")

ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler'
Bundler.require(:default, :test)

require 'minitest/autorun'
require 'shushu'
require 'shushu_helpers'

class ShushuTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods
  include ShushuHelpers

  def clean_tables
    Shushu::DB.run("DELETE FROM billable_events CASCADE")
    Shushu::DB.run("DELETE FROM rate_codes CASCADE")
    Shushu::DB.run("DELETE FROM providers CASCADE")
    Shushu::DB.run("DELETE FROM resource_ownership_records CASCADE")
    Shushu::DB.run("DELETE FROM accounts CASCADE")
  end

  def setup
    clean_tables
  end

  def teardown
    clean_tables
  end

  def app
    Shushu.web_api
  end

  def jan
    Time.mktime(2011,1)
  end

  def feb
    Time.mktime(2011,2)
  end

end
