require './lib/billable_event'
require './lib/rate_code'
require './lib/resource_ownership'

module Api
  class Http < Sinatra::Base
    include Authentication
    include Helpers

    register Sinatra::Instrumentation
    instrument_routes

    before {authenticate_provider; content_type(:json)}

    not_found do
      perform do
        [404, "Not Found"]
      end
    end

    head "/" do
      status(200)
      body(nil)
    end

    get "/heartbeat" do
      perform do
        [200, {:alive => Time.now}]
      end
    end

    put "/resources/:hid/billable_events/:entity_id" do
      perform do
        Shushu::BillableEvent.handle_in(
          :provider_id    => session[:provider_id],
          :rate_code      => params[:rate_code],
          :product_name   => params[:product_name],
          :description    => params[:description],
          :hid            => params[:hid],
          :entity_id_uuid => params[:entity_id_uuid],
          :entity_id      => params[:entity_id],
          :qty            => params[:qty],
          :time           => dec_time(params[:time]),
          :state          => params[:state]
        )
      end
    end

    put "/accounts/:account_id/resource_ownerships/:entity_id" do
      perform do
        Shushu::ResourceOwnership.handle_in(
          params[:state],
          session[:provider_id],
          params[:account_id],
          params[:resource_id],
          dec_time(params[:time]),
          params[:entity_id]
        )
      end
    end

    post "/rate_codes" do
      perform do
        Shushu::RateCode.handle_in(
          :provider_id   => session[:provider_id],
          :rate          => params[:rate],
          :period        => params[:period],
          :product_group => params[:group],
          :product_name  => params[:name]
        )
      end
    end

    put "/rate_codes/:slug" do
      perform do
        Shushu::RateCode.handle_in(
          :provider_id   => session[:provider_id],
          :slug          => params[:slug],
          :rate          => params[:rate],
          :period        => params[:period],
          :product_group => params[:group],
          :product_name  => params[:name]
        )
      end
    end

    def perform
      begin
        s, b = yield
        status(s)
        body(enc_json(b))
      rescue Exception => e
        log({level: "error", exception: e.message}.merge(params))
        status(500)
        body(enc_json(e.message))
      end
    end
  end
end
