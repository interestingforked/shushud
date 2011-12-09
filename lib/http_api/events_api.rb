class EventsApi < Sinatra::Application

  helpers { include Authentication }

  before do
    authenticate_provider #sets params[:provider_id]
    content_type :json
  end

  get "/:hid/billable_events" do
    provider = Provider[params[:provider_id]]
    builder = EventBuilder.new(EventHandler)

    cond = {:hid => params[:hid], :provider_id => params[:provider_id]}
    events = builder.find(cond)
    JSON.dump(events.map(&:api_values))
  end

  put "/:hid/billable_events/:event_id" do
    provider = Provider[params[:provider_id]]
    builder = EventBuilder.new(EventHandler)

    http_status, event = builder.handle_incomming(
      :provider_id    => params[:provider_id],
      :event_id       => params[:event_id],
      :hid            => params[:hid],
      :rate_code      => params[:rate_code],
      :qty            => params[:qty],
      :reality_from   => params[:from],
      :reality_to     => params[:to]
    )
    status(http_status)
    body(JSON.dump(event.api_values))
  end

  delete "/:hid/billable_events/:event_id" do
  end

end

