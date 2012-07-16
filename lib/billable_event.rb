module Shushu
  module BillableEvent
    extend self

    OPEN = 1
    CLOSED = 0

    def handle_in(args)
      validate_args!(args)
      if prev_recorded?(args[:entity_id_uuid], args[:state])
        [200, "OK"]
      elsif args[:state] == "open"
        if open_event(args)
          [200, "OK"]
        else
          [400, {error: "unable to open event"}]
        end
      elsif args[:state] == "closed"
        Utils.transaction do
          if open = delete_event(args[:entity_id_uuid])
            if close_event(open, args)
              [200, "OK"]
            else
              [400, {error: "unable to open event"}]
            end
          else
            [400, {error: "must open an event before closing it"}]
          end
        end
      else
        [400, {error: "state must be 'open' or 'closed'"}]
      end
    end

    private

    def prev_recorded?(uuid, state)
      ! DB[:billable_events].
        filter(entity_id_uuid: uuid, state: state).
        count.
        zero?
    end

    def open_event(args)
      DB[:billable_events].
        insert(provider_id: args[:provider_id],
                entity_id_uuid: Utils.validate_uuid(args[:entity_id_uuid]),
                rate_code_id: args[:rate_code],
                hid: args[:hid],
                qty: args[:qty],
                product_name: args[:product_name],
                description: args[:description],
                time: args[:time],
                created_at: Time.now,
                state: OPEN)
    end

    def close_event(open, args)
      DB[:closed_events].
        insert(provider_id: args[:provider_id],
                entity_id_uuid: Utils.validate_uuid(args[:entity_id_uuid]),
                rate_code_id: open[:rate_code_id],
                hid: open[:hid],
                qty: open[:qty],
                product_name: open[:product_name],
                description: open[:description],
                from: open[:time],
                to: args[:time],
                created_at: Time.now)
    end

    def validate_args!(args)
      mis_args = missing_args(args)
      if mis_args.length > 0
        raise(ArgumentError,
               "Missing arguments for billable_event api: #{mis_args}")
      end
    end

    def missing_args(args)
      required_args(args[:state]) - args.reject {|k,v| v.nil?}.keys
    end

    def required_args(state)
      case state.to_s
      when "open"
        [:provider_id, :rate_code, :entity_id_uuid, :hid, :qty, :time, :state]
      when "close"
        [:provider_id, :entity_id_uuid, :state, :time]
      end
    end

  end
end
