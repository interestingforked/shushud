require File.expand_path('../../test_helper', __FILE__)

class ResourceOwnershipServiceTest < ShushuTest

  def test_transfer_record_marks_to_of_old_record
    second_account = build_account
    ResourceOwnershipService.activate(provider.id, account.id, "123", t1, "event1")
    ResourceOwnershipService.transfer(provider.id, account.id, second_account.id, "123", (t1 + 100), "event1", "event2")
    _, records = ResourceOwnershipService.query(account.id)
    record = records.first
    assert_equal(account.id, record[:account_id])
    assert_equal((t1 + 100), record[:to])
  end

  def test_transfer_record_marks_from_of_new_record
    second_account = build_account
    ResourceOwnershipService.activate(provider.id, account.id, "123", t1, "event1")
    ResourceOwnershipService.transfer(provider.id, account.id, second_account.id, "123", t2, "event1", "event2")
    _, records = ResourceOwnershipService.query(second_account.id)
    record = records.first
    assert_equal(second_account.id, record[:account_id])
    assert_equal(t2.to_i, record[:from].to_i)
  end

  def test_query_returns_many_records_when_there_are_many_transferes
    second_account = build_account
    ResourceOwnershipService.activate(provider.id, account.id, "123", t1, "event1")
    ResourceOwnershipService.transfer(provider.id, account.id, second_account.id, "123", (t1 + 1000), "event1", "event2")
    ResourceOwnershipService.transfer(provider.id, second_account.id, account.id, "123", (t1 + 2000), "event2", "event3")
    ResourceOwnershipService.transfer(provider.id, account.id, second_account.id, "123", (t1 + 3000), "event3", "event4")
    _, records = ResourceOwnershipService.query(account.id)
    assert_equal(2, records.length)
    record = records.first
    assert_equal(account.id, record[:account_id])
  end

  def t1
    Time.mktime(2000)
  end

  def t2
    Time.mktime(2000,2)
  end

  def account
    @account ||= build_account
  end

  def provider
    @provider ||= build_provider
  end

end
