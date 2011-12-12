module BillableEventService
  extend self

  def find(conditions)
    BillableEvent.
      filter(:provider_id => conditions[:provider_id], :hid => conditions[:hid]).
      all
  end

  def handle_new_event(args)
    case args[:state]
    when BillableEvent::Open
      shulog("#event_open")
      if event = BillableEvent[:state => BillableEvent::Open, :event_id => args[:event_id]]
        shulog("#event_found")
        event
      else
        open(args)
      end when BillableEvent::Close
      shulog("#event_close")
      close(args)
    else
      shulog("#unhandled_state args=#{args}")
      raise(ArgumentError, "Unable to create new event with args=#{args}")
    end
  end

  private

  def open(args)
    BillableEvent.append_new_event(args, BillableEvent::Open)
  end

  def close(args)
    BillableEvent.append_new_event(args, BillableEvent::Close)
  end

end
