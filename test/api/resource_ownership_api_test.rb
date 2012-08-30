require File.expand_path('../../test_helper', __FILE__)

class ResourceOwnershipApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
    @account_slug = 123
    @new_account_slug = 124
    authorize(@provider.id, "abc123")
  end

  def test_activate_record
    put("/accounts/#{@account_slug}/resource_ownerships/#{SecureRandom.uuid}", {
      :state => "active",
      :resource_id => "123",
      :time => Time.now.utc.to_s
    })
    assert_equal(201, last_response.status)
  end

  def test_activate_record_with_new_account_id
    eid = SecureRandom.uuid
    put("/accounts/#{@new_account_slug}/resource_ownerships/#{eid}", {
      :state => "active",
      :resource_id => "123",
      :time => Time.now.utc.to_s
    })
    assert_equal(201, last_response.status)
  end

  def test_deactivate_record
    eid = SecureRandom.uuid
    put("/accounts/#{@account_slug}/resource_ownerships/#{eid}", {
      :state => "active",
      :resource_id => "123",
      :time => Time.now.utc.to_s
    })
    put("/accounts/#{@account_slug}/resource_ownerships/#{eid}", {
      :state => "inactive",
      :resource_id => "123",
      :time => Time.now.utc.to_s
    })
    assert_equal(201, last_response.status)
  end

end
