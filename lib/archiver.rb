require 'shushu'
require 'utils'
require 'scrolls'
require 'time'

module Shushu
  module Archiver
    extend self

    def archive_events!(time)
      log(fn: __method__, time: time.iso8601) do
        Utils.txn do
          sname = ["closed_events", time.year, time.month].join("_")
          create_schema(sname) unless schema_exists?(sname)
          cp_events(time.iso8601, sname)
          rm_events!(time.iso8601)
        end
      end
    end

    def cp_events(time, schema)
      log(fn: __method__, schema: schema) do
        sql = "select * into #{schema}.closed_events from closed_events "
        sql << "where \"to\" < '#{time}'::timestamptz"
        Utils.exec(sql)
      end
    end

    def rm_events!(time)
      log(fn: __method__) do
        sql = "delete from public.closed_events "
        sql << "where \"to\" < '#{time}'::timestamptz"
        Utils.exec(sql)
      end
    end

    def schema_exists?(name)
      s ="SELECT nspname from pg_catalog.pg_namespace"
      Utils.exec(s).map {|r| r["nspname"]}.include?(name)
    end

    def create_schema(name)
      log(fn: __method__, schema: name) do
        Utils.exec("CREATE SCHEMA #{name}")
      end
    end

    def log(data, &blk)
      Scrolls.log({ns: "archiver"}.merge(data), &blk)
    end
  end
end
