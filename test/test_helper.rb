$:.unshift("lib")
$:.unshift("test")

ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler'
Bundler.require(:default, :test)

require 'minitest/autorun'
require 'shushu'

class ShushuTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def clean_tables
    Shushu::DB.run("DELETE FROM billable_events CASCADE")    
    Shushu::DB.run("DELETE FROM rate_codes CASCADE")
    Shushu::DB.run("DELETE FROM providers CASCADE")
    ResourceHistory.delete_all
  end

  def setup
    clean_tables
  end

  def teardown
    clean_tables
  end

  def build_provider(opts={})
    Provider.create({
      :name  => "sendgrid",
      :token => "password"
    }.merge(opts))
  end

  def build_rate_code(opts={})
    RateCode.create({
      :slug => "RT01",
      :rate => 5,
      :description => "dyno hour"
    }.merge(opts))
  end

  def app
    Rack::Builder.new do
      map("/resources")  { run Api }
      map("/rate_codes") { run RateCodeApi }
      map("/providers")  { run ProviderApi }
    end
  end
  
end
