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

  def app
    Shushu::Web::Api
  end

end
