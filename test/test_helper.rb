$:.unshift("lib")
$:.unshift("test")

ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler'
Bundler.require(:default, :test)

require 'minitest/autorun'
require 'shushu'

class Shushu::Test < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def clean_tables
    Shushu::DB.run("DELETE FROM billable_events CASCADE")
    Shushu::DB.run("DELETE FROM providers CASCADE")
  end

  def setup
    clean_tables
  end

  def teardown
    clean_tables
  end

  def app
    Shushu::Web::Api
  end

end
