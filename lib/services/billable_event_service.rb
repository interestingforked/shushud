module BillableEventService
  extend self

  def find(conditions)
    events = BillableEvent.filter(
      :provider_id => conditions[:provider_id],
      :hid => conditions[:hid]
    ).all
    [200, events.map(&:to_h)]
  end

  def handle_new_event(args)
    if event = BillableEvent.prev_recorded(args[:state], args[:event_id])
      shulog("#event_found")
      [200, event.to_h]
    else
      [201, open_or_close(args).to_h]
    end
  end

  private

  def open_or_close(args)
    case args[:state]
    when BillableEvent::Open
      shulog("#event_open")
      open(args)
    when BillableEvent::Close
      shulog("#event_close")
      close(args)
    else
      shulog("#unhandled_state args=#{args}")
      raise(ArgumentError, "Unable to create new event with args=#{args}")
    end
  end

  def resolve_rate_code_id(slug)
    if rc = RateCode[:slug => slug]
      rc[:id]
    end
  end

  def resolve_provider_id(provider_id)
    if p = Provider[provider_id]
      p[:id]
    end
  end

  def open(args)
    shulog("#event_creation #{args}")
    BillableEvent.create(
      :provider_id      => resolve_provider_id(args[:provider_id]),
      :rate_code_id     => resolve_rate_code_id(args[:rate_code_slug]),
      :event_id         => args[:event_id],
      :hid              => args[:hid],
      :qty              => args[:qty],
      :time             => args[:time],
      :state            => BillableEvent::Open,
      :transitioned_at  => Time.now
    )
  end

  def close(args)
    shulog("#event_creation #{args}")
    BillableEvent.create(
      :provider_id      => resolve_provider_id(args[:provider_id]),
      :rate_code_id     => resolve_rate_code_id(args[:rate_code_slug]),
      :event_id         => args[:event_id],
      :hid              => args[:hid],
      :qty              => args[:qty],
      :time             => args[:time],
      :state            => BillableEvent::Close,
      :transitioned_at  => Time.now
    )
  end

end
