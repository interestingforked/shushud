module Shushu
  module EventBuilder
    extend self

    def handle_incomming(args)
      open_or_close(args)
    end

    private

    # Returns a new event or the existing event.
    def open_or_close(args)
      log("handle incomming args=#{args}")
      if existing = find_open(args[:provider_id], args[:event_id])
        eid = existing[:id]
        log("found existing billable_event=#{eid}")
        if [:qty, :reality_from, :rate_code].any? {|field| args[field] && (existing[field].to_s != args[field].to_s) }
          log("attempting to change field")
          [409, existing]
        elsif close_dt = args[:reality_to] #wants to close event
          log("closing event=#{eid}")
          event = close(eid, close_dt)
          [200, event]
        else
          log("existing is identical to new")
          [200, existing]
        end
      else
        log("open billable_event args=#{args}")
        event = open(args)
        [201, event]
      end
    end

    def close(existing_event_id, close_date_time)
      now = Time.now

      existing_event = BillableEvent[existing_event_id]
      existing_event.update_only({:system_to => now}, [:system_to])
      log("expired event=#{existing_event_id} system_to=#{now}")

      new_event = BillableEvent.new(existing_event.public_values)
      new_event.set(:system_from => now)
      log("set new_event system_from=#{now}")

      new_event.set(:reality_to => close_date_time)
      log("set new_event reality_to=#{close_date_time}")

      new_event.save(:raise_on_failure => true)
      log("save new_event event=#{new_event.id}")

      new_event
    end

    def find_open(provider_id, event_id)
      BillableEvent.filter(:provider_id => provider_id, :event_id => event_id).first
    end

    def open(args)
      BillableEvent.create(
        :event_id       => args[:event_id],
        :provider_id    => args[:provider_id],
        :resource_id    => args[:resource_id],
        :rate_code      => args[:rate_code],
        :qty            => args[:qty],
        :reality_from   => args[:reality_from],
        :reality_to     => args[:reality_to],
        :system_from    => Time.now,
        :system_to      => nil
      )
    end

  end
end
