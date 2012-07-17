$:.unshift("lib")
$:.unshift("test")

ENV["RACK_ENV"] = "test"

require 'bundler'
Bundler.require :test

require "shushu"
require "shushu_helpers"

module TableCleaner
  def clean_tables
    Shushu::DB.transaction do
      Shushu::DB.run(<<-EOD)
        DELETE FROM billable_events CASCADE;
        DELETE FROM closed_events CASCADE;
        DELETE FROM rate_codes CASCADE;
        DELETE FROM resource_ownership_records CASCADE;
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

  def provider
    @provider ||= build_provider
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
end
