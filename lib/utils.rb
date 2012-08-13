require 'cgi'
require 'config'
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

  def count(name)
    log(measure: true, at: name)
  end

  def count_status(status)
    if prefix = status.to_s.match(/\d\d/)[0]
      log(measure: true, at: "web-#{prefix}")
    end
  end

  def time(name, t)
    if name
      name.
        gsub(/\/:\w+/,'').            #remove param names from path
        gsub("/","-").                #remove slash from path
        gsub(/[^A-Za-z0-9\-\_]/, ''). #only keep subset of chars
        slice(1..-1).
        tap {|res| log(measure: true, fn: res, elapsed: t)}
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
