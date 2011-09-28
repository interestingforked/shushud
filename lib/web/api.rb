class Api < Sinatra::Application

  helpers { include Authentication }

  before do
    authenticate_provider
    content_type :json
  end

  get "/heartbeat" do
    JSON.dump({:ok => true})
  end

  get "/:resource_id/billable_events" do
    provider = Provider[params[:provider_id]]

    if provider.write_to_billable_events?
      builder = EventBuilder.new(ShushuBE)
    else
      builder = EventBuilder.new(CoreRH)
    end

    cond = {:resource_id => params[:resource_id], :provider_id => params[:provider_id]}
    events = builder.find(cond)
    JSON.dump(events.map(&:api_values))
  end

  put "/:resource_id/billable_events/:event_id" do
    provider = Provider[params[:provider_id]]

    if provider.write_to_billable_events?
      builder = EventBuilder.new(ShushuBE)
    else
      builder = EventBuilder.new(CoreRH)
    end

    http_status, event = builder.handle_incomming(
      :provider_id    => params[:provider_id],
      :event_id       => params[:event_id],
      :resource_id    => params[:resource_id],
      :rate_code      => params[:rate_code],
      :qty            => params[:qty],
      :reality_from   => params[:from],
      :reality_to     => params[:to]
    )
    status(http_status)
    body(JSON.dump(event.api_values))
  end

  delete "/:resource_id/billable_events/:event_id" do
  end

end

