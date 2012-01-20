require File.expand_path('../../test_helper', __FILE__)

class ReportServiceTest < ShushuTest

  def test_report_returns_hash
    account = build_account
    rate_code = build_rate_code
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :entity_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    BillableEvent.create(
      :hid          => "app123",
      :rate_code_id => rate_code.id,
      :entity_id     => 1,
      :state        => BillableEvent::Open,
      :time         => jan
    )
    _, report = ReportService.usage_report(account.id, jan, feb)
    assert_equal(Hash, report.class)
  end

  def test_one_owner_one_event
    account = build_account
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :entity_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    BillableEvent.create(
      :hid      => "app123",
      :entity_id => 1,
      :state    => BillableEvent::Open,
      :time     => jan
    )

    _, usage_report = ReportService.usage_report(account.id, jan, feb)
    billable_units = usage_report[:billable_units]
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
      :entity_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :entity_id   => 1,
      :state      => ResourceOwnershipRecord::Inactive,
      :time       => jan + 100
    )
    ResourceOwnershipRecord.create(
      :account_id => another_account.id,
      :hid        => "app123",
      :entity_id   => 2,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan + 100
    )
    BillableEvent.create(
      :hid      => "app123",
      :entity_id => 1,
      :state    => BillableEvent::Open,
      :time     => jan
    )

    _, usage_report = ReportService.usage_report(account.id, jan, feb)
    billable_units = usage_report[:billable_units]
    assert_equal(1, billable_units.length)
    billable_unit = billable_units.first
    assert_equal(jan, Time.parse(billable_unit["from"]))
    assert_equal((jan + 100), Time.parse(billable_unit["to"]))

    _, usage_report = ReportService.usage_report(another_account.id, jan, feb)
    billable_units = usage_report[:billable_units]
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
      :entity_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    BillableEvent.create(
      :hid          => "app123",
      :entity_id     => 1,
      :state        => BillableEvent::Open,
      :time         => jan,
      :rate_code_id => rate_code.id
    )
    _, usage_report = ReportService.usage_report(account.id, jan, feb)
    billable_units = usage_report[:billable_units]
    billable_unit = billable_units.pop
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
      :entity_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    BillableEvent.create(
      :hid          => "app123",
      :entity_id     => 1,
      :state        => BillableEvent::Open,
      :time         => jan,
      :rate_code_id => rate_code.id
    )
    BillableEvent.create(
      :hid          => "app123",
      :entity_id     => 1,
      :state        => BillableEvent::Close,
      :time         => jan + (60 * 60 * 24 * 5), #5days
      :rate_code_id => rate_code.id
    )
    _, usage_report = ReportService.usage_report(account.id, jan, feb)
    billable_unit = usage_report[:billable_units].pop
    assert_equal(120.0, billable_unit["qty"].to_i)
  end

  def test_billable_units_qty_computation_on_open_event
    account = build_account
    rate_code = build_rate_code
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :entity_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    BillableEvent.create(
      :hid          => "app123",
      :entity_id     => 1,
      :state        => BillableEvent::Open,
      :time         => Time.now - 3600,
      :rate_code_id => rate_code.id
    )
    _, usage_report = ReportService.usage_report(account.id, jan, Time.now)
    billable_unit = usage_report[:billable_units].pop
    assert_in_delta(1.0, billable_unit["qty"].to_f, 0.001)
  end

  def test_invoice_two_accounts_one_event
    payment_method = build_payment_method
    account = build_account(:payment_method_id => payment_method.id)
    another_account = build_account(:payment_method_id => payment_method.id)

    build_act_own(account.id, payment_method.id, 1, AccountOwnershipRecord::Active, jan)
    build_act_own(another_account.id, payment_method.id, 2, AccountOwnershipRecord::Active, jan)

    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Active, jan)
    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Inactive, (jan + 100))
    build_res_own(another_account.id, "app123", 2, ResourceOwnershipRecord::Active, (jan + 100))

    build_billable_event("app123", 1, BillableEvent::Open, jan)

    _, invoice = ReportService.invoice(payment_method.id, jan, feb)
    billable_units = invoice[:billable_units]
    assert_equal(1, billable_units.length)
    billable_unit = billable_units.first
    assert_equal(jan, Time.parse(billable_unit["from"]))
    assert_equal(feb, Time.parse(billable_unit["to"]))
  end

  def test_invoice_two_accounts_many_events
    payment_method = build_payment_method
    another_payment_method = build_payment_method

    account = build_account(:payment_method_id => payment_method.id)
    another_account = build_account(:payment_method_id => another_payment_method.id)

    build_act_own(account.id, payment_method.id, 1, AccountOwnershipRecord::Active, jan)
    build_act_own(another_account.id, another_payment_method.id, 2, AccountOwnershipRecord::Active, jan)

    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Active, jan)
    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Inactive, jan + 100)
    build_res_own(another_account.id, "app123", 2, ResourceOwnershipRecord::Active, jan + 101)

    build_billable_event("app123", 1, BillableEvent::Open, jan)
    build_billable_event("app124", 2, BillableEvent::Open, jan)

    _, invoice = ReportService.invoice(payment_method.id, jan, feb)
    billable_units = invoice[:billable_units]
    assert_equal(1, billable_units.length)
    billable_unit = billable_units.first
    assert_equal(jan, Time.parse(billable_unit["from"]))
    assert_equal((jan + 100), Time.parse(billable_unit["to"]))

    _, invoice = ReportService.invoice(another_payment_method.id, jan, feb)
    billable_units = invoice[:billable_units]
    assert_equal(1, billable_units.length)
    billable_unit = billable_units.first
    assert_equal((jan + 101), Time.parse(billable_unit["from"]))
    assert_equal(feb, Time.parse(billable_unit["to"]))
  end

  def test_inv_uses_prod_name_on_events_when_not_present_on_rate_code
    account = build_account
    rate_code = build_rate_code(:product_name => nil)
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :entity_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    BillableEvent.create(
      :hid          => "app123",
      :product_name => "web",
      :entity_id    => 1,
      :state        => BillableEvent::Open,
      :time         => Time.now - 3600,
      :rate_code_id => rate_code.id
    )
    _, usage_report = ReportService.usage_report(account.id, jan, Time.now)
    billable_unit = usage_report[:billable_units].pop
    assert_equal("web", billable_unit["product_name"])
  end

  def test_invoice_uses_product_name_on_rate_codes_when_present
    account = build_account
    rate_code = build_rate_code(:product_name => "specialweb")
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :entity_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    BillableEvent.create(
      :hid          => "app123",
      :product_name => "web",
      :entity_id    => 1,
      :state        => BillableEvent::Open,
      :time         => Time.now - 3600,
      :rate_code_id => rate_code.id
    )
    _, usage_report = ReportService.usage_report(account.id, jan, Time.now)
    billable_unit = usage_report[:billable_units].pop
    assert_equal("specialweb", billable_unit["product_name"])
  end

  def test_inv_doesnt_care_about_res_own
    payment_method = build_payment_method

    account = build_account(:payment_method_id => payment_method.id)
    another_account = build_account(:payment_method_id => payment_method.id)

    build_act_own(account.id, payment_method.id, 1, AccountOwnershipRecord::Active, jan)
    build_act_own(another_account.id, payment_method.id, 2, AccountOwnershipRecord::Active, jan)

    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Active, jan)
    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Inactive, jan + 100)
    build_res_own(another_account.id, "app123", 2, ResourceOwnershipRecord::Active, jan + 101)

    build_billable_event("app123", 1, BillableEvent::Open, jan)
    build_billable_event("app124", 2, BillableEvent::Open, jan)

    _, invoice = ReportService.invoice(payment_method.id, jan, feb)
    billable_units = invoice[:billable_units]
    assert_equal(1, billable_units.length)
    billable_unit = billable_units.first
    assert_equal(jan, Time.parse(billable_unit["from"]))
    assert_equal(feb, Time.parse(billable_unit["to"]))
  end

  def test_rev_report
    rate = 100
    rate_code = build_rate_code :rate => rate
    eid1 = SecureRandom.uuid
    eid2 = SecureRandom.uuid
    build_billable_event("app123", eid1, BillableEvent::Open, jan, rate_code.id)
    build_billable_event("app124", eid2, BillableEvent::Open, jan, rate_code.id)
    _, report = ReportService.rev_report(jan, feb)
    expected_total = (((feb - jan) / 60.0 / 60.0) * rate) * 2
    assert_equal expected_total, report[:total].to_f
  end

end
