module EventHandler

  # This handler implements the EventBuilder protocol
  # and uses the BillableEvent model to store the event data.

  extend self

  def find(conditions)
    BillableEvent.filter(:provider_id => conditions[:provider_id], :resource_id => conditions[:resource_id]).all
  end

  def find_open(provider_id, event_id)
    BillableEvent.filter(:provider_id => provider_id, :event_id => event_id).first
  end

  def close(existing_event_id, close_date_time)
    now = Time.now

    existing_event = BillableEvent[existing_event_id]
    existing_event.update_only({:system_to => now}, [:system_to])
    log("expired event=#{existing_event_id} system_to=#{now}")

    new_event = BillableEvent.new(existing_event.public_values)
    new_event.set(:system_from => now)
    log("set new_event system_from=#{now}")

    new_event.set(:reality_to => close_date_time)
    log("set new_event reality_to=#{close_date_time}")

    new_event.save(:raise_on_failure => true)
    log("save new_event event=#{new_event.id}")

    new_event
  end

  def open(args)
    BillableEvent.create(
      :event_id       => args[:event_id],
      :provider_id    => args[:provider_id],
      :resource_id    => args[:resource_id],
      :rate_code_id   => find_rate_code_id(args[:rate_code]),
      :qty            => args[:qty],
      :reality_from   => args[:reality_from],
      :reality_to     => args[:reality_to],
      :system_from    => Time.now,
      :system_to      => nil
    )
  end

  private

  def find_rate_code_id(slug)
    if rate_code = RateCode.filter(:slug => slug).first
      rate_code.id
    else
      raise "coult not find rate_code"
    end
  end

  def log(msg)
    shulog(msg)
  end

end
