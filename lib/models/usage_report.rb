class UsageReport

  attr_reader :billable_units

  def initialize(account_id, from, to)
    @account_id, @from, @to = account_id, from, to
    @billable_units = BillableUnitBuilder.build(@account_id, @from, @to)
  end

end
