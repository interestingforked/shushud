module BillableEventService
  extend self

  def find(provider_id)
    events = BillableEvent.filter(:provider_id => provider_id).all
    [200, events.map(&:to_h)]
  end

  def handle_new_event(args)
    check_args!(args)
    if event = BillableEvent.prev_recorded(args[:state], args[:entity_id], args[:provider_id])
      Log.info(:action => "event_found", :provider => event[:provider_id], :entity => event[:entity_id])
      [200, event.to_h]
    else
      [201, open_or_close(args).to_h]
    end
  end

  private

  def open_or_close(args)
    case args[:state]
    when BillableEvent::Open
      create_record(BillableEvent::Open, args)
    when BillableEvent::Close
      create_record(BillableEvent::Close, args)
    else
      Log.error({:error => true, :action => "open_or_close"}.merge(args))
      raise(ArgumentError, "Unable to create new event with args=#{args}")
    end
  end

  def create_record(state, args)
    action = state == BillableEvent::Open ? "open_event" : "close_event"
    Log.info_t({:action => action}.merge(args)) do
      BillableEvent.create(
        :provider_id      => args[:provider_id],
        :rate_code_id     => args[:rate_code_id],
        :entity_id        => args[:entity_id],
        :hid              => args[:hid],
        :qty              => args[:qty],
        :product_name     => args[:product_name],
        :description      => args[:description],
        :time             => args[:time],
        :state_int        => BillableEvent.enc_state(state)
      )
    end
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
      [:provider_id, :rate_code_id, :entity_id, :hid, :qty, :time, :state]
    when "close"
      [:provider_id, :entity_id, :state, :time]
    end
  end

end
