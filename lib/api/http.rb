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
        [201, Account.create(:provider_id => session[:provider_id]).to_h]
      end
    end

    #
    # Receivables
    #
    post "/receivables" do
      perform do
        ReceivablesService.create(
          session[:provider_id],
          enc_int(params[:init_payment_method_id]),
          enc_int(params[:amount]),
          enc_time(params[:from]),
          enc_time(params[:to])
        )
      end
    end

    #
    # PaymentMethod
    #
    post "/payment_methods" do
      perform do
        PaymentMethodService.new_payment_method(
          :provider_id    => session[:provider_id],
          :slug           => nil,
          :card_token     => params[:card_token],
          :card_num       => params[:card_num],
          :card_exp_year  => params[:card_exp_year],
          :card_exp_month => params[:card_exp_month]
        )
      end
    end

    put "/payment_methods/:slug" do
      perform do
        PaymentMethodService.new_payment_method(
          :provider_id    => session[:provider_id],
          :slug           => params[:slug],
          :card_token     => params[:card_token],
          :card_num       => params[:card_num],
          :card_exp_year  => params[:card_exp_year],
          :card_exp_month => params[:card_exp_month]
        )
      end
    end

    #
    # PaymentAttempts
    #
    post "/receivables/:receivable_id/payment_attempts" do
      perform do
        PaymentService.attempt(
          session[:provider_id],
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
          :rate_code_id   => params[:rate_code],
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
    put "/payment_methods/:payment_method_id/account_ownerships/:entity_id" do
      perform do
        AccountOwnershipService.handle_new_event(
          params[:state],
          session[:provider_id],
          dec_int(params[:payment_method_id]),
          dec_int(params[:account_id]),
          dec_time(params[:time]),
          params[:entity_id]
        )
      end
    end

    #
    # ResourceOwnership
    #
    put "/accounts/:account_id/resource_ownerships/:entity_id" do
      perform do
        ResourceOwnershipService.handle_new_event(
          params[:state],
          session[:provider_id],
          enc_int(params[:account_id]),
          params[:resource_id],
          dec_time(params[:time]),
          params[:entity_id]
        )
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
        t0 = Time.now
        Log.info({:action => "begin_api_request", :provider_id => session[:provider_id]}.merge(params))
        s, b = yield
        status(s)
        body(enc_json(b))
        t1 = Time.now
        Log.info({:action => "finish_api_request", :elapsed_time => (t1 - t0), :provider_id => session[:provider_id]}.merge(params))
      rescue RuntimeError, ArgumentError => e
        Log.error({:error => "argument", :exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(400)
        body(enc_json(e.message))
      rescue Shushu::AuthorizationError => e
        Log.error({:error => "authorization", :exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(403)
        body(enc_json(e.message))
      rescue Shushu::NotFound => e
        Log.error({:error => "not-found", :exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(404)
        body(enc_json(e.message))
      rescue Shushu::DataConflict => e
        Log.error({:error => "conflict", :exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(409)
        body(enc_json(e.message))
      rescue Exception => e
        Log.error({:error => true, :exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(500)
        body(enc_json(e.message))
        raise if Shushu.test?
      end
    end

  end
end
