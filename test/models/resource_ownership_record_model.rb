require File.expand_path('../../test_helper', __FILE__)

class ResourceOwnershipRecordTest < ShushuTest

  def test_find
    account = build_account
    build_resource_ownership_record(:account_id => account.id, :hid => "123", :time => jan, :state => ResourceOwnershipRecord::Active)
    records = ResourceOwnershipRecord.find(account.id, jan, feb)
    assert(!records.empty?, "Expected to find some records")
  end

=begin
  def test_find_returns_from_and_to
    account = build_account
    build_resource_ownership_record(:hid => "123", :time => jan, :state => ResourceOwnershipRecord::Active)
    records = ResourceOwnershipRecord.find(account.id, jan, feb)
    assert(!records.empty?, "Expected to find some records")
  end
=end

  def jan
    Time.mktime(2011,1)
  end

  def feb
    Time.mktime(2011,2)
  end

end
