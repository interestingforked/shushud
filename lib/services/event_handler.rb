module EventHandler

  # This handler implements the EventBuilder protocol
  # and uses the BillableEvent model to store the event data.

  extend self

  def find(conditions)
    BillableEvent.filter(:provider_id => conditions[:provider_id], :hid => conditions[:hid]).all
  end

  def handle(args)
    case args[:state]
    when BillableEvent::Open
      shulog("#event_open")
      if event = BillableEvent[:state => BillableEvent::Open, :event_id => args[:event_id]]
        shulog("#event_found")
        [200, event]
      else
        [201, open(args)]
      end
    when BillableEvent::Close
      shulog("#event_close")
      [200, close(args)]
    else
      shulog("#unhandled_state args=#{args}")
      [500, nil]
    end
  end

  def open(args)
    BillableEvent.append_new_event(args, BillableEvent::Open)
  end

  def close(args)
    BillableEvent.append_new_event(args, BillableEvent::Close)
  end

end
