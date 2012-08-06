require 'shushu'
require 'utils'
require 'date'
require 'time'

module Shushu
  # @author Ryan Smith
  # Shushud's reporting function. Combines ownerships and billable events.
  module ResourceHistory
    extend self

    def fetch(owner, from, to)
      [200, Utils.enc_j(resource_histories(owner, from, to))]
    end

    def summary(owner, from, to, w_avg=true)
      [200, Utils.enc_j(resource_summaries(owner, from, to, w_avg))]
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

    def resource_summaries(owner, from, to, w_avg)
      ownerships(owner, from, to).map do |ownership|
        if w_avg
          summaries_w_avg(ownership[:resource_id],
                              ownership[:from], ownership[:to])
        else
          summaries(ownership[:resource_id],
                     ownership[:from], ownership[:to])
        end
      end
    end

    def ownerships(owner, from, to)
      ownership_records(owner).map do |eid, col|
        open = col.find {|c| c[:state] == 1}
        closed = col.find {|c| c[:state] == 0} || {time: to}
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
      FollowerDB[:resource_ownership_records].
        filter("owner = ?", owner).
        to_a.
        group_by {|r| r[:entity_id]}
    end

    def events(resid, from, to)
      log(fn: __method__, resid: resid, from: from, to: to) do
        s = "select * from resource_history(?, ?, ?)"
        FollowerDB[s, resid, from, to].map do |event|
          f = [from.to_i, event[:from]].max
          t = [to.to_i, event[:to]].min
          event.merge(from: f, to: t, qty: ((t - f) / 3600))
        end
      end
    end

    def summaries(resid, from, to)
      log(fn: __method__, resid: resid, from: from, to: to) do
        s = "select * from resource_summary(?, ?, ?)"
        FollowerDB[s, resid, from, to].to_a
      end
    end

    def summaries_w_avg(resid, from, to)
      from.to_date.upto(to.to_date).map do |day|
        f = day.to_time
        # if to is today, we don't want to compute into the future.
        t = [(f + (60*60*24)), Time.now].min
        summaries(resid, f, t).map do |s|
          s.merge(avg: {day.to_s => s[:qty] / 24.0})
        end
      end.flatten.group_by do |s|
        [:product_group, :product_name, :description].map do |t|
          s[t]
        end.join("-")
      end.map do |name, sums|
        {product_group: sums.sample[:product_group],
          product_name: sums.sample[:product_name],
          description: sums.sample[:description],
          qty: sums.map {|s| s[:qty]}.reduce(:+).to_f,
          daily_avgs: sums.map {|s| s[:avg]}}
      end.reduce({}) do |ret, col|
        ret[resid] ||= []
        ret[resid] << col
        ret
      end
    end

    def log(data, &blk)
      Scrolls.log({ns: "resource_history"}.merge(data), &blk)
    end

  end
end
