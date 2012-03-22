require File.expand_path('../../test_helper', __FILE__)

class ReportServiceTest < ShushuTest

  def test_report_returns_hash
    account = build_account(:provider_id => provider.id)
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
      :entity_id    => 1,
      :state        => 1,
      :time         => jan
    )
    _, report = ReportService.usage_report(account.id, jan, feb)
    assert_equal(Hash, report.class)
  end

  def test_one_owner_one_event
    account = build_account(:provider_id => provider.id)
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :entity_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    BillableEvent.create(
      :hid          => "app123",
      :rate_code_id => build_rate_code.id,
      :entity_id    => 1,
      :state        => 1,
      :time         => jan
    )

    _, usage_report = ReportService.usage_report(account.id, jan, feb)
    billable_units = usage_report[:billable_units]
    assert_equal(1, billable_units.length)

    billable_unit = billable_units.first
    assert_equal(jan, Time.parse(billable_unit["from"]))
  end

  def test_two_owners_one_event
    account = build_account(:provider_id => provider.id)
    another_account = build_account(:provider_id => provider.id)

    eid1 = SecureRandom.uuid
    build_resource_ownership_record(account.id, "app123", eid1, "active", jan)
    build_resource_ownership_record(account.id, "app123", eid1, "inactive", jan + 100)
    build_resource_ownership_record(another_account.id, "app123", nil, "active", jan + 100)

    build_billable_event("app123", nil, 1, jan)

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
    account = build_account(:provider_id => provider.id)
    ResourceOwnershipRecord.create(
      :account_id => account.id,
      :hid        => "app123",
      :entity_id   => 1,
      :state      => ResourceOwnershipRecord::Active,
      :time       => jan
    )
    BillableEvent.create(
      :hid          => "app123",
      :rate_code_id => build_rate_code.id,
      :entity_id    => 1,
      :state        => 1,
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
    account = build_account(:provider_id => provider.id)
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
      :state        => 1,
      :time         => jan,
      :rate_code_id => rate_code.id
    )
    BillableEvent.create(
      :hid          => "app123",
      :entity_id    => 1,
      :state        => 0,
      :time         => jan + (60 * 60 * 24 * 5), #5days
      :rate_code_id => rate_code.id
    )
    _, usage_report = ReportService.usage_report(account.id, jan, feb)
    billable_unit = usage_report[:billable_units].pop
    assert_equal(120.0, billable_unit["qty"].to_i)
  end

  def test_billable_units_qty_computation_on_open_event
    account = build_account(:provider_id => provider.id)
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
      :state        => 1,
      :time         => Time.now - 3600,
      :rate_code_id => rate_code.id
    )
    _, usage_report = ReportService.usage_report(account.id, jan, Time.now)
    billable_unit = usage_report[:billable_units].pop
    assert_in_delta(1.0, billable_unit["qty"].to_f, 0.001)
  end

  def test_invoice_rate_period_month_and_hour
    monthly_rc = build_rate_code(:rate_period => "month", :rate => 1000)
    hourly_rc = build_rate_code(:rate_period => "hour", :rate => 5)

    payment_method = build_payment_method
    account = build_account(:provider_id => provider.id)
    build_act_own(account.id, payment_method.id, 1, AccountOwnershipRecord::Active, jan)
    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Active, jan)
    build_billable_event("app123", nil, 1, jan, monthly_rc.id)
    build_billable_event("app123", nil, 1, jan, hourly_rc.id)

    _, invoice = ReportService.invoice(payment_method.id, jan, feb)
    billable_units = invoice[:billable_units]
    assert_equal(["app123"], billable_units.keys)
    sub_billable_units = billable_units["app123"]
    assert_equal(2, sub_billable_units.length)
    hourly_bu = sub_billable_units.find {|bu| bu["rate_period"] == "hour"}
    monthly_bu = sub_billable_units.find {|bu| bu["rate_period"] == "month"}
    assert_equal(1.0, Float(monthly_bu["qty"]))
    assert_equal(744.0, Float(hourly_bu["qty"]))
  end

  def test_invoice_two_accounts_one_event
    payment_method = build_payment_method
    account = build_account(:provider_id => provider.id)
    another_account = build_account(:provider_id => provider.id)

    build_act_own(account.id, payment_method.id, 1, AccountOwnershipRecord::Active, jan)
    build_act_own(another_account.id, payment_method.id, 2, AccountOwnershipRecord::Active, jan)

    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Active, jan)
    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Inactive, (jan + 100))
    build_res_own(another_account.id, "app123", 2, ResourceOwnershipRecord::Active, (jan + 100))

    build_billable_event("app123", 1, 1, jan)

    _, invoice = ReportService.invoice(payment_method.id, jan, feb)
    billable_units = invoice[:billable_units]
    assert_equal(["app123"], billable_units.keys)
    sub_billable_units = billable_units["app123"]
    assert_equal(1, sub_billable_units.length)
    billable_unit = sub_billable_units.pop
    assert_equal(jan, Time.parse(billable_unit["from"]))
    assert_equal(feb, Time.parse(billable_unit["to"]))
  end

  def test_invoice_two_accounts_many_events
    payment_method = build_payment_method
    another_payment_method = build_payment_method

    account = build_account
    another_account = build_account

    build_act_own(account.id, payment_method.id, 1, AccountOwnershipRecord::Active, jan)
    build_act_own(another_account.id, another_payment_method.id, 2, AccountOwnershipRecord::Active, jan)

    build_res_own(account.id, "app124", nil, ResourceOwnershipRecord::Active, jan)
    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Active, jan)
    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Inactive, jan + 100)
    build_res_own(another_account.id, "app123", 2, ResourceOwnershipRecord::Active, jan + 101)

    build_billable_event("app123", 1, 1, jan)
    build_billable_event("app124", 2, 1, jan)

    _, invoice = ReportService.invoice(payment_method.id, jan, feb)
    billable_units = invoice[:billable_units]
    assert_equal(2, billable_units.length)
    assert_includes(billable_units.keys, "app123")
    assert_includes(billable_units.keys, "app124")
    sub_billable_units = billable_units["app123"]
    assert_equal(1, sub_billable_units.length)
    billable_unit = sub_billable_units.pop
    assert_equal(jan, Time.parse(billable_unit["from"]))
    assert_equal((jan + 100), Time.parse(billable_unit["to"]))

    _, invoice = ReportService.invoice(another_payment_method.id, jan, feb)
    billable_units = invoice[:billable_units]
    assert_equal(["app123"], billable_units.keys)
    sub_billable_units = billable_units["app123"]
    assert_equal(1, sub_billable_units.length)
    billable_unit = sub_billable_units.pop
    assert_equal((jan + 101), Time.parse(billable_unit["from"]))
    assert_equal(feb, Time.parse(billable_unit["to"]))
  end

  def test_inv_uses_prod_name_on_events_when_not_present_on_rate_code
    account = build_account(:provider_id => provider.id)
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
      :state        => 1,
      :time         => Time.now - 3600,
      :rate_code_id => rate_code.id
    )
    _, usage_report = ReportService.usage_report(account.id, jan, Time.now)
    billable_unit = usage_report[:billable_units].pop
    assert_equal("web", billable_unit["product_name"])
  end

  def test_invoice_uses_product_name_on_rate_codes_when_present
    account = build_account(:provider_id => provider.id)
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
      :state        => 1,
      :time         => Time.now - 3600,
      :rate_code_id => rate_code.id
    )
    _, usage_report = ReportService.usage_report(account.id, jan, Time.now)
    billable_unit = usage_report[:billable_units].pop
    assert_equal("specialweb", billable_unit["product_name"])
  end

  def test_inv_doesnt_care_about_res_own
    payment_method = build_payment_method

    account = build_account(:provider_id => provider.id)
    another_account = build_account(:provider_id => provider.id)

    build_act_own(account.id, payment_method.id, 1, AccountOwnershipRecord::Active, jan)
    build_act_own(another_account.id, payment_method.id, 2, AccountOwnershipRecord::Active, jan)

    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Active, jan)
    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Inactive, jan + 100)
    build_res_own(another_account.id, "app123", 2, ResourceOwnershipRecord::Active, jan + 101)

    build_billable_event("app123", 1, 1, jan)
    build_billable_event("app124", 2, 1, jan)

    _, invoice = ReportService.invoice(payment_method.id, jan, feb)
    billable_units = invoice[:billable_units]
    assert_equal(["app123"], billable_units.keys)
    sub_billable_units = billable_units["app123"]
    assert_equal(1, sub_billable_units.length)
    billable_unit = sub_billable_units.pop
    assert_equal(jan, Time.parse(billable_unit["from"]))
    assert_equal(feb, Time.parse(billable_unit["to"]))
  end

  def test_rev_report_acks_credits
    build_billable_event("app123", nil, 1, Time.mktime(2011,1))
    build_billable_event("app123", nil, 1, Time.mktime(2011,1))
    build_billable_event("app124", nil, 1, Time.mktime(2011,1))

    hours_in_month = ((Time.mktime(2012,2) - Time.mktime(2012,1))/60/60).to_i

    _, rev_report = ReportService.rev_report(Time.mktime(2012,1), Time.mktime(2012,2))
    assert_equal((hours_in_month * 15), rev_report[:total])

    _, rev_report = ReportService.rev_report(jan, feb, hours_in_month)
    assert_equal((hours_in_month * 5), rev_report[:total])
  end

  def test_rate_code_report_disambiguates_providers
    rate_code = build_rate_code :slug => "foo"
    build_billable_event("app123", nil, 1, jan, rate_code.id)
    provider2  = build_provider :name => "service depot"
    rate_code2 = build_rate_code :slug => 'foo', :provider_id => provider2.id
    build_billable_event("app123", nil, 1, jan, rate_code2.id)
    build_billable_event("app123", nil, 1, jan, rate_code2.id)
    _, report = ReportService.rate_code_report(provider2.id, 'foo', jan, feb)
    billable_units = report[:billable_units]
    assert_equal(2, billable_units.length)
  end

  def test_rate_code_report
    rate_code = build_rate_code
    build_billable_event("app123", nil, 1, jan, rate_code.id)
    build_billable_event("app124", nil, 1, jan, rate_code.id)
    _, report = ReportService.rate_code_report(provider.id, rate_code.slug, jan, feb)
    assert_equal rate_code.slug, report[:rate_code]
    expected_total = (((feb - jan) / 60.0 / 60.0) * rate_code.rate) * 2
    assert_equal expected_total, report[:total].to_f
    billable_units = report[:billable_units]
    assert_equal(2, billable_units.length)
  end

  def test_rate_code_report_when_res_own_change
    rate_code = build_rate_code
    payment_method = build_payment_method

    account = build_account(:provider_id => provider.id)
    another_account = build_account(:provider_id => provider.id)

    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Active, jan)
    build_res_own(account.id, "app123", 1, ResourceOwnershipRecord::Inactive, jan + 100)
    build_res_own(another_account.id, "app123", 2, ResourceOwnershipRecord::Active, jan + 101)

    #many people have owned app123
    build_billable_event("app123", 1, 1, jan, rate_code.id)
    #no one owns app124, but it still uses the rate code
    build_billable_event("app124", 2, 1, jan, rate_code.id)

    _, report = ReportService.rate_code_report(provider.id, rate_code.slug, jan, feb)
    expected_total = (((feb - jan) / 60.0 / 60.0) * rate_code.rate) * 2
    assert_equal(expected_total, report[:total].to_f)

    billable_units = report[:billable_units]
    assert_equal(2, billable_units.length)
    billable_unit = billable_units.first
    assert_equal(jan, Time.parse(billable_unit["from"]))
    assert_equal(feb, Time.parse(billable_unit["to"]))
  end

=begin
  def test_rate_code_report_perc_month
    rate_code = build_rate_code(:rate => 100, :rate_period => "month")
    build_billable_event("app123", nil, 1, jan, rate_code.id)
    build_billable_event("app124", nil, 1, jan, rate_code.id)
    _, report = ReportService.rate_code_report(rate_code.id, jan, feb)
    expected_total = (((feb - jan) / 60.0 / 60.0) * rate_code.rate) * 2
    assert_equal(expected_total, report[:total].to_f)
    billable_units = report[:billable_units]
    assert_equal(2, billable_units.last["qty"])
  end
=end

end
