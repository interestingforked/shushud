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
    check_args!(args)
    if event = BillableEvent.prev_recorded(args[:state], args[:entity_id], args[:provider_id])
      Log.info("#event_found provider=#{event[:provider_id]} entity=#{event[:entity_id]}")
      [200, event.to_h]
    else
      [201, open_or_close(args).to_h]
    end
  end

  private

  def open_or_close(args)
    case args[:state]
    when BillableEvent::Open
      Log.info("#event_open")
      open(args)
    when BillableEvent::Close
      Log.info("#event_close")
      close(args)
    else
      Log.info("#unhandled_state args=#{args}")
      raise(ArgumentError, "Unable to create new event with args=#{args}")
    end
  end

  def open(args)
    Log.info("#event_creation #{args}")
    BillableEvent.create(
      :provider_id      => resolve_provider_id(args[:provider_id]),
      :rate_code_id     => resolve_rate_code_id(args[:rate_code_slug]),
      :entity_id        => args[:entity_id],
      :hid              => args[:hid],
      :qty              => args[:qty],
      :product_name     => args[:product_name],
      :time             => args[:time],
      :state            => BillableEvent::Open,
      :created_at       => Time.now
    )
  end

  def close(args)
    Log.info("#event_creation #{args}")
    BillableEvent.create(
      :provider_id      => resolve_provider_id(args[:provider_id]),
      :rate_code_id     => resolve_rate_code_id(args[:rate_code_slug]),
      :entity_id        => args[:entity_id],
      :hid              => args[:hid],
      :qty              => args[:qty],
      :product_name     => args[:product_name],
      :time             => args[:time],
      :state            => BillableEvent::Close,
      :created_at       => Time.now
    )
  end

  def check_args!(args)
    mis_args = missing_args(args)
    unless mis_args.empty?
      raise(ArgumentError, "Missing arguments for billable_event api: #{mis_args}")
    end
  end

  def missing_args(args)
    required_args(args[:state]) - args.reject {|k,v| v.nil?}.keys
  end

  def required_args(state)
    case state.to_s
    when "open"
      [:provider_id, :rate_code_slug, :entity_id, :hid, :qty, :time, :state]
    when "close"
      [:provider_id, :entity_id, :state]
    end
  end

  def resolve_rate_code_id(slug)
    if rc = RateCode[:slug => slug]
      rc[:id]
    else
      raise(Shushu::NotFound, "Could not find rate_code with slug=#{slug}")
    end
  end

  def resolve_provider_id(provider_id)
    if p = Provider[provider_id]
      p[:id]
    else
      raise(Shushu::NotFound, "Could not find provider with id=#{provider_id}")
    end
  end

end
