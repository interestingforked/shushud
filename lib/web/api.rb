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
        authenticate_provider

        event_params = {}
        BillableEvent::ATTRS.each do |key|
          event_params[key] = params[key]
        end
        event_params[:provider_id] = request.env["PROVIDER_ID"]

        http_status, http_resp = EventCurator.process(event_params)
        content_type :json
        status(http_status)
        body(http_resp)
      end

      delete "/resources/:resource_id/billable_events/:event_id" do
      end

    end
  end
end
