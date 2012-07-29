require './lib/shushu'
require './lib/config'
require './lib/authentication'
require './lib/billable_event'
require './lib/rate_code'
require './lib/resource_ownership'
require './lib/resource_history'

module Shushu
  class Web < Sinatra::Base

    # Start a Unicorn http server and serve Shushu's API via HTTP
    #
    def self.start
      log(fn: __method__, at: "build")
      Unicorn::Configurator::RACKUP[:port] = Config.port
      Unicorn::Configurator::RACKUP[:set_listener] = true
      @server = Unicorn::HttpServer.new(Http.new).start.join
      log(fn: __method__, at: "install_trap")
      ["TERM", "INT"].each do |s|
        Signal.trap(s) do
          log(fn: "trap", signal: s)
          @server.stop(true)
          log(fn: "trap", signal: s, at: "exit", status: 0)
          Kernel.exit!(0)
        end
      end
      log(fn: __method__, at: "run", port: Config.port)
      @server.run.join
    end

    include Authentication
    register Sinatra::Instrumentation
    instrument_routes

    before do
      authenticate_provider
      content_type(:json)
    end

    error do
      e = env['sinatra.error']
      log({level: "error", exception: e.message}.merge(params))
      [500, Utils.enc_j(msg: "un-handled error")]
    end

    not_found do
      [404, Utils.enc_j(msg: "endpoint not found")]
    end

    head "/" do
      200
    end

    get "/heartbeat" do
      [200, Utils.enc_j(alive: Time.now)]
    end

    get "/owners/:owner_id/resource_histories" do
      ResourceHistory.fetch(params[:owner_id],
                             Utils.dec_time(params[:from]),
                             Utils.dec_time(params[:to]))
    end

    put "/resources/:hid/billable_events/:entity_id" do
      BillableEvent.
        handle_in(provider_id: session[:provider_id],
                   rate_code: params[:rate_code],
                   product_name: params[:product_name],
                   description: params[:description],
                   hid: params[:hid],
                   entity_id_uuid:  params[:entity_id_uuid],
                   entity_id: params[:entity_id],
                   qty: params[:qty],
                   time: Utils.dec_time(params[:time]),
                   state: params[:state])
    end

    put "/accounts/:account_id/resource_ownerships/:entity_id" do
      ResourceOwnership.
        handle_in(params[:state],
                   session[:provider_id],
                   params[:account_id],
                   params[:resource_id],
                   Utils.dec_time(params[:time]),
                   params[:entity_id])
    end

    post "/rate_codes" do
      RateCode.
        handle_in(provider_id: session[:provider_id],
                   rate: params[:rate],
                   period: params[:period],
                   product_group: params[:group],
                   product_name: params[:name])
    end

    put "/rate_codes/:slug" do
      RateCode.
        handle_in(provider_id: session[:provider_id],
                   slug: params[:slug],
                   rate: params[:rate],
                   period: params[:period],
                   product_group: params[:group],
                   product_name: params[:name])
    end

  end
end
