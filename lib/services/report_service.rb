module ReportService
  extend self

  def rate_code_report(rate_code_id, from, to)
    Log.info_t(
      :action    => "rate_code_report",
      :rate_code => rate_code_id,
      :from      => from,
      :to        => to
    ) do
      s = "SELECT * FROM rate_code_report($1, $2, $3)"
      billable_units = exec_sql(s, rate_code_id, from, to)
      [200, {
        :rate_code      => rate_code_id,
        :from           => from,
        :to             => to,
        :billable_units => billable_units,
        :total          => Calculator.total(billable_units)
      }]
    end
  end

  def usage_report(account_id, from, to)
    Log.info_t(
      :action     => "usage_report",
      :account_id => account_id,
      :from       => from,
      :to         => to
    ) do
      s = "SELECT * FROM usage_report($1, $2, $3)"
      billable_units = exec_sql(s, account_id, from, to)
      [200, {
        :account_id     => account_id,
        :from           => from,
        :to             => to,
        :billable_units => billable_units,
        :total          => Calculator.total(billable_units)
      }]
    end
  end

  def invoice(payment_method_id, from, to)
    Log.info_t(
        :action         => "usage_report",
        :payment_method => payment_method_id,
        :from           => from,
        :to             => to
      ) do
      s = "SELECT * FROM invoice($1, $2, $3)"
      billable_units = exec_sql(s, payment_method_id, from, to)
      [200, {
        :payment_method_id => payment_method_id,
        :from              => from,
        :to                => to,
        :billable_units    => billable_units,
        :total             => Calculator.total(billable_units)
      }]
    end
  end

  def rev_report(from, to)
    Log.info_t(:action => "rev_report", :from => from, :to => to) do
      s = "SELECT * from rev_report($1, $2)"
      total = exec_sql(s, from, to).first["rev_report"]
      [200, {:time => Time.now, :total => total}]
    end
  end

  def exec_sql(sql, *args)
    Shushu::DB.synchronize do |conn|
      conn.exec(sql, args).to_a
    end
  end

end
