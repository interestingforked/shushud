module UsageReportService
  extend self

  def build_report(account_id, from, to)
    shulog("#usage_report_requested account=#{account_id} from=#{from} to=#{to}")
    billable_units = query_usage_report(account_id, from, to)
    {
      :account_id     => account_id,
      :from           => from,
      :to             => to,
      :billable_units => billable_units,
      :total          => Calculator.total(billable_units)
    }.tap do |hash|
      shulog("#usage_report_success account=#{account_id} from=#{from} to=#{to}")
    end
  end

  def query_usage_report(account_id, from, to)
    shulog("#billable_unit_builder_select account=#{account_id} from=#{from} to=#{to}")
    Shushu::DB.synchronize do |conn|
      conn.exec("SELECT * FROM usage_report($1, $2, $3)", [account_id, from, to]).to_a
    end
  end

end
