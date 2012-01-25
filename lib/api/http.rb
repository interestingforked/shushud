module Api
  class Http < Sinatra::Base
    include Authentication
    include Helpers

    before {authenticate_provider; content_type(:json)}
    #
    # Errors
    #
    not_found do
      perform do
        [404, "Not Found"]
      end
    end

    delete "/sessions" do
      session.clear
    end

    #
    # Heartbeat
    #
    get "/heartbeat" do
      perform do
        [200, {:alive => Time.now}]
      end
    end

    #
    # Accounts
    #
    post "/accounts" do
      perform do
        [201, Account.create.to_h]
      end
    end

    #
    # Receivables
    #
    post "/receivables" do
      perform do
        ReceivablesService.create(
          enc_int(params[:init_payment_method_id]),
          enc_int(params[:amount]),
          enc_time(params[:from]),
          enc_time(params[:to])
        )
      end
    end

    #
    # PaymentAttempts
    #
    post "/receivables/:receivable_id/payment_attempts" do
      perform do
        PaymentService.attempt(
          enc_int(params[:receivable_id]),
          enc_int(params[:payment_method_id]),
          enc_time(params[:wait_until])
        )
      end
    end

    #
    # Reports
    #
    get "/accounts/:account_id/usage_reports" do
      perform do
        ReportService.usage_report(params[:account_id], dec_time(params[:from]), dec_time(params[:to]))
      end
    end

    get "/rev_report" do
      perform do
        ReportService.rev_report(dec_time(params[:from]), dec_time(params[:to]))
      end
    end

    #
    # BillableEvents
    #
    get "/billable_events" do
      perform do
        BillableEventService.find(enc_int(session[:provider_id]))
      end
    end

    put "/resources/:hid/billable_events/:entity_id" do
      perform do
        BillableEventService.handle_new_event(
          :provider_id    => session[:provider_id],
          :rate_code_slug => params[:rate_code],
          :product_name   => params[:product_name],
          :hid            => params[:hid],
          :entity_id      => params[:entity_id],
          :qty            => params[:qty],
          :time           => dec_time(params[:time]),
          :state          => params[:state]
        )
      end
    end

    #
    # AccountOwnership
    #
    post "/payment_methods/:payment_method_id/account_ownerships/:entity_id" do
      perform do
        AccountOwnershipService.activate(
          dec_int(params[:payment_method_id]),
          dec_int(params[:account_id]),
          dec_time(params[:time]),
          params[:entity_id]
        )
      end
    end

    put "/payment_methods/:prev_payment_method_id/account_ownerships/:prev_entity_id" do
      perform do
        AccountOwnershipService.transfer(
          dec_int(params[:prev_payment_method_id]),
          dec_int(params[:payment_method_id]),
          dec_int(params[:account_id]),
          dec_time(params[:time]),
          params[:prev_entity_id],
          params[:entity_id]
        )
      end
    end

    #
    # ResourceOwnership
    #
    get "/accounts/:account_id/resource_ownerships" do
      perform do
        ResourceOwnershipService.query(params[:account_id])
      end
    end

    post "/accounts/:account_id/resource_ownerships/:entity_id" do
      perform do
        ResourceOwnershipService.activate(dec_int(params[:account_id]), params[:hid], dec_time(params[:time]), params[:entity_id])
      end
    end

    put "/accounts/:prev_account_id/resource_ownerships/:prev_entity_id" do
      perform do
        ResourceOwnershipService.transfer(
          dec_int(params[:prev_account_id]),
          dec_int(params[:account_id]),
          params[:hid],
          dec_time(params[:time]),
          params[:prev_entity_id],
          params[:entity_id]
        )
      end
    end

    delete "/accounts/:account_id/resource_ownerships/:entity_id" do
      perform do
        ResourceOwnershipService.deactivate(dec_int(params[:account_id]), params[:hid], dec_time(params[:time]), params[:entity_id])
      end
    end

    #
    # RateCode
    #
    post "/providers/:target_provider_id/rate_codes" do
      perform do
        RateCodeService.create(
          :provider_id        => session[:provider_id],
          :target_provider_id => params[:target_provider_id],
          :slug               => params[:slug],
          :rate               => params[:rate],
          :product_group      => params[:group],
          :product_name       => params[:name]
        )
      end
    end

    post "/rate_codes" do
      perform do
        RateCodeService.create(
          :provider_id        => session[:provider_id],
          :slug               => params[:slug],
          :rate               => params[:rate],
          :product_group      => params[:group],
          :product_name       => params[:name]
        )
      end
    end

    put "/rate_codes/:rate_code_slug" do
      perform do
        RateCodeService.update(
          :provider_id        => session[:provider_id],
          :target_provider_id => params[:target_provider_id],
          :slug               => params[:rate_code_slug],
          :rate               => params[:rate],
          :product_group      => params[:group],
          :product_name       => params[:name]
        )
      end
    end

    get "/rate_codes/:rate_code_slug" do
      perform do
        RateCodeService.find(params[:rate_code_slug])
      end
    end

    def perform
      begin
        Log.debug("#api_begin_request")
        s, b = yield
        Log.debug("#api_prepare_status")
        status(s)
        Log.debug("#api_prepare_body")
        body(enc_json(b))
        Log.debug("#api_finish_request")
      rescue RuntimeError, ArgumentError => e
        log("#api_error_runtime_arg e=#{e.message} s=#{e.backtrace}")
        status(400)
        body(enc_json(e.message))
      rescue Shushu::AuthorizationError => e
        log("#api_error_authorization e=#{e.message} s=#{e.backtrace}")
        status(403)
        body(enc_json(e.message))
      rescue Shushu::NotFound => e
        log("#api_error_not_found e=#{e.message} s=#{e.backtrace}")
        status(404)
        body(enc_json(e.message))
      rescue Shushu::DataConflict => e
        log("#api_error_conflict e=#{e.message} s=#{e.backtrace}")
        status(409)
        body(enc_json(e.message))
      rescue Exception => e
        log("#api_error_unhandled e=#{e.message} s=#{e.backtrace}")
        status(500)
        body(enc_json(e.message))
        raise if Shushu.test?
      end
    end

    def log(msg)
      Log.info("account=#{params[:account_id]} provider=#{session[:provider_id]} hid=#{params[:hid]} #{msg}")
    end

  end
end
