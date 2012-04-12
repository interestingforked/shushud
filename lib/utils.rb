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

  def start_month(time)
    Time.mktime(time.year, time.month)
  end

  def end_month(time)
    y,m = if time.month == 12
      [(time.year + 1), 1]
    else
      [time.year, (time.month + 1)]
    end
    Time.mktime(y, m)
  end

  def txn
    Shushu::DB.transaction {yield}
  end

  def exec(sql, *args)
    conn_exec(Shushu::DB, sql, *args)
  end

  def read_exec(sql, *args)
    conn_exec(Shushu::RSDB, sql, *args)
  end

  def conn_exec(db, sql, *args)
    db.synchronize do |conn|
      conn.exec(sql, args).to_a
    end
  end

end
