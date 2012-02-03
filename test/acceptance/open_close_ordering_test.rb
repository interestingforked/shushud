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
end
