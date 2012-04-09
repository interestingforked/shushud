module BillableEventService
  extend self

  def find(provider_id)
    events = BillableEvent.filter(:provider_id => provider_id).all
    [200, events.map(&:to_h)]
  end

  def handle_in(args)
    check_args!(args)
    if event = BillableEvent.prev_recorded(args[:state], args[:entity_id_uuid], args[:provider_id])
      Log.info(:action => "event_found", :provider => event[:provider_id], :entity => event[:entity_id_uuid])
      [200, event.to_h]
    else
      [201, open_or_close(args).to_h]
    end
  end

  private

  def open_or_close(args)
    if !["open", "close"].include?(args[:state])
      Log.error({:action => "open_or_close"}.merge(args))
      raise(ArgumentError, "Unable to create new event with args=#{args}")
    else
      create_record(args[:state], args)
    end
  end

  def create_record(state, args)
    begin
      Utils.txn do
        BillableEvent.create(
          :provider_id      => args[:provider_id],
          :entity_id_uuid   => Utils.validate_uuid(args[:entity_id_uuid]),
          :rate_code_id     => args[:rate_code],
          :entity_id        => args[:entity_id],
          :hid              => args[:hid],
          :qty              => args[:qty],
          :product_name     => args[:product_name],
          :description      => args[:description],
          :time             => args[:time],
          :state            => BillableEvent.enc_state(state)
        ).tap do |ev|
          EventTracker.track(
            ev[:entity_id_uuid],
            ev[:state],
            ev[:created_at],
            ev[:provider_id]
          )
        end
      end
    rescue StandardError => e
      Log.error({:action => "#{state}_event"}.merge(args))
      raise(e)
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
      [:provider_id, :rate_code, :entity_id_uuid, :hid, :qty, :time, :state]
    when "close"
      [:provider_id, :entity_id_uuid, :state, :time]
    end
  end

end
