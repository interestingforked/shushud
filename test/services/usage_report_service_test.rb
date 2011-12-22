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

  def test_one_owner_one_event
    account = build_account
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :event_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    BillableEvent.create(
      :hid      => "app123",
      :event_id => 1,
      :state    => BillableEvent::Open,
      :time     => jan
    )

    billable_units = UsageReportService.query_usage_report(account.id, jan, feb)
    assert_equal(1, billable_units.length)

    billable_unit = billable_units.first
    assert_equal(jan, Time.parse(billable_unit["from"]))
  end

  def test_two_owners_one_event
    account = build_account
    another_account = build_account
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :event_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :event_id   => 1,
      :state      => ResourceOwnershipRecord::Inactive,
      :time       => jan + 100
    )
    ResourceOwnershipRecord.create(
      :account_id => another_account.id,
      :hid        => "app123",
      :event_id   => 2,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan + 100
    )
    BillableEvent.create(
      :hid      => "app123",
      :event_id => 1,
      :state    => BillableEvent::Open,
      :time     => jan
    )

    billable_units = UsageReportService.query_usage_report(account.id, jan, feb)
    assert_equal(1, billable_units.length)
    billable_unit = billable_units.first
    assert_equal(jan, Time.parse(billable_unit["from"]))
    assert_equal((jan + 100), Time.parse(billable_unit["to"]))

    billable_units = UsageReportService.query_usage_report(another_account.id, jan, feb)
    assert_equal(1, billable_units.length)
    billable_unit = billable_units.last
    assert_equal((jan + 100), Time.parse(billable_unit["from"]))
    assert_in_delta(feb, Time.parse(billable_unit["to"]), 2)
  end

  def test_billable_units_include_rate_code_information
    rate_code = build_rate_code(:product_name => "a test product", :product_group => "super dyno", :rate => 1000, :rate_period => "hour")
    account = build_account
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :event_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    BillableEvent.create(
      :hid          => "app123",
      :event_id     => 1,
      :state        => BillableEvent::Open,
      :time         => jan,
      :rate_code_id => rate_code.id
    )
    billable_unit = UsageReportService.query_usage_report(account.id, jan, feb).pop
    assert_equal("a test product", billable_unit["product_name"])
    assert_equal("super dyno", billable_unit["product_group"])
    assert_equal("hour", billable_unit["rate_period"])
    assert_equal(1000, billable_unit["rate"].to_i)
  end

  def test_billable_units_qty_computation_on_closed_event
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
      :event_id     => 1,
      :state        => BillableEvent::Open,
      :time         => jan,
      :rate_code_id => rate_code.id
    )
    BillableEvent.create(
      :hid          => "app123",
      :event_id     => 1,
      :state        => BillableEvent::Close,
      :time         => jan + (60 * 60 * 24 * 5), #5days
      :rate_code_id => rate_code.id
    )
    billable_unit = UsageReportService.query_usage_report(account.id, jan, feb).pop
    assert_equal(120.0, billable_unit["qty"].to_i)
  end

  def test_billable_units_qty_computation_on_open_event
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
      :event_id     => 1,
      :state        => BillableEvent::Open,
      :time         => Time.now - 3600,
      :rate_code_id => rate_code.id
    )
    billable_unit = UsageReportService.query_usage_report(account.id, jan, Time.now).pop
    assert_in_delta(1.0, billable_unit["qty"].to_f, 0.001)
  end

end
