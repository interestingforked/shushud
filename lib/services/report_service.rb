module ReportService
  extend self

  def usage_report(account_id, from, to)
    Log.info("#usage_report_requested account=#{account_id} from=#{from} to=#{to}")
    billable_units = exec_sql("SELECT * FROM usage_report($1, $2, $3)", account_id, from, to)
    res = {
      :account_id     => account_id,
      :from           => from,
      :to             => to,
      :billable_units => billable_units,
      :total          => Calculator.total(billable_units)
    }
    Log.info("#usage_report_success account=#{account_id} from=#{from} to=#{to}")
    [200, res]
  end

  def invoice(payment_method_id, from, to)
    billable_units = exec_sql("SELECT * FROM invoice($1, $2, $3)", payment_method_id, from, to)
    res = {
      :payment_method_id => payment_method_id,
      :from              => from,
      :to                => to,
      :billable_units    => billable_units,
      :total             => Calculator.total(billable_units)
    }
    [200, res]
  end

  def exec_sql(sql, *args)
    Shushu::DB.synchronize do |conn|
      conn.exec(sql, args).to_a
    end
  end
end
