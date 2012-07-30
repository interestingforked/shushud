require 'shushu'
require 'utils'

module Shushu
  # @author Ryan Smith
  # Shushud's reporting function. Combines ownerships and billable events.
  module ResourceHistory
    extend self

    def fetch(owner, from, to)
      [200, Utils.enc_j(resource_histories(owner, from, to))]
    end

    private

    def overlaps?(a, b, c, d)
      (a >= c && a <= d) || (d >= a)
    end

    def resource_histories(owner, from, to)
      ownerships(owner, from, to).map do |ownership|
        events = events(ownership[:resource_id],
                         ownership[:from], ownership[:to])
        qty =  events.map {|e| e[:qty]}.reduce(:+) || 0
        {resource_id: ownership[:resource_id],
          dyno_hours: qty,
          adjusted_dyno_hours: (qty - [750, qty].min),
          events: events}
      end
    end

    def ownerships(owner, from, to)
      ownership_records(owner).map do |eid, col|
        open = col.find {|c| c[:state] == 1}
        closed = col.find {|c| c[:state] == 0} || {time: Time.now}
        if overlaps?(from, to, open[:time], closed[:time])
          {entity_id: eid,
            resource_id: open[:hid],
            from: [from, open[:time]].max,
            to: [to, closed[:time]].min}
        else
          nil
        end
      end.compact
    end

    def ownership_records(owner)
      DB[:resource_ownership_records].
        filter("owner = ?", owner).
        to_a.
        group_by {|r| r[:entity_id]}
    end

    def events(resid, from, to)
      log(fn: __method__, resid: resid, from: from, to: to) do
        s = "select * from resource_history(?, ?, ?)"
        DB[s, resid, from, to].map do |event|
          f = [from.to_i, event[:from]].max
          t = [to.to_i, event[:to]].min
          event.merge(from: f, to: t, qty: ((t - f) / 3600))
        end
      end
    end

    def log(data, &blk)
      Scrolls.log({ns: "resource_history"}.merge(data), &blk)
    end

  end
end
