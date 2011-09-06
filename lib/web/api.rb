module Shushu
  module Web
    class Api < Sinatra::Application

      helpers do
        include Web::Authentication
      end

      before do
        authenticate_provider
        LogJam.setup_logger(Kernel, :puts)
        LogJam.priorities(:provider, :event)
        content_type :json
      end

      get "/heartbeat" do
        JSON.dump({:ok => true})
      end

      get "/resources/:resource_id/billable_events" do
        cond = {:resource_id => params[:resource_id], :provider_id => params[:provider_id]}
        JSON.dump(BillableEvent.filter(cond).all.map(&:public_values))
      end

      put "/resources/:resource_id/billable_events/:event_id" do
        event = BillableEvent.find_or_instantiate_by_provider_and_event(params[:provider_id], params[:event_id])
        event.set_all(params)
        http_status, http_resp = EventHttpHelper.process!(event)

        status(http_status)
        body(http_resp)
      end

      delete "/resources/:resource_id/billable_events/:event_id" do
      end

    end
  end
end
