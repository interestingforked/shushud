class EventsApi < Sinatra::Application

  helpers { include Authentication }

  before do
    authenticate_provider #sets params[:provider_id]
    content_type :json
  end

  get "/:hid/billable_events" do
    provider = Provider[params[:provider_id]]
    events = EventHandler.find({:hid => params[:hid], :provider_id => provider.id})
    JSON.dump(events.map(&:api_values))
  end

  put "/:hid/billable_events/:event_id" do
    provider  = Provider[params[:provider_id]]
    rate_code = RateCode[:slug => params[:rate_code]]

    http_status, event = EventHandler.handle(
      :provider_id    => provider.id,
      :rate_code_id   => rate_code.id,
      :hid            => params[:hid],
      :event_id       => params[:event_id],
      :qty            => params[:qty],
      :time           => params[:time],
      :state          => params[:state]
    )
    status(http_status)
    body(JSON.dump(event.api_values))
  end

  delete "/:hid/billable_events/:event_id" do
  end

end
