$:.unshift("lib")
$:.unshift("test")

require 'bundler'
Bundler.require :test

ENV["DATABASE_URL"] = ENV["TEST_DATABASE_URL"]

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

require "./lib/provider"
require "./lib/web"

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
    Shushu::Web
  end

end
