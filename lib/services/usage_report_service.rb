module UsageReportService
  extend self

  def build_report(account_id, from, to)
    shulog("#usage_report_requested account=#{account_id} ")
    report = UsageReport.new(account_id, from, to)
    billable_units = report.billable_units
    shulog("#usage_report_build_complete units=#{billable_units.length} ")
    {
      :account_id     => account_id,
      :from           => from,
      :to             => to,
      :billable_units => billable_units.map(&:to_h),
      :total          => Calculator.total(billable_units)
    }.tap do |hash|
      hash = hash.dup
      hash.delete(:billable_units) # Lets not log this. It will be huge.
      shulog("#usage_report_success account=#{account_id} from=#{from} to=#{to} #{hash.map {|k,v| [k,'=',v].join}}")
    end
  end

end
