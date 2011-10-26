class EventBuilder
  # Responsibility:
  # => open / close events, notify open / close, return http status code

  # Abstract:
  # The EventBuilder provides the handle_incomming(args) & find(conds)
  # interface to some sort of public api, be it http or otherwise.
  #
  # HTTP -> EventBuilder -> EventHandler (billable_events_table | message_bus | whatever...)
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
      log("found existing billable_event=#{existing.id}")
      try_close(existing, args)
    else
      log("open billable_event args=#{args}")
      open(args)
    end
  end

  private

  def try_close(existing, args)
    eid = existing.id
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
  end

  def open(args)
    [201, @handler.open(args)]
  end

end
