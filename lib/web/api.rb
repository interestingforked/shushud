module Shushu
  module Web
    class Api < Sinatra::Application

      get "/heartbeat" do
        {:ok => true}.to_json
      end

      put "/resources/:resource_id/billable_events/:event_id" do
      end

      delete "/resources/:resource_id/billable_events/:event_id" do
      end

    end
  end
end
