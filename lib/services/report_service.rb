module ReportService
  extend self

  def usage_report(account_id, from, to)
    Log.info("#usage_report_requested account=#{account_id} from=#{from} to=#{to}")
    billable_units = query_usage_report(account_id, from, to)
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

  def query_usage_report(account_id, from, to)
    Log.info("#billable_unit_builder_select account=#{account_id} from=#{from} to=#{to}")
    Shushu::DB.synchronize do |conn|
      conn.exec("SELECT * FROM usage_report($1, $2, $3)", [account_id, from, to]).to_a
    end
  end

  def invoice(payment_method_id, from, to)
    billable_units = Shushu::DB.synchronize do |conn|
      conn.exec("SELECT * FROM invoice($1, $2, $3)", [payment_method_id, from, to]).to_a
    end
    res = {
      :payment_method_id => payment_method_id,
      :from              => from,
      :to                => to,
      :billable_units    => billable_units,
      :total             => Calculator.total(billable_units)
    }
    [200, res]
  end

end
