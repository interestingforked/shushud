require 'shushu'
require 'utils'

module Shushu
  # @author Ryan Smith
  module BillableEvent
    extend self

    # The API will accept 'open' althought we store it in the DB as 1
    OPEN = 1
    # The API will accept 'close' althought we store it in the DB as 0
    CLOSED = 0

    # Entry point for incomming billable_events.
    #
    # If an entity is closed before it is opened, a 422 will be returned.
    # The client should keep trying the closed until it succeeds.
    #
    # @param [Hash] state key must be equal to 'open' or 'close'
    # @return [Array] First element is HTTP status code. Last element is JSON.
    def handle_in(args)
      return [400, Utils.enc_j(msg: "invalid args")] unless valid_args?(args)

      if args[:state] == "open"
        if prev_opened?(args[:entity_id_uuid])
          [200, Utils.enc_j(id: args[:entity_id_uuid])]
        elsif e = open_event(args)
          [201, Utils.enc_j(id: e[:entity_id_uuid])]
        else
          [400, Utils.enc_j(error: "unable to open event")]
        end
      elsif args[:state] == "close"
        Utils.txn do
          if prev_closed?(args[:entity_id_uuid])
            [200, Utils.enc_j(id: args[:entity_id_uuid])]
          elsif open = delete_event(args[:entity_id_uuid])
            if e = close_event(open, args)
              [201, Utils.enc_j(id: e[:entity_id])]
            else
              [400, Utils.enc_j(error: "unable to close event")]
            end
          else
            [422, Utils.enc_j(error: "must open an event before closing it")]
          end
        end
      else
        [400, Utils.enc_j(error: "state must be 'open' or 'closed'")]
      end
    end

    private

    def prev_opened?(uuid)
      ! DB[:billable_events].
        filter(entity_id_uuid: uuid, state: OPEN).
        count.
        zero?
    end

    def prev_closed?(eid)
      ! DB[:closed_events].
        filter(entity_id: eid).
        count.
        zero?
    end

    def delete_event(eid)
      s = DB[:billable_events].
        filter(entity_id_uuid: eid)
      s.first.tap {s.delete}
    end

    def open_event(args)
      log(measure: true, fn: [args[:provider_id], __method__].join("-")) do
        DB[:billable_events].
          returning(:entity_id_uuid).
          insert(provider_id: args[:provider_id],
                  entity_id_uuid: Utils.validate_uuid(args[:entity_id_uuid]),
                  rate_code_id: resolve_rc(args[:rate_code]),
                  hid: args[:hid],
                  qty: args[:qty],
                  product_name: args[:product_name],
                  description: trim_desc(args[:description]),
                  time: args[:time],
                  created_at: Time.now,
                  state: OPEN).pop
      end
    end

    def close_event(open, args)
      log(measure: true, fn: [args[:provider_id], __method__].join("-")) do
        DB[:closed_events].
          returning(:entity_id).
          insert(provider_id: args[:provider_id],
                  entity_id: Utils.validate_uuid(args[:entity_id_uuid]),
                  rate_code_id: open[:rate_code_id],
                  resource_id: open[:hid],
                  qty: open[:qty],
                  product_name: open[:product_name],
                  description: open[:description],
                  from: open[:time],
                  to: args[:time],
                  created_at: Time.now).pop
      end
    end

    def resolve_rc(slug)
      DB[:rate_codes].filter(slug: slug).first[:id]
    end

    def valid_args?(args)
      missing_args(args).length.zero?
    end

    def missing_args(args)
      required_args(args[:state]) -
        args.reject {|k,v| v.nil? || v.to_s.length.zero?}.keys
    end

    def required_args(state)
      case state.to_s
      when "open"
        [:provider_id, :rate_code, :entity_id_uuid, :hid, :qty, :time, :state]
      when "close"
        [:provider_id, :entity_id_uuid, :state, :time]
      end
    end

    #TODO: database shouldn't care about length of description
    def trim_desc(s)
      if s && s.length > 0
        s[0..254]
      else
        s
      end
    end

    def log(data, &blk)
      Scrolls.log({ns: "billable_event"}.merge(data), &blk)
    end

  end
end
