require File.expand_path('../../test_helper', __FILE__)

class UsageReportServiceTest < ShushuTest

  def test_report_returns_hash
    account = build_account
    rate_code = build_rate_code
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :event_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    BillableEvent.create(
      :hid          => "app123",
      :rate_code_id => rate_code.id,
      :event_id     => 1,
      :state        => BillableEvent::Open,
      :time         => jan
    )
    report = UsageReportService.build_report(account.id, jan, feb)
    assert_equal(Hash, report.class)
  end

  def test_report_returns_billable_units
    account = build_account
    rate_code = build_rate_code
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :event_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan - 100
    )
    BillableEvent.create(
      :hid          => "app123",
      :rate_code_id => rate_code.id,
      :event_id     => 1,
      :state        => BillableEvent::Open,
      :time         => jan
    )
    report = UsageReportService.build_report(account.id, jan, feb)
    billable_unit = report[:billable_units].first
    assert_equal("app123", billable_unit[:hid])
    assert_equal(jan, billable_unit[:from])
    assert_in_delta(feb, billable_unit[:to], 2)
  end

end
