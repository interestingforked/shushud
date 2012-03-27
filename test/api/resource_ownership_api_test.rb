require File.expand_path('../../test_helper', __FILE__)

class ResourceOwnershipApiTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
    authorize(@provider.id, "abc123")
  end

  def test_activate_record
    put("/accounts/#{account.id}/resource_ownerships/#{SecureRandom.uuid}", {
      :state => "active",
      :resource_id => "123",
      :time => Time.now.utc.to_s
    })
    assert_equal(200, last_response.status)
  end

  def test_activate_record_with_new_account_id_
    put("/accounts/new_slug/resource_ownerships/#{SecureRandom.uuid}", {
      :state => "active",
      :resource_id => "123",
      :time => Time.now.utc.to_s
    })
    assert_equal(200, last_response.status)
    updated_record = JSON.parse(last_response.body)
    assert_equal("new_slug", updated_record["account_id"])
  end

  def test_deactivate_record
    eid = SecureRandom.uuid
    put("/accounts/#{account.id}/resource_ownerships/#{eid}", {
      :state => "active",
      :resource_id => "123",
      :time => Time.now.utc.to_s
    })
    put("/accounts/#{account.id}/resource_ownerships/#{eid}", {
      :state => "inactive",
      :resource_id => "123",
      :time => Time.now.utc.to_s
    })
    assert_equal(200, last_response.status)
    updated_record = JSON.parse(last_response.body)
    assert_equal(account.id, updated_record["account_id"].to_i)
  end

  def account
    @account ||= build_account
  end

end
