module UsageReportService
  extend self

  def build_report(account_id, from, to)
    report = UsageReport.new(account_id, from, to)
    billable_units = report.billable_units.map(&:to_h)
    {
      :account_id     => account_id,
      :from           => from,
      :to             => to,
      :billable_units => billable_units
    }
  end

end
