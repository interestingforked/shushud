module Shushu
  class Web::ProviderApi < Sinatra::Application

    helpers { include Web::Authentication }

    before do
      authenticate_provider
      content_type :json
    end

    post "/" do
      log("create rate code rate=#{params[:rate]} description=#{params[:description]}")
      
      rate_code = RateCode.new(
        :provider_id => params[:provider_id],
        :rate        => params[:rate],
        :description => params[:description]
      )
      
      if rate_code.save
        log("rate_code=#{rate_code.id} created")
        status(201)
        body(JSON.dump(rate_code.api_values))
      else
        log("rate_code failed_creation")
        status(422)
        body(JSON.dump("rate_code was not able to save."))
      end
    end
    
    get "/:rate_code_slug" do
      if rate_code = RateCode.find(:slug => params[:rate_code_slug])
        log("action=get_rate_code found rate_code=#{rate_code.id}")
        status(200)
        body(JSON.dump(rate_code.api_values))
      else
        log("action=get_rate_code not_found rate_code_id=#{params[:rate_code_id]}")
        status(404)
        body(JSON.dump({:message => "Could not find rate_code with slug=#{params[:rate_code_slug]}"}))
      end
    end

    put "/:rate_code_slug" do
      begin
        if rate_code = RateCode.find(:slug => params[:rate_code_slug])
          log("action=update_rate_code found rate_code=#{rate_code.id}")
          rate_code.set(params[:rate_code])
          if rate_code.save(:raise_on_failure => false)
            status(200)
            body(JSON.dump(rate_code.api_values))
          else
            status(422)
            body(JSON.dump({:message => "rate_code=#{rate_code.id} params=#{params[:rate_code]} Failed to save changes"}))
          end
        else
          log("action=update_rate_code not_found rate_code_id=#{params[:rate_code_id]}")
          status(404)
          body(JSON.dump({:message => "Could not find rate_code with slug=#{params[:rate_code_slug]}"}))
        end
      rescue Sequel::Error => e
        log("action=update_rate_code error=#{e.inspect}")
        status(422)
        body(JSON.dump({:message => "error=#{e.inspect}"}))
      end
    end

    def log(msg)
      puts("api=provider_api provider=#{params[:provider_id]} #{msg}")
    end
    
  end
end
