module Shushu
  module Web
    class Api < Sinatra::Application

      helpers do
        include Web::Authentication
      end

      get "/heartbeat" do
        authenticate_provider
        {:ok => true}.to_json
      end

      put "/resources/:resource_id/billable_events/:event_id" do
        LogJam.setup_logger(Kernel, :puts)
        LogJam.priorities(:provider, :event)

        authenticate_provider

        event = BillableEvent.find_or_instantiate_by_provider_and_event(params[:provider_id], params[:event_id])
        event.set_all(params)
        http_status, http_resp = EventHttpHelper.process!(event)

        content_type :json
        status(http_status)
        body(http_resp)
      end

      delete "/resources/:resource_id/billable_events/:event_id" do
      end

    end
  end
end
