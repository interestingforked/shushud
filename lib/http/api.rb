module Http
  class Api < Sinatra::Base

    include Authentication
    include Helpers

    before  {content_type(:json)}
    #
    # Errors
    #
    not_found do
      status(404)
      body(enc_json("Not Found"))
    end

    #
    # Heartbeat
    #
    get "/heartbeat" do
      authenticate_provider
      status(200)
      body({:alive => Time.now})
    end

    #
    # Accounts
    #
    post "/accounts" do
      authenticate_trusted_consumer
      perform do
        Account.create.to_h
      end
    end

    #
    # Reports
    #
    get "/accounts/:account_id/usage_reports" do
      authenticate_trusted_consumer
      perform do
        ReportService.usage_report(params[:account_id], dec_time(params[:from]), dec_time(params[:to]))
      end
    end

    #
    # BillableEvents
    #
    get "/resources/:hid/billable_events" do
      authenticate_provider #sets params[:provider_id]
      perform do
        BillableEventService.find({:hid => params[:hid], :provider_id => params[:provider_id]})
      end
    end

    put "/resources/:hid/billable_events/:event_id" do
      authenticate_provider #sets params[:provider_id]
      perform do
        BillableEventService.handle_new_event(
          :provider_id    => params[:provider_id],
          :rate_code_slug => params[:rate_code],
          :hid            => params[:hid],
          :event_id       => params[:event_id],
          :qty            => params[:qty],
          :time           => dec_time(params[:time]),
          :state          => params[:state]
        )
      end
    end

    #
    # AccountOwnership
    #
    post "/payment_methods/:payment_method_id/account_ownerships/:event_id" do
      authenticate_trusted_consumer
      perform do
        AccountOwnershipService.activate(
          dec_int(params[:payment_method_id]),
          dec_int(params[:account_id]),
          dec_time(params[:time]),
          params[:event_id]
        )
      end
    end

    put "/payment_methods/:prev_payment_method_id/account_ownerships/:prev_event_id" do
      authenticate_trusted_consumer
      perform do
        AccountOwnershipService.transfer(
          dec_int(params[:prev_payment_method_id]),
          dec_int(params[:payment_method_id]),
          dec_int(params[:account_id]),
          dec_time(params[:time]),
          params[:prev_event_id],
          params[:event_id]
        )
      end
    end

    #
    # ResourceOwnership
    #
    get "/accounts/:account_id/resource_ownerships" do
      authenticate_trusted_consumer
      perform do
        ResourceOwnershipService.query(params[:account_id])
      end
    end

    post "/accounts/:account_id/resource_ownerships/:event_id" do
      authenticate_trusted_consumer
      perform do
        ResourceOwnershipService.activate(dec_int(params[:account_id]), params[:hid], dec_time(params[:time]), params[:event_id])
      end
    end

    put "/accounts/:prev_account_id/resource_ownerships/:prev_event_id" do
      authenticate_trusted_consumer
      perform do
        ResourceOwnershipService.transfer(
          dec_int(params[:prev_account_id]),
          dec_int(params[:account_id]),
          params[:hid],
          dec_time(params[:time]),
          params[:prev_event_id],
          params[:event_id]
        )
      end
    end

    delete "/accounts/:account_id/resource_ownerships/:event_id" do
      authenticate_trusted_consumer
      perform do
        ResourceOwnershipService.deactivate(dec_int(params[:account_id]), params[:hid], dec_time(params[:time]), params[:event_id])
      end
    end

    #
    # RateCode
    #
    post "/providers/:target_provider_id/rate_codes" do
      authenticate_provider
      perform do
        RateCodeService.create(
          :provider_id        => params[:provider_id],
          :target_provider_id => params[:target_provider_id],
          :slug               => params[:slug],
          :rate               => params[:rate],
          :product_group      => params[:group],
          :product_name       => params[:name]
        )
      end
    end

    post "/rate_codes" do
      authenticate_provider
      perform do
        RateCodeService.create(
          :provider_id        => params[:provider_id],
          :slug               => params[:slug],
          :rate               => params[:rate],
          :product_group      => params[:group],
          :product_name       => params[:name]
        )
      end
    end

    put "/rate_codes/:rate_code_slug" do
      authenticate_provider
      perform do
        RateCodeService.update(
          :provider_id        => params[:provider_id],
          :target_provider_id => params[:target_provider_id],
          :slug               => params[:rate_code_slug],
          :rate               => params[:rate],
          :product_group      => params[:group],
          :product_name       => params[:name]
        )
      end
    end

    get "/rate_codes/:rate_code_slug" do
      authenticate_provider
      perform do
        RateCodeService.find(params[:rate_code_slug])
      end
    end

    def perform
      begin
        exception_message = nil
        res = yield
        json = enc_json(res)
        status(status_based_on_verb(request.request_method))
        body(json)
      rescue RuntimeError => e
        log("#http_api_runtime_error e=#{e.message} s=#{e.backtrace}")
        status(400)
        body(enc_json(e.message))
      rescue Shushu::AuthorizationError => e
        log("#http_api_authorization_error e=#{e.message} s=#{e.backtrace}")
        status(403)
        body(enc_json(e.message))
      rescue Shushu::NotFound => e
        log("#http_api_find_error e=#{e.message} s=#{e.backtrace}")
        status(404)
        body(enc_json(e.message))
      rescue Shushu::DataConflict => e
        log("#http_api_data_error e=#{e.message} s=#{e.backtrace}")
        status(409)
        body(enc_json(e.message))
      rescue Exception => e
        log("#http_api_error e=#{e.message} s=#{e.backtrace}")
        status(500)
        body(enc_json(e.message))
        raise if Shushu.test?
      end
    end

    def log(msg)
      shulog("account=#{params[:account_id]} provider=#{params[:provider_id]} hid=#{params[:hid]} #{msg}")
    end

  end
end
