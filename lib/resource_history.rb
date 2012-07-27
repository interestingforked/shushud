require './lib/utils'

module Shushu
  module ResourceHistory
    extend self

    def fetch(owner, from, to)
      [200, Utils.enc_j(resource_histories(owner, from, to))]
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

    def overlaps?(a, b, c, d)
      (a >= c && a <= d) || (d >= a)
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
      Shushu::DB[:resource_ownership_records].
        filter("owner = ?", owner).
        to_a.
        group_by {|r| r[:entity_id]}
    end

    def events(resid, from, to)
      log(ns: "resource-histories", fn: "fetch-rh", resid: resid) do
        s = "select * from resource_history(?, ?, ?)"
        Shushu::DB[s, resid, from, to].map do |event|
          f = [from, event[:from]].max
          t = [to, event[:to]].min
          event.merge(from: f, to: t, qty: ((t - f) / 3600))
        end
      end
    end

  end
end
