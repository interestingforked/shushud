class EventBuilder
  # Responsibility:
  # => open / close events, notify open / close, return http status code

  # Abstract:
  # The EventBuilder provides the handle_incomming(args) interface to
  # some sort of public api, be it http or otherwise. It should add an
  # abstraction between the API and to storage layer.
  #
  # HTTP -> API -> EventBuilder -> (billable_events_table | legacy_rh_table | message_bus | etc...)
  #

  def initialize(handler)
    @handler = handler
  end
  
  def find(conditions)
    @handler.find(conditions)
  end
  
  def handle_incomming(args)
    log("handle incomming args=#{args}")
    if existing = @handler.find_open(args[:provider_id], args[:event_id])
      eid = existing[:id]
      log("found existing billable_event=#{eid}")
      if EventValidator.invalid?(existing, args)
        log("attempting to change field")
        [409, existing]
      elsif close_dt = args[:reality_to] #wants to close event
        log("closing event=#{eid}")
        event = @handler.close(eid, close_dt)
        [200, event]
      else
        log("existing is identical to new")
        [200, existing]
      end
    else
      log("open billable_event args=#{args}")
      event = @handler.open(args)
      [201, event]
    end
  end

end
