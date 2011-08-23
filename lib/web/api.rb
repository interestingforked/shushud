module Shushu
  module Web
    class Api < Sinatra::Application

      use Rack::Auth::Basic, "Protected API" do |username, password|
        username == 'sendgrid' && password == 'sendgrid_token'
      end

      get "/heartbeat" do
        {:ok => true}.to_json
      end

      put "/resources/:resource_id/billable_events/:event_id" do
        EventCurator.process(params[:resource_id], params[:event_id], params[:event]) do |http_helper|
          content_type :json
          status(http_helper.status)
          body(http_helper.body)
        end
      end

      delete "/resources/:resource_id/billable_events/:event_id" do
      end

    end
  end
end
