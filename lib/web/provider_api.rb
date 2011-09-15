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
      puts "found rate code with slug=#{params[:rate_code_slug]}"
    end

    put "/:rate_code_slug" do
      puts "updated rate code with slug=#{params[:rate_code_slug]}"
    end

    def log(msg)
      puts("api=provider_api provider=#{params[:provider_id]} #{msg}")
    end
    
  end
end
