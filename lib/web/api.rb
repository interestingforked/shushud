module Shushu
  module Web
    class Api < Sinatra::Application

      helpers { include Web::Authentication }

      before do
        authenticate_provider
        LogJam.setup_logger(Kernel, :puts)
        LogJam.priorities(:provider, :event)
        content_type :json
      end

      get "/heartbeat" do
        JSON.dump({:ok => true})
      end

      get "/:resource_id/billable_events" do
        cond = {:resource_id => params[:resource_id], :provider_id => params[:provider_id]}
        events = BillableEvent.filter(cond).all.map(&:api_values)
        JSON.dump(events)
      end

      put "/:resource_id/billable_events/:event_id" do
        http_status, event = EventBuilder.handle_incomming(
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
  end
end
