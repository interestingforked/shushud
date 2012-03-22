$:.unshift("lib")
$:.unshift("test")

ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "shushu"
require "shushu_helpers"
require "ruby-debug"
require "rack/test"

Log.level = Logger::ERROR

module TableCleaner
  def clean_tables
    Shushu::DB.transaction do
      Shushu::DB.run(<<-EOD)
        DELETE FROM billable_events CASCADE;
        DELETE FROM rate_codes CASCADE;
        DELETE FROM card_tokens CASCADE;
        DELETE FROM resource_ownership_records CASCADE;
        DELETE FROM account_ownership_records CASCADE;
        DELETE FROM accounts CASCADE;
        DELETE FROM payment_attempt_records CASCADE;
        DELETE FROM receivables CASCADE;
        DELETE FROM payment_methods CASCADE;
        DELETE FROM providers CASCADE;
      EOD
    end
  end
end

class ShushuTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods
  include ShushuHelpers
  include TableCleaner

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

  module TestAuthorizer
    GOOD_NUM = "4111111111111111"
    BAD_NUM = "999999999999999"
    TOKEN= "abc123"
    def run(num, year, month)
      Log.debug(:action => "authorize", :num => num)
      if num == GOOD_NUM
        [201, {:card_last4 => "1111", :card_type => "visa", :card_token => TOKEN}]
      else
        [422, {:error => "bad card"}]
      end
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
