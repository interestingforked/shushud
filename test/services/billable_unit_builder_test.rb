require File.expand_path('../../test_helper', __FILE__)

class BillableUnitBuilderTest < ShushuTest

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

    billable_units = BillableUnitBuilder.build(account.id, jan, feb)
    assert_equal(1, billable_units.length)

    billable_unit = billable_units.first
    assert_equal(jan, billable_unit.from)
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

    billable_units = BillableUnitBuilder.build(account.id, jan, feb)
    assert_equal(1, billable_units.length)
    billable_unit = billable_units.first
    assert_equal(jan, billable_unit.from)
    assert_equal((jan + 100), billable_unit.to)

    billable_units = BillableUnitBuilder.build(another_account.id, jan, feb)
    assert_equal(1, billable_units.length)
    billable_unit = billable_units.last
    assert_equal((jan + 100), billable_unit.from)
    assert_in_delta(feb, billable_unit.to, 2)
  end


end
