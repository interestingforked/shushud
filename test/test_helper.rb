$:.unshift("lib")
$:.unshift("test")

ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler'
Bundler.require(:default, :test)

require 'minitest/autorun'
require 'shushu'
require 'shushu_helpers'

Log.level = Logger::WARN

class ShushuTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods
  include ShushuHelpers

  def clean_tables
    Shushu::DB.run("DELETE FROM billable_events CASCADE")
    Shushu::DB.run("DELETE FROM rate_codes CASCADE")
    Shushu::DB.run("DELETE FROM providers CASCADE")
    Shushu::DB.run("DELETE FROM resource_ownership_records CASCADE")
    Shushu::DB.run("DELETE FROM account_ownership_records CASCADE")
    Shushu::DB.run("DELETE FROM accounts CASCADE")
    Shushu::DB.run("DELETE FROM card_tokens CASCADE")
    Shushu::DB.run("DELETE FROM payment_attempt_records CASCADE")
    Shushu::DB.run("DELETE FROM receivables CASCADE")
  end

  def setup
    clean_tables
  end

  def teardown
    clean_tables
  end

  def app
    Api::Http
  end

  def jan
    Time.mktime(2011,1)
  end

  def feb
    Time.mktime(2011,2)
  end

  module JSON
    def self.parse(json)
      Yajl::Parser.parse(json)
    end
  end

  module TestGateway
    extend self
    attr_accessor :force_success

    def success
      @force_success
    end

    def charge(token, amount, recid)
      if success
        [PaymentService::SUCCESS, "OK"]
      else
        [PaymentService::FAILED_NOACT, "OH SNAP!"]
      end
    end
  end

end
