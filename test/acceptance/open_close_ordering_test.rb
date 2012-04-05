require File.expand_path('../../test_helper', __FILE__)

# Purpose:
# Providers may submit billable_events in no particular order. This is especially
# true in cases where the provider is submitting events asynchronously. Thus we
# need to ensure that Shushu can handle event out of order. Here is the rule:
#
# When we have a close event without an open event, we should exclude it from
# any sort of report. Since all reports rely on the billable_units SQL view, it
# suffices to ensure that billable_units should exclude any set of events such
# that a close is present when there is no open present.

class OpenCloseOrderingTest < ShushuTest

  def setup
    super
    @provider = build_provider(:token => "abc123")
    authorize(@provider.id, "abc123")
    @rate_code = build_rate_code(:provider_id => @provider.id)
  end

  def test_close_can_happen_before_open
    eid = SecureRandom.uuid
    put("resources/123/billable_events/#{eid}", {
      :entity_id_uuid => eid,
      :qty       => 1,
      :rate_code => @rate_code.slug,
      :state     => 'close',
      :time      => "2012-01-01 00:00:01 UTC"
    })
    assert_equal(201, last_response.status)
  end

  def test_usage_report_does_not_include_close_without_open
    eid = SecureRandom.uuid
    put("resources/123/billable_events/#{eid}", {
      :entity_id_uuid => eid,
      :qty       => 1,
      :rate_code => @rate_code.slug,
      :state     => 'close',
      :time      => jan
    })
    assert_equal(201, last_response.status)

    account = build_account(:provider_id => @provider.id)
    aeid = SecureRandom.uuid
    put("/accounts/#{account.id}/resource_ownerships/#{aeid}", {
      :state => ResourceOwnershipRecord::ACTIVE,
      :resource_id => "123",
      :time => jan
    })
    assert_equal(200, last_response.status)

    _, report = ReportService.usage_report(account.id, jan, feb)
    billable_units = report[:billable_units]
    assert_equal(0, billable_units.length)
  end

end
