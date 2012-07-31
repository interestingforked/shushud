require 'cgi'
require 'shushu'

module Utils
  extend self

  UUID4_REGEX = /^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$/

  def validate_uuid(str)
    str =~ UUID4_REGEX ? str : nil
  end

  def validate_uuid!(str)
    if str =~ UUID4_REGEX
      str
    else
      raise(ArgumentError, "expected #{str} to be UUIDv4")
    end
  end

  def heartbeat
    if @heartbeat
      @heartbeat.update {|n| n + 1}
    else
      @heartbeat = Atomic.new(0)
      Thread.new do
        loop do
          n = @heartbeat.swap(0)
          log(fn: "heartbeat", at: "emit", received: n)
          sleep(1)
        end
      end
      @heartbeat.update {|n| n + 1}
    end
  end

  def txn
    Shushu::DB.transaction {yield}
  end

  def exec(sql, *args)
    conn_exec(Shushu::DB, sql, *args)
  end

  def read_exec(sql, *args)
    conn_exec(Shushu::FollowerDB, sql, *args)
  end

  def conn_exec(db, sql, *args)
    db.synchronize do |conn|
      conn.exec(sql, args).to_a
    end
  end

  def dec_time(t)
    Time.parse(CGI.unescape(t.to_s))
  end

  def enc_j(data)
    Yajl::Encoder.encode(data)
  end
  def self.log(data, &blk)
    Scrolls.log({ns: "utils"}.merge(data), &blk)
  end

end

module Scrolls
  module Log
    def unparse(data)
      data.map do |(k, v)|
        if (v == true)
          k.to_s
        elsif v.is_a?(Float)
          "#{k}=#{format("%.3f", v)}"
        elsif v.nil?
          nil
        else
          v_str = v.to_s
          if (v_str =~ /^[a-zA-z0-9\-\_\.]+$/)
            "#{k}=#{v_str}"
          else
            "#{k}=\"#{v_str}\""
          end
        end
      end.compact.join(" ")
    end
  end
end
