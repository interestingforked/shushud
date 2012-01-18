$:.unshift("lib")
$:.unshift("test")

ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "shushu"
require "shushu_helpers"
require "ruby-debug"
require "rack/test"

Log.level = Logger::WARN

class ShushuTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods
  include ShushuHelpers

  def clean_tables
    Shushu::DB.transaction do
      Shushu::DB.run(<<-EOD)
        DELETE FROM billable_events CASCADE;
        DELETE FROM rate_codes CASCADE;
        DELETE FROM providers CASCADE;
        DELETE FROM resource_ownership_records CASCADE;
        DELETE FROM account_ownership_records CASCADE;
        DELETE FROM accounts CASCADE;
        DELETE FROM card_tokens CASCADE;
        DELETE FROM payment_attempt_records CASCADE;
        DELETE FROM receivables CASCADE;
      EOD
    end
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
