module Shushu
  class Web::ProviderApi < Sinatra::Application

    post "/" do
      puts "create rate code rate=#{params[:rate]} description=#{params[:description]}"
      
      rate_code = RateCode.new(
        :provider_id => params[:provider_id],
        :rate        => params[:rate],
        :description => params[:description]
      )
      
      if rate_code.save
        status(201)
        body(JSON.dump(rate_code.api_values))
      else
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
    
  end
end
