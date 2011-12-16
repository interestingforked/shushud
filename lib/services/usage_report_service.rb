module UsageReportService
  extend self

  def build_report(account_id, from, to)
    from = Time.parse(from) if from.class == String
    to   = Time.parse(to)   if to.class   == String

    report = UsageReport.new(account_id, from, to)
    billable_units = report.billable_units.map(&:to_h)
    {
      :account_id => account_id,
      :from => from,
      :to => to,
      :billable_units => billable_units
    }
  end

end
